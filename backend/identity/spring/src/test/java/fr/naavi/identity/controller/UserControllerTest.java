package fr.naavi.identity.controller;

import fr.naavi.core.exception.GlobalExceptionHandler;
import fr.naavi.identity.configuration.CacheConfigurationTest;
import fr.naavi.identity.entity.User;
import fr.naavi.identity.repository.UserRepository;
import fr.naavi.identity.seeder.UserSeeder;
import fr.naavi.identity.util.AuthenticationManagerUtil;
import org.hamcrest.core.IsNull;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.webmvc.test.autoconfigure.AutoConfigureMockMvc;
import org.springframework.context.annotation.Import;
import org.springframework.http.MediaType;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.context.TestPropertySource;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.result.MockMvcResultHandlers;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotEquals;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.authentication;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.delete;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
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
                .andExpect(jsonPath("$.id").doesNotExist())
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
                .andExpect(jsonPath("$.id").doesNotExist())
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
                .andExpect(jsonPath("$.id").doesNotExist())
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
