package fr.naavi.hike.repository.interfaces;

import fr.naavi.core.dto.PaginationDTO;
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

    /**
     * Find all hikes owned by a user with pagination.
     *
     * @param paginationDTO The pagination data.
     * @param userId        The user ID.
     * @return The paginated hikes.
     */
    PaginatorDTO<HikeDto> findAllByUserIdWithPagination(PaginationDTO paginationDTO, Long userId);
}
