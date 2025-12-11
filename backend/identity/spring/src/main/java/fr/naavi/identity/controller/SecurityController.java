package fr.naavi.identity.controller;

import fr.naavi.core.annotation.AuthenticationNotRequired;
import fr.naavi.core.dto.ApiResponseDTO;
import fr.naavi.core.exception.GenericHttpException;
import fr.naavi.core.exception.children.NaaviBadCredentialsException;
import fr.naavi.core.exception.children.NaaviUnauthorizedException;
import fr.naavi.core.service.TurnstileService;
import fr.naavi.core.utils.RequestUtils;
import fr.naavi.identity.abstraction.AbstractController;
import fr.naavi.identity.dto.input.ForgotPasswordDTO;
import fr.naavi.identity.dto.input.IsAvailableEmailDTO;
import fr.naavi.identity.dto.input.LoginDTO;
import fr.naavi.identity.dto.input.RefreshDTO;
import fr.naavi.identity.dto.input.RegisterDTO;
import fr.naavi.identity.dto.input.ResetPasswordDTO;
import fr.naavi.identity.dto.output.AuthenticationDTO;
import fr.naavi.identity.entity.ResetPasswordRequest;
import fr.naavi.identity.entity.Session;
import fr.naavi.identity.entity.User;
import fr.naavi.identity.repository.SessionRepository;
import fr.naavi.identity.service.AuthenticationService;
import fr.naavi.identity.service.MailerService;
import fr.naavi.identity.service.UserService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.media.Content;
import io.swagger.v3.oas.annotations.media.ExampleObject;
import io.swagger.v3.oas.annotations.media.Schema;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.responses.ApiResponses;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.Authentication;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RestController;

import java.util.Map;
import java.util.Optional;

@RestController
public class SecurityController extends AbstractController {
    private final UserService userService;
    private final AuthenticationManager authenticationManager;
    private final MailerService mailerService;
    private final SessionRepository sessionRepository;
    private final AuthenticationService authenticationService;
    private final TurnstileService turnstileService;

    /**
     * Constructs a SecurityController
     */
    @Autowired
    public SecurityController(
            UserService userService,
            AuthenticationManager authenticationManager,
            MailerService mailerService,
            SessionRepository sessionRepository,
            AuthenticationService authenticationService,
            TurnstileService turnstileService
    ) {
        this.userService = userService;
        this.authenticationManager = authenticationManager;
        this.mailerService = mailerService;
        this.sessionRepository = sessionRepository;
        this.authenticationService = authenticationService;
        this.turnstileService = turnstileService;
    }

    /**
     * Endpoint for user login.
     * This endpoint is used to authenticate a user and return an authentication token.
     *
     * @param loginDto the login credentials
     * @return an AuthenticationDto containing the access token
     */
    @Operation(
            summary = "Authentification de l'utilisateur",
            description = "Permet de connecter un utilisateur et de retourner les tokens d'authentification.",
            tags = {"Sécurité"}
    )
    @ApiResponses(value = {
            @ApiResponse(
                    responseCode = "200",
                    description = "Authentification réussie.",
                    content = @Content(
                            mediaType = "application/json",
                            schema = @Schema(implementation = AuthenticationDTO.class)
                    )
            ),
            @ApiResponse(
                    responseCode = "401",
                    description = "Échec lors de la tentative d'authentification",
                    content = @Content(
                            mediaType = "application/json",
                            examples = {
                                    @ExampleObject(
                                            name = "If credentials are invalid",
                                            value = "{\n"
                                                    + "  \"i18nKey\": \"security.invalid_credentials\",\n"
                                                    + "  \"message\": \"Invalid credentials provided.\",\n"
                                                    + "  \"extra\": null\n"
                                                    + "}"
                                    ),
                                    @ExampleObject(
                                            name = "If turnstile validation fails",
                                            value = "{\n"
                                                    + "  \"i18nKey\": \"unauthorized\",\n"
                                                    + "  \"message\": \"Can't access this resource\",\n"
                                                    + "  \"extra\": null\n"
                                                    + "}"
                                    )
                            }
                    )
            ),
            @ApiResponse(responseCode = "422", ref = "#/components/responses/ValidationError"),
    })
    @PostMapping("/login")
    public AuthenticationDTO login(@RequestBody @Validated LoginDTO loginDto) {
        boolean turnstile = this.turnstileService.validate(loginDto.getToken(), RequestUtils.getClientIpAddress());

        if (!turnstile) {
            throw new NaaviUnauthorizedException();
        }

        try {
            Authentication authentication = authenticationManager.authenticate(
                    new UsernamePasswordAuthenticationToken(loginDto.getEmail(), loginDto.getPassword())
            );

            return (AuthenticationDTO) authentication.getDetails();
        } catch (Exception e) {
            throw new NaaviBadCredentialsException(
                    "security.invalid_credentials",
                    "Invalid credentials provided."
            );
        }
    }

    /**
     * Endpoint for user registration.
     * This endpoint is used to register a new user and send a confirmation email.
     *
     * @param registerDto the registration details
     * @return an ApiResponseDTO indicating success or failure
     */
    @Operation(
            summary = "Inscription d'un nouvel utilisateur",
            description = "Permet de créer un nouvel utilisateur et d'envoyer un e-mail de confirmation.",
            tags = {"Sécurité"}
    )
    @ApiResponses(value = {
            @ApiResponse(
                    responseCode = "200",
                    description = "Utilisateur inscrit avec succès.",
                    content = @Content(
                            mediaType = "application/json",
                            schema = @Schema(
                                    implementation = ApiResponseDTO.class,
                                    example = "{\n"
                                            + "  \"i18nKey\": \"security.register.success\",\n"
                                            + "  \"message\": \"User registered successfully.\",\n"
                                            + "  \"extra\": null\n"
                                            + "}"
                            )
                    )
            ),
            @ApiResponse(
                    responseCode = "401",
                    description = "Échec de la validation du token",
                    content = @Content(
                            mediaType = "application/json",
                            schema = @Schema(
                                    implementation = ApiResponseDTO.class,
                                    example = "{\n"
                                            + "  \"i18nKey\": \"unauthorized\",\n"
                                            + "  \"message\": \"Can't access this resource\",\n"
                                            + "  \"extra\": null\n"
                                            + "}"
                            )
                    )
            ),
            @ApiResponse(
                    responseCode = "409",
                    description = "Un compte avec cet e-mail existe déjà.",
                    content = @Content(
                            mediaType = "application/json",
                            schema = @Schema(
                                    implementation = ApiResponseDTO.class,
                                    example = "{\n"
                                            + "  \"i18nKey\": \"security.email_already_exists\",\n"
                                            + "  \"message\": \"An account with this email already exists.\",\n"
                                            + "  \"extra\": null\n"
                                            + "}"
                            )
                    )
            ),
            @ApiResponse(responseCode = "422", ref = "#/components/responses/ValidationError"),
    })
    @PostMapping("/register")
    @AuthenticationNotRequired
    public ApiResponseDTO register(@RequestBody @Validated RegisterDTO registerDto) {
        boolean turnstile = this.turnstileService.validate(registerDto.getToken(), RequestUtils.getClientIpAddress());

        if (!turnstile) {
            throw new NaaviUnauthorizedException();
        }

        User existingUser = this.userService.checkIfUserExists(registerDto.getEmail());

        if (existingUser != null) {
            throw new GenericHttpException(
                    HttpStatus.CONFLICT,
                    "security.email_already_exists",
                    "An account with this email already exists."
            );
        }

        User newUser = this.userService.createUser(registerDto);
        this.mailerService.sendRegistrationEmail(newUser);

        return new ApiResponseDTO("security.register.success", "User registered successfully.");
    }

    /**
     * Endpoint to log out the user.
     * This endpoint is used to invalidate the current session.
     *
     * @return an ApiResponseDTO indicating success or failure
     */
    @Operation(
            summary = "Déconnexion de l'utilisateur",
            description = "Invalide la session courante de l'utilisateur.",
            tags = {"Sécurité"}
    )
    @ApiResponses(value = {
            @ApiResponse(
                    responseCode = "200",
                    description = "Utilisateur déconnecté avec succès.",
                    content = @Content(
                            mediaType = "application/json",
                            schema = @Schema(
                                    implementation = ApiResponseDTO.class,
                                    example = "{\n"
                                            + "  \"i18nKey\": \"logout.success\",\n"
                                            + "  \"message\": \"User logged out successfully.\",\n"
                                            + "  \"extra\": null\n"
                                            + "}"
                            )
                    )
            ),
            @ApiResponse(
                    responseCode = "401",
                    description = "Session invalide ou inexistante.",
                    content = @Content(
                            mediaType = "application/json",
                            schema = @Schema(implementation = ApiResponseDTO.class),
                            examples = {
                                    @ExampleObject(
                                            name = "Session manquante ou invalide",
                                            value = "{\n"
                                                    + "  \"i18nKey\": \"security.logout.error\",\n"
                                                    + "  \"message\": \"Session ID is missing or invalid.\",\n"
                                                    + "  \"extra\": null\n"
                                                    + "}"
                                    ),
                                    @ExampleObject(
                                            name = "Session non trouvée ou expirée",
                                            value = "{\n"
                                                    + "  \"i18nKey\": \"security.logout.error\",\n"
                                                    + "  \"message\": \"Session not found or already expired.\",\n"
                                                    + "  \"extra\": null\n"
                                                    + "}"
                                    )
                            }
                    )
            )
    })
    @DeleteMapping("/logout")
    public ApiResponseDTO logout() {
        String sessId = (String) this.getCurrentRequest().getAttribute("sessId");

        if (sessId == null || sessId.isEmpty()) {
            throw new NaaviUnauthorizedException(
                    "security.logout.error",
                    "Session ID is missing or invalid."
            );
        }

        Optional<Session> session = this.sessionRepository.findByAccessToken(sessId);

        if (session.isEmpty()) {
            throw new NaaviUnauthorizedException(
                    "security.logout.error",
                    "Session not found or already expired."
            );
        }

        this.sessionRepository.delete(session.get());

        return new ApiResponseDTO("logout.success", "User logged out successfully.");
    }

    /**
     * Endpoint to refresh the authentication token.
     * This endpoint is used to renew the session using a valid refresh token.
     *
     * @param refreshDto the refresh token details
     * @return an AuthenticationDTO containing the new access token
     */
    @Operation(
            summary = "Renouvellement du token d'authentification",
            description = "Permet de renouveler la session à l'aide d'un refresh token valide.",
            tags = {"Sécurité"}
    )
    @ApiResponses(value = {
            @ApiResponse(
                    responseCode = "200",
                    description = "Token renouvelé avec succès.",
                    content = @Content(
                            mediaType = "application/json",
                            schema = @Schema(implementation = AuthenticationDTO.class)
                    )
            ),
            @ApiResponse(
                    responseCode = "401",
                    description = "Refresh token invalide ou expiré.",
                    content = @Content(
                            mediaType = "application/json",
                            schema = @Schema(
                                    implementation = ApiResponseDTO.class,
                                    example = "{\n"
                                            + "  \"i18nKey\": \"security.refresh_token_invalid\",\n"
                                            + "  \"message\": \"The provided refresh token is invalid or expired.\",\n"
                                            + "  \"extra\": null\n"
                                            + "}"
                            )
                    )
            ),
            @ApiResponse(responseCode = "422", ref = "#/components/responses/ValidationError"),
    })
    @PostMapping("/refresh")
    @AuthenticationNotRequired
    public AuthenticationDTO refresh(@RequestBody @Validated RefreshDTO refreshDto) {
        try {
            return this.authenticationService.renewSession(refreshDto.getToken());
        } catch (Exception e) {
            throw new NaaviBadCredentialsException(
                    "security.refresh_token_invalid",
                    "The provided refresh token is invalid or expired."
            );
        }
    }

    /**
     * Endpoint to handle forgotten passwords.
     * This endpoint is used to send a password-reset email if the user exists.
     *
     * @param forgotPasswordDTO the email address for password reset
     * @return an ApiResponseDTO indicating success or failure
     */
    @Operation(
            summary = "Demande de réinitialisation du mot de passe",
            description = "Envoie un e-mail de réinitialisation si l'utilisateur existe. Réponse identique même si l'e-mail n'existe pas.",
            tags = {"Sécurité"}
    )
    @ApiResponses(value = {
            @ApiResponse(
                    responseCode = "200",
                    description = "E-mail de réinitialisation envoyé (ou réponse générique si l'utilisateur n'existe pas).",
                    content = @Content(
                            mediaType = "application/json",
                            schema = @Schema(
                                    implementation = ApiResponseDTO.class,
                                    example = "{\n"
                                            + "  \"i18nKey\": \"forgot_password.success\",\n"
                                            + "  \"message\": \"If an account exists with the e-mail address entered,"
                                            + " an e-mail will be sent to you with instructions for resetting your password.\",\n"
                                            + "  \"extra\": null\n"
                                            + "}"
                            )
                    )
            ),
            @ApiResponse(
                    responseCode = "401",
                    description = "Échec de la validation du token",
                    content = @Content(
                            mediaType = "application/json",
                            schema = @Schema(
                                    implementation = ApiResponseDTO.class,
                                    example = "{\n"
                                            + "  \"i18nKey\": \"unauthorized\",\n"
                                            + "  \"message\": \"Can't access this resource\",\n"
                                            + "  \"extra\": null\n"
                                            + "}"
                            )
                    )
            ),
            @ApiResponse(responseCode = "422", ref = "#/components/responses/ValidationError"),
    })
    @PostMapping("/forgot-password")
    @AuthenticationNotRequired
    public ApiResponseDTO forgotPassword(@RequestBody @Validated ForgotPasswordDTO forgotPasswordDTO) {
        boolean turnstile = this.turnstileService.validate(forgotPasswordDTO.getToken(), RequestUtils.getClientIpAddress());

        if (!turnstile) {
            throw new NaaviUnauthorizedException();
        }

        User user = this.userService.checkIfUserExists(forgotPasswordDTO.getEmail());

        if (user != null) {
            ResetPasswordRequest resetPasswordRequest = this.userService.createResetPasswordRequest(user);
            this.mailerService.sendForgotPasswordEmail(resetPasswordRequest);
        }

        return new ApiResponseDTO(
                "forgot_password.success",
                "If an account exists with the e-mail address entered, an e-mail will be "
                        + "sent to you with instructions for resetting your password."
        );
    }

    /**
     * Endpoint to reset the user's password.
     * This endpoint is used to update the user's password using a valid reset token.
     *
     * @param resetPasswordDTO the new password and reset token
     * @return an ApiResponseDTO indicating success or failure
     */
    @Operation(
            summary = "Réinitialisation du mot de passe",
            description = "Permet de réinitialiser le mot de passe à l'aide d'un token de réinitialisation valide.",
            tags = {"Sécurité"}
    )
    @ApiResponses(value = {
            @ApiResponse(
                    responseCode = "200",
                    description = "Mot de passe réinitialisé avec succès.",
                    content = @Content(
                            mediaType = "application/json",
                            schema = @Schema(
                                    implementation = ApiResponseDTO.class,
                                    example = "{\n"
                                            + "  \"i18nKey\": \"reset_password.success\",\n"
                                            + "  \"message\": \"Your password has been successfully reset.\",\n"
                                            + "  \"extra\": null\n"
                                            + "}"
                            )
                    )
            ),
            @ApiResponse(
                    responseCode = "404",
                    description = "Token de réinitialisation invalide ou expiré.",
                    content = @Content(
                            mediaType = "application/json",
                            schema = @Schema(
                                    implementation = ApiResponseDTO.class,
                                    example = "{\n"
                                            + "  \"i18nKey\": \"reset_password.request_not_found\",\n"
                                            + "  \"message\": \"The reset password request is invalid or has expired.\",\n"
                                            + "  \"extra\": null\n"
                                            + "}"
                            )
                    )
            ),
            @ApiResponse(
                    responseCode = "401",
                    description = "Échec de la validation du token",
                    content = @Content(
                            mediaType = "application/json",
                            schema = @Schema(
                                    implementation = ApiResponseDTO.class,
                                    example = "{\n"
                                            + "  \"i18nKey\": \"unauthorized\",\n"
                                            + "  \"message\": \"Can't access this resource\",\n"
                                            + "  \"extra\": null\n"
                                            + "}"
                            )
                    )
            ),
            @ApiResponse(responseCode = "422", ref = "#/components/responses/ValidationError"),
    })
    @PostMapping("/reset-password")
    @AuthenticationNotRequired
    public ApiResponseDTO resetPassword(@RequestBody @Validated ResetPasswordDTO resetPasswordDTO) {
        boolean turnstile = this.turnstileService.validate(resetPasswordDTO.getToken(), RequestUtils.getClientIpAddress());

        if (!turnstile) {
            throw new NaaviUnauthorizedException();
        }

        ResetPasswordRequest resetPasswordRequest = this.userService.checkIfResetPasswordRequestExists(resetPasswordDTO.getResetPasswordToken());

        if (resetPasswordRequest == null) {
            throw new GenericHttpException(
                    HttpStatus.NOT_FOUND,
                    "reset_password.request_not_found",
                    "The reset password request is invalid or has expired."
            );
        }

        User user = resetPasswordRequest.getUser();
        this.userService.updatePassword(user, resetPasswordDTO);
        this.userService.deleteResetPasswordRequest(resetPasswordRequest);
        this.mailerService.sendResetPasswordConfirmationEmail(user);

        return new ApiResponseDTO("reset_password.success", "Your password has been successfully reset.");
    }

    /**
     * Endpoint to check if an email address is available.
     *
     * @param isAvailableEmailDTO the email address to check
     * @return an ApiResponseDTO indicating success or failure
     */
    @Operation(
            summary = "Vérification de la disponibilité de l'e-mail",
            description = "Permet de vérifier si une adresse e-mail est disponible pour l'inscription.",
            tags = {"Sécurité"}
    )
    @ApiResponses(value = {
            @ApiResponse(
                    responseCode = "200",
                    description = "Vérification de la disponibilité de l'e-mail réussie.",
                    content = @Content(
                            mediaType = "application/json",
                            examples = {
                                    @ExampleObject(
                                            name = "If email is available",
                                            value = "{\n"
                                                    + "  \"i18nKey\": \"security.email_available\",\n"
                                                    + "  \"message\": \"This email address is available.\",\n"
                                                    + "  \"extra\": {\n"
                                                    + "    \"success\": true\n"
                                                    + "  }\n"
                                                    + "}"
                                    ),
                                    @ExampleObject(
                                            name = "If email is unavailable",
                                            value = "{\n"
                                                    + "  \"i18nKey\": \"security.email_unavailable\",\n"
                                                    + "  \"message\": \"This email address is already taken.\",\n"
                                                    + "  \"extra\": {\n"
                                                    + "    \"success\": false\n"
                                                    + "  }\n"
                                                    + "}"
                                    )
                            }
                    )
            ),
            @ApiResponse(
                    responseCode = "401",
                    description = "Échec de la validation du token",
                    content = @Content(
                            mediaType = "application/json",
                            schema = @Schema(
                                    implementation = ApiResponseDTO.class,
                                    example = "{\n"
                                            + "  \"i18nKey\": \"unauthorized\",\n"
                                            + "  \"message\": \"Can't access this resource\",\n"
                                            + "  \"extra\": null\n"
                                            + "}"
                            )
                    )
            ),
            @ApiResponse(responseCode = "422", ref = "#/components/responses/ValidationError"),
    })
    @PostMapping("/is-available-email")
    @AuthenticationNotRequired
    public ApiResponseDTO isAvailableEmail(@RequestBody @Validated IsAvailableEmailDTO isAvailableEmailDTO) {
        boolean turnstile = this.turnstileService.validate(isAvailableEmailDTO.getToken(), RequestUtils.getClientIpAddress());

        if (!turnstile) {
            throw new NaaviUnauthorizedException();
        }

        User user = this.userService.checkIfUserExists(isAvailableEmailDTO.getEmail());

        if (user == null) {
            return new ApiResponseDTO(
                    "security.email_unavailable",
                    "This email address is already taken.",
                    Map.of("success", false)
            );
        }

        return new ApiResponseDTO(
                "security.email_available",
                "This email address is available.",
                Map.of("success", true)
        );
    }
}
