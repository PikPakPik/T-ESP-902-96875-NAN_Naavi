package fr.naavi.hike.repository.interfaces;

import fr.naavi.core.dto.PaginatorDTO;
import fr.naavi.hike.dto.input.GeoPaginationDTO;
import fr.naavi.hike.dto.output.PointOfInterestDto;

public interface PointOfInterestRepositoryInterface {
    /**
     * Find all point of interest with pagination.
     *
     * @param geoPaginationDTO The pagination data.
     * @return The paginated point of interests.
     */
    PaginatorDTO<PointOfInterestDto> findAllPointOfInterestWithPagination(GeoPaginationDTO geoPaginationDTO);
}
