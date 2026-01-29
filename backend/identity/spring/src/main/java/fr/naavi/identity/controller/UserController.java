package fr.naavi.identity.controller;

import fr.naavi.core.dto.ApiResponseDTO;
import fr.naavi.core.dto.PaginationDTO;
import fr.naavi.core.dto.PaginatorDTO;
import fr.naavi.core.exception.children.NaaviConflictException;
import fr.naavi.core.exception.children.NaaviNotFoundException;
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
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.ModelAttribute;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RestController;

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
        return new UserDto(this.getUser(), false);
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
        return new UserDto(user, false);
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
                            schema = @Schema(implementation = ApiResponseDTO.class)
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
}