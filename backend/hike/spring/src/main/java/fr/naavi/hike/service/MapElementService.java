package fr.naavi.hike.service;

import fr.naavi.core.exception.children.NaaviBadCredentialsException;
import fr.naavi.hike.composite.MapElementReactionId;
import fr.naavi.hike.dto.UserDTO;
import fr.naavi.hike.dto.input.MapElementDTO;
import fr.naavi.hike.entity.MapElement;
import fr.naavi.hike.entity.MapElementReaction;
import fr.naavi.hike.entity.Media;
import fr.naavi.hike.enums.MapElementEnum;
import fr.naavi.hike.enums.ReactionEnum;
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
     * @return The saved map element.
     */
    public MapElement save(MapElement element, MapElementDTO dto, TypeMapElementEnum type) {
        if (element.getId() != null) {
            isValidType(element, type);
        } else {
            element.setType(type);
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

    /**
     * Check if the category is valid.
     *
     * @param category The category to check.
     * @return True if the category is valid, false otherwise.
     */
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

    /**
     * Check if the type of the map element is valid.
     *
     * @param element The map element to check.
     * @param expectedType The expected type of the map element.
     */
    protected void isValidType(MapElement element, TypeMapElementEnum expectedType) {
        if (element.getType() != expectedType) {
            throw new NaaviBadCredentialsException(
                    "map_element.type_mismatch",
                    "Expected type " + expectedType + " but found " + element.getType()
            );
        }
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
