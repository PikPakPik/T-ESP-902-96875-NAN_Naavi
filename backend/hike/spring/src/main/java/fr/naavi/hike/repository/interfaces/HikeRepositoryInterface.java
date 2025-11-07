package fr.naavi.hike.repository.interfaces;

import fr.naavi.core.dto.PaginatorDTO;
import fr.naavi.hike.dto.input.HikePaginationDTO;
import fr.naavi.hike.dto.output.HikeDto;

public interface HikeRepositoryInterface {
    /**
     * Find all hikes with pagination.
     *
     * @param hikePaginationDTO The pagination data.
     * @return The paginated hikes.
     */
    PaginatorDTO<HikeDto> findAllHikeWithPagination(HikePaginationDTO hikePaginationDTO);
}
