
package fr.naavi.identity.controller;

import fr.naavi.core.exception.GlobalExceptionHandler;
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
import fr.naavi.identity.util.DtoFactory;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.context.annotation.Import;
import org.springframework.http.MediaType;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.Authentication;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.context.TestPropertySource;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;
import org.springframework.web.context.WebApplicationContext;

import javax.sql.DataSource;
import java.time.LocalDateTime;
import java.util.Map;
import java.util.Optional;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.doNothing;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.delete;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.content;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@ActiveProfiles("ci")
@WebMvcTest(SecurityController.class)
@Import(GlobalExceptionHandler.class)
@TestPropertySource(locations = "classpath:application-ci.properties")
class SecurityControllerTest {
    @Autowired
    private WebApplicationContext webApplicationContext;

    @Autowired
    private MockMvc mockMvc;

    @MockitoBean
    private UserService userService;

    @MockitoBean
    private MailerService mailerService;

    @MockitoBean
    private AuthenticationManager authenticationManager;

    @MockitoBean
    private SessionRepository sessionRepository;

    @MockitoBean
    private AuthenticationService authenticationService;

    @MockitoBean
    private DataSource dataSource;

    @BeforeEach
    void setUp() {
        mockMvc = MockMvcBuilders.webAppContextSetup(webApplicationContext).build();
    }

    @Test
    void register_ShouldReturn200_WhenRegistrationSuccessful() throws Exception {
        User user = new User();
        when(userService.checkIfUserExists(anyString())).thenReturn(null);
        when(userService.createUser(any(RegisterDTO.class))).thenReturn(user);
        doNothing().when(mailerService).sendRegistrationEmail(any(User.class));

        RegisterDTO validRegisterDto = DtoFactory.createDto(RegisterDTO.class,
                Map.of(
                        "firstname", "John",
                        "lastname", "Doe",
                        "email", "john.doe@example.com",
                        "password", "azertyuiop",
                        "confirmPassword", "azertyuiop"
                )
        );

        mockMvc.perform(post("/register")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(DtoFactory.toJson(validRegisterDto)))
                .andExpect(status().isOk())
                .andExpect(content().contentType(MediaType.APPLICATION_JSON))
                .andExpect(jsonPath("$.i18nKey").value("security.register.success"))
                .andExpect(jsonPath("$.message").value("User registered successfully."))
                .andExpect(jsonPath("$.extra").doesNotExist());

        verify(userService).checkIfUserExists("john.doe@example.com");
        verify(userService).createUser(any(RegisterDTO.class));
        verify(mailerService).sendRegistrationEmail(user);
    }

    @Test
    void register_ShouldReturn409_WhenEmailAlreadyExists() throws Exception {
        User user = new User();
        user.setEmail("john.doe@example.com");
        when(userService.checkIfUserExists(anyString())).thenReturn(user);

        RegisterDTO registerDto = DtoFactory.createDto(RegisterDTO.class,
                Map.of(
                        "firstname", "John",
                        "lastname", "Doe",
                        "email", "john.doe@example.com",
                        "password", "azertyuiop",
                        "confirmPassword", "azertyuiop"
                )
        );

        mockMvc.perform(post("/register")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(DtoFactory.toJson(registerDto)))
                .andExpect(status().isConflict())
                .andExpect(content().contentType(MediaType.APPLICATION_JSON))
                .andExpect(jsonPath("$.i18nKey").value("security.email_already_exists"))
                .andExpect(jsonPath("$.message").value("An account with this email already exists."));

        verify(userService).checkIfUserExists("john.doe@example.com");
        verify(userService, never()).createUser(any(RegisterDTO.class));
        verify(mailerService, never()).sendRegistrationEmail(any(User.class));
    }

    @Test
    void register_ShouldReturn400_WhenRequestBodyIsMissing() throws Exception {
        mockMvc.perform(post("/register")
                        .contentType(MediaType.APPLICATION_JSON))
                .andExpect(status().isBadRequest());

        verify(userService, never()).checkIfUserExists(anyString());
        verify(userService, never()).createUser(any(RegisterDTO.class));
        verify(mailerService, never()).sendRegistrationEmail(any(User.class));
    }

    @Test
    void register_ShouldReturn400_WhenJsonIsMalformed() throws Exception {
        mockMvc.perform(post("/register")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"invalid\":\"json\"}"))
                .andExpect(status().isUnprocessableEntity());

        verify(userService, never()).checkIfUserExists(anyString());
        verify(userService, never()).createUser(any(RegisterDTO.class));
        verify(mailerService, never()).sendRegistrationEmail(any(User.class));
    }

    @Test
    void register_ShouldReturn422_WhenPasswordsDoNotMatch() throws Exception {
        when(userService.checkIfUserExists(anyString())).thenReturn(null);

        RegisterDTO invalidDto = DtoFactory.createDto(RegisterDTO.class,
                Map.of(
                        "firstname", "John",
                        "lastname", "Doe",
                        "email", "john.doe@example.com",
                        "password", "azertyuiop",
                        "confirmPassword", "differentpassword"
                )
        );

        mockMvc.perform(post("/register")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(DtoFactory.toJson(invalidDto)))
                .andExpect(status().isUnprocessableEntity())
                .andExpect(jsonPath("$.i18nKey").value("validation.failed"))
                .andExpect(jsonPath("$.message").value("Validation failed"))
                .andExpect(jsonPath("$.extra.confirmPassword").exists());

        verify(userService, never()).checkIfUserExists(anyString());
        verify(userService, never()).createUser(any(RegisterDTO.class));
        verify(mailerService, never()).sendRegistrationEmail(any(User.class));
    }

    @Test
    void register_ShouldReturn422_WhenPasswordTooShort() throws Exception {
        when(userService.checkIfUserExists(anyString())).thenReturn(null);
        RegisterDTO shortPasswordDto = DtoFactory.createDto(RegisterDTO.class,
                Map.of(
                        "firstname", "John",
                        "lastname", "Doe",
                        "email", "john.doe@example.com",
                        "password", "123456",
                        "confirmPassword", "123456"
                )
        );

        mockMvc.perform(post("/register")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(DtoFactory.toJson(shortPasswordDto)))
                .andExpect(status().isUnprocessableEntity())
                .andExpect(content().contentType(MediaType.APPLICATION_JSON))
                .andExpect(jsonPath("$.i18nKey").value("validation.failed"))
                .andExpect(jsonPath("$.message").value("Validation failed"))
                .andExpect(jsonPath("$.extra.password").exists())
                .andExpect(jsonPath("$.extra.confirmPassword").exists());

        verify(userService, never()).checkIfUserExists(anyString());
        verify(userService, never()).createUser(any(RegisterDTO.class));
        verify(mailerService, never()).sendRegistrationEmail(any(User.class));
    }

    @Test
    void register_ShouldReturn422_WhenEmailIsInvalid() throws Exception {
        when(userService.checkIfUserExists(anyString())).thenReturn(null);
        RegisterDTO invalidEmailDto = DtoFactory.createDto(RegisterDTO.class,
                Map.of(
                        "firstname", "John",
                        "lastname", "Doe",
                        "email", "email-invalide",
                        "password", "azertyuiop",
                        "confirmPassword", "azertyuiop"
                )
        );

        mockMvc.perform(post("/register")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(DtoFactory.toJson(invalidEmailDto)))
                .andExpect(status().isUnprocessableEntity())
                .andExpect(content().contentType(MediaType.APPLICATION_JSON))
                .andExpect(jsonPath("$.i18nKey").value("validation.failed"))
                .andExpect(jsonPath("$.message").value("Validation failed"))
                .andExpect(jsonPath("$.extra.email").exists());

        verify(userService, never()).checkIfUserExists(anyString());
        verify(userService, never()).createUser(any(RegisterDTO.class));
        verify(mailerService, never()).sendRegistrationEmail(any(User.class));
    }

    @Test
    void login_ShouldReturn400_WhenRequestBodyIsMissing() throws Exception {
        mockMvc.perform(post("/login")
                        .contentType(MediaType.APPLICATION_JSON))
                .andExpect(status().isBadRequest());

        verify(authenticationService, never()).renewSession(anyString());
    }

    @Test
    void login_ShouldReturn400_WhenJsonIsMalformed() throws Exception {
        mockMvc.perform(post("/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"invalid\":\"json\"}"))
                .andExpect(status().isUnprocessableEntity());

        verify(authenticationService, never()).renewSession(anyString());
    }

    @Test
    void login_ShouldReturn200_WhenCredentialsAreValid() throws Exception {
        Authentication mockAuthentication = mock(Authentication.class);
        AuthenticationDTO expectedAuthDto = new AuthenticationDTO("mock-access-token", "mock-refresh-token");
        when(mockAuthentication.getDetails()).thenReturn(expectedAuthDto);
        when(authenticationManager.authenticate(any(UsernamePasswordAuthenticationToken.class)))
                .thenReturn(mockAuthentication);

        LoginDTO validLoginDto = DtoFactory.createDto(LoginDTO.class,
                Map.of(
                        "email", "john.doe@example.com",
                        "password", "azertyuiop"
                )
        );

        mockMvc.perform(post("/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(DtoFactory.toJson(validLoginDto)))
                .andExpect(status().isOk())
                .andExpect(content().contentType(MediaType.APPLICATION_JSON))
                .andExpect(jsonPath("$.accessToken").value("mock-access-token"))
                .andExpect(jsonPath("$.refreshToken").value("mock-refresh-token"));

        verify(authenticationManager).authenticate(any(UsernamePasswordAuthenticationToken.class));
    }

    @Test
    void login_ShouldReturn401_WhenCredentialsAreInvalid() throws Exception {
        when(authenticationManager.authenticate(any(UsernamePasswordAuthenticationToken.class)))
                .thenThrow(new RuntimeException("Invalid credentials"));

        LoginDTO invalidLoginDto = DtoFactory.createDto(LoginDTO.class,
                Map.of(
                        "email", "john.doe@example.com",
                        "password", "wrongpassword"
                )
        );

        mockMvc.perform(post("/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(DtoFactory.toJson(invalidLoginDto)))
                .andExpect(status().isBadRequest())
                .andExpect(content().contentType(MediaType.APPLICATION_JSON))
                .andExpect(jsonPath("$.i18nKey").value("security.invalid_credentials"))
                .andExpect(jsonPath("$.message").value("Invalid credentials provided."));

        verify(authenticationManager).authenticate(any(UsernamePasswordAuthenticationToken.class));
    }

    @Test
    void login_ShouldReturn422_WhenEmailIsEmpty() throws Exception {
        LoginDTO invalidLoginDto = DtoFactory.createDto(LoginDTO.class,
                Map.of(
                        "email", "",
                        "password", "azertyuiop"
                )
        );

        mockMvc.perform(post("/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(DtoFactory.toJson(invalidLoginDto)))
                .andExpect(status().isUnprocessableEntity())
                .andExpect(content().contentType(MediaType.APPLICATION_JSON))
                .andExpect(jsonPath("$.i18nKey").value("validation.failed"))
                .andExpect(jsonPath("$.message").value("Validation failed"))
                .andExpect(jsonPath("$.extra.email").exists());

        verify(authenticationManager, never()).authenticate(any(UsernamePasswordAuthenticationToken.class));
    }

    @Test
    void login_ShouldReturn422_WhenPasswordIsEmpty() throws Exception {
        LoginDTO invalidLoginDto = DtoFactory.createDto(LoginDTO.class,
                Map.of(
                        "email", "john.doe@example.com",
                        "password", ""
                )
        );

        mockMvc.perform(post("/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(DtoFactory.toJson(invalidLoginDto)))
                .andExpect(status().isUnprocessableEntity())
                .andExpect(content().contentType(MediaType.APPLICATION_JSON))
                .andExpect(jsonPath("$.i18nKey").value("validation.failed"))
                .andExpect(jsonPath("$.message").value("Validation failed"))
                .andExpect(jsonPath("$.extra.password").exists());

        verify(authenticationManager, never()).authenticate(any(UsernamePasswordAuthenticationToken.class));
    }

    @Test
    void login_ShouldReturn422_WhenEmailIsInvalid() throws Exception {
        LoginDTO invalidLoginDto = DtoFactory.createDto(LoginDTO.class,
                Map.of(
                        "email", "email-invalide",
                        "password", "azertyuiop"
                )
        );

        mockMvc.perform(post("/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(DtoFactory.toJson(invalidLoginDto)))
                .andExpect(status().isUnprocessableEntity())
                .andExpect(content().contentType(MediaType.APPLICATION_JSON))
                .andExpect(jsonPath("$.i18nKey").value("validation.failed"))
                .andExpect(jsonPath("$.message").value("Validation failed"))
                .andExpect(jsonPath("$.extra.email").exists());

        verify(authenticationManager, never()).authenticate(any(UsernamePasswordAuthenticationToken.class));
    }

    @Test
    void login_ShouldReturn422_WhenBothFieldsAreEmpty() throws Exception {
        LoginDTO invalidLoginDto = DtoFactory.createDto(LoginDTO.class,
                Map.of(
                        "email", "",
                        "password", ""
                )
        );

        mockMvc.perform(post("/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(DtoFactory.toJson(invalidLoginDto)))
                .andExpect(status().isUnprocessableEntity())
                .andExpect(content().contentType(MediaType.APPLICATION_JSON))
                .andExpect(jsonPath("$.i18nKey").value("validation.failed"))
                .andExpect(jsonPath("$.message").value("Validation failed"))
                .andExpect(jsonPath("$.extra.email").exists())
                .andExpect(jsonPath("$.extra.password").exists());

        verify(authenticationManager, never()).authenticate(any(UsernamePasswordAuthenticationToken.class));
    }

    @Test
    void logout_ShouldReturn200_WhenSessionIsValidAndDeleted() throws Exception {
        String validAccessToken = "valid-access-token";
        Session mockSession = new Session();
        mockSession.setAccessToken(validAccessToken);
        mockSession.setRefreshToken("refresh-token");
        mockSession.setClientIp("192.168.1.1");
        mockSession.setUserAgent("Test-Agent");
        mockSession.setAccessTokenExpiredAt(LocalDateTime.now().plusHours(1));
        mockSession.setRefreshTokenExpiredAt(LocalDateTime.now().plusDays(7));
        mockSession.setCreatedAt(LocalDateTime.now());

        User mockUser = new User();
        mockSession.setUser(mockUser);
        when(sessionRepository.findByAccessToken(validAccessToken)).thenReturn(Optional.of(mockSession));

        mockMvc.perform(delete("/logout")
                        .requestAttr("sessId", validAccessToken))
                .andExpect(status().isOk())
                .andExpect(content().contentType(MediaType.APPLICATION_JSON))
                .andExpect(jsonPath("$.i18nKey").value("logout.success"))
                .andExpect(jsonPath("$.message").value("User logged out successfully."))
                .andExpect(jsonPath("$.extra").doesNotExist());

        verify(sessionRepository).findByAccessToken(validAccessToken);
        verify(sessionRepository).delete(mockSession);
    }

    @Test
    void logout_ShouldReturn401_WhenSessionIdIsMissing() throws Exception {
        mockMvc.perform(delete("/logout"))
                .andExpect(status().isUnauthorized())
                .andExpect(content().contentType(MediaType.APPLICATION_JSON))
                .andExpect(jsonPath("$.i18nKey").value("security.logout.error"))
                .andExpect(jsonPath("$.message").value("Session ID is missing or invalid."));

        verify(sessionRepository, never()).findByAccessToken(any());
        verify(sessionRepository, never()).delete(any());
    }

    @Test
    void logout_ShouldReturn401_WhenSessionIdIsEmpty() throws Exception {
        mockMvc.perform(delete("/logout")
                        .requestAttr("sessId", ""))
                .andExpect(status().isUnauthorized())
                .andExpect(content().contentType(MediaType.APPLICATION_JSON))
                .andExpect(jsonPath("$.i18nKey").value("security.logout.error"))
                .andExpect(jsonPath("$.message").value("Session ID is missing or invalid."));

        verify(sessionRepository, never()).findByAccessToken(any());
        verify(sessionRepository, never()).delete(any());
    }

    @Test
    void logout_ShouldReturn401_WhenSessionNotFound() throws Exception {
        String invalidAccessToken = "invalid-access-token";
        when(sessionRepository.findByAccessToken(invalidAccessToken)).thenReturn(Optional.empty());

        mockMvc.perform(delete("/logout")
                        .requestAttr("sessId", invalidAccessToken))
                .andExpect(status().isUnauthorized())
                .andExpect(content().contentType(MediaType.APPLICATION_JSON))
                .andExpect(jsonPath("$.i18nKey").value("security.logout.error"))
                .andExpect(jsonPath("$.message").value("Session not found or already expired."));

        verify(sessionRepository).findByAccessToken(invalidAccessToken);
        verify(sessionRepository, never()).delete(any());
    }

    @Test
    void refresh_ShouldReturn200_WhenRefreshTokenIsValid() throws Exception {
        String validRefreshToken = "valid-refresh-token";
        AuthenticationDTO expectedAuthDto = new AuthenticationDTO("new-access-token", "new-refresh-token");
        when(authenticationService.renewSession(validRefreshToken)).thenReturn(expectedAuthDto);

        RefreshDTO validRefreshDto = DtoFactory.createDto(RefreshDTO.class,
                Map.of("token", validRefreshToken)
        );

        mockMvc.perform(post("/refresh")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(DtoFactory.toJson(validRefreshDto)))
                .andExpect(status().isOk())
                .andExpect(content().contentType(MediaType.APPLICATION_JSON))
                .andExpect(jsonPath("$.accessToken").value("new-access-token"))
                .andExpect(jsonPath("$.refreshToken").value("new-refresh-token"));

        verify(authenticationService).renewSession(validRefreshToken);
    }

    @Test
    void refresh_ShouldReturn401_WhenRefreshTokenIsExpired() throws Exception {
        String expiredRefreshToken = "expired-refresh-token";
        when(authenticationService.renewSession(expiredRefreshToken))
                .thenThrow(new RuntimeException("Refresh token is expired."));

        RefreshDTO expiredRefreshDto = DtoFactory.createDto(RefreshDTO.class,
                Map.of("token", expiredRefreshToken)
        );

        mockMvc.perform(post("/refresh")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(DtoFactory.toJson(expiredRefreshDto)))
                .andExpect(status().isBadRequest())
                .andExpect(content().contentType(MediaType.APPLICATION_JSON))
                .andExpect(jsonPath("$.i18nKey").value("security.refresh_token_invalid"))
                .andExpect(jsonPath("$.message").value("The provided refresh token is invalid or expired."));

        verify(authenticationService).renewSession(expiredRefreshToken);
    }

    @Test
    void refresh_ShouldReturn400_WhenRequestBodyIsMissing() throws Exception {
        mockMvc.perform(post("/refresh")
                        .contentType(MediaType.APPLICATION_JSON))
                .andExpect(status().isBadRequest());

        verify(authenticationService, never()).renewSession(anyString());
    }

    @Test
    void refresh_ShouldReturn400_WhenJsonIsMalformed() throws Exception {
        mockMvc.perform(post("/refresh")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"invalid\":\"json\"}"))
                .andExpect(status().isUnprocessableEntity());

        verify(authenticationService, never()).renewSession(anyString());
    }

    @Test
    void refresh_ShouldReturn422_WhenTokenIsBlank() throws Exception {
        RefreshDTO blankTokenDto = DtoFactory.createDto(RefreshDTO.class,
                Map.of("token", "")
        );

        mockMvc.perform(post("/refresh")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(DtoFactory.toJson(blankTokenDto)))
                .andExpect(status().isUnprocessableEntity())
                .andExpect(content().contentType(MediaType.APPLICATION_JSON))
                .andExpect(jsonPath("$.i18nKey").value("validation.failed"))
                .andExpect(jsonPath("$.message").value("Validation failed"))
                .andExpect(jsonPath("$.extra.token").exists());

        verify(authenticationService, never()).renewSession(anyString());
    }

    @Test
    void refresh_ShouldCallAuthenticationService_WhenTokenIsValid() throws Exception {
        String validToken = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...";
        AuthenticationDTO authDto = new AuthenticationDTO("new-access-token", "new-refresh-token");
        when(authenticationService.renewSession(validToken)).thenReturn(authDto);

        RefreshDTO refreshDto = DtoFactory.createDto(RefreshDTO.class,
                Map.of("token", validToken)
        );

        mockMvc.perform(post("/refresh")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(DtoFactory.toJson(refreshDto)))
                .andExpect(status().isOk());

        verify(authenticationService).renewSession(validToken);
    }


    @Test
    void forgotPassword_ShouldReturn200_WhenUserExistsAndEmailIsSent() throws Exception {
        User user = new User();
        user.setEmail("john.doe@example.com");

        ResetPasswordRequest resetPasswordRequest = new ResetPasswordRequest();
        resetPasswordRequest.setUser(user);
        resetPasswordRequest.setToken("mock-reset-token");
        resetPasswordRequest.setExpiredAt(LocalDateTime.now().plusHours(24));
        resetPasswordRequest.setCreatedAt(LocalDateTime.now());

        when(userService.checkIfUserExists(user.getEmail())).thenReturn(user);
        when(userService.createResetPasswordRequest(user)).thenReturn(resetPasswordRequest);

        ForgotPasswordDTO validForgotPasswordDto = DtoFactory.createDto(ForgotPasswordDTO.class,
                Map.of("email", user.getEmail())
        );

        mockMvc.perform(post("/forgot-password")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(DtoFactory.toJson(validForgotPasswordDto)))
                .andExpect(status().isOk())
                .andExpect(content().contentType(MediaType.APPLICATION_JSON))
                .andExpect(jsonPath("$.i18nKey").value("forgot_password.success"))
                .andExpect(jsonPath("$.message").value("If an account exists with the e-mail address entered, an e-mail will be sent to you with instructions for resetting your password."))
                .andExpect(jsonPath("$.extra").doesNotExist());

        verify(userService).checkIfUserExists(user.getEmail());
        verify(userService).createResetPasswordRequest(user);
        verify(mailerService).sendForgotPasswordEmail(resetPasswordRequest);
    }

    @Test
    void forgotPassword_ShouldReturn200_WhenUserDoesNotExistButResponseIsGeneric() throws Exception {
        String nonExistentEmail = "nonexistent@example.com";
        when(userService.checkIfUserExists(nonExistentEmail)).thenReturn(null);

        ForgotPasswordDTO forgotPasswordDto = DtoFactory.createDto(ForgotPasswordDTO.class,
                Map.of("email", nonExistentEmail)
        );

        mockMvc.perform(post("/forgot-password")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(DtoFactory.toJson(forgotPasswordDto)))
                .andExpect(status().isOk())
                .andExpect(content().contentType(MediaType.APPLICATION_JSON))
                .andExpect(jsonPath("$.i18nKey").value("forgot_password.success"))
                .andExpect(jsonPath("$.message").value("If an account exists with the e-mail address entered, an e-mail will be sent to you with instructions for resetting your password."))
                .andExpect(jsonPath("$.extra").doesNotExist());

        verify(userService).checkIfUserExists(nonExistentEmail);
        verify(userService, never()).createResetPasswordRequest(any(User.class));
        verify(mailerService, never()).sendForgotPasswordEmail(any(ResetPasswordRequest.class));
    }

    @Test
    void forgotPassword_ShouldReturn400_WhenRequestBodyIsMissing() throws Exception {
        mockMvc.perform(post("/forgot-password")
                        .contentType(MediaType.APPLICATION_JSON))
                .andExpect(status().isBadRequest());

        verify(userService, never()).checkIfUserExists(anyString());
        verify(userService, never()).createResetPasswordRequest(any(User.class));
        verify(mailerService, never()).sendForgotPasswordEmail(any(ResetPasswordRequest.class));
    }

    @Test
    void forgotPassword_ShouldReturn400_WhenJsonIsMalformed() throws Exception {
        mockMvc.perform(post("/forgot-password")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"invalid\":\"json\"}"))
                .andExpect(status().isUnprocessableEntity());

        verify(userService, never()).checkIfUserExists(anyString());
        verify(userService, never()).createResetPasswordRequest(any(User.class));
        verify(mailerService, never()).sendForgotPasswordEmail(any(ResetPasswordRequest.class));
    }

    @Test
    void forgotPassword_ShouldReturn422_WhenEmailIsBlank() throws Exception {
        ForgotPasswordDTO blankEmailDto = DtoFactory.createDto(ForgotPasswordDTO.class,
                Map.of("email", "")
        );

        mockMvc.perform(post("/forgot-password")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(DtoFactory.toJson(blankEmailDto)))
                .andExpect(status().isUnprocessableEntity())
                .andExpect(content().contentType(MediaType.APPLICATION_JSON))
                .andExpect(jsonPath("$.i18nKey").value("validation.failed"))
                .andExpect(jsonPath("$.message").value("Validation failed"))
                .andExpect(jsonPath("$.extra.email").exists());

        verify(userService, never()).checkIfUserExists(anyString());
        verify(userService, never()).createResetPasswordRequest(any(User.class));
        verify(mailerService, never()).sendForgotPasswordEmail(any(ResetPasswordRequest.class));
    }

    @Test
    void forgotPassword_ShouldReturn422_WhenEmailIsInvalid() throws Exception {
        ForgotPasswordDTO invalidEmailDto = DtoFactory.createDto(ForgotPasswordDTO.class,
                Map.of("email", "email-invalide")
        );

        mockMvc.perform(post("/forgot-password")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(DtoFactory.toJson(invalidEmailDto)))
                .andExpect(status().isUnprocessableEntity())
                .andExpect(content().contentType(MediaType.APPLICATION_JSON))
                .andExpect(jsonPath("$.i18nKey").value("validation.failed"))
                .andExpect(jsonPath("$.message").value("Validation failed"))
                .andExpect(jsonPath("$.extra.email").exists());

        verify(userService, never()).checkIfUserExists(anyString());
        verify(userService, never()).createResetPasswordRequest(any(User.class));
        verify(mailerService, never()).sendForgotPasswordEmail(any(ResetPasswordRequest.class));
    }

    @Test
    void resetPassword_ShouldReturn200_WhenTokenIsValidAndPasswordReset() throws Exception {
        String validToken = "valid-reset-token";
        User user = new User();
        user.setEmail("john.doe@example.com");

        ResetPasswordRequest resetPasswordRequest = new ResetPasswordRequest();
        resetPasswordRequest.setToken(validToken);
        resetPasswordRequest.setUser(user);
        resetPasswordRequest.setExpiredAt(LocalDateTime.now().plusHours(24));
        resetPasswordRequest.setCreatedAt(LocalDateTime.now());

        when(userService.checkIfResetPasswordRequestExists(validToken)).thenReturn(resetPasswordRequest);

        ResetPasswordDTO validResetPasswordDto = DtoFactory.createDto(ResetPasswordDTO.class,
                Map.of(
                        "token", validToken,
                        "password", "newpassword123",
                        "confirmPassword", "newpassword123"
                )
        );

        mockMvc.perform(post("/reset-password")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(DtoFactory.toJson(validResetPasswordDto)))
                .andExpect(status().isOk())
                .andExpect(content().contentType(MediaType.APPLICATION_JSON))
                .andExpect(jsonPath("$.i18nKey").value("reset_password.success"))
                .andExpect(jsonPath("$.message").value("Your password has been successfully reset."))
                .andExpect(jsonPath("$.extra").doesNotExist());

        verify(userService).checkIfResetPasswordRequestExists(validToken);
        verify(userService).updatePassword(eq(user), any(ResetPasswordDTO.class));
        verify(userService).deleteResetPasswordRequest(resetPasswordRequest);
        verify(mailerService).sendResetPasswordConfirmationEmail(user);
    }

    @Test
    void resetPassword_ShouldReturn404_WhenTokenIsInvalid() throws Exception {
        String invalidToken = "invalid-token";
        when(userService.checkIfResetPasswordRequestExists(invalidToken)).thenReturn(null);

        ResetPasswordDTO resetPasswordDto = DtoFactory.createDto(ResetPasswordDTO.class,
                Map.of(
                        "token", invalidToken,
                        "password", "newpassword123",
                        "confirmPassword", "newpassword123"
                )
        );

        mockMvc.perform(post("/reset-password")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(DtoFactory.toJson(resetPasswordDto)))
                .andExpect(status().isNotFound())
                .andExpect(content().contentType(MediaType.APPLICATION_JSON))
                .andExpect(jsonPath("$.i18nKey").value("reset_password.request_not_found"))
                .andExpect(jsonPath("$.message").value("The reset password request is invalid or has expired."));

        verify(userService).checkIfResetPasswordRequestExists(invalidToken);
        verify(userService, never()).updatePassword(any(User.class), any(ResetPasswordDTO.class));
        verify(userService, never()).deleteResetPasswordRequest(any(ResetPasswordRequest.class));
        verify(mailerService, never()).sendResetPasswordConfirmationEmail(any(User.class));
    }

    @Test
    void resetPassword_ShouldReturn400_WhenRequestBodyIsMissing() throws Exception {
        mockMvc.perform(post("/reset-password")
                        .contentType(MediaType.APPLICATION_JSON))
                .andExpect(status().isBadRequest());

        verify(userService, never()).checkIfResetPasswordRequestExists(anyString());
        verify(userService, never()).updatePassword(any(User.class), any(ResetPasswordDTO.class));
        verify(userService, never()).deleteResetPasswordRequest(any(ResetPasswordRequest.class));
        verify(mailerService, never()).sendResetPasswordConfirmationEmail(any(User.class));
    }

    @Test
    void resetPassword_ShouldReturn400_WhenJsonIsMalformed() throws Exception {
        mockMvc.perform(post("/reset-password")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"invalid\":\"json\"}"))
                .andExpect(status().isUnprocessableEntity());

        verify(userService, never()).checkIfResetPasswordRequestExists(anyString());
        verify(userService, never()).updatePassword(any(User.class), any(ResetPasswordDTO.class));
        verify(userService, never()).deleteResetPasswordRequest(any(ResetPasswordRequest.class));
        verify(mailerService, never()).sendResetPasswordConfirmationEmail(any(User.class));
    }

    @Test
    void resetPassword_ShouldReturn422_WhenPasswordIsTooShort() throws Exception {
        ResetPasswordDTO shortPasswordDto = DtoFactory.createDto(ResetPasswordDTO.class,
                Map.of(
                        "token", "valid-token",
                        "password", "123456",
                        "confirmPassword", "123456"
                )
        );

        mockMvc.perform(post("/reset-password")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(DtoFactory.toJson(shortPasswordDto)))
                .andExpect(status().isUnprocessableEntity())
                .andExpect(content().contentType(MediaType.APPLICATION_JSON))
                .andExpect(jsonPath("$.i18nKey").value("validation.failed"))
                .andExpect(jsonPath("$.message").value("Validation failed"))
                .andExpect(jsonPath("$.extra.password").exists())
                .andExpect(jsonPath("$.extra.confirmPassword").exists());

        verify(userService, never()).checkIfResetPasswordRequestExists(anyString());
        verify(userService, never()).updatePassword(any(User.class), any(ResetPasswordDTO.class));
        verify(userService, never()).deleteResetPasswordRequest(any(ResetPasswordRequest.class));
        verify(mailerService, never()).sendResetPasswordConfirmationEmail(any(User.class));
    }

    @Test
    void resetPassword_ShouldReturn422_WhenPasswordsDoNotMatch() throws Exception {
        ResetPasswordDTO mismatchPasswordDto = DtoFactory.createDto(ResetPasswordDTO.class,
                Map.of(
                        "token", "valid-token",
                        "password", "newpassword123",
                        "confirmPassword", "differentpassword123"
                )
        );

        mockMvc.perform(post("/reset-password")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(DtoFactory.toJson(mismatchPasswordDto)))
                .andExpect(status().isUnprocessableEntity())
                .andExpect(content().contentType(MediaType.APPLICATION_JSON))
                .andExpect(jsonPath("$.i18nKey").value("validation.failed"))
                .andExpect(jsonPath("$.message").value("Validation failed"))
                .andExpect(jsonPath("$.extra.confirmPassword").exists());

        verify(userService, never()).checkIfResetPasswordRequestExists(anyString());
        verify(userService, never()).updatePassword(any(User.class), any(ResetPasswordDTO.class));
        verify(userService, never()).deleteResetPasswordRequest(any(ResetPasswordRequest.class));
        verify(mailerService, never()).sendResetPasswordConfirmationEmail(any(User.class));
    }

    @Test
    void resetPassword_ShouldReturn422_WhenAllFieldsAreBlank() throws Exception {
        ResetPasswordDTO allBlankDto = DtoFactory.createDto(ResetPasswordDTO.class,
                Map.of(
                        "token", "",
                        "password", "",
                        "confirmPassword", ""
                )
        );

        mockMvc.perform(post("/reset-password")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(DtoFactory.toJson(allBlankDto)))
                .andExpect(status().isUnprocessableEntity())
                .andExpect(content().contentType(MediaType.APPLICATION_JSON))
                .andExpect(jsonPath("$.i18nKey").value("validation.failed"))
                .andExpect(jsonPath("$.message").value("Validation failed"))
                .andExpect(jsonPath("$.extra.token").exists())
                .andExpect(jsonPath("$.extra.password").exists())
                .andExpect(jsonPath("$.extra.confirmPassword").exists());

        verify(userService, never()).checkIfResetPasswordRequestExists(anyString());
        verify(userService, never()).updatePassword(any(User.class), any(ResetPasswordDTO.class));
        verify(userService, never()).deleteResetPasswordRequest(any(ResetPasswordRequest.class));
        verify(mailerService, never()).sendResetPasswordConfirmationEmail(any(User.class));
    }
}