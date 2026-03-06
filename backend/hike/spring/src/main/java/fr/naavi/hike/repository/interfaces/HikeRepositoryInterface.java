package fr.naavi.hike.repository.interfaces;

import fr.naavi.core.dto.PaginatorDTO;
import fr.naavi.hike.dto.input.GeoPaginationDTO;
import fr.naavi.hike.dto.output.HikeDto;

public interface HikeRepositoryInterface {
    /**
     * Find all hikes with pagination.
     *
     * @param geoPaginationDTO The pagination data.
     * @return The paginated hikes.
     */
    PaginatorDTO<HikeDto> findAllHikeWithPagination(GeoPaginationDTO geoPaginationDTO, boolean includeAllStatus);
}
