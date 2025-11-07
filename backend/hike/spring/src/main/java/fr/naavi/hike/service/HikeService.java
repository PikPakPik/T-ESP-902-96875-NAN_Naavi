package fr.naavi.hike.service;

import fr.naavi.core.exception.children.NaaviBadCredentialsException;
import fr.naavi.hike.dto.input.HikeDTO;
import fr.naavi.hike.dto.output.HikeDto;
import fr.naavi.hike.entity.Hike;
import fr.naavi.hike.enums.DifficultyEnum;
import fr.naavi.hike.enums.StatusEnum;
import fr.naavi.hike.repository.HikeRepository;
import org.springframework.stereotype.Service;

import java.util.Map;

@Service
public class HikeService {
    private final HikeRepository hikeRepository;
    private final OpenStreetMapService openStreetMapService;

    /**
     * Constructor for HikeService.
     *
     * @param hikeRepository The hike repository.
     * @param openStreetMapService The OpenStreetMap service.
     */
    public HikeService(
            HikeRepository hikeRepository,
            OpenStreetMapService openStreetMapService
    ) {
        this.hikeRepository = hikeRepository;
        this.openStreetMapService = openStreetMapService;
    }

    /**
     * @param hikeDto The hike to create.
     * @return The created hike.
     */
    public HikeDto createHike(HikeDTO hikeDto) {
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
        hike.setDistance(hikeDto.getDistance());
        hike.setDuration(hikeDto.getDuration());

        if (hikeDto.getDifficulty() != null && isValidDifficulty(hikeDto.getDifficulty())) {
            hike.setDifficulty(DifficultyEnum.valueOf(hikeDto.getDifficulty()));
        }

        if (hikeDto.getStatus() != null && isValidStatus(hikeDto.getStatus())) {
            hike.setStatus(StatusEnum.valueOf(hikeDto.getStatus()));
        }

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

        return new HikeDto(this.hikeRepository.save(hike), true);
    }

    /**
     * @param hike The hike to delete.
     */
    public void deleteHike(Hike hike) {
        this.hikeRepository.delete(hike);
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
}
