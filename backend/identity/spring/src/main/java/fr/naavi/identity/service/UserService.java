package fr.naavi.identity.service;

import fr.naavi.core.enums.PermissionEnum;
import fr.naavi.core.enums.RoleEnum;
import fr.naavi.core.exception.children.NaaviBadCredentialsException;
import fr.naavi.core.exception.children.NaaviConflictException;
import fr.naavi.core.exception.children.NaaviNotFoundException;
import fr.naavi.core.service.RandomService;
import fr.naavi.identity.dto.input.RegisterDTO;
import fr.naavi.identity.dto.input.ResetPasswordDTO;
import fr.naavi.identity.dto.input.UserDTO;
import fr.naavi.identity.entity.ResetPasswordRequest;
import fr.naavi.identity.entity.User;
import fr.naavi.identity.enums.StatusEnum;
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

        user.setFirstname(registerDto.getFirstname());
        user.setLastname(registerDto.getLastname());
        user.setEmail(registerDto.getEmail());
        user.setPassword(this.hashPassword(registerDto.getPassword()));

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
     * Creates a new user from the provided registration data.
     *
     * @param userDto The registration data containing user details.
     * @return The created User entity.
     */
    public User createUserFromAdmin(UserDTO userDto) {
        User user = new User();

        user.setFirstname(userDto.getFirstname());
        user.setLastname(userDto.getLastname());
        user.setEmail(userDto.getEmail());
        user.setPassword(this.hashPassword(this.randomService.randomString(32)));
        if (userDto.getRoles() != null) {
            user.setRoles(userDto.getRoles().stream()
                    .filter(role -> !role.equals(RoleEnum.ROLE_USER.name()))
                    .filter(this::isValidRole)
                    .map(RoleEnum::valueOf)
                    .toList());
        }
        if (userDto.getPermissions() != null) {
            user.setPermissions(userDto.getPermissions().stream()
                    .filter(this::isValidPermission)
                    .map(PermissionEnum::valueOf)
                    .toList());
        }
        if (userDto.getStatus() != null && isValidStatus(userDto.getStatus())) {
            user.setStatus(StatusEnum.valueOf(userDto.getStatus()));
        }

        return this.userRepository.save(user);
    }

    /**
     * Updates the user's password with the new password provided in the reset password DTO.
     *
     * @param user The user whose password is to be updated.
     * @param resetPasswordDTO The DTO containing the new password.
     */
    public void updatePassword(User user, ResetPasswordDTO resetPasswordDTO) {
        user.setPassword(this.hashPassword(resetPasswordDTO.getPassword()));
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

    /**
     * Updates the user's details.
     *
     * @param id The ID of the user to update.
     * @param userDto The DTO containing the new details.
     * @return The updated User entity.
     */
    public User updateUser(Long id, UserDTO userDto) {
        User user = userRepository.findByIdAndStatusNotDeleted(id)
                .orElseThrow(() -> new NaaviNotFoundException("user.not_found", "User not found"));

        if (userDto.getFirstname() != null) {
            user.setFirstname(userDto.getFirstname());
        }
        if (userDto.getLastname() != null) {
            user.setLastname(userDto.getLastname());
        }
        if (userDto.getEmail() != null) {
            User existingUser = userRepository.findByEmail(userDto.getEmail()).orElse(null);
            if (existingUser != null && !existingUser.getId().equals(id)) {
                throw new NaaviConflictException(
                        "user.email_already_used",
                        "The email address you entered already exists."
                );
            }
            user.setEmail(userDto.getEmail());
        }
        if (userDto.getRoles() != null) {
            user.setRoles(userDto.getRoles().stream()
                    .filter(role -> !role.equals(RoleEnum.ROLE_USER.name()))
                    .filter(this::isValidRole)
                    .map(RoleEnum::valueOf)
                    .toList());
        }
        if (userDto.getPermissions() != null) {
            user.setPermissions(userDto.getPermissions().stream()
                    .filter(this::isValidPermission)
                    .map(PermissionEnum::valueOf)
                    .toList());
        }
        if (userDto.getStatus() != null && isValidStatus(userDto.getStatus())) {
            user.setStatus(StatusEnum.valueOf(userDto.getStatus()));
        }

        return userRepository.save(user);
    }

    /**
     * Deletes a user from the repository.
     *
     * @param id The ID of the user to delete.
     */
    public void deleteUser(Long id) {
        User user = userRepository.findByIdAndStatusNotDeleted(id)
                .orElseThrow(() -> new NaaviNotFoundException("user.not_found", "User not found"));

        user.setFirstname("User");
        user.setLastname("Deleted");
        user.setEmail("deleted-user" + id + "@naavi-trails.fr");
        user.setStatus(StatusEnum.DELETED);

        String randomPassword = randomService.randomString(16);
        user.setPassword(this.hashPassword(randomPassword));

        userRepository.save(user);
    }

    /**
     * Hashes the password using BCrypt.
     *
     * @param password The password to hash.
     * @return The hashed password.
     */
    private String hashPassword(String password) {
        return new BCryptPasswordEncoder().encode(password);
    }

    /**
     * Checks if the given role is valid.
     *
     * @param role The role to check.
     * @return True if the role is valid, false otherwise.
     */
    @SuppressWarnings("PMD.UnusedPrivateMethod")
    private boolean isValidRole(String role) {
        try {
            RoleEnum.valueOf(role);
            return true;
        } catch (IllegalArgumentException e) {
            throw new NaaviBadCredentialsException(
                    "user.role_invalid",
                    "The role '" + role + "' does not exist."
            );
        }
    }

    /**
     * Checks if the given permission is valid.
     *
     * @param role The permission to check.
     * @return True if the permission is valid, false otherwise.
     */
    @SuppressWarnings("PMD.UnusedPrivateMethod")
    private boolean isValidPermission(String role) {
        try {
            PermissionEnum.valueOf(role);
            return true;
        } catch (IllegalArgumentException e) {
            throw new NaaviBadCredentialsException(
                    "user.permission_invalid",
                    "The permission '" + role + "' does not exist."
            );
        }
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
                    "user.status_invalid",
                    "The status '" + status + "' does not exist."
            );
        }
    }
}
