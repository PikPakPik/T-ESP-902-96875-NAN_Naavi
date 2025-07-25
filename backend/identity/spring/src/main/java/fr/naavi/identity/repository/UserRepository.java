package fr.naavi.identity.repository;

import fr.naavi.identity.entity.User;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;

public interface UserRepository extends JpaRepository<User, Long> {
    /**
     * @param email the email address of the user to find
     * @return an Optional containing the User if found, or empty if not found
     */
    Optional<User> findByEmail(String email);
}