package fr.naavi.identity.repository.interfaces;

import fr.naavi.core.dto.PaginationDTO;
import fr.naavi.core.dto.PaginatorDto;
import fr.naavi.identity.dto.output.UserDto;
import fr.naavi.identity.entity.User;

import java.util.Optional;

public interface UserRepositoryInterface {
    /**
     * Find all users with pagination.
     *
     * @param paginationDTO The pagination data.
     * @return The paginated users.
     */
    PaginatorDto<UserDto> findAllUserWithPagination(PaginationDTO paginationDTO);

    /**
     * Find a user by id and status not deleted.
     *
     * @param id The user id.
     * @return The user if found, otherwise null.
     */
    Optional<User> findByIdAndStatusNotDeleted(Long id);
}
