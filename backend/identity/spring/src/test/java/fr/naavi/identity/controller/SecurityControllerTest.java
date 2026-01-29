package fr.naavi.identity.controller;

import fr.naavi.core.exception.GlobalExceptionHandler;
import fr.naavi.core.service.TurnstileService;
import fr.naavi.identity.configuration.CacheConfigurationTest;
import fr.naavi.identity.dto.input.AuthorizationDTO;
import fr.naavi.identity.dto.input.ForgotPasswordDTO;
import fr.naavi.identity.dto.input.IsAvailableEmailDTO;
import fr.naavi.identity.dto.input.LoginDTO;
import fr.naavi.identity.dto.input.RefreshDTO;
import fr.naavi.identity.dto.input.RegisterDTO;
import fr.naavi.identity.dto.input.ResetPasswordDTO;
import fr.naavi.identity.dto.output.AuthenticationDTO;
import fr.naavi.identity.entity.Authorization;
import fr.naavi.identity.entity.ResetPasswordRequest;
import fr.naavi.identity.entity.Session;
import fr.naavi.identity.entity.User;
import fr.naavi.identity.enums.StatusEnum;
import fr.naavi.identity.exception.BannedException;
import fr.naavi.identity.exception.UnverifiedException;
import fr.naavi.identity.repository.ResetPasswordRequestRepository;
import fr.naavi.identity.repository.SessionRepository;
import fr.naavi.identity.repository.UserRepository;
import fr.naavi.identity.seeder.UserSeeder;
import fr.naavi.identity.service.AuthenticationService;
import fr.naavi.identity.service.AuthorizationService;
import fr.naavi.identity.service.MailerService;
import fr.naavi.identity.service.UserService;
import fr.naavi.identity.util.AuthenticationManagerUtil;
import fr.naavi.identity.util.DtoFactory;
import org.hamcrest.core.IsNull;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.ArgumentMatchers;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.webmvc.test.autoconfigure.AutoConfigureMockMvc;
import org.springframework.context.annotation.Import;
import org.springframework.http.MediaType;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.context.TestPropertySource;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.result.MockMvcResultHandlers;

import java.util.Map;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.when;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.user;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.delete;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("ci")
@TestPropertySource(locations = "classpath:application-ci.properties")
@Import({GlobalExceptionHandler.class, CacheConfigurationTest.class})
public class SecurityControllerTest {
    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private UserSeeder userSeeder;

    @MockitoBean
    private AuthenticationManager authenticationManager;

    @MockitoBean
    private AuthenticationService authenticationService;

    @MockitoBean
    private TurnstileService turnstileService;

    @Autowired
    private SessionRepository sessionRepository;

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private ResetPasswordRequestRepository resetPasswordRequestRepository;

    @Autowired
    private UserService userService;

    @Autowired
    private AuthorizationService authorizationService;

    @MockitoBean
    private MailerService mailerService;

    @BeforeEach
    void setUp() {
        resetPasswordRequestRepository.deleteAll();
        sessionRepository.deleteAll();
        userSeeder.seedUsers();

        when(turnstileService.validate(anyString(), anyString())).thenReturn(true);
    }

    /*
     * LOGIN ENDPOINT TESTS
     */

    @Test
    void shouldLogin_WithValidCredentials() throws Exception {
        LoginDTO loginDTO = DtoFactory.createDto(LoginDTO.class,
                Map.of(
                        "email", UserSeeder.USER_EMAIL,
                        "password", UserSeeder.USER_DEFAULT_PASSWORD,
                        "token", "azertyuiop"
                )
        );

        AuthenticationManagerUtil.mockAuthenticationManager(authenticationManager, sessionRepository, UserSeeder.USER);

        mockMvc.perform(post("/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(DtoFactory.toJson(loginDTO)))
                .andDo(MockMvcResultHandlers.print())
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.accessToken").value("fake-access-token"))
                .andExpect(jsonPath("$.refreshToken").value("fake-refresh-token"));
    }

    @Test
    void shouldLogin_WithInvalidCredentials() throws Exception {
        LoginDTO loginDTO = DtoFactory.createDto(LoginDTO.class,
                Map.of(
                        "email", UserSeeder.INVALID_USER_EMAIL,
                        "password", UserSeeder.USER_DEFAULT_PASSWORD,
                        "token", "azertyuiop"
                )
        );

        mockMvc.perform(post("/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(DtoFactory.toJson(loginDTO)))
                .andDo(MockMvcResultHandlers.print())
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.i18nKey").value("security.invalid_credentials"))
                .andExpect(jsonPath("$.message").value("Invalid credentials provided."))
                .andExpect(jsonPath("$.extra").value(IsNull.nullValue()));
    }

    @Test
    void shouldLogin_WithMalformedRequest() throws Exception {
        LoginDTO loginDTO = DtoFactory.createDto(LoginDTO.class,
                Map.of(
                        "password", UserSeeder.USER_DEFAULT_PASSWORD,
                        "token", "azertyuiop"
                )
        );

        mockMvc.perform(post("/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(DtoFactory.toJson(loginDTO)))
                .andDo(MockMvcResultHandlers.print())
                .andExpect(status().isUnprocessableContent())
                .andExpect(jsonPath("$.i18nKey").value("validation.failed"))
                .andExpect(jsonPath("$.message").value("Validation failed"))
                .andExpect(jsonPath("$.extra.email").value("must not be blank"));
    }

    @Test
    void shouldLogin_WithUnverifiedUser() throws Exception {
        this.userSeeder.createUnverifiedUser();

        LoginDTO loginDTO = DtoFactory.createDto(LoginDTO.class,
                Map.of(
                        "email", UserSeeder.UNVERIFIED_USER_EMAIL,
                        "password", UserSeeder.USER_DEFAULT_PASSWORD,
                        "token", "azertyuiop"
                )
        );

        when(authenticationManager.authenticate(ArgumentMatchers.any())).thenThrow(new UnverifiedException());

        mockMvc.perform(post("/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(DtoFactory.toJson(loginDTO)))
                .andDo(MockMvcResultHandlers.print())
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.i18nKey").value("security.email_not_verified"))
                .andExpect(jsonPath("$.message").value("Your email address has not been confirmed. Please check your email and click the confirmation link."))
                .andExpect(jsonPath("$.extra").value(IsNull.nullValue()));
    }

    @Test
    void shouldLogin_WithBannedUser() throws Exception {
        this.userSeeder.createBannedUser();

        LoginDTO loginDTO = DtoFactory.createDto(LoginDTO.class,
                Map.of(
                        "email", UserSeeder.BANNED_USER_EMAIL,
                        "password", UserSeeder.USER_DEFAULT_PASSWORD,
                        "token", "azertyuiop"
                )
        );

        when(authenticationManager.authenticate(ArgumentMatchers.any())).thenThrow(new BannedException());

        mockMvc.perform(post("/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(DtoFactory.toJson(loginDTO)))
                .andDo(MockMvcResultHandlers.print())
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.i18nKey").value("security.account_banned"))
                .andExpect(jsonPath("$.message").value("Your account has been banned."))
                .andExpect(jsonPath("$.extra").value(IsNull.nullValue()));
    }

    /*
     * REGISTER ENDPOINT TESTS
     */

    @Test
    void shouldRegister_WithValidCredentials() throws Exception {
        RegisterDTO registerDTO = DtoFactory.createDto(RegisterDTO.class,
                Map.of(
                        "firstname", "New",
                        "lastname", "User",
                        "email", UserSeeder.NEW_USER_EMAIL,
                        "password", UserSeeder.USER_DEFAULT_PASSWORD,
                        "confirmPassword", UserSeeder.USER_DEFAULT_PASSWORD,
                        "token", "azertyuiop"
                )
        );

        mockMvc.perform(post("/register")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(DtoFactory.toJson(registerDTO)))
                .andDo(MockMvcResultHandlers.print())
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.i18nKey").value("security.register.success"))
                .andExpect(jsonPath("$.message").value("User registered successfully. Please check your email to confirm your account."))
                .andExpect(jsonPath("$.extra").value(IsNull.nullValue()));
    }

    @Test
    void shouldRegister_WithAnExistingUser() throws Exception {
        RegisterDTO registerDTO = DtoFactory.createDto(RegisterDTO.class,
                Map.of(
                        "firstname", "User",
                        "lastname", "User",
                        "email", UserSeeder.USER_EMAIL,
                        "password", UserSeeder.USER_DEFAULT_PASSWORD,
                        "confirmPassword", UserSeeder.USER_DEFAULT_PASSWORD,
                        "token", "azertyuiop"
                )
        );

        mockMvc.perform(post("/register")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(DtoFactory.toJson(registerDTO)))
                .andDo(MockMvcResultHandlers.print())
                .andExpect(status().isConflict())
                .andExpect(jsonPath("$.i18nKey").value("security.email_already_exists"))
                .andExpect(jsonPath("$.message").value("An account with this email already exists."))
                .andExpect(jsonPath("$.extra").value(IsNull.nullValue()));
    }

    @Test
    void shouldRegister_WithMalformedRequest() throws Exception {
        RegisterDTO registerDTO = DtoFactory.createDto(RegisterDTO.class,
                Map.of(
                        "firstname", "User",
                        "lastname", "User",
                        "password", UserSeeder.USER_DEFAULT_PASSWORD,
                        "confirmPassword", UserSeeder.USER_DEFAULT_PASSWORD,
                        "token", "azertyuiop"
                )
        );

        mockMvc.perform(post("/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(DtoFactory.toJson(registerDTO)))
                .andDo(MockMvcResultHandlers.print())
                .andExpect(status().isUnprocessableContent())
                .andExpect(jsonPath("$.i18nKey").value("validation.failed"))
                .andExpect(jsonPath("$.message").value("Validation failed"))
                .andExpect(jsonPath("$.extra.email").value("must not be blank"));
    }

    /*
     * LOGOUT ENDPOINT TESTS
     */

    @Test
    void shouldLogout_WithValidSession() throws Exception {
        AuthenticationManagerUtil.mockAuthenticationManager(authenticationManager, sessionRepository, UserSeeder.USER);

        Optional<Session> before = sessionRepository.findByAccessToken(AuthenticationManagerUtil.ACCESS_TOKEN);
        assertTrue(before.isPresent());

        mockMvc.perform(delete("/logout")
                        .with(user(UserSeeder.USER_EMAIL))
                        .requestAttr("sessId", AuthenticationManagerUtil.ACCESS_TOKEN)
                        .contentType(MediaType.APPLICATION_JSON))
                .andDo(MockMvcResultHandlers.print())
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.i18nKey").value("logout.success"))
                .andExpect(jsonPath("$.message").value("User logged out successfully."))
                .andExpect(jsonPath("$.extra").value(IsNull.nullValue()));

        Optional<Session> after = sessionRepository.findByAccessToken(AuthenticationManagerUtil.ACCESS_TOKEN);
        assertFalse(after.isPresent());
    }

    @Test
    void shouldLogout_WithInvalidSession() throws Exception {
        Session session = AuthenticationManagerUtil.mockAuthenticationManager(authenticationManager, sessionRepository, UserSeeder.USER);

        sessionRepository.deleteById(session.getId());
        Optional<Session> after = sessionRepository.findByAccessToken(AuthenticationManagerUtil.ACCESS_TOKEN);
        assertFalse(after.isPresent());

        mockMvc.perform(delete("/logout")
                        .with(user(UserSeeder.USER_EMAIL))
                        .requestAttr("sessId", AuthenticationManagerUtil.ACCESS_TOKEN)
                        .contentType(MediaType.APPLICATION_JSON))
                .andDo(MockMvcResultHandlers.print())
                .andExpect(status().isUnauthorized())
                .andExpect(jsonPath("$.i18nKey").value("security.logout.error"))
                .andExpect(jsonPath("$.message").value("Session not found or already expired."))
                .andExpect(jsonPath("$.extra").value(IsNull.nullValue()));
    }

    /*
     * REFRESH TOKEN ENDPOINT TESTS
     */

    @Test
    void shouldRefresh_WithValidToken() throws Exception {
        RefreshDTO refreshDTO = DtoFactory.createDto(RefreshDTO.class,
                Map.of("token", "valid-refresh-token")
        );

        when(authenticationService.renewSession("valid-refresh-token"))
                .thenReturn(new AuthenticationDTO("new-access-token", "new-refresh-token"));

        mockMvc.perform(post("/refresh")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(DtoFactory.toJson(refreshDTO)))
                .andDo(MockMvcResultHandlers.print())
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.accessToken").value("new-access-token"))
                .andExpect(jsonPath("$.refreshToken").value("new-refresh-token"));
    }

    @Test
    void shouldRefresh_WithInvalidToken() throws Exception {
        RefreshDTO refreshDTO = DtoFactory.createDto(RefreshDTO.class,
                Map.of("token", "invalid-refresh-token")
        );

        when(authenticationService.renewSession(anyString()))
                .thenThrow(new RuntimeException("invalid or expired"));

        mockMvc.perform(post("/refresh")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(DtoFactory.toJson(refreshDTO)))
                .andDo(MockMvcResultHandlers.print())
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.i18nKey").value("security.refresh_token_invalid"))
                .andExpect(jsonPath("$.message").value("The provided refresh token is invalid or expired."))
                .andExpect(jsonPath("$.extra").value(IsNull.nullValue()));
    }

    /*
     * FORGOT PASSWORD ENDPOINT TESTS
     */

    @Test
    void shouldForgotPassword_WithExistingUser() throws Exception {
        ForgotPasswordDTO forgotPasswordDTO = DtoFactory.createDto(ForgotPasswordDTO.class,
                Map.of(
                        "email", UserSeeder.USER_EMAIL,
                        "token", "azertyuiop"
                )
        );

        mockMvc.perform(post("/forgot-password")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(DtoFactory.toJson(forgotPasswordDTO)))
                .andDo(MockMvcResultHandlers.print())
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.i18nKey").value("forgot_password.success"))
                .andExpect(jsonPath("$.message").value("If an account exists with the e-mail address entered, an e-mail will be sent to you with instructions for resetting your password."))
                .andExpect(jsonPath("$.extra").value(IsNull.nullValue()));
    }

    @Test
    void shouldForgotPassword_WithNonExistingUser() throws Exception {
        ForgotPasswordDTO forgotPasswordDTO = DtoFactory.createDto(ForgotPasswordDTO.class,
                Map.of(
                        "email", UserSeeder.INVALID_USER_EMAIL,
                        "token", "azertyuiop"
                )
        );

        mockMvc.perform(post("/forgot-password")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(DtoFactory.toJson(forgotPasswordDTO)))
                .andDo(MockMvcResultHandlers.print())
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.i18nKey").value("forgot_password.success"))
                .andExpect(jsonPath("$.message").value("If an account exists with the e-mail address entered, an e-mail will be sent to you with instructions for resetting your password."))
                .andExpect(jsonPath("$.extra").value(IsNull.nullValue()));
    }

    @Test
    void shouldForgotPassword_WithMalformedRequest() throws Exception {
        ForgotPasswordDTO forgotPasswordDTO = DtoFactory.createDto(ForgotPasswordDTO.class,
                Map.of(
                        "token", "azertyuiop"
                )
        );

        mockMvc.perform(post("/forgot-password")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(DtoFactory.toJson(forgotPasswordDTO)))
                .andDo(MockMvcResultHandlers.print())
                .andExpect(status().isUnprocessableContent())
                .andExpect(jsonPath("$.i18nKey").value("validation.failed"))
                .andExpect(jsonPath("$.message").value("Validation failed"))
                .andExpect(jsonPath("$.extra.email").value("must not be blank"));
    }

    /*
     * RESET PASSWORD ENDPOINT TESTS
     */

    @Test
    void shouldResetPassword_WithValidToken() throws Exception {
        ResetPasswordRequest resetRequest = userService.createResetPasswordRequest(UserSeeder.USER);

        ResetPasswordDTO resetPasswordDTO = DtoFactory.createDto(
                fr.naavi.identity.dto.input.ResetPasswordDTO.class,
                Map.of(
                        "resetPasswordToken", resetRequest.getToken(),
                        "password", "NewPassword1!",
                        "confirmPassword", "NewPassword1!",
                        "token", "azertyuiop"
                )
        );

        mockMvc.perform(post("/reset-password")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(DtoFactory.toJson(resetPasswordDTO)))
                .andDo(MockMvcResultHandlers.print())
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.i18nKey").value("reset_password.success"))
                .andExpect(jsonPath("$.message").value("Your password has been successfully reset."))
                .andExpect(jsonPath("$.extra").value(IsNull.nullValue()));
    }

    @Test
    void shouldResetPassword_WithInvalidToken() throws Exception {
        ResetPasswordDTO resetPasswordDTO = DtoFactory.createDto(
                ResetPasswordDTO.class,
                Map.of(
                        "resetPasswordToken", "non-existent-token",
                        "password", "NewPassword1!",
                        "confirmPassword", "NewPassword1!",
                        "token", "azertyuiop"
                )
        );

        mockMvc.perform(post("/reset-password")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(DtoFactory.toJson(resetPasswordDTO)))
                .andDo(MockMvcResultHandlers.print())
                .andExpect(status().isNotFound())
                .andExpect(jsonPath("$.i18nKey").value("reset_password.request_not_found"))
                .andExpect(jsonPath("$.message").value("The reset password request is invalid or has expired."))
                .andExpect(jsonPath("$.extra").value(IsNull.nullValue()));
    }

    @Test
    void shouldResetPassword_WithMalformedRequest() throws Exception {
        ResetPasswordDTO resetPasswordDTO = DtoFactory.createDto(
                ResetPasswordDTO.class,
                Map.of(
                        "password", "NewPassword1!",
                        "confirmPassword", "NewPassword1!",
                        "token", "azertyuiop"
                )
        );

        mockMvc.perform(post("/reset-password")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(DtoFactory.toJson(resetPasswordDTO)))
                .andDo(MockMvcResultHandlers.print())
                .andExpect(status().isUnprocessableContent())
                .andExpect(jsonPath("$.i18nKey").value("validation.failed"))
                .andExpect(jsonPath("$.message").value("Validation failed"))
                .andExpect(jsonPath("$.extra.resetPasswordToken").value("must not be blank"));
    }

    /*
     * IS AVAILABLE EMAIL ENDPOINT TESTS
     */

    @Test
    void shouldIsAvailableEmail_WithExistingUser() throws Exception {
        var dto = DtoFactory.createDto(IsAvailableEmailDTO.class,
                Map.of(
                        "email", UserSeeder.USER_EMAIL,
                        "token", "azertyuiop"
                )
        );

        mockMvc.perform(post("/is-available-email")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(DtoFactory.toJson(dto)))
                .andDo(MockMvcResultHandlers.print())
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.i18nKey").value("security.email_unavailable"))
                .andExpect(jsonPath("$.message").value("This email address is already taken."))
                .andExpect(jsonPath("$.extra.success").value(false));
    }

    @Test
    void shouldIsAvailableEmail_WithNonExistingEmail() throws Exception {
        var dto = DtoFactory.createDto(IsAvailableEmailDTO.class,
                Map.of(
                        "email", UserSeeder.INVALID_USER_EMAIL,
                        "token", "azertyuiop"
                )
        );

        mockMvc.perform(post("/is-available-email")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(DtoFactory.toJson(dto)))
                .andDo(MockMvcResultHandlers.print())
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.i18nKey").value("security.email_available"))
                .andExpect(jsonPath("$.message").value("This email address is available."))
                .andExpect(jsonPath("$.extra.success").value(true));
    }

    @Test
    void shouldIsAvailableEmail_WithMalformedRequest() throws Exception {
        var dto = DtoFactory.createDto(fr.naavi.identity.dto.input.IsAvailableEmailDTO.class,
                Map.of(
                        "token", "azertyuiop"
                )
        );

        mockMvc.perform(post("/is-available-email")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(DtoFactory.toJson(dto)))
                .andDo(MockMvcResultHandlers.print())
                .andExpect(status().isUnprocessableContent())
                .andExpect(jsonPath("$.i18nKey").value("validation.failed"))
                .andExpect(jsonPath("$.message").value("Validation failed"))
                .andExpect(jsonPath("$.extra.email").value("must not be blank"));
    }

    /*
     * AUTHORIZATION ENDPOINT TESTS
     */

    @Test
    void shouldAuthorization_WithValidToken() throws Exception {
        User user = this.userSeeder.createUnverifiedUser();

        User userAfterCreation = this.userRepository.findById(user.getId()).orElseThrow();
        assertEquals(StatusEnum.UNVERIFIED, userAfterCreation.getStatus());

        Authorization authorization = this.authorizationService.createAuthorizationForRegistration(user);

        AuthorizationDTO authorizationDTO = DtoFactory.createDto(AuthorizationDTO.class,
                Map.of(
                        "authorizationToken", authorization.getToken(),
                        "token", "azertyuiop"
                )
        );

        mockMvc.perform(post("/authorization")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(DtoFactory.toJson(authorizationDTO)))
                .andDo(MockMvcResultHandlers.print())
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.i18nKey").value("authorization.success"))
                .andExpect(jsonPath("$.message").value("Your authorization request has been successfully completed."))
                .andExpect(jsonPath("$.extra").value(IsNull.nullValue()));

        User updatedUser = this.userRepository.findById(user.getId()).orElseThrow();
        assertEquals(StatusEnum.VERIFIED, updatedUser.getStatus());
    }

    @Test
    void shouldAuthorization_WithInvalidToken() throws Exception {
        AuthorizationDTO authorizationDTO = DtoFactory.createDto(AuthorizationDTO.class,
                Map.of(
                        "authorizationToken", "invalid-token",
                        "token", "azertyuiop"
                )
        );

        mockMvc.perform(post("/authorization")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(DtoFactory.toJson(authorizationDTO)))
                .andDo(MockMvcResultHandlers.print())
                .andExpect(status().isNotFound())
                .andExpect(jsonPath("$.i18nKey").value("authorization.request_not_found"))
                .andExpect(jsonPath("$.message").value("The authorization request is invalid or has expired."))
                .andExpect(jsonPath("$.extra").value(IsNull.nullValue()));
    }
}
