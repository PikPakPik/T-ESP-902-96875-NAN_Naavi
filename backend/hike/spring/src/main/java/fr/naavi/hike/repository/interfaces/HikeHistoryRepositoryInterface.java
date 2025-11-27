package fr.naavi.hike.repository.interfaces;

import fr.naavi.core.dto.PaginationDTO;
import fr.naavi.core.dto.PaginatorDTO;
import fr.naavi.hike.dto.output.HikeHistoryDto;

public interface HikeHistoryRepositoryInterface {
    /**
     * Find all hikes with pagination.
     *
     * @param paginationDTO The pagination data.
     * @param userId The user Id.
     * @return The paginated hikes.
     */
    PaginatorDTO<HikeHistoryDto> findAllWithPagination(PaginationDTO paginationDTO, Long userId);
}
