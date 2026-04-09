package fr.naavi.identity.controller;

import fr.naavi.core.enums.S3Enum;
import fr.naavi.core.exception.GlobalExceptionHandler;
import fr.naavi.core.service.S3Service;
import fr.naavi.identity.configuration.CacheConfigurationTest;
import fr.naavi.identity.entity.User;
import fr.naavi.identity.repository.UserRepository;
import fr.naavi.identity.seeder.UserSeeder;
import fr.naavi.identity.util.AuthenticationManagerUtil;
import org.hamcrest.core.IsNull;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.Mockito;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.webmvc.test.autoconfigure.AutoConfigureMockMvc;
import org.springframework.context.annotation.Import;
import org.springframework.http.MediaType;
import org.springframework.mock.web.MockMultipartFile;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.context.TestPropertySource;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.result.MockMvcResultHandlers;

import static org.junit.jupiter.api.Assertions.*;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.authentication;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("ci")
@TestPropertySource(locations = "classpath:application-ci.properties")
@Import({GlobalExceptionHandler.class, CacheConfigurationTest.class})
public class UserControllerTest {
    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private UserSeeder userSeeder;

    @MockitoBean
    private AuthenticationManager authenticationManager;

    @Autowired
    private UserRepository userRepository;

    @MockitoBean
    private S3Service s3Service;

    @BeforeEach
    void setUp() {
        userSeeder.seedUsers();
    }

    @Test
    void shouldGetUserData_WithAnUnauthenticatedUser() throws Exception {
        mockMvc.perform(get("/user")).andExpect(status().isUnauthorized());
    }

    @Test
    void shouldGetUser_WithAuthenticatedUser() throws Exception {
        User user = UserSeeder.USER;
        UsernamePasswordAuthenticationToken authToken = AuthenticationManagerUtil.mockAuthenticationManager(authenticationManager, user);

        mockMvc.perform(get("/user")
                        .with(authentication(authToken))
                        .contentType(MediaType.APPLICATION_JSON))
                .andDo(MockMvcResultHandlers.print())
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.id").isNumber())
                .andExpect(jsonPath("$.firstname").value(user.getFirstname()))
                .andExpect(jsonPath("$.lastname").value(user.getLastname()))
                .andExpect(jsonPath("$.fullName").value(user.getFullName()))
                .andExpect(jsonPath("$.email").value(user.getEmail()))
                .andExpect(jsonPath("$.status").value(user.getStatus().name()))
                .andExpect(jsonPath("$.roles").isArray())
                .andExpect(jsonPath("$.permissions").isArray())
                .andExpect(jsonPath("$.createdAt").exists())
                .andExpect(jsonPath("$.updatedAt").value(IsNull.nullValue()));
    }

    @Test
    void shouldUpdateUser_WithAuthenticatedUser() throws Exception {
        User user = UserSeeder.USER;
        UsernamePasswordAuthenticationToken authToken = AuthenticationManagerUtil.mockAuthenticationManager(authenticationManager, user);

        String payload = "{\"firstname\":\"UpdatedFirst\",\"lastname\":\"UpdatedLast\"}";

        mockMvc.perform(put("/user")
                        .with(authentication(authToken))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(payload))
                .andDo(MockMvcResultHandlers.print())
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.id").isNumber())
                .andExpect(jsonPath("$.firstname").value("UpdatedFirst"))
                .andExpect(jsonPath("$.lastname").value("UpdatedLast"))
                .andExpect(jsonPath("$.fullName").value("UpdatedFirst UpdatedLast"))
                .andExpect(jsonPath("$.email").value(user.getEmail()))
                .andExpect(jsonPath("$.roles").isArray())
                .andExpect(jsonPath("$.permissions").isArray())
                .andExpect(jsonPath("$.createdAt").exists())
                .andExpect(jsonPath("$.updatedAt").exists());
    }

    @Test
    void shouldUpdateUser_WithEmailChange_SendsAuthorizationEmail() throws Exception {
        User user = UserSeeder.USER;
        UsernamePasswordAuthenticationToken authToken = AuthenticationManagerUtil.mockAuthenticationManager(authenticationManager, user);

        String newEmail = "newemail@naavi.test";
        String payload = "{\"email\":\"" + newEmail + "\"}";

        mockMvc.perform(put("/user")
                        .with(authentication(authToken))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(payload))
                .andDo(MockMvcResultHandlers.print())
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.id").isNumber())
                .andExpect(jsonPath("$.firstname").value(user.getFirstname()))
                .andExpect(jsonPath("$.lastname").value(user.getLastname()))
                .andExpect(jsonPath("$.fullName").value(user.getFullName()))
                .andExpect(jsonPath("$.email").value(user.getEmail()))
                .andExpect(jsonPath("$.roles").isArray())
                .andExpect(jsonPath("$.permissions").isArray())
                .andExpect(jsonPath("$.createdAt").exists())
                .andExpect(jsonPath("$.updatedAt").value(IsNull.nullValue()));

        User updatedUser = userRepository.findById(user.getId()).orElseThrow();
        assertEquals(user.getEmail(), updatedUser.getEmail());
        assertNotEquals(newEmail, updatedUser.getEmail());
    }

    @Test
    void shouldUploadProfilePicture_WithUnauthenticatedUser_ReturnsUnauthorized() throws Exception {
        MockMultipartFile image = new MockMultipartFile(
                "image", "photo.png", "image/png", "fake-image-content".getBytes()
        );

        mockMvc.perform(multipart("/user/profile-picture").file(image))
                .andDo(MockMvcResultHandlers.print())
                .andExpect(status().isUnauthorized());
    }

    @Test
    void shouldUploadProfilePicture_WithEmptyFile_ReturnsBadRequest() throws Exception {
        UsernamePasswordAuthenticationToken authToken = AuthenticationManagerUtil.mockAuthenticationManager(authenticationManager, UserSeeder.USER);

        MockMultipartFile image = new MockMultipartFile(
                "image", "photo.png", "image/png", new byte[0]
        );

        mockMvc.perform(multipart("/user/profile-picture")
                        .file(image)
                        .with(authentication(authToken)))
                .andDo(MockMvcResultHandlers.print())
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.i18nKey").value("user.profile.invalid_file"))
                .andExpect(jsonPath("$.message").value("The file is empty or invalid."));
    }

    @Test
    void shouldUploadProfilePicture_WithInvalidContentType_ReturnsBadRequest() throws Exception {
        UsernamePasswordAuthenticationToken authToken = AuthenticationManagerUtil.mockAuthenticationManager(authenticationManager, UserSeeder.USER);

        MockMultipartFile image = new MockMultipartFile(
                "image", "document.pdf", "application/pdf", "fake-pdf-content".getBytes()
        );

        mockMvc.perform(multipart("/user/profile-picture")
                        .file(image)
                        .with(authentication(authToken)))
                .andDo(MockMvcResultHandlers.print())
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.i18nKey").value("user.profile.invalid_file"))
                .andExpect(jsonPath("$.message").value("Only image files are allowed."));
    }

    @Test
    void shouldUploadProfilePicture_WithValidFile_ReturnsSuccess() throws Exception {
        UsernamePasswordAuthenticationToken authToken = AuthenticationManagerUtil.mockAuthenticationManager(authenticationManager, UserSeeder.USER);

        MockMultipartFile image = new MockMultipartFile(
                "image", "photo.png", "image/png", "fake-image-content".getBytes()
        );

        mockMvc.perform(multipart("/user/profile-picture")
                        .file(image)
                        .with(authentication(authToken)))
                .andDo(MockMvcResultHandlers.print())
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.i18nKey").value("user.profile.uploaded"))
                .andExpect(jsonPath("$.message").value("The image was successfully uploaded."));
    }

    @Test
    void shouldUploadProfilePicture_WhenS3Fails_ReturnsBadRequest() throws Exception {
        UsernamePasswordAuthenticationToken authToken = AuthenticationManagerUtil.mockAuthenticationManager(authenticationManager, UserSeeder.USER);

        Mockito.doThrow(new RuntimeException("S3 unavailable"))
                .when(s3Service).upload(Mockito.any(S3Enum.class), Mockito.any(), Mockito.anyString(), Mockito.any());

        MockMultipartFile image = new MockMultipartFile(
                "image", "photo.png", "image/png", "fake-image-content".getBytes()
        );

        mockMvc.perform(multipart("/user/profile-picture")
                        .file(image)
                        .with(authentication(authToken)))
                .andDo(MockMvcResultHandlers.print())
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.i18nKey").value("user.profile.failed_upload"))
                .andExpect(jsonPath("$.message").value("Failed to upload the image. Please try again later."));
    }

    @Test
    void shouldDeleteProfilePicture_WithUnauthenticatedUser_ReturnsUnauthorized() throws Exception {
        mockMvc.perform(delete("/user/profile-picture"))
                .andDo(MockMvcResultHandlers.print())
                .andExpect(status().isUnauthorized());
    }

    @Test
    void shouldDeleteProfilePicture_WithNoProfilePicture_ReturnsBadRequest() throws Exception {
        User user = UserSeeder.USER;
        UsernamePasswordAuthenticationToken authToken = AuthenticationManagerUtil.mockAuthenticationManager(authenticationManager, user);

        // S'assurer que l'utilisateur n'a pas de photo de profil
        user.setProfilePicture(null);
        userRepository.save(user);

        mockMvc.perform(delete("/user/profile-picture")
                        .with(authentication(authToken))
                        .contentType(MediaType.APPLICATION_JSON))
                .andDo(MockMvcResultHandlers.print())
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.i18nKey").value("user.profile.no_picture"))
                .andExpect(jsonPath("$.message").value("No profile picture to delete."));
    }

    @Test
    void shouldDeleteProfilePicture_WithExistingProfilePicture_ReturnsSuccess() throws Exception {
        User user = UserSeeder.USER;
        UsernamePasswordAuthenticationToken authToken = AuthenticationManagerUtil.mockAuthenticationManager(authenticationManager, user);

        // Définir une photo de profil existante
        user.setProfilePicture("existing-picture.png");
        userRepository.save(user);

        mockMvc.perform(delete("/user/profile-picture")
                        .with(authentication(authToken))
                        .contentType(MediaType.APPLICATION_JSON))
                .andDo(MockMvcResultHandlers.print())
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.i18nKey").value("user.profile.deleted"))
                .andExpect(jsonPath("$.message").value("The profile picture was successfully deleted."));

        User updatedUser = userRepository.findById(user.getId()).orElseThrow();
        assertNull(updatedUser.getProfilePicture());
    }

    @Test
    void shouldSearchUser_AsNonAdmin_ReturnsForbidden() throws Exception {
        User nonAdmin = UserSeeder.USER;
        UsernamePasswordAuthenticationToken authToken = AuthenticationManagerUtil.mockAuthenticationManager(authenticationManager, nonAdmin);

        mockMvc.perform(get("/administration/users")
                        .with(authentication(authToken))
                        .contentType(MediaType.APPLICATION_JSON)
                        .param("query", "@naavi.local"))
                .andDo(MockMvcResultHandlers.print())
                .andExpect(status().isForbidden());
    }

    @Test
    void shouldSearchUser_AsAdmin_ReturnsPaginator() throws Exception {
        User admin = UserSeeder.ADMIN;
        UsernamePasswordAuthenticationToken authToken = AuthenticationManagerUtil.mockAuthenticationManager(authenticationManager, admin);

        mockMvc.perform(get("/administration/users")
                        .with(authentication(authToken))
                        .contentType(MediaType.APPLICATION_JSON)
                        .param("query", "@naavi.local"))
                .andDo(MockMvcResultHandlers.print())
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.items").isArray())
                .andExpect(jsonPath("$.items[0].id").isNumber())
                .andExpect(jsonPath("$.items[0].email").isString())
                .andExpect(jsonPath("$.items[0].firstname").isString())
                .andExpect(jsonPath("$.items[0].lastname").isString())
                .andExpect(jsonPath("$.items[0].fullName").isString())
                .andExpect(jsonPath("$.items[0].roles").isArray())
                .andExpect(jsonPath("$.items[0].permissions").isArray())
                .andExpect(jsonPath("$.items[0].status").isString())
                .andExpect(jsonPath("$.items[0].createdAt").value(org.hamcrest.Matchers.matchesPattern("\\d{4}-\\d{2}-\\d{2}T.*")))
                .andExpect(jsonPath("$.items[0].updatedAt").value(IsNull.nullValue()))
                .andExpect(jsonPath("$.totalItems").value(2))
                .andExpect(jsonPath("$.totalPages").value(1))
                .andExpect(jsonPath("$.currentPage").value(1))
                .andExpect(jsonPath("$.nextPage").doesNotExist())
                .andExpect(jsonPath("$.previousPage").doesNotExist());
    }

    @Test
    void shouldCreateUser_AsNonAdmin_ReturnsForbidden() throws Exception {
        User user = UserSeeder.USER;
        UsernamePasswordAuthenticationToken authToken = AuthenticationManagerUtil.mockAuthenticationManager(authenticationManager, user);

        String payload = "{\"firstname\":\"New\",\"lastname\":\"User\",\"email\":\"new.user@naavi.test\"}";

        mockMvc.perform(post("/administration/users")
                        .with(authentication(authToken))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(payload))
                .andDo(MockMvcResultHandlers.print())
                .andExpect(status().isForbidden());
    }

    @Test
    void shouldCreateUser_AsAdmin_CreatesUser() throws Exception {
        User user = UserSeeder.ADMIN;
        UsernamePasswordAuthenticationToken authToken = AuthenticationManagerUtil.mockAuthenticationManager(authenticationManager, user);

        String uniqueEmail = "created+" + System.currentTimeMillis() + "@naavi.test";
        String payload = "{\"firstname\":\"Created\",\"lastname\":\"User\",\"email\":\"" + uniqueEmail + "\"}";

        mockMvc.perform(post("/administration/users")
                        .with(authentication(authToken))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(payload))
                .andDo(MockMvcResultHandlers.print())
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.firstname").value("Created"))
                .andExpect(jsonPath("$.lastname").value("User"))
                .andExpect(jsonPath("$.email").value(uniqueEmail))
                .andExpect(jsonPath("$.roles").isArray())
                .andExpect(jsonPath("$.permissions").isArray())
                .andExpect(jsonPath("$.createdAt").exists());
    }

    @Test
    void shouldGetUser_AsNonAdmin_ReturnsForbidden() throws Exception {
        User nonAdmin = UserSeeder.USER;
        UsernamePasswordAuthenticationToken authToken = AuthenticationManagerUtil.mockAuthenticationManager(authenticationManager, nonAdmin);

        mockMvc.perform(get("/administration/users/{id}", UserSeeder.ADMIN.getId())
                        .with(authentication(authToken))
                        .contentType(MediaType.APPLICATION_JSON))
                .andDo(MockMvcResultHandlers.print())
                .andExpect(status().isForbidden());
    }

    @Test
    void shouldGetUser_AsAdmin_ReturnsUser() throws Exception {
        User admin = UserSeeder.ADMIN;
        UsernamePasswordAuthenticationToken authToken = AuthenticationManagerUtil.mockAuthenticationManager(authenticationManager, admin);

        User target = UserSeeder.USER;

        mockMvc.perform(get("/administration/users/{id}", target.getId())
                        .with(authentication(authToken))
                        .contentType(MediaType.APPLICATION_JSON))
                .andDo(MockMvcResultHandlers.print())
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.id").value(target.getId()))
                .andExpect(jsonPath("$.firstname").value(target.getFirstname()))
                .andExpect(jsonPath("$.lastname").value(target.getLastname()))
                .andExpect(jsonPath("$.fullName").value(target.getFullName()))
                .andExpect(jsonPath("$.email").value(target.getEmail()))
                .andExpect(jsonPath("$.status").value(target.getStatus().name()))
                .andExpect(jsonPath("$.roles").isArray())
                .andExpect(jsonPath("$.permissions").isArray())
                .andExpect(jsonPath("$.createdAt").exists());
    }

    @Test
    void shouldUpdateUser_AsNonAdmin_ReturnsForbidden() throws Exception {
        User nonAdmin = UserSeeder.USER;
        UsernamePasswordAuthenticationToken authToken = AuthenticationManagerUtil.mockAuthenticationManager(authenticationManager, nonAdmin);

        String payload = "{\"firstname\":\"X\",\"lastname\":\"Y\"}";

        mockMvc.perform(put("/administration/users/{id}", UserSeeder.ADMIN.getId())
                        .with(authentication(authToken))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(payload))
                .andDo(MockMvcResultHandlers.print())
                .andExpect(status().isForbidden());
    }

    @Test
    void shouldUpdateUser_AsAdmin_UpdatesUser() throws Exception {
        User admin = UserSeeder.ADMIN;
        UsernamePasswordAuthenticationToken authToken = AuthenticationManagerUtil.mockAuthenticationManager(authenticationManager, admin);

        User target = UserSeeder.USER;

        String payload = "{"
                + "\"firstname\":\"UpdatedByAdmin\","
                + "\"lastname\":\"AdminUpdated\","
                + "\"roles\":[\"ROLE_ADMIN\"]"
                + "}";

        mockMvc.perform(put("/administration/users/{id}", target.getId())
                        .with(authentication(authToken))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(payload))
                .andDo(MockMvcResultHandlers.print())
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.id").value(target.getId()))
                .andExpect(jsonPath("$.firstname").value("UpdatedByAdmin"))
                .andExpect(jsonPath("$.lastname").value("AdminUpdated"))
                .andExpect(jsonPath("$.fullName").value("UpdatedByAdmin AdminUpdated"))
                .andExpect(jsonPath("$.email").value(target.getEmail()))
                .andExpect(jsonPath("$.roles").isArray())
                .andExpect(jsonPath("$.roles[0]").value("ROLE_USER"))
                .andExpect(jsonPath("$.roles[1]").value("ROLE_ADMIN"))
                .andExpect(jsonPath("$.permissions").isArray())
                .andExpect(jsonPath("$.createdAt").exists());
    }

    @Test
    void shouldUpdateUser_AsAdmin_InvalidRole_ReturnsBadRequest() throws Exception {
        User admin = UserSeeder.ADMIN;
        UsernamePasswordAuthenticationToken authToken = AuthenticationManagerUtil.mockAuthenticationManager(authenticationManager, admin);

        User target = UserSeeder.USER;

        String payload = "{\"roles\":[\"ROLE_UNKNOWN\"]}";

        mockMvc.perform(put("/administration/users/{id}", target.getId())
                        .with(authentication(authToken))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(payload))
                .andDo(MockMvcResultHandlers.print())
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.i18nKey").value("user.role_invalid"))
                .andExpect(jsonPath("$.message").value("The role 'ROLE_UNKNOWN' does not exist."))
                .andExpect(jsonPath("$.extra").doesNotExist());
    }

    @Test
    void shouldUpdateUser_AsAdmin_InvalidPermission_ReturnsBadRequest() throws Exception {
        User admin = UserSeeder.ADMIN;
        UsernamePasswordAuthenticationToken authToken = AuthenticationManagerUtil.mockAuthenticationManager(authenticationManager, admin);

        User target = UserSeeder.USER;

        String payload = "{\"permissions\":[\"UNKNOWN\"]}";

        mockMvc.perform(put("/administration/users/{id}", target.getId())
                        .with(authentication(authToken))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(payload))
                .andDo(MockMvcResultHandlers.print())
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.i18nKey").value("user.permission_invalid"))
                .andExpect(jsonPath("$.message").value("The permission 'UNKNOWN' does not exist."))
                .andExpect(jsonPath("$.extra").doesNotExist());
    }

    @Test
    void shouldUpdateUser_AsAdmin_InvalidStatus_ReturnsBadRequest() throws Exception {
        User admin = UserSeeder.ADMIN;
        UsernamePasswordAuthenticationToken authToken = AuthenticationManagerUtil.mockAuthenticationManager(authenticationManager, admin);

        User target = UserSeeder.USER;

        String payload = "{\"status\":\"VERIFIE\"}";

        mockMvc.perform(put("/administration/users/{id}", target.getId())
                        .with(authentication(authToken))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(payload))
                .andDo(MockMvcResultHandlers.print())
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.i18nKey").value("user.status_invalid"))
                .andExpect(jsonPath("$.message").value("The status 'VERIFIE' does not exist."))
                .andExpect(jsonPath("$.extra").doesNotExist());
    }

    @Test
    void shouldDeleteUser_AsNonAdmin_ReturnsForbidden() throws Exception {
        User nonAdmin = UserSeeder.USER;
        UsernamePasswordAuthenticationToken authToken = AuthenticationManagerUtil.mockAuthenticationManager(authenticationManager, nonAdmin);

        mockMvc.perform(delete("/administration/users/{id}", UserSeeder.ADMIN.getId())
                        .with(authentication(authToken))
                        .contentType(MediaType.APPLICATION_JSON))
                .andDo(MockMvcResultHandlers.print())
                .andExpect(status().isForbidden());
    }

    @Test
    void shouldDeleteUser_AsAdmin_DeletesUser() throws Exception {
        User admin = UserSeeder.ADMIN;
        UsernamePasswordAuthenticationToken authToken = AuthenticationManagerUtil.mockAuthenticationManager(authenticationManager, admin);

        User target = UserSeeder.USER;

        mockMvc.perform(delete("/administration/users/{id}", target.getId())
                        .with(authentication(authToken))
                        .contentType(MediaType.APPLICATION_JSON))
                .andDo(MockMvcResultHandlers.print())
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.i18nKey").value("user.deleted"))
                .andExpect(jsonPath("$.message").value("User successfully deleted"))
                .andExpect(jsonPath("$.extra").doesNotExist());

        User deleted = userRepository.findById(target.getId()).orElseThrow();
        assertEquals(fr.naavi.identity.enums.StatusEnum.DELETED, deleted.getStatus());
        assertEquals("User", deleted.getFirstname());
        assertEquals("Deleted", deleted.getLastname());
        assertEquals("deleted-user" + target.getId() + "@naavi-trails.fr", deleted.getEmail());
        assertNotEquals(target.getPassword(), deleted.getPassword());
    }
}
