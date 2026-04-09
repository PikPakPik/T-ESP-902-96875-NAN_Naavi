package fr.naavi.hike.service;

import fr.naavi.core.enums.RoleEnum;
import fr.naavi.core.exception.children.NaaviBadCredentialsException;
import fr.naavi.hike.composite.HikeReactionId;
import fr.naavi.hike.dto.UserDTO;
import fr.naavi.hike.dto.input.HikeDTO;
import fr.naavi.hike.dto.input.HikeHistoryDTO;
import fr.naavi.hike.dto.output.HikeDto;
import fr.naavi.hike.entity.Hike;
import fr.naavi.hike.entity.HikeHistory;
import fr.naavi.hike.entity.HikeReaction;
import fr.naavi.hike.entity.Media;
import fr.naavi.hike.enums.DifficultyEnum;
import fr.naavi.hike.enums.SourceEnum;
import fr.naavi.hike.enums.VisibilityEnum;
import fr.naavi.hike.enums.ReactionEnum;
import fr.naavi.hike.enums.StatusEnum;
import fr.naavi.hike.repository.HikeHistoryRepository;
import fr.naavi.hike.repository.HikeReactionRepository;
import fr.naavi.hike.repository.HikeRepository;
import org.springframework.stereotype.Service;

import java.util.Map;

@Service
public class HikeService {
    private final HikeRepository hikeRepository;
    private final HikeHistoryRepository hikeHistoryRepository;
    private final HikeReactionRepository hikeReactionRepository;
    private final OpenStreetMapService openStreetMapService;

    /**
     * Constructor for HikeService.
     *
     * @param hikeRepository The hike repository.
     * @param hikeHistoryRepository The hike history repository.
     * @param hikeReactionRepository The hike reaction repository.
     * @param openStreetMapService The OpenStreetMap service.
     */
    public HikeService(
            HikeRepository hikeRepository,
            HikeHistoryRepository hikeHistoryRepository,
            HikeReactionRepository hikeReactionRepository,
            OpenStreetMapService openStreetMapService
    ) {
        this.hikeRepository = hikeRepository;
        this.hikeHistoryRepository = hikeHistoryRepository;
        this.hikeReactionRepository = hikeReactionRepository;
        this.openStreetMapService = openStreetMapService;
    }

    /**
     * @param hikeDto The hike to create.
     * @return The created hike.
     */
    public HikeDto createHike(UserDTO user, HikeDTO hikeDto) {
        Hike hike = new Hike();

        hike.setName(hikeDto.getName());
        hike.setStartingPointLatitude(hikeDto.getStartingPointLatitude());
        hike.setStartingPointLongitude(hikeDto.getStartingPointLongitude());
        hike.setStartingElevation(hikeDto.getStartingElevation());
        hike.setArrivalPointLatitude(hikeDto.getArrivalPointLatitude());
        hike.setArrivalPointLongitude(hikeDto.getArrivalPointLongitude());
        hike.setArrivalElevation(hikeDto.getArrivalElevation());

        Map<String, Object> reverseGeocode = this.openStreetMapService.reverseGeocode(hikeDto.getStartingPointLatitude(), hikeDto.getStartingPointLongitude());
        hike.setLocation(reverseGeocode == null ? "unknown" : reverseGeocode.get("name").toString());

        hike.setWkbGeometry(hikeDto.getWkbGeometry());
        hike.setWkbWaypoints(hikeDto.getWkbWaypoints());
        hike.setDistance(hikeDto.getDistance());
        hike.setDuration(hikeDto.getDuration());

        boolean isAdminOrModerator = user != null
                && user.getRoles() != null
                && user.getRoles().stream().anyMatch(
                        role -> role == RoleEnum.ROLE_ADMIN
                                || role == RoleEnum.ROLE_MODERATOR
                );

        // Admin creating without specifying source/userId = create for themselves
        boolean createForSelf = !isAdminOrModerator
                || (isAdminOrModerator && (hikeDto.getSource() == null || hikeDto.getSource().isBlank()) && hikeDto.getUserId() == null);

        if (createForSelf) {
            hike.setSource(SourceEnum.COMMUNITY);
            hike.setUserId(user != null ? user.getId() : null);
        } else {
            applySourceAndOwner(hike, hikeDto.getSource(), hikeDto.getUserId(), user);
        }

        if (hikeDto.getDifficulty() != null && isValidDifficulty(hikeDto.getDifficulty())) {
            hike.setDifficulty(DifficultyEnum.valueOf(hikeDto.getDifficulty()));
        }

        if (hikeDto.getStatus() != null && isValidStatus(hikeDto.getStatus())) {
            hike.setStatus(StatusEnum.valueOf(hikeDto.getStatus()));
        }

        if (hikeDto.getVisibility() != null && isValidVisibility(hikeDto.getVisibility())) {
            hike.setVisibility(VisibilityEnum.valueOf(hikeDto.getVisibility()));
        }

        validateSourceAndVisibility(hike);

        return new HikeDto(this.hikeRepository.save(hike), true);
    }

    /**
     * @param hike The hike to update.
     * @param hikeDto The hike to update with.
     * @return The updated hike.
     */
    public HikeDto updateHike(Hike hike, HikeDTO hikeDto) {
        hike.setName(hikeDto.getName());

        if (hikeDto.getStartingPointLatitude() != null && hikeDto.getStartingPointLongitude() != null) {
            hike.setStartingPointLatitude(hikeDto.getStartingPointLatitude());
            hike.setStartingPointLongitude(hikeDto.getStartingPointLongitude());
            Map<String, Object> reverseGeocode = this.openStreetMapService.reverseGeocode(hikeDto.getStartingPointLatitude(), hikeDto.getStartingPointLongitude());
            hike.setLocation(reverseGeocode == null ? "unknown" : reverseGeocode.get("name").toString());
        }

        if (hikeDto.getStartingElevation() != null) {
            hike.setStartingElevation(hikeDto.getStartingElevation());
        }

        if (hikeDto.getArrivalPointLatitude() != null && hikeDto.getArrivalPointLongitude() != null) {
            hike.setArrivalPointLatitude(hikeDto.getArrivalPointLatitude());
            hike.setArrivalPointLongitude(hikeDto.getArrivalPointLongitude());
        }

        if (hikeDto.getArrivalElevation() != null) {
            hike.setArrivalElevation(hikeDto.getArrivalElevation());
        }

        if (hikeDto.getWkbGeometry() != null && !hikeDto.getWkbGeometry().isEmpty()) {
            hike.setWkbGeometry(hikeDto.getWkbGeometry());
        }

        if (hikeDto.getWkbWaypoints() != null && !hikeDto.getWkbWaypoints().isEmpty()) {
            hike.setWkbWaypoints(hikeDto.getWkbWaypoints());
        }

        if (hikeDto.getDistance() != null) {
            hike.setDistance(hikeDto.getDistance());
        }

        if (hikeDto.getDuration() != null) {
            hike.setDuration(hikeDto.getDuration());
        }

        if (hikeDto.getDifficulty() != null && isValidDifficulty(hikeDto.getDifficulty())) {
            hike.setDifficulty(DifficultyEnum.valueOf(hikeDto.getDifficulty()));
        }

        if (hikeDto.getStatus() != null && isValidStatus(hikeDto.getStatus())) {
            hike.setStatus(StatusEnum.valueOf(hikeDto.getStatus()));
        }

        if (hikeDto.getVisibility() != null && isValidVisibility(hikeDto.getVisibility())) {
            hike.setVisibility(VisibilityEnum.valueOf(hikeDto.getVisibility()));
        }

        if (hikeDto.getSource() != null || hikeDto.getUserId() != null) {
            applySourceAndOwner(hike, hikeDto.getSource(), hikeDto.getUserId(), null);
        }

        validateSourceAndVisibility(hike);

        return new HikeDto(this.hikeRepository.save(hike), true);
    }

    /**
     * Save a hike history.
     *
     * @param user The user.
     * @param hike The hike.
     * @param hikeHistoryDTO The hike history to save.
     */
    public void saveHikeHistory(UserDTO user, Hike hike, HikeHistoryDTO hikeHistoryDTO) {
        HikeHistory hikeHistory = new HikeHistory();

        hikeHistory.setHike(hike);
        hikeHistory.setUser(user.getId());
        hikeHistory.setDuration(hikeHistoryDTO.getDuration());
        hikeHistory.setDistance(hikeHistoryDTO.getDistance());
        hikeHistory.setElevationGain(hikeHistoryDTO.getElevationGain());
        hikeHistory.setAverageSpeed(hikeHistoryDTO.getAverageSpeed());
        hikeHistory.setWkbGeometry(hikeHistoryDTO.getWkbGeometry());
        hikeHistory.setStartingPointLatitude(
            hikeHistoryDTO.getStartingPointLatitude()
        );
        hikeHistory.setStartingPointLongitude(
            hikeHistoryDTO.getStartingPointLongitude()
        );
        hikeHistory.setArrivalPointLatitude(
            hikeHistoryDTO.getArrivalPointLatitude()
        );
        hikeHistory.setArrivalPointLongitude(
            hikeHistoryDTO.getArrivalPointLongitude()
        );
        if (hikeHistoryDTO.getCreatedAt() != null) {
            hikeHistory.setCreatedAt(hikeHistoryDTO.getCreatedAt());
        }

        this.hikeHistoryRepository.save(hikeHistory);
    }

    /**
     * Soft-delete a hike by setting its status to DELETED.
     * History entries are preserved.
     *
     * @param hike The hike to soft-delete.
     */
    public void softDeleteHike(Hike hike) {
        hike.setStatus(StatusEnum.DELETED);
        this.hikeRepository.save(hike);
    }

    /**
     * @param hike The hike to delete.
     */
    public void deleteHike(Hike hike) {
        this.hikeRepository.delete(hike);
    }

    /**
     * Add a media to a hike.
     *
     * @param hike The hike to add the media to.
     * @param media The media to add.
     */
    public void addMedia(Hike hike, Media media) {
        hike.getImages().add(media);
        this.hikeRepository.save(hike);
    }

    /**
     * Delete a media from a hike.
     *
     * @param hike The hike to delete the media from.
     * @param media The media to delete.
     */
    public void deleteMedia(Hike hike, Media media) {
        hike.getImages().remove(media);
        this.hikeRepository.save(hike);
    }

    /**
     * Checks if the given status is valid.
     *
     * @param status The status to check.
     * @return True if the status is valid, false otherwise.
     */
    private boolean isValidStatus(String status) {
        try {
            StatusEnum.valueOf(status);
            return true;
        } catch (IllegalArgumentException e) {
            throw new NaaviBadCredentialsException(
                    "hike.status_invalid",
                    "The status '" + status + "' does not exist."
            );
        }
    }

    /**
     * Checks if the given difficulty is valid.
     *
     * @param difficulty The status to check.
     * @return True if the status is valid, false otherwise.
     */
    private boolean isValidDifficulty(String difficulty) {
        try {
            DifficultyEnum.valueOf(difficulty);
            return true;
        } catch (IllegalArgumentException e) {
            throw new NaaviBadCredentialsException(
                    "hike.difficulty_invalid",
                    "The difficulty '" + difficulty + "' does not exist."
            );
        }
    }

    /**
     * Checks if the given visibility is valid.
     *
     * @param visibility The visibility to check.
     * @return True if the visibility is valid, false otherwise.
     */
    private boolean isValidVisibility(String visibility) {
        try {
            VisibilityEnum.valueOf(visibility);
            return true;
        } catch (IllegalArgumentException e) {
            throw new NaaviBadCredentialsException(
                    "hike.visibility_invalid",
                    "The visibility '" + visibility + "' does not exist."
            );
        }
    }

    /**
     * Add a reaction to a hike.
     *
     * @param hike The hike to add the reaction to.
     * @param user The user who added the reaction.
     * @param reaction The reaction type.
     */
    public void addReaction(Hike hike, UserDTO user, ReactionEnum reaction) {
        HikeReaction hr = new HikeReaction();
        HikeReactionId id = new HikeReactionId();
        id.setUserId(user.getId());
        id.setHikeId(hike.getId());

        hr.setId(id);
        hr.setHike(hike);
        hr.setReaction(reaction);

        hikeReactionRepository.save(hr);
    }

    /**
     * Remove a reaction from a hike.
     *
     * @param hike The hike to remove the reaction from.
     * @param user The user who removed the reaction.
     * @param reaction The reaction type.
     */
    public void removeReaction(Hike hike, UserDTO user, ReactionEnum reaction) {
        hikeReactionRepository.deleteByUserAndHikeAndReaction(
                user.getId(),
                hike.getId(),
                reaction
        );
    }

    private void applySourceAndOwner(Hike hike, String source, Long userId, UserDTO currentUser) {
        SourceEnum targetSource;

        if (source == null || source.isBlank()) {
            targetSource = userId == null ? SourceEnum.OFFICIAL : SourceEnum.COMMUNITY;
        } else {
            targetSource = SourceEnum.valueOf(source);
        }

        // Si COMMUNITY sans userId, assigner l'utilisateur courant
        if (targetSource == SourceEnum.COMMUNITY && userId == null) {
            userId = currentUser != null ? currentUser.getId() : null;
        }

        if (targetSource == SourceEnum.OFFICIAL && userId != null) {
            throw new NaaviBadCredentialsException(
                    "hike.source_user_incompatible",
                    "Official hikes cannot have an owner user."
            );
        }

        if (targetSource == SourceEnum.COMMUNITY && userId == null) {
            throw new NaaviBadCredentialsException(
                    "hike.user_required",
                    "Community hikes require an owner user id."
            );
        }

        hike.setSource(targetSource);
        hike.setUserId(targetSource == SourceEnum.COMMUNITY ? userId : null);
    }

    private void validateSourceAndVisibility(Hike hike) {
        if (hike.getSource() == SourceEnum.OFFICIAL && hike.getVisibility() == VisibilityEnum.PRIVATE) {
            throw new NaaviBadCredentialsException(
                    "hike.official_visibility_invalid",
                    "Official hikes can only be PUBLIC or UNLISTED."
            );
        }
    }
}
