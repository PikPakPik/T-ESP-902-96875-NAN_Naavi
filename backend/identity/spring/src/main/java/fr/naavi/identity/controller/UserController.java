package fr.naavi.identity.controller;

import fr.naavi.core.dto.ApiResponseDTO;
import fr.naavi.core.dto.PaginationDTO;
import fr.naavi.core.dto.PaginatorDTO;
import fr.naavi.core.enums.S3Enum;
import fr.naavi.core.exception.children.NaaviBadRequestException;
import fr.naavi.core.exception.children.NaaviConflictException;
import fr.naavi.core.exception.children.NaaviNotFoundException;
import fr.naavi.core.service.S3Service;
import fr.naavi.identity.abstraction.AbstractController;
import fr.naavi.identity.dto.input.UserDTO;
import fr.naavi.identity.dto.output.UserDto;
import fr.naavi.identity.entity.Authorization;
import fr.naavi.identity.entity.User;
import fr.naavi.identity.repository.UserRepository;
import fr.naavi.identity.service.AuthorizationService;
import fr.naavi.identity.service.MailerService;
import fr.naavi.identity.service.UserService;
import fr.naavi.identity.validation.ValidationGroups;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.enums.SecuritySchemeIn;
import io.swagger.v3.oas.annotations.enums.SecuritySchemeType;
import io.swagger.v3.oas.annotations.media.Content;
import io.swagger.v3.oas.annotations.media.ExampleObject;
import io.swagger.v3.oas.annotations.media.Schema;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.responses.ApiResponses;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.security.SecurityScheme;
import jakarta.validation.Valid;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.util.Set;

@SecurityScheme(
        type = SecuritySchemeType.HTTP,
        name = "bearerAuth",
        scheme = "bearer",
        bearerFormat = "JWT",
        paramName = "Authorization: Bearer <token>",
        in = SecuritySchemeIn.HEADER
)
@RestController
public class UserController extends AbstractController {
    @Autowired
    private UserRepository userRepository;

    @Autowired
    private UserService userService;

    @Autowired
    private MailerService mailerService;

    @Autowired
    private AuthorizationService authorizationService;

    @Autowired
    private S3Service s3Service;

    /**
     * Endpoint to retrieve the current authenticated user.
     * This endpoint returns the details of the user currently authenticated in the session.
     *
     * @return the User object representing the current user
     */
    @Operation(
            summary = "Récupérer l'utilisateur connecté",
            description = "Retourne les informations de l'utilisateur actuellement authentifié. Requiert une authentification.",
            security = @SecurityRequirement(name = "bearerAuth"),
            tags = {"Utilisateur"}
    )
    @ApiResponses(value = {
            @ApiResponse(
                    responseCode = "200",
                    description = "Utilisateur authentifié retourné avec succès.",
                    content = @Content(
                            mediaType = "application/json",
                            schema = @Schema(implementation = UserDto.class)
                    )
            ),
            @ApiResponse(responseCode = "401", ref = "#/components/responses/UnauthorizedError")
    })
    @GetMapping("/user")
    public UserDto user() {
        return new UserDto(this.getUser(), true);
    }

    /**
     * Endpoint to update the current authenticated user.
     *
     * @param userDto the user DTO
     * @return the updated user
     */
    @Operation(
            summary = "Mettre à jour l'utilisateur connecté",
            description = "Met à jour les informations de l'utilisateur actuellement authentifié. Requiert une authentification.",
            security = @SecurityRequirement(name = "bearerAuth"),
            tags = {"Utilisateur"}
    )
    @ApiResponses(value = {
            @ApiResponse(
                    responseCode = "200",
                    description = "Informations de l'utilisateur mises à jour avec succès.",
                    content = @Content(
                            mediaType = "application/json",
                            schema = @Schema(implementation = UserDto.class)
                    )
            ),
            @ApiResponse(responseCode = "401", ref = "#/components/responses/UnauthorizedError"),
            @ApiResponse(
                    responseCode = "404",
                    description = "Utilisateur non trouvé",
                    content = @Content(
                            mediaType = "application/json",
                            schema = @Schema(
                                    example = "{\n"
                                            + "\"i18nKey\": \"user.not_found\",\n"
                                            + "\"message\": \"User not found\",\n"
                                            + "\"extra\": null\n"
                                            + "}"
                            )
                    )
            ),
            @ApiResponse(
                    responseCode = "409",
                    description = "Conflit pendant l'enregistrement des données",
                    content = @Content(
                            mediaType = "application/json",
                            schema = @Schema(
                                    example = "{\n"
                                            + "\"i18nKey\": \"user.already_exist\",\n"
                                            + "\"message\": \"User already exist with this email\",\n"
                                            + "\"extra\": null\n"
                                            + "}"
                            )
                    )
            ),
            @ApiResponse(responseCode = "422", ref = "#/components/responses/ValidationError")
    })
    @PutMapping("/user")
    public UserDto updateUser(@RequestBody @Validated UserDTO userDto) {
        User user = this.userService.updateUser(this.getUser().getId(), userDto, false);
        Authorization authorization = this.authorizationService.createAuthorizationForUpdateOldEmail(user, userDto);
        this.mailerService.sendEmailChangeOldEmailConfirmation(authorization);
        return new UserDto(user, true);
    }

    @Operation(
            summary = "Mettre à jour la photo de profil",
            description = "Permet à l'utilisateur connecté d'uploader une photo de profil. Formats acceptés : PNG, JPEG, JPG, WEBP, SVG, HEIC.",
            security = @SecurityRequirement(name = "bearerAuth"),
            tags = {"Utilisateur"}
    )
    @ApiResponses(value = {
            @ApiResponse(
                    responseCode = "200",
                    description = "Photo de profil uploadée avec succès.",
                    content = @Content(
                            mediaType = "application/json",
                            schema = @Schema(
                                    implementation = ApiResponseDTO.class,
                                    example = "{"
                                            + "\"i18nKey\": \"user.profile.uploaded\","
                                            + "\"message\": \"The image was successfully uploaded.\","
                                            + "\"extra\": null"
                                            + "}"
                            )
                    )
            ),
            @ApiResponse(responseCode = "401", ref = "#/components/responses/UnauthorizedError"),
            @ApiResponse(
                    responseCode = "400",
                    description = "Fichier invalide ou format non supporté.",
                    content = @Content(
                            mediaType = "application/json",
                            examples = {
                                    @ExampleObject(
                                            name = "Fichier vide ou invalide",
                                            value = "{"
                                                    + "\"i18nKey\": \"user.profile.invalid_file\","
                                                    + "\"message\": \"The file is empty or invalid.\","
                                                    + "\"extra\": null"
                                                    + "}"
                                    ),
                                    @ExampleObject(
                                            name = "Format non autorisé",
                                            value = "{"
                                                    + "\"i18nKey\": \"hike.image.invalid_file\","
                                                    + "\"message\": \"Only image files are allowed.\","
                                                    + "\"extra\": [\n"
                                                    + "\"image/png\",\n"
                                                    + "\"image/svg+xml\",\n"
                                                    + "\"image/jpg\",\n"
                                                    + "\"image/jpeg\",\n"
                                                    + "\"image/heic\",\n"
                                                    + "\"image/webp\"\n"
                                                    + "],\n"
                                                    + "}"
                                    ),
                                    @ExampleObject(
                                            name = "Échec de l'upload",
                                            value = "{"
                                                    + "\"i18nKey\": \"user.profile.failed_upload\","
                                                    + "\"message\": \"Failed to upload the image. Please try again later.\","
                                                    + "\"extra\": null"
                                                    + "}"
                                    )
                            }
                    )
            )
    })
    @PostMapping("/user/profile-picture")
    public ApiResponseDTO uploadUserProfilePicture(@RequestParam("image") MultipartFile file) {
        String fileName = file.getOriginalFilename();
        if (file.isEmpty() || fileName == null) {
            throw new NaaviBadRequestException("user.profile.invalid_file", "The file is empty or invalid.");
        }

        String contentType = file.getContentType() != null ? file.getContentType().toLowerCase() : "";
        Set<String> allowedContentTypes = Set.of(
                "image/png", "image/jpeg", "image/jpg", "image/webp", "image/svg+xml", "image/heic"
        );
        if (!allowedContentTypes.contains(contentType)) {
            throw new NaaviBadRequestException("user.profile.invalid_file", "Only image files are allowed.", allowedContentTypes);
        }

        String extension = fileName.substring(fileName.lastIndexOf(".") + 1).toLowerCase();

        User user = this.getUser();

        try {
            if (user.getProfilePicture() != null) {
                s3Service.delete(S3Enum.USERS, user.getProfilePicture(), null);
            }

            String toHash = fileName + "_" + System.currentTimeMillis();

            MessageDigest md = MessageDigest.getInstance("MD5");
            byte[] digest = md.digest(toHash.getBytes(StandardCharsets.UTF_8));
            StringBuilder hex = new StringBuilder();
            for (byte b : digest) {
                hex.append(String.format("%02x", b));
            }
            fileName = hex + "." + extension;

            s3Service.upload(S3Enum.USERS, file.getInputStream(), fileName, null);
            user.setProfilePicture(fileName);
            userRepository.save(user);

            return new ApiResponseDTO(
                    "user.profile.uploaded",
                    "The image was successfully uploaded."
            );
        } catch (Exception e) {
            throw new NaaviBadRequestException(
                    "user.profile.failed_upload",
                    "Failed to upload the image. Please try again later."
            );
        }
    }

    @Operation(
            summary = "Supprimer la photo de profil",
            description = "Permet à l'utilisateur connecté de supprimer sa photo de profil.",
            security = @SecurityRequirement(name = "bearerAuth"),
            tags = {"Utilisateur"}
    )
    @ApiResponses(value = {
            @ApiResponse(
                    responseCode = "200",
                    description = "Photo de profil supprimée avec succès.",
                    content = @Content(
                            mediaType = "application/json",
                            schema = @Schema(
                                    implementation = ApiResponseDTO.class,
                                    example = "{"
                                            + "\"i18nKey\": \"user.profile.deleted\","
                                            + "\"message\": \"The profile picture was successfully deleted.\","
                                            + "\"extra\": null"
                                            + "}"
                            )
                    )
            ),
            @ApiResponse(responseCode = "401", ref = "#/components/responses/UnauthorizedError"),
            @ApiResponse(
                    responseCode = "400",
                    description = "Aucune photo de profil à supprimer ou échec de la suppression.",
                    content = @Content(
                            mediaType = "application/json",
                            schema = @Schema(
                                    implementation = ApiResponseDTO.class,
                                    example = "{"
                                            + "\"i18nKey\": \"user.profile.no_picture\","
                                            + "\"message\": \"No profile picture to delete.\","
                                            + "\"extra\": null"
                                            + "}"
                            )
                    )
            )
    })
    @DeleteMapping("/user/profile-picture")
    public ApiResponseDTO deleteUserProfilePicture() {
        User user = this.getUser();
        if (user.getProfilePicture() == null) {
            throw new NaaviBadRequestException("user.profile.no_picture", "No profile picture to delete.");
        }

        s3Service.delete(S3Enum.USERS, user.getProfilePicture(), null);
        user.setProfilePicture(null);
        userRepository.save(user);
        return new ApiResponseDTO(
                "user.profile.deleted",
                "The profile picture was successfully deleted."
        );
    }

    //////////////////////
    /// ADMINISTRATION ///
    //////////////////////

    /**
     * Endpoint to retrieve all users.
     *
     * @param paginationDto the pagination parameters
     * @return the list of users
     */
    @Operation(
            summary = "Rechercher des utilisateurs",
            description = "Retourne la liste des utilisateurs.",
            security = @SecurityRequirement(name = "bearerAuth"),
            tags = {"Administration"}
    )
    @ApiResponses(value = {
            @ApiResponse(
                    responseCode = "200",
                    description = "Liste paginée des utilisateurs retournée avec succès.",
                    content = @Content(
                            mediaType = "application/json",
                            schema = @Schema(implementation = PaginatorDTO.class)
                    )
            ),
            @ApiResponse(responseCode = "401", ref = "#/components/responses/UnauthorizedError"),
            @ApiResponse(responseCode = "403", ref = "#/components/responses/AccessDeniedError"),
            @ApiResponse(responseCode = "422", ref = "#/components/responses/ValidationError")
    })
    @PreAuthorize("hasRole('ADMIN')")
    @GetMapping("/administration/users")
    public PaginatorDTO<UserDto> searchUser(@Valid @ModelAttribute PaginationDTO paginationDto) {
        return this.userRepository.findAllUserWithPagination(paginationDto);
    }

    /**
     * Endpoint to create a new user.
     *
     * @param userDto the user DTO
     * @return the created user
     */
    @Operation(
            summary = "Créer un utilisateur",
            description = "Permet a un administrateur de créer un utilisateur",
            security = @SecurityRequirement(name = "bearerAuth"),
            tags = {"Administration"}
    )
    @ApiResponses(value = {
            @ApiResponse(
                    responseCode = "200",
                    description = "Informations de l'utilisateur",
                    content = @Content(
                            mediaType = "application/json",
                            schema = @Schema(implementation = UserDto.class)
                    )
            ),
            @ApiResponse(responseCode = "401", ref = "#/components/responses/UnauthorizedError"),
            @ApiResponse(responseCode = "403", ref = "#/components/responses/AccessDeniedError"),
            @ApiResponse(
                    responseCode = "409",
                    description = "Conflit pendant l'enregistrement des données",
                    content = @Content(
                            mediaType = "application/json",
                            schema = @Schema(
                                    example = "{\n"
                                            + "\"i18nKey\": \"user.already_exist\",\n"
                                            + "\"message\": \"User already exist with this email\",\n"
                                            + "\"extra\": null\n"
                                            + "}"
                            )
                    )
            ),
            @ApiResponse(responseCode = "422", ref = "#/components/responses/ValidationError")
    })
    @PreAuthorize("hasRole('ADMIN')")
    @PostMapping("/administration/users")
    public UserDto createUser(@RequestBody @Validated(ValidationGroups.OnCreate.class) UserDTO userDto) {
        userRepository.findByEmail(userDto.getEmail())
                .ifPresent(user -> {
                    throw new NaaviConflictException("user.already_exist", "User already exist with this email");
                });

        User newUser = userService.createUserFromAdmin(userDto);
        this.mailerService.sendRegistrationEmail(newUser, true);

        return new UserDto(newUser, true);
    }

    /**
     * Endpoint to retrieve a user by ID.
     *
     * @param id the user ID
     * @return the user
     */
    @Operation(
            summary = "Récupérer un utilisateur par ID",
            description = "Retourne les informations d'un utilisateur spécifique en fonction de son ID.",
            security = @SecurityRequirement(name = "bearerAuth"),
            tags = {"Administration"}
    )
    @ApiResponses(value = {
            @ApiResponse(
                    responseCode = "200",
                    description = "Informations de l'utilisateur",
                    content = @Content(
                            mediaType = "application/json",
                            schema = @Schema(implementation = UserDto.class)
                    )
            ),
            @ApiResponse(responseCode = "401", ref = "#/components/responses/UnauthorizedError"),
            @ApiResponse(responseCode = "403", ref = "#/components/responses/AccessDeniedError"),
            @ApiResponse(
                    responseCode = "404",
                    description = "Utilisateur non trouvé",
                    content = @Content(
                            mediaType = "application/json",
                            schema = @Schema(
                                    example = "{"
                                            + "\"i18nKey\": \"user.not_found\",\n"
                                            + "\"message\": \"User not found\",\n"
                                            + "\"extra\": null\n"
                                            + "}"
                            )
                    )
            )
    })
    @PreAuthorize("hasRole('ADMIN')")
    @GetMapping("/administration/users/{id}")
    public UserDto getUser(@PathVariable Long id) {
        return userRepository.findById(id)
                .map(user -> new UserDto(user, true))
                .orElseThrow(() -> new NaaviNotFoundException("user.not_found", "User not found"));
    }

    /**
     * Endpoint to update a user by ID.
     *
     * @param id the user ID
     * @param userDto the user DTO
     * @return the updated user
     */
    @Operation(
            summary = "Mettre à jour un utilisateur par ID",
            description = "Met à jour les informations d'un utilisateur spécifique en fonction de son ID.",
            security = @SecurityRequirement(name = "bearerAuth"),
            tags = {"Administration"}
    )
    @ApiResponses(value = {
            @ApiResponse(
                    responseCode = "200",
                    description = "Informations de l'utilisateur",
                    content = @Content(
                            mediaType = "application/json",
                            schema = @Schema(implementation = UserDto.class)
                    )
            ),
            @ApiResponse(
                    responseCode = "400",
                    description = "Bad request",
                    content = @Content(
                            mediaType = "application/json",
                            examples = {
                                    @ExampleObject(
                                            name = "If role is invalid",
                                            value = "{"
                                                    + "\"i18nKey\": \"user.role_invalid\","
                                                    + "\"message\": \"The role '...' does not exist.\","
                                                    + "\"extra\": null"
                                                    + "}"
                                    ),
                                    @ExampleObject(
                                            name = "If permission is invalid",
                                            value = "{"
                                                    + "\"i18nKey\": \"user.permission_invalid\","
                                                    + "\"message\": \"The permission '...' does not exist.\","
                                                    + "\"extra\": null"
                                                    + "}"
                                    ),
                                    @ExampleObject(
                                            name = "If status is invalid",
                                            value = "{"
                                                    + "\"i18nKey\": \"user.status_invalid\","
                                                    + "\"message\": \"The status '...' does not exist.\","
                                                    + "\"extra\": null"
                                                    + "}"
                                    )
                            }
                    )
            ),
            @ApiResponse(responseCode = "401", ref = "#/components/responses/UnauthorizedError"),
            @ApiResponse(responseCode = "403", ref = "#/components/responses/AccessDeniedError"),
            @ApiResponse(
                    responseCode = "404",
                    description = "Utilisateur non trouvé",
                    content = @Content(
                            mediaType = "application/json",
                            schema = @Schema(
                                    example = "{\n"
                                            + "\"i18nKey\": \"user.not_found\",\n"
                                            + "\"message\": \"User not found\",\n"
                                            + "\"extra\": null\n"
                                            + "}"
                            )
                    )
            ),
            @ApiResponse(
                    responseCode = "409",
                    description = "Conflit pendant l'enregistrement des données",
                    content = @Content(
                            mediaType = "application/json",
                            schema = @Schema(
                                    example = "{\n"
                                            + "\"i18nKey\": \"user.email_already_used\",\n"
                                            + "\"message\": \"The email address you entered already exists.\",\n"
                                            + "\"extra\": null\n"
                                            + "}"
                            )
                    )
            ),
            @ApiResponse(responseCode = "422", ref = "#/components/responses/ValidationError")
    })
    @PreAuthorize("hasRole('ADMIN')")
    @PutMapping("/administration/users/{id}")
    public UserDto updateUser(@PathVariable Long id, @RequestBody @Validated UserDTO userDto) {
        User user = userService.updateUser(id, userDto, true);
        return new UserDto(user, true);
    }

    /**
     * Endpoint to delete a user by ID.
     *
     * @param id the user ID
     * @return the API response
     */
    @Operation(
            summary = "Supprimer un utilisateur par ID",
            description = "Supprime un utilisateur spécifique en fonction de son ID.",
            security = @SecurityRequirement(name = "bearerAuth"),
            tags = {"Administration"}
    )
    @ApiResponses(value = {
            @ApiResponse(
                    responseCode = "200",
                    description = "Utilisateur supprimé avec succès.",
                    content = @Content(
                            mediaType = "application/json",
                            schema = @Schema(
                                    implementation = ApiResponseDTO.class,
                                    example = "{"
                                            + "\"i18nKey\": \"user.deleted\","
                                            + "\"message\": \"User successfully deleted\","
                                            + "\"extra\": null"
                                            + "}"
                            )
                    )
            ),
            @ApiResponse(responseCode = "401", ref = "#/components/responses/UnauthorizedError"),
            @ApiResponse(responseCode = "403", ref = "#/components/responses/AccessDeniedError"),
            @ApiResponse(
                    responseCode = "404",
                    description = "Utilisateur non trouvé",
                    content = @Content(
                            mediaType = "application/json",
                            schema = @Schema(
                                    example = "{\n"
                                            + "\"i18nKey\": \"user.not_found\",\n"
                                            + "\"message\": \"User not found\",\n"
                                            + "\"extra\": null\n"
                                            + "}"
                            )
                    )
            )
    })
    @PreAuthorize("hasRole('ADMIN')")
    @DeleteMapping("/administration/users/{id}")
    public ApiResponseDTO deleteUser(@PathVariable Long id) {
        this.userService.deleteUser(id);
        return new ApiResponseDTO("user.deleted", "User successfully deleted");
    }

    @Operation(
            summary = "Supprimer la photo de profil d'un utilisateur",
            description = "Permet à un administrateur de supprimer la photo de profil d'un utilisateur spécifique.",
            security = @SecurityRequirement(name = "bearerAuth"),
            tags = {"Administration"}
    )
    @ApiResponses(value = {
            @ApiResponse(
                    responseCode = "200",
                    description = "Photo de profil supprimée avec succès.",
                    content = @Content(
                            mediaType = "application/json",
                            schema = @Schema(
                                    implementation = ApiResponseDTO.class,
                                    example = "{"
                                            + "\"i18nKey\": \"user.profile.deleted\","
                                            + "\"message\": \"The profile picture was successfully deleted.\","
                                            + "\"extra\": null"
                                            + "}"
                            )
                    )
            ),
            @ApiResponse(responseCode = "401", ref = "#/components/responses/UnauthorizedError"),
            @ApiResponse(responseCode = "403", ref = "#/components/responses/AccessDeniedError"),
            @ApiResponse(
                    responseCode = "404",
                    description = "Utilisateur non trouvé.",
                    content = @Content(
                            mediaType = "application/json",
                            schema = @Schema(
                                    example = "{"
                                            + "\"i18nKey\": \"user.not_found\","
                                            + "\"message\": \"User not found.\","
                                            + "\"extra\": null"
                                            + "}"
                            )
                    )
            ),
            @ApiResponse(
                    responseCode = "400",
                    description = "Aucune photo de profil à supprimer ou échec de la suppression.",
                    content = @Content(
                            mediaType = "application/json",
                            examples = {
                                    @ExampleObject(
                                            name = "Aucune photo de profil",
                                            value = "{"
                                                    + "\"i18nKey\": \"user.profile.no_picture\","
                                                    + "\"message\": \"No profile picture to delete.\","
                                                    + "\"extra\": null"
                                                    + "}"
                                    ),
                                    @ExampleObject(
                                            name = "Échec de la suppression",
                                            value = "{"
                                                    + "\"i18nKey\": \"user.profile.failed_delete\","
                                                    + "\"message\": \"Failed to delete the profile picture. Please try again later.\","
                                                    + "\"extra\": null"
                                                    + "}"
                                    )
                            }
                    )
            )
    })
    @PreAuthorize("hasRole('ADMIN')")
    @DeleteMapping("/administration/users/{id}/profile-picture")
    public ApiResponseDTO deleteUserProfilePictureFromAdmin(@PathVariable Long id) {
        this.userService.deleteUserProfilePictureById(id);
        return new ApiResponseDTO("user.profile.deleted", "The profile picture was successfully deleted.");
    }
}