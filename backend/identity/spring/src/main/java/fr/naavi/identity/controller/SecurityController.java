package fr.naavi.identity.controller;

import fr.naavi.core.annotation.AuthenticationNotRequired;
import fr.naavi.core.dto.ApiResponseDto;
import fr.naavi.core.exception.GenericHttpException;
import fr.naavi.core.exception.children.NaaviBadCredentialsException;
import fr.naavi.core.exception.children.NaaviUnauthorizedException;
import fr.naavi.identity.abstraction.AbstractController;
import fr.naavi.identity.dto.input.ForgotPasswordDTO;
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

import java.util.Optional;

@RestController
public class SecurityController extends AbstractController {
    private final UserService userService;
    private final AuthenticationManager authenticationManager;
    private final MailerService mailerService;
    private final SessionRepository sessionRepository;
    private final AuthenticationService authenticationService;

    /**
     * Constructs a SecurityController
     */
    @Autowired
    public SecurityController(
            UserService userService,
            AuthenticationManager authenticationManager,
            MailerService mailerService,
            SessionRepository sessionRepository,
            AuthenticationService authenticationService
    ) {
        this.userService = userService;
        this.authenticationManager = authenticationManager;
        this.mailerService = mailerService;
        this.sessionRepository = sessionRepository;
        this.authenticationService = authenticationService;
    }

    /**
     * Endpoint for user login.
     * This endpoint is used to authenticate a user and return an authentication token.
     *
     * @param loginDto the login credentials
     * @return an AuthenticationDto containing the access token
     */
    @PostMapping("/login")
    public AuthenticationDTO login(@RequestBody @Validated LoginDTO loginDto) {
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
     * @return an ApiResponseDto indicating success or failure
     */
    @PostMapping("/register")
    @AuthenticationNotRequired
    public ApiResponseDto register(@RequestBody @Validated RegisterDTO registerDto) {
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

        return new ApiResponseDto("security.register.success", "User registered successfully.");
    }

    /**
     * Endpoint to log out the user.
     * This endpoint is used to invalidate the current session.
     *
     * @return an ApiResponseDto indicating success or failure
     */
    @DeleteMapping("/logout")
    public ApiResponseDto logout() {
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

        return new ApiResponseDto("logout.success", "User logged out successfully.");
    }

    /**
     * Endpoint to refresh the authentication token.
     * This endpoint is used to renew the session using a valid refresh token.
     *
     * @param refreshDto the refresh token details
     * @return an AuthenticationDTO containing the new access token
     */
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
     * @return an ApiResponseDto indicating success or failure
     */
    @PostMapping("/forgot-password")
    @AuthenticationNotRequired
    public ApiResponseDto forgotPassword(@RequestBody @Validated ForgotPasswordDTO forgotPasswordDTO) {
        User user = this.userService.checkIfUserExists(forgotPasswordDTO.getEmail());

        if (user != null) {
            ResetPasswordRequest resetPasswordRequest = this.userService.createResetPasswordRequest(user);
            this.mailerService.sendForgotPasswordEmail(resetPasswordRequest);
        }

        return new ApiResponseDto(
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
     * @return an ApiResponseDto indicating success or failure
     */
    @PostMapping("/reset-password")
    @AuthenticationNotRequired
    public ApiResponseDto resetPassword(@RequestBody @Validated ResetPasswordDTO resetPasswordDTO) {
        ResetPasswordRequest resetPasswordRequest = this.userService.checkIfResetPasswordRequestExists(resetPasswordDTO.getToken());

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

        return new ApiResponseDto("reset_password.success", "Your password has been successfully reset.");
    }
}
