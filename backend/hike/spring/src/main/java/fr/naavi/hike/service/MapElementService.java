package fr.naavi.hike.service;

import fr.naavi.core.exception.children.NaaviBadCredentialsException;
import fr.naavi.core.exception.children.NaaviBadRequestException;
import fr.naavi.core.enums.RoleEnum;
import fr.naavi.hike.composite.MapElementReactionId;
import fr.naavi.hike.dto.UserDTO;
import fr.naavi.hike.dto.input.MapElementDTO;
import fr.naavi.hike.entity.MapElement;
import fr.naavi.hike.entity.MapElementReaction;
import fr.naavi.hike.entity.Media;
import fr.naavi.hike.enums.MapElementEnum;
import fr.naavi.hike.enums.ReactionEnum;
import fr.naavi.hike.enums.SourceEnum;
import fr.naavi.hike.enums.StatusEnum;
import fr.naavi.hike.enums.TypeMapElementEnum;
import fr.naavi.hike.repository.MapElementReactionRepository;
import fr.naavi.hike.repository.MapElementRepository;
import org.springframework.stereotype.Service;

import java.util.Objects;

@Service
public class MapElementService {
    private final MapElementRepository mapElementRepository;
    private final MapElementReactionRepository reactionRepository;

    /**
     * Constructor for MapElementService.
     */
    public MapElementService(
            MapElementRepository mapElementRepository,
            MapElementReactionRepository reactionRepository
    ) {
        this.mapElementRepository = mapElementRepository;
        this.reactionRepository = reactionRepository;
    }

    /**
     * Save a map element.
     *
     * @param element The map element to save (can be new or existing).
     * @param dto The DTO containing the data to update.
     * @param type The expected type of the map element.
     * @param currentUser The authenticated user.
     * @return The saved map element.
     */
    public MapElement save(MapElement element, MapElementDTO dto, TypeMapElementEnum type, UserDTO currentUser) {
        boolean isCreate = element.getId() == null;
        boolean isAdminOrModerator = currentUser != null
                && currentUser.getRoles() != null
                && currentUser.getRoles().stream().anyMatch(
                role -> role == RoleEnum.ROLE_ADMIN || role == RoleEnum.ROLE_MODERATOR
        );

        if (!isCreate) {
            isValidType(element, type);
        } else {
            element.setType(type);
            if (dto.getStatus() != null) {
                throw new NaaviBadRequestException(
                        "map_element.status_not_allowed_on_create",
                        "The status is managed by the backoffice validation workflow."
                );
            }
            boolean createForSelf = !isAdminOrModerator
                    || ((dto.getSource() == null || dto.getSource().isBlank()) && dto.getUserId() == null);

            if (createForSelf) {
                applySourceAndOwner(element, null, null, currentUser, true);
            } else {
                applySourceAndOwner(element, dto.getSource(), dto.getUserId(), currentUser, false);
            }
        }
        if (!isCreate && (dto.getSource() != null || dto.getUserId() != null)) {
            applySourceAndOwner(element, dto.getSource(), dto.getUserId(), currentUser, false);
        }
        mapCommonFields(element, dto);

        if (dto.getCategories() != null) {
            element.setCategories(dto.getCategories().stream()
                    .filter(this::isValidCategory)
                    .map(MapElementEnum::valueOf)
                    .toList());
        }

        return mapElementRepository.save(element);
    }

    /**
     * Map common fields between DTO and entity.
     *
     * @param element The entity to update.
     * @param dto The DTO containing the data to update.
     */
    protected void mapCommonFields(MapElement element, MapElementDTO dto) {
        if (!Objects.equals(dto.getName(), element.getName())) {
            element.setName(dto.getName());
        }
        if (!Objects.equals(dto.getDescription(), element.getDescription())) {
            element.setDescription(dto.getDescription());
        }
        if (!Objects.equals(dto.getLatitude(), element.getLatitude())) {
            element.setLatitude(dto.getLatitude());
        }
        if (!Objects.equals(dto.getLongitude(), element.getLongitude())) {
            element.setLongitude(dto.getLongitude());
        }
        if (dto.getStatus() != null && isValidStatus(dto.getStatus())) {
            element.setStatus(StatusEnum.valueOf(dto.getStatus()));
        }
    }

    /**
     * Check if the status is valid.
     *
     * @param status The status to check.
     * @return True if the status is valid, false otherwise.
     */
    protected boolean isValidStatus(String status) {
        try {
            StatusEnum.valueOf(status);
            return true;
        } catch (IllegalArgumentException e) {
            throw new NaaviBadCredentialsException(
                    "map_element.status_invalid",
                    "The status '" + status + "' does not exist."
            );
        }
    }

    protected boolean isValidCategory(String category) {
        try {
            MapElementEnum.valueOf(category);
            return true;
        } catch (IllegalArgumentException e) {
            throw new NaaviBadCredentialsException(
                    "map_element.category_invalid",
                    "The category '" + category + "' does not exist."
            );
        }
    }
    protected void isValidType(MapElement element, TypeMapElementEnum expectedType) {
        if (element.getType() != expectedType) {
            throw new NaaviBadCredentialsException(
                    "map_element.type_mismatch",
                    "Expected type " + expectedType + " but found " + element.getType()
            );
        }
    }

    protected void applySourceAndOwner(
            MapElement element,
            String source,
            Long userId,
            UserDTO currentUser,
            boolean isCreate
    ) {
        SourceEnum targetSource;

        if (isCreate) {
            targetSource = SourceEnum.COMMUNITY;
            userId = currentUser != null ? currentUser.getId() : userId;
        } else if (source == null || source.isBlank()) {
            targetSource = userId == null ? SourceEnum.OFFICIAL : SourceEnum.COMMUNITY;
        } else {
            try {
                targetSource = SourceEnum.valueOf(source);
            } catch (IllegalArgumentException e) {
                throw new NaaviBadCredentialsException(
                        "map_element.source_invalid",
                        "The source '" + source + "' does not exist."
                );
            }
        }

        if (targetSource == SourceEnum.COMMUNITY && userId == null && currentUser != null) {
            userId = currentUser.getId();
        }

        if (targetSource == SourceEnum.OFFICIAL && userId != null) {
            throw new NaaviBadCredentialsException(
                    "map_element.source_user_incompatible",
                    "Official map elements cannot have an owner user."
            );
        }

        if (targetSource == SourceEnum.COMMUNITY && userId == null) {
            throw new NaaviBadCredentialsException(
                    "map_element.user_required",
                    "Community map elements require an owner user id."
            );
        }

        element.setSource(targetSource);
        element.setUserId(targetSource == SourceEnum.COMMUNITY ? userId : null);
    }


    /**
     * Add a media to a map element.
     *
     * @param element The map element to add the media to.
     * @param media The media to add.
     */
    public void addMedia(MapElement element, Media media) {
        element.getImages().add(media);
        mapElementRepository.save(element);
    }

    /**
     * Delete a media from a map element.
     *
     * @param element The map element to delete the media from.
     * @param media The media to delete.
     */
    public void deleteMedia(MapElement element, Media media) {
        element.getImages().remove(media);
        mapElementRepository.save(element);
    }

    /**
     * Add a reaction to a map element.
     *
     * @param element The map element to add the reaction to.
     * @param user The user who added the reaction.
     * @param reaction The reaction type.
     */
    public void addReaction(MapElement element, UserDTO user, ReactionEnum reaction) {
        MapElementReaction r = new MapElementReaction();
        MapElementReactionId id = new MapElementReactionId();
        id.setUserId(user.getId());
        id.setMapElementId(element.getId());

        r.setId(id);
        r.setMapElement(element);
        r.setReaction(reaction);

        reactionRepository.save(r);
    }

    /**
     * Remove a reaction from a map element.
     *
     * @param element The map element to remove the reaction from.
     * @param user The user who removed the reaction.
     * @param reaction The reaction type.
     */
    public void removeReaction(MapElement element, UserDTO user, ReactionEnum reaction) {
        reactionRepository.deleteByUserAndMapElementAndReaction(
                user.getId(),
                element.getId(),
                reaction
        );
    }

    /**
     * Delete a map element.
     *
     * @param element The map element to delete.
     */
    public void delete(MapElement element) {
        mapElementRepository.delete(element);
    }
}
