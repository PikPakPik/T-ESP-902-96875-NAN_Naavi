package fr.naavi.identity.controller;

import fr.naavi.core.dto.PaginationDTO;
import fr.naavi.core.dto.PaginatorDTO;
import fr.naavi.core.enums.RoleEnum;
import fr.naavi.core.exception.GlobalExceptionHandler;
import fr.naavi.identity.dto.input.UserDTO;
import fr.naavi.identity.dto.output.UserDto;
import fr.naavi.identity.entity.User;
import fr.naavi.identity.enums.StatusEnum;
import fr.naavi.identity.repository.UserRepository;
import fr.naavi.identity.service.AuthenticationService;
import fr.naavi.identity.service.MailerService;
import fr.naavi.identity.service.UserService;
import fr.naavi.identity.util.DtoFactory;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.Mockito;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.context.annotation.Import;
import org.springframework.http.MediaType;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.test.context.support.WithMockUser;
import org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.context.TestPropertySource;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.request.RequestPostProcessor;
import org.springframework.test.web.servlet.result.MockMvcResultHandlers;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;
import org.springframework.web.context.WebApplicationContext;

import javax.sql.DataSource;
import java.lang.reflect.Field;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;
import java.util.Optional;

import static org.springframework.security.test.web.servlet.setup.SecurityMockMvcConfigurers.springSecurity;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.delete;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.content;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@ActiveProfiles("ci")
@WebMvcTest(UserController.class)
@Import(GlobalExceptionHandler.class)
@TestPropertySource(locations = "classpath:application-ci.properties")
class UserControllerTest {

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
    private AuthenticationService authenticationService;

    @MockitoBean
    private DataSource dataSource;

    @MockitoBean
    private UserRepository userRepository;

    @BeforeEach
    void setUp() {
        mockMvc = MockMvcBuilders
                .webAppContextSetup(webApplicationContext)
                .apply(springSecurity())
                .build();
    }

    @Test
    void user_ShouldReturn401_WhenUserIsNotAuthenticated() throws Exception {
        mockMvc.perform(get("/user"))
                .andExpect(status().isUnauthorized());
    }

    @Test
    @WithMockUser(username = "jean.dupont@example.com")
    void user_ShouldReturn200_WhenUserIsAuthenticated() throws Exception {
        User authenticatedUser = createMockUser();

        mockMvc.perform(get("/user").with(createAuthenticatedUser(authenticatedUser)))
                .andExpect(status().isOk())
                .andExpect(content().contentType(MediaType.APPLICATION_JSON))
                .andExpect(jsonPath("$.firstname").value("Jean"))
                .andExpect(jsonPath("$.lastname").value("Dupont"))
                .andExpect(jsonPath("$.email").value("jean.dupont@example.com"))
                .andExpect(jsonPath("$.roles").isArray())
                .andExpect(jsonPath("$.status").value("VERIFIED"))
                .andExpect(jsonPath("$.createdAt").exists())
                .andExpect(jsonPath("$.updatedAt").exists())
                .andExpect(jsonPath("$.id").doesNotExist())
                .andExpect(jsonPath("$.password").doesNotExist());
    }

    @Test
    @WithMockUser(username = "admin@example.com", roles = {"ADMIN"})
    void shouldReturnPaginatedUsersList_WhenAdminAccessesSearchUser() throws Exception {
        User user1 = createMockUser();
        user1.setEmail("user1@example.com");

        User user2 = createMockUser();
        user2.setEmail("user2@example.com");

        List<UserDto> userDtos = List.of(
                new UserDto(user1, true),
                new UserDto(user2, true)
        );

        PaginationDTO paginationDTO = new PaginationDTO();
        paginationDTO.setPage(1);

        PaginatorDTO<UserDto> paginatorDto = new PaginatorDTO<>(userDtos, 2, paginationDTO);
        paginatorDto.setItems(userDtos);

        Mockito.when(userRepository.findAllUserWithPagination(Mockito.any(PaginationDTO.class)))
                .thenReturn(paginatorDto);

        mockMvc.perform(get("/administration/users"))
                .andExpect(status().isOk())
                .andExpect(content().contentType(MediaType.APPLICATION_JSON))
                .andExpect(jsonPath("$.items").isArray())
                .andExpect(jsonPath("$.items[0].email").value("user1@example.com"))
                .andExpect(jsonPath("$.items[1].email").value("user2@example.com"))
                .andExpect(jsonPath("$.totalItems").value(2))
                .andExpect(jsonPath("$.totalPages").value(1))
                .andExpect(jsonPath("$.currentPage").value(1))
                .andExpect(jsonPath("$.nextPage").doesNotExist())
                .andExpect(jsonPath("$.previousPage").doesNotExist());
    }

    @Test
    @WithMockUser(username = "admin@example.com", roles = {"ADMIN"})
    void returnsPaginatedUsers_WhenAdminIsAuthenticated() throws Exception {
        User user1 = createMockUser();
        user1.setEmail("user1@example.com");

        User user2 = createMockUser();
        user2.setEmail("user2@example.com");

        List<UserDto> userDtos = List.of(
                new UserDto(user1, true),
                new UserDto(user2, true)
        );

        PaginationDTO paginationDTO = new PaginationDTO();
        paginationDTO.setPage(1);
        paginationDTO.setLimit(1);

        PaginatorDTO<UserDto> paginatorDto = new PaginatorDTO<>(userDtos, 2, paginationDTO);
        paginatorDto.setItems(userDtos);

        Mockito.when(userRepository.findAllUserWithPagination(Mockito.any(PaginationDTO.class)))
                .thenReturn(paginatorDto);

        mockMvc.perform(get("/administration/users").param("limit", "1"))
                .andExpect(status().isOk())
                .andExpect(content().contentType(MediaType.APPLICATION_JSON))
                .andExpect(jsonPath("$.items").isArray())
                .andExpect(jsonPath("$.items[0].email").value("user1@example.com"))
                .andExpect(jsonPath("$.totalItems").value(2))
                .andExpect(jsonPath("$.totalPages").value(2))
                .andExpect(jsonPath("$.currentPage").value(1))
                .andExpect(jsonPath("$.nextPage").value(2))
                .andExpect(jsonPath("$.previousPage").doesNotExist());
    }

    @Test
    @WithMockUser(username = "admin@example.com", roles = {"ADMIN"})
    void shouldReturnUserById_WhenUserExists() throws Exception {
        User user = createMockUser();
        user.setEmail("user1@example.com");

        Field idField = User.class.getDeclaredField("id");
        idField.setAccessible(true);
        idField.set(user, 42L);

        Mockito.when(userRepository.findById(42L))
                .thenReturn(Optional.of(user));

        mockMvc.perform(get("/administration/users/42"))
                .andExpect(status().isOk())
                .andExpect(content().contentType(MediaType.APPLICATION_JSON))
                .andExpect(jsonPath("$.email").value("user1@example.com"))
                .andExpect(jsonPath("$.firstname").value("Jean"))
                .andExpect(jsonPath("$.lastname").value("Dupont"));
    }

    @Test
    @WithMockUser(username = "admin@example.com", roles = {"ADMIN"})
    void shouldReturn404_WhenUserDoesNotExist() throws Exception {
        Mockito.when(userRepository.findById(99L))
                .thenReturn(Optional.empty());

        mockMvc.perform(get("/administration/users/99"))
                .andExpect(status().isNotFound())
                .andExpect(content().contentType(MediaType.APPLICATION_JSON))
                .andExpect(jsonPath("$.i18nKey").value("user.not_found"))
                .andExpect(jsonPath("$.message").value("User not found"));
    }

    @Test
    @WithMockUser(username = "admin@example.com", roles = {"ADMIN"})
    void shouldCreateUser_WhenAdminCreatesNewUser() throws Exception {
        User user = createMockUser();
        user.setEmail("newuser@example.com");

        Mockito.when(userRepository.findByEmail("newuser@example.com"))
                .thenReturn(Optional.empty());
        Mockito.when(userService.createUserFromAdmin(Mockito.any()))
                .thenReturn(user);

        UserDTO userDto = DtoFactory.createDto(UserDTO.class,
                Map.of(
                        "firstname", "John",
                        "lastname", "Doe",
                        "email", "newuser@example.com"
                )
        );

        mockMvc.perform(
                        post("/administration/users")
                                .contentType(MediaType.APPLICATION_JSON)
                                .content(DtoFactory.toJson(userDto))
                                .with(SecurityMockMvcRequestPostProcessors.csrf())
                )
                .andExpect(status().isOk())
                .andExpect(content().contentType(MediaType.APPLICATION_JSON))
                .andExpect(jsonPath("$.email").value("newuser@example.com"))
                .andExpect(jsonPath("$.firstname").value("Jean"))
                .andExpect(jsonPath("$.lastname").value("Dupont"));
    }

    @Test
    @WithMockUser(username = "admin@example.com", roles = {"ADMIN"})
    void shouldReturn409_WhenEmailAlreadyExists() throws Exception {
        User existingUser = createMockUser();
        existingUser.setEmail("existing@example.com");

        Mockito.when(userRepository.findByEmail("existing@example.com"))
                .thenReturn(Optional.of(existingUser));

        UserDTO userDto = DtoFactory.createDto(UserDTO.class,
                Map.of(
                        "firstname", "John",
                        "lastname", "Doe",
                        "email", "existing@example.com"
                )
        );

        mockMvc.perform(
                        post("/administration/users")
                                .contentType(MediaType.APPLICATION_JSON)
                                .content(DtoFactory.toJson(userDto))
                                .with(SecurityMockMvcRequestPostProcessors.csrf())
                )
                .andExpect(status().isConflict())
                .andExpect(content().contentType(MediaType.APPLICATION_JSON))
                .andExpect(jsonPath("$.i18nKey").value("user.already_exist"))
                .andExpect(jsonPath("$.message").value("User already exist with this email"));
    }

    @Test
    @WithMockUser(username = "admin@example.com", roles = {"ADMIN"})
    void shouldUpdateUser_WhenUserExists() throws Exception {
        User user = createMockUser();
        user.setEmail("updated@example.com");

        User authenticatedUser = createMockUser();
        authenticatedUser.setRoles(List.of(RoleEnum.ROLE_ADMIN));

        Field idField = User.class.getDeclaredField("id");
        idField.setAccessible(true);
        idField.set(user, 42L);

        Mockito.when(userService.updateUser(Mockito.eq(42L), Mockito.any()))
                .thenReturn(user);

        UserDTO userDto = DtoFactory.createDto(UserDTO.class,
                Map.of(
                        "firstname", "Jean",
                        "lastname", "Dupont"
                )
        );

        mockMvc.perform(
                        put("/administration/users/42")
                                .contentType(MediaType.APPLICATION_JSON)
                                .content(DtoFactory.toJson(userDto))
                                .with(SecurityMockMvcRequestPostProcessors.csrf())
                )
                .andDo(MockMvcResultHandlers.print())
                .andExpect(status().isOk())
                .andExpect(content().contentType(MediaType.APPLICATION_JSON))
                .andExpect(jsonPath("$.email").value("updated@example.com"))
                .andExpect(jsonPath("$.firstname").value("Jean"))
                .andExpect(jsonPath("$.lastname").value("Dupont"));
    }

    @Test
    @WithMockUser(username = "admin@example.com", roles = {"ADMIN"})
    void shouldDeleteUser_WhenUserExists() throws Exception {
        User authenticatedUser = createMockUser();
        authenticatedUser.setRoles(List.of(RoleEnum.ROLE_ADMIN));

        Mockito.doNothing().when(userService).deleteUser(42L);

        mockMvc.perform(
                        delete("/administration/users/42")
                                .with(SecurityMockMvcRequestPostProcessors.csrf())
                )
                .andExpect(status().isOk())
                .andExpect(content().contentType(MediaType.APPLICATION_JSON))
                .andExpect(jsonPath("$.i18nKey").value("user.deleted"))
                .andExpect(jsonPath("$.message").value("User successfully deleted"));
    }

    private RequestPostProcessor createAuthenticatedUser(User user) {
        List<SimpleGrantedAuthority> authorities = user.getRoles().stream()
                .map(Enum::name)
                .map(SimpleGrantedAuthority::new)
                .toList();
        return SecurityMockMvcRequestPostProcessors.authentication(
                new UsernamePasswordAuthenticationToken(user, null, authorities)
        );
    }

    private User createMockUser() {
        User user = new User();
        user.setFirstname("Jean");
        user.setLastname("Dupont");
        user.setEmail("jean.dupont@example.com");
        user.setPassword("hashed-password-123");
        user.setRoles(List.of(RoleEnum.ROLE_USER));
        user.setStatus(StatusEnum.VERIFIED);
        user.setCreatedAt(LocalDateTime.of(2024, 6, 1, 12, 0, 0));
        user.setUpdatedAt(LocalDateTime.of(2024, 6, 10, 15, 30, 0));
        return user;
    }
}