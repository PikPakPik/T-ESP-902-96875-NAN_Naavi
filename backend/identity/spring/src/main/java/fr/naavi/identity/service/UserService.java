package fr.naavi.identity.service;

import fr.naavi.identity.dto.input.RegisterDTO;
import fr.naavi.identity.dto.input.ResetPasswordDTO;
import fr.naavi.identity.entity.ResetPasswordRequest;
import fr.naavi.identity.entity.User;
import fr.naavi.identity.repository.ResetPasswordRequestRepository;
import fr.naavi.identity.repository.UserRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.util.Optional;

@Service
public class UserService {
    private final UserRepository userRepository;
    private final ResetPasswordRequestRepository resetPasswordRequestRepository;
    private final RandomService randomService;

    /**
     * Constructs a UserService
     */
    @Autowired
    public UserService(
            UserRepository userRepository,
            ResetPasswordRequestRepository resetPasswordRequestRepository,
            RandomService randomService
    ) {
        this.userRepository = userRepository;
        this.resetPasswordRequestRepository = resetPasswordRequestRepository;
        this.randomService = randomService;
    }

    /**
     * Checks if a user with the given email exists in the repository.
     *
     * @param email The email of the user to check.
     * @return The User entity if found, otherwise null.
     */
    public User checkIfUserExists(String email) {
        Optional<User> user = this.userRepository.findByEmail(email);

        return user.orElse(null);
    }

    /**
     * Creates a new user from the provided registration data.
     *
     * @param registerDto The registration data containing user details.
     * @return The created User entity.
     */
    public User createUser(RegisterDTO registerDto) {
        User user = new User();

        String encryptedPassword = new BCryptPasswordEncoder().encode(registerDto.getPassword());
        user.setFirstname(registerDto.getFirstname());
        user.setLastname(registerDto.getLastname());
        user.setEmail(registerDto.getEmail());
        user.setPassword(encryptedPassword);

        return this.userRepository.save(user);
    }

    /**
     * Creates a reset password request for the given user.
     *
     * @param user The user for whom the reset password request is created.
     * @return The created ResetPasswordRequest entity.
     */
    public ResetPasswordRequest createResetPasswordRequest(User user) {
        ResetPasswordRequest resetPasswordRequest = new ResetPasswordRequest();

        resetPasswordRequest.setUser(user);
        resetPasswordRequest.setToken(this.randomService.randomString(32));

        return this.resetPasswordRequestRepository.save(resetPasswordRequest);
    }

    /**
     * Checks if a reset password request exists for the given token.
     * If the request is expired, it deletes the request and returns null.
     *
     * @param token The token to check.
     * @return The ResetPasswordRequest if found and not expired, otherwise null.
     */
    public ResetPasswordRequest checkIfResetPasswordRequestExists(String token) {
        Optional<ResetPasswordRequest> resetPasswordRequest = this.resetPasswordRequestRepository.findByToken(token);

        if (resetPasswordRequest.isEmpty()) {
            return null;
        }

        ResetPasswordRequest request = resetPasswordRequest.get();

        if (request.getExpiredAt().isBefore(LocalDateTime.now())) {
            this.resetPasswordRequestRepository.delete(request);
            return null;
        }

        return request;
    }

    /**
     * Updates the user's password with the new password provided in the reset password DTO.
     *
     * @param user The user whose password is to be updated.
     * @param resetPasswordDTO The DTO containing the new password.
     */
    public void updatePassword(User user, ResetPasswordDTO resetPasswordDTO) {
        String encryptedPassword = new BCryptPasswordEncoder().encode(resetPasswordDTO.getPassword());
        user.setPassword(encryptedPassword);
        this.userRepository.save(user);
    }

    /**
     * Deletes a reset password request from the repository.
     *
     * @param resetPasswordRequest The ResetPasswordRequest entity to delete.
     */
    public void deleteResetPasswordRequest(ResetPasswordRequest resetPasswordRequest) {
        this.resetPasswordRequestRepository.delete(resetPasswordRequest);
    }
}
