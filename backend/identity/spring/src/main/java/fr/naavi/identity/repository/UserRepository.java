package fr.naavi.identity.repository;

import fr.naavi.core.dto.PaginationDTO;
import fr.naavi.core.dto.PaginatorDto;
import fr.naavi.identity.dto.output.UserDto;
import fr.naavi.identity.entity.User;
import fr.naavi.identity.repository.interfaces.UserRepositoryInterface;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;

public interface UserRepository extends JpaRepository<User, Long>, UserRepositoryInterface {
    /**
     * @param email the email address of the user to find
     * @return an Optional containing the User if found, or empty if not found
     */
    Optional<User> findByEmail(String email);

    /**
     * Find all users with pagination.
     *
     * @param paginationDTO The pagination data.
     * @return The PaginatorDto containing the users.
     */
    PaginatorDto<UserDto> findAllUserWithPagination(PaginationDTO paginationDTO);
}