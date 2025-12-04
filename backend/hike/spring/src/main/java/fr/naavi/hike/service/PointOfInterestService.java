package fr.naavi.hike.service;

import fr.naavi.core.exception.children.NaaviBadCredentialsException;
import fr.naavi.hike.dto.input.PointOfInterestDTO;
import fr.naavi.hike.dto.output.PointOfInterestDto;
import fr.naavi.hike.entity.PointOfInterest;
import fr.naavi.hike.enums.PointOfInterestCategoryEnum;
import fr.naavi.hike.enums.StatusEnum;
import fr.naavi.hike.repository.PointOfInterestRepository;
import org.springframework.stereotype.Service;

import java.util.Objects;

@Service
public class PointOfInterestService {
    private final PointOfInterestRepository pointOfInterestRepository;

    /**
     * Constructor for PointOfInterestService.
     *
     * @param pointOfInterestRepository The point of interest repository.
     */
    public PointOfInterestService(
            PointOfInterestRepository pointOfInterestRepository
    ) {
        this.pointOfInterestRepository = pointOfInterestRepository;
    }

    /**
     * Create a new point of interest.
     *
     * @param pointOfInterestDTO The point of interest to create.
     * @return The created point of interest.
     */
    public PointOfInterestDto createPointOfInterest(PointOfInterestDTO pointOfInterestDTO) {
        PointOfInterest pointOfInterest = new PointOfInterest();
        pointOfInterest.setName(pointOfInterestDTO.getName());
        pointOfInterest.setDescription(pointOfInterestDTO.getDescription());
        pointOfInterest.setLatitude(pointOfInterestDTO.getLatitude());
        pointOfInterest.setLongitude(pointOfInterestDTO.getLongitude());

        if (pointOfInterestDTO.getCategories() != null) {
            pointOfInterest.setCategories(pointOfInterestDTO.getCategories().stream()
                    .filter(this::isValidCategory)
                    .map(PointOfInterestCategoryEnum::valueOf)
                    .toList());
        }

        if (pointOfInterestDTO.getStatus() != null && isValidStatus(pointOfInterestDTO.getStatus())) {
            pointOfInterest.setStatus(StatusEnum.valueOf(pointOfInterestDTO.getStatus()));
        }

        return new PointOfInterestDto(this.pointOfInterestRepository.save(pointOfInterest), true);
    }

    /**
     * Update a point of interest.
     *
     * @param pointOfInterest The point of interest to update.
     * @param pointOfInterestDTO The updated point of interest.
     * @return The updated point of interest.
     */
    public PointOfInterestDto updatePointOfInterest(PointOfInterest pointOfInterest, PointOfInterestDTO pointOfInterestDTO) {
        if (!Objects.equals(pointOfInterestDTO.getName(), pointOfInterest.getName())) {
            pointOfInterest.setName(pointOfInterestDTO.getName());
        }

        if (!Objects.equals(pointOfInterestDTO.getDescription(), pointOfInterest.getDescription())) {
            pointOfInterest.setDescription(pointOfInterestDTO.getDescription());
        }

        if (!Objects.equals(pointOfInterestDTO.getLatitude(), pointOfInterest.getLatitude())) {
            pointOfInterest.setLatitude(pointOfInterestDTO.getLatitude());
        }

        if (!Objects.equals(pointOfInterestDTO.getLongitude(), pointOfInterest.getLongitude())) {
            pointOfInterest.setLongitude(pointOfInterestDTO.getLongitude());
        }

        if (pointOfInterestDTO.getCategories() != null) {
            pointOfInterest.setCategories(pointOfInterestDTO.getCategories().stream()
                    .filter(this::isValidCategory)
                    .map(PointOfInterestCategoryEnum::valueOf)
                    .toList());
        }

        if (pointOfInterestDTO.getStatus() != null && isValidStatus(pointOfInterestDTO.getStatus())) {
            pointOfInterest.setStatus(StatusEnum.valueOf(pointOfInterestDTO.getStatus()));
        }

        return new PointOfInterestDto(this.pointOfInterestRepository.save(pointOfInterest), true);
    }

    /**
     * Delete a point of interest.
     *
     * @param pointOfInterest The point of interest to delete.
     */
    public void deletePointOfInterest(PointOfInterest pointOfInterest) {
        this.pointOfInterestRepository.delete(pointOfInterest);
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
                    "point_of_interest.status_invalid",
                    "The status '" + status + "' does not exist."
            );
        }
    }

    /**
     * Check if the given category is valid.
     *
     * @param category The category to check.
     * @return True if the season is valid, false otherwise.
     */
    @SuppressWarnings("PMD.UnusedPrivateMethod")
    private boolean isValidCategory(String category) {
        try {
            PointOfInterestCategoryEnum.valueOf(category);
            return true;
        } catch (IllegalArgumentException e) {
            throw new NaaviBadCredentialsException(
                    "point_of_interest.category_invalid",
                    "The category '" + category + "' does not exist."
            );
        }
    }
}
