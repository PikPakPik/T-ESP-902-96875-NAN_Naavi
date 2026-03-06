package fr.naavi.hike.controller;

import fr.naavi.core.exception.GlobalExceptionHandler;
import fr.naavi.hike.configuration.CacheConfigurationTest;
import fr.naavi.hike.dto.input.HikeDTO;
import fr.naavi.hike.dto.input.HikeHistoryDTO;
import fr.naavi.hike.entity.Hike;
import fr.naavi.hike.enums.SourceEnum;
import fr.naavi.hike.repository.HikeHistoryRepository;
import fr.naavi.hike.repository.HikeRepository;
import fr.naavi.hike.seeder.HikeHistorySeeder;
import fr.naavi.hike.seeder.HikeSeeder;
import fr.naavi.hike.seeder.UserSeeder;
import fr.naavi.hike.utils.AuthenticationManagerUtil;
import fr.naavi.hike.utils.DtoFactory;
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

import java.util.List;
import java.util.Map;
import java.util.concurrent.ThreadLocalRandom;

import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.authentication;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.delete;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("ci")
@TestPropertySource(locations = "classpath:application-ci.properties")
@Import({GlobalExceptionHandler.class, CacheConfigurationTest.class})
public class HikeControllerTest {
    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private UserSeeder userSeeder;

    @Autowired
    private HikeSeeder hikeSeeder;

    @Autowired
    private HikeHistorySeeder hikeHistorySeeder;

    @Autowired
    private HikeRepository hikeRepository;

    @Autowired
    private HikeHistoryRepository hikeHistoryRepository;

    @MockitoBean
    private AuthenticationManager authenticationManager;

    @BeforeEach
    void setUp() {
        hikeHistoryRepository.deleteAll();
        hikeSeeder.seedHikes();
        userSeeder.seedUsers();
    }

    /*
     * HIKES ENDPOINT TESTS
     */

    @Test
    void shouldReturnPaginatedHikes_WithCorrectCoordinates() throws Exception {
        String[] coords = HikeSeeder.COORDINATES.get(0).split(",");

        mockMvc.perform(get("/hikes")
                        .contentType(MediaType.APPLICATION_JSON)
                        .param("latitude", coords[1])
                        .param("longitude", coords[2]))
                .andDo(MockMvcResultHandlers.print())
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.items").isArray())
                .andExpect(jsonPath("$.totalItems").value(15))
                .andExpect(jsonPath("$.totalPages").value(1))
                .andExpect(jsonPath("$.currentPage").value(1))
                .andExpect(jsonPath("$.nextPage").doesNotExist())
                .andExpect(jsonPath("$.previousPage").doesNotExist());
    }

    @Test
    void shouldReturnValidationError_WhenCoordinatesAreInvalid() throws Exception {
        mockMvc.perform(get("/hikes")
                        .contentType(MediaType.APPLICATION_JSON)
                        .param("latitude", "")
                        .param("longitude", ""))
                .andDo(MockMvcResultHandlers.print())
                .andExpect(status().isUnprocessableContent())
                .andExpect(jsonPath("$.i18nKey").value("validation.failed"))
                .andExpect(jsonPath("$.message").value("Validation failed"))
                .andExpect(jsonPath("$.extra").isMap())
                .andExpect(jsonPath("$.extra.latitude").value("must not be null"))
                .andExpect(jsonPath("$.extra.longitude").value("must not be null"));
    }

    @Test
    void shouldReturnHikeDetails_WhenHikeExists() throws Exception {
        Hike hike = hikeRepository.findAll().getFirst();

        mockMvc.perform(get("/hikes/{id}", hike.getId())
                        .contentType(MediaType.APPLICATION_JSON))
                .andDo(MockMvcResultHandlers.print())
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.id").value(hike.getId()))
                .andExpect(jsonPath("$.name").value(hike.getName()))
                .andExpect(jsonPath("$.duration").exists());
    }

    @Test
    void shouldReturnNotFound_WhenHikeDoesNotExist() throws Exception {
        Long nonExistentId = 999999999L;

        mockMvc.perform(get("/hikes/{id}", nonExistentId)
                        .contentType(MediaType.APPLICATION_JSON))
                .andDo(MockMvcResultHandlers.print())
                .andExpect(status().isNotFound())
                .andExpect(jsonPath("$.i18nKey").value("hike.not_found"))
                .andExpect(jsonPath("$.message").value("Hike not found"))
                .andExpect(jsonPath("$.extra").doesNotExist());
    }

    @Test
    void shouldCreateHike_WithLoggedUser_WhenValidRequest() throws Exception {
        int size = HikeSeeder.SARTHE_COORDINATES.size();
        int randomIndex = ThreadLocalRandom.current().nextInt(size);
        String[] coords = HikeSeeder.SARTHE_COORDINATES.get(randomIndex).split(",");

        double testDuration = 7200.0; // 2 hours in seconds
        HikeDTO hikeDTO = DtoFactory.createDto(HikeDTO.class, Map.of(
                "name", coords[0],
                "startingPointLatitude", Double.parseDouble(coords[1]),
                "startingPointLongitude", Double.parseDouble(coords[2]),
                "startingElevation", 0,
                "arrivalPointLatitude", Double.parseDouble(coords[1]),
                "arrivalPointLongitude", Double.parseDouble(coords[2]),
                "arrivalElevation", 0,
                "wkbGeometry", "none",
                "wkbWaypoints", "none",
                "duration", testDuration
        ));

        UsernamePasswordAuthenticationToken auth = AuthenticationManagerUtil.mockAuthenticationManager(authenticationManager, UserSeeder.USER);

        mockMvc.perform(post("/hikes")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(DtoFactory.toJson(hikeDTO))
                        .with(authentication(auth)))
                .andDo(MockMvcResultHandlers.print())
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.id").exists())
                .andExpect(jsonPath("$.name").value(coords[0]))
                .andExpect(jsonPath("$.source").value(SourceEnum.COMMUNITY.name()))
                .andExpect(jsonPath("$.duration").value(testDuration));
    }

    @Test
    void shouldCreateHike_WithNullDuration_WhenDurationNotProvided() throws Exception {
        int size = HikeSeeder.SARTHE_COORDINATES.size();
        int randomIndex = ThreadLocalRandom.current().nextInt(size);
        String[] coords = HikeSeeder.SARTHE_COORDINATES.get(randomIndex).split(",");

        HikeDTO hikeDTO = DtoFactory.createDto(HikeDTO.class, Map.of(
                "name", coords[0],
                "startingPointLatitude", Double.parseDouble(coords[1]),
                "startingPointLongitude", Double.parseDouble(coords[2]),
                "startingElevation", 0,
                "arrivalPointLatitude", Double.parseDouble(coords[1]),
                "arrivalPointLongitude", Double.parseDouble(coords[2]),
                "arrivalElevation", 0,
                "wkbGeometry", "none",
                "wkbWaypoints", "none"
        ));

        UsernamePasswordAuthenticationToken auth = AuthenticationManagerUtil.mockAuthenticationManager(authenticationManager, UserSeeder.USER);

        mockMvc.perform(post("/hikes")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(DtoFactory.toJson(hikeDTO))
                        .with(authentication(auth)))
                .andDo(MockMvcResultHandlers.print())
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.id").exists())
                .andExpect(jsonPath("$.name").value(coords[0]))
                .andExpect(jsonPath("$.source").value(SourceEnum.COMMUNITY.name()))
                .andExpect(jsonPath("$.duration").isEmpty());
    }

    @Test
    void shouldCreateHike_WithUnloggedUser_WhenValidRequest() throws Exception {
        int size = HikeSeeder.SARTHE_COORDINATES.size();
        int randomIndex = ThreadLocalRandom.current().nextInt(size);
        String[] coords = HikeSeeder.SARTHE_COORDINATES.get(randomIndex).split(",");

        HikeDTO hikeDTO = DtoFactory.createDto(HikeDTO.class, Map.of(
                "name", coords[0],
                "startingPointLatitude", Double.parseDouble(coords[1]),
                "startingPointLongitude", Double.parseDouble(coords[2]),
                "startingElevation", 0,
                "arrivalPointLatitude", Double.parseDouble(coords[1]),
                "arrivalPointLongitude", Double.parseDouble(coords[2]),
                "arrivalElevation", 0,
                "wkbGeometry", "none",
                "wkbWaypoints", "none"
        ));

        mockMvc.perform(post("/hikes")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(DtoFactory.toJson(hikeDTO)))
                .andDo(MockMvcResultHandlers.print())
                .andExpect(status().isUnauthorized())
                .andExpect(jsonPath("$.message").value("Unauthorized access. You must be authenticated to access this resource."));
    }

    @Test
    void shouldReturnValidationError_WhenInvalidData() throws Exception {
        int size = HikeSeeder.SARTHE_COORDINATES.size();
        int randomIndex = ThreadLocalRandom.current().nextInt(size);
        String[] coords = HikeSeeder.SARTHE_COORDINATES.get(randomIndex).split(",");

        HikeDTO hikeDTO = DtoFactory.createDto(HikeDTO.class, Map.of(
                "name", coords[0],
                "startingPointLatitude", Double.parseDouble(coords[1]),
                "startingPointLongitude", Double.parseDouble(coords[2]),
                "startingElevation", 0,
                "arrivalPointLatitude", Double.parseDouble(coords[1]),
                "arrivalPointLongitude", Double.parseDouble(coords[2]),
                "arrivalElevation", 0,
                "wkbGeometry", "",
                "wkbWaypoints", ""
        ));

        UsernamePasswordAuthenticationToken auth = AuthenticationManagerUtil.mockAuthenticationManager(authenticationManager, UserSeeder.USER);

        mockMvc.perform(post("/hikes")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(DtoFactory.toJson(hikeDTO))
                        .with(authentication(auth)))
                .andDo(MockMvcResultHandlers.print())
                .andExpect(status().isUnprocessableContent())
                .andExpect(jsonPath("$.i18nKey").value("validation.failed"))
                .andExpect(jsonPath("$.message").value("Validation failed"))
                .andExpect(jsonPath("$.extra").isMap())
                .andExpect(jsonPath("$.extra.wkbGeometry").value("must not be empty"))
                .andExpect(jsonPath("$.extra.wkbWaypoints").value("must not be empty"));
    }

    @Test
    void shouldReturnHistory_WithLoggedUser_WhenAuthenticated() throws Exception {
        UsernamePasswordAuthenticationToken auth = AuthenticationManagerUtil.mockAuthenticationManager(authenticationManager, UserSeeder.USER);

        List<Hike> hikes = hikeRepository.findAll();
        hikeHistorySeeder.seedHistory(UserSeeder.USER, hikes);

        mockMvc.perform(get("/hikes/history")
                        .contentType(MediaType.APPLICATION_JSON)
                        .with(authentication(auth)))
                .andDo(MockMvcResultHandlers.print())
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.items").isArray())
                .andExpect(jsonPath("$.totalItems").value(hikes.size()))
                .andExpect(jsonPath("$.totalPages").value(2))
                .andExpect(jsonPath("$.currentPage").value(1))
                .andExpect(jsonPath("$.nextPage").value(2))
                .andExpect(jsonPath("$.previousPage").doesNotExist());
    }

    @Test
    void shouldReturnUnauthorized_WhenGetHistoryWithoutAuthentication() throws Exception {
        mockMvc.perform(get("/hikes/history")
                        .contentType(MediaType.APPLICATION_JSON))
                .andDo(MockMvcResultHandlers.print())
                .andExpect(status().isUnauthorized())
                .andExpect(jsonPath("$.message").value("Unauthorized access. You must be authenticated to access this resource."));
    }

    @Test
    void shouldSaveHistory_WithLoggedUser_WhenHikeExists() throws Exception {
        Hike hike = hikeRepository.findAll().getFirst();
        int randomDurationMinutes = ThreadLocalRandom.current().nextInt(1, 3600);

        HikeHistoryDTO dto = DtoFactory.createDto(HikeHistoryDTO.class, Map.of(
                "hikeId", hike.getId(),
                "duration", randomDurationMinutes
        ));

        UsernamePasswordAuthenticationToken auth = AuthenticationManagerUtil.mockAuthenticationManager(authenticationManager, UserSeeder.USER);

        mockMvc.perform(post("/hikes/history")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(DtoFactory.toJson(dto))
                        .with(authentication(auth)))
                .andDo(MockMvcResultHandlers.print())
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.i18nKey").value("hike.history.success"))
                .andExpect(jsonPath("$.message").value("The hike has been successfully saved."))
                .andExpect(jsonPath("$.extra").doesNotExist());
    }

    @Test
    void shouldReturnNotFound_WhenSaveHistoryForNonExistentHike() throws Exception {
        Long nonExistentId = 999999999L;
        int randomDurationMinutes = ThreadLocalRandom.current().nextInt(1, 3600);

        HikeHistoryDTO dto = DtoFactory.createDto(HikeHistoryDTO.class, Map.of(
                "hikeId", nonExistentId,
                "duration", randomDurationMinutes
        ));

        UsernamePasswordAuthenticationToken auth = AuthenticationManagerUtil.mockAuthenticationManager(authenticationManager, UserSeeder.USER);

        mockMvc.perform(post("/hikes/history")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(DtoFactory.toJson(dto))
                        .with(authentication(auth)))
                .andDo(MockMvcResultHandlers.print())
                .andExpect(status().isNotFound())
                .andExpect(jsonPath("$.i18nKey").value("hike.not_found"))
                .andExpect(jsonPath("$.message").value("Hike not found"))
                .andExpect(jsonPath("$.extra").doesNotExist());
    }

    @Test
    void shouldReturnUnauthorized_WhenSaveHistoryWithoutAuthentication() throws Exception {
        Hike hike = hikeRepository.findAll().getFirst();

        HikeHistoryDTO dto = DtoFactory.createDto(HikeHistoryDTO.class, Map.of(
                "hikeId", hike.getId()
        ));

        mockMvc.perform(post("/hikes/history")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(DtoFactory.toJson(dto)))
                .andDo(MockMvcResultHandlers.print())
                .andExpect(status().isUnauthorized())
                .andExpect(jsonPath("$.message").value("Unauthorized access. You must be authenticated to access this resource."));
    }

    @Test
    void shouldReturnValidationError_WhenSaveHistoryInvalidData() throws Exception {
        HikeHistoryDTO dto = DtoFactory.createDto(HikeHistoryDTO.class, Map.of(
                "duration", 10
        ));

        UsernamePasswordAuthenticationToken auth = AuthenticationManagerUtil.mockAuthenticationManager(authenticationManager, UserSeeder.USER);

        mockMvc.perform(post("/hikes/history")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(DtoFactory.toJson(dto))
                        .with(authentication(auth)))
                .andDo(MockMvcResultHandlers.print())
                .andExpect(status().isUnprocessableContent())
                .andExpect(jsonPath("$.i18nKey").value("validation.failed"))
                .andExpect(jsonPath("$.message").value("Validation failed"))
                .andExpect(jsonPath("$.extra").isMap())
                .andExpect(jsonPath("$.extra.hikeId").value("must not be null"));
    }

    @Test
    void shouldDeleteHistory_WithLoggedUser_WhenHistoryExists() throws Exception {
        Hike hike = hikeRepository.findAll().getFirst();

        hikeHistorySeeder.seedHistory(UserSeeder.USER, List.of(hike));

        var history = hikeHistoryRepository.findAll().stream()
                .filter(h -> h.getUser().equals(UserSeeder.USER.getId()))
                .findFirst()
                .orElseThrow();

        UsernamePasswordAuthenticationToken auth = AuthenticationManagerUtil.mockAuthenticationManager(authenticationManager, UserSeeder.USER);

        mockMvc.perform(delete("/hikes/history/{id}", history.getId())
                        .with(authentication(auth)))
                .andDo(MockMvcResultHandlers.print())
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.i18nKey").value("hike.history.success"))
                .andExpect(jsonPath("$.message").value("The hike has been successfully deleted."));
    }

    @Test
    void shouldReturnNotFound_WhenDeleteNonExistentHistory() throws Exception {
        Long nonExistentId = 999999999L;

        UsernamePasswordAuthenticationToken auth = AuthenticationManagerUtil.mockAuthenticationManager(authenticationManager, UserSeeder.USER);

        mockMvc.perform(delete("/hikes/history/{id}", nonExistentId)
                        .with(authentication(auth)))
                .andDo(MockMvcResultHandlers.print())
                .andExpect(status().isNotFound())
                .andExpect(jsonPath("$.i18nKey").value("hike.history.not_found"))
                .andExpect(jsonPath("$.message").value("Hike history not found"))
                .andExpect(jsonPath("$.extra").doesNotExist());
    }

    @Test
    void shouldReturnUnauthorized_WhenDeleteHistoryWithoutAuthentication() throws Exception {
        Hike hike = hikeRepository.findAll().getFirst();
        hikeHistorySeeder.seedHistory(UserSeeder.USER, List.of(hike));

        var history = hikeHistoryRepository.findAll().stream()
                .filter(h -> h.getUser().equals(UserSeeder.USER.getId()))
                .findFirst()
                .orElseThrow();

        mockMvc.perform(delete("/hikes/history/{id}", history.getId()))
                .andDo(MockMvcResultHandlers.print())
                .andExpect(status().isUnauthorized())
                .andExpect(jsonPath("$.message").value("Unauthorized access. You must be authenticated to access this resource."));
    }

    @Test
    void shouldReturnForbidden_WhenUserDeletesAdminHistory() throws Exception {
        Hike hike = hikeRepository.findAll().getFirst();

        hikeHistorySeeder.seedHistory(UserSeeder.ADMIN, List.of(hike));

        var adminHistory = hikeHistoryRepository.findAll().stream()
                .filter(h -> h.getUser().equals(UserSeeder.ADMIN.getId()))
                .findFirst()
                .orElseThrow();

        UsernamePasswordAuthenticationToken auth = AuthenticationManagerUtil.mockAuthenticationManager(authenticationManager, UserSeeder.USER);

        mockMvc.perform(delete("/hikes/history/{id}", adminHistory.getId())
                        .with(authentication(auth)))
                .andDo(MockMvcResultHandlers.print())
                .andExpect(status().isForbidden())
                .andExpect(jsonPath("$.i18nKey").value("hike.history.forbidden"))
                .andExpect(jsonPath("$.message").value("You are not allowed to delete this hike history."))
                .andExpect(jsonPath("$.extra").doesNotExist());
    }

    @Test
    void shouldDeleteHistory_WhenAdminDeletesOtherUserHistory() throws Exception {
        Hike hike = hikeRepository.findAll().getFirst();

        hikeHistorySeeder.seedHistory(UserSeeder.USER, List.of(hike));

        var userHistory = hikeHistoryRepository.findAll().stream()
                .filter(h -> h.getUser().equals(UserSeeder.USER.getId()))
                .findFirst()
                .orElseThrow();

        UsernamePasswordAuthenticationToken auth = AuthenticationManagerUtil.mockAuthenticationManager(authenticationManager, UserSeeder.ADMIN);

        mockMvc.perform(delete("/hikes/history/{id}", userHistory.getId())
                        .with(authentication(auth)))
                .andDo(MockMvcResultHandlers.print())
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.i18nKey").value("hike.history.success"))
                .andExpect(jsonPath("$.message").value("The hike has been successfully deleted."));
    }

    /*
     * ADMINISTRATION ENDPOINT TESTS
     */

    @Test
    void shouldUpdateHike_WithAdmin_WhenValidRequest() throws Exception {
        Hike hike = hikeRepository.findAll().getFirst();
        String newName = hike.getName() + " - updated";
        double newDuration = 5400.0; // 1.5 hours in seconds

        HikeDTO hikeDTO = DtoFactory.createDto(HikeDTO.class, Map.of(
                "name", newName,
                "startingPointLatitude", hike.getStartingPointLatitude(),
                "startingPointLongitude", hike.getStartingPointLongitude(),
                "startingElevation", hike.getStartingElevation(),
                "arrivalPointLatitude", hike.getArrivalPointLatitude(),
                "arrivalPointLongitude", hike.getArrivalPointLongitude(),
                "arrivalElevation", hike.getArrivalElevation(),
                "wkbGeometry", "geom",
                "wkbWaypoints", "wp",
                "duration", newDuration
        ));

        UsernamePasswordAuthenticationToken auth = AuthenticationManagerUtil.mockAuthenticationManager(authenticationManager, UserSeeder.ADMIN);

        mockMvc.perform(put("/administration/hikes/{id}", hike.getId())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(DtoFactory.toJson(hikeDTO))
                        .with(authentication(auth)))
                .andDo(MockMvcResultHandlers.print())
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.id").value(hike.getId()))
                .andExpect(jsonPath("$.name").value(newName))
                .andExpect(jsonPath("$.duration").value(newDuration));
    }

    @Test
    void shouldReturnNotFound_WhenUpdateNonExistentHike() throws Exception {
        Long nonExistentId = 999999999L;

        HikeDTO hikeDTO = DtoFactory.createDto(HikeDTO.class, Map.of(
                "name", "Non existent",
                "startingPointLatitude", 0.0,
                "startingPointLongitude", 0.0,
                "startingElevation", 0,
                "arrivalPointLatitude", 0.0,
                "arrivalPointLongitude", 0.0,
                "arrivalElevation", 0,
                "wkbGeometry", "geom",
                "wkbWaypoints", "wp"
        ));

        UsernamePasswordAuthenticationToken auth = AuthenticationManagerUtil.mockAuthenticationManager(authenticationManager, UserSeeder.ADMIN);

        mockMvc.perform(put("/administration/hikes/{id}", nonExistentId)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(DtoFactory.toJson(hikeDTO))
                        .with(authentication(auth)))
                .andDo(MockMvcResultHandlers.print())
                .andExpect(status().isNotFound())
                .andExpect(jsonPath("$.i18nKey").value("hike.not_found"))
                .andExpect(jsonPath("$.message").value("Hike not found"))
                .andExpect(jsonPath("$.extra").doesNotExist());
    }

    @Test
    void shouldReturnForbidden_WhenUserUpdatesHikeWithoutAdminRole() throws Exception {
        Hike hike = hikeRepository.findAll().getFirst();

        HikeDTO hikeDTO = DtoFactory.createDto(HikeDTO.class, Map.of(
                "name", "Attempted update",
                "startingPointLatitude", hike.getStartingPointLatitude(),
                "startingPointLongitude", hike.getStartingPointLongitude(),
                "startingElevation", hike.getStartingElevation(),
                "arrivalPointLatitude", hike.getArrivalPointLatitude(),
                "arrivalPointLongitude", hike.getArrivalPointLongitude(),
                "arrivalElevation", hike.getArrivalElevation(),
                "wkbGeometry", "geom",
                "wkbWaypoints", "wp"
        ));

        UsernamePasswordAuthenticationToken auth = AuthenticationManagerUtil.mockAuthenticationManager(authenticationManager, UserSeeder.USER);

        mockMvc.perform(put("/administration/hikes/{id}", hike.getId())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(DtoFactory.toJson(hikeDTO))
                        .with(authentication(auth)))
                .andDo(MockMvcResultHandlers.print())
                .andExpect(status().isForbidden())
                .andExpect(jsonPath("$.message").value("Access denied. You do not have the necessary permissions to access this resource"));
    }

    @Test
    void shouldReturnUnauthorized_WhenUpdateHikeWithoutAuthentication() throws Exception {
        Hike hike = hikeRepository.findAll().getFirst();

        HikeDTO hikeDTO = DtoFactory.createDto(HikeDTO.class, Map.of(
                "name", "No auth update",
                "startingPointLatitude", hike.getStartingPointLatitude(),
                "startingPointLongitude", hike.getStartingPointLongitude(),
                "startingElevation", hike.getStartingElevation(),
                "arrivalPointLatitude", hike.getArrivalPointLatitude(),
                "arrivalPointLongitude", hike.getArrivalPointLongitude(),
                "arrivalElevation", hike.getArrivalElevation(),
                "wkbGeometry", "geom",
                "wkbWaypoints", "wp"
        ));

        mockMvc.perform(put("/administration/hikes/{id}", hike.getId())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(DtoFactory.toJson(hikeDTO)))
                .andDo(MockMvcResultHandlers.print())
                .andExpect(status().isUnauthorized())
                .andExpect(jsonPath("$.message").value("Unauthorized access. You must be authenticated to access this resource."));
    }

    @Test
    void shouldReturnValidationError_WhenUpdateHikeInvalidData() throws Exception {
        Hike hike = hikeRepository.findAll().getFirst();

        HikeDTO hikeDTO = DtoFactory.createDto(HikeDTO.class, Map.of(
                "name", ""
        ));

        UsernamePasswordAuthenticationToken auth = AuthenticationManagerUtil.mockAuthenticationManager(authenticationManager, UserSeeder.ADMIN);

        mockMvc.perform(org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put("/administration/hikes/{id}", hike.getId())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(DtoFactory.toJson(hikeDTO))
                        .with(authentication(auth)))
                .andDo(MockMvcResultHandlers.print())
                .andExpect(status().isUnprocessableContent())
                .andExpect(jsonPath("$.i18nKey").value("validation.failed"))
                .andExpect(jsonPath("$.message").value("Validation failed"))
                .andExpect(jsonPath("$.extra").isMap())
                .andExpect(jsonPath("$.extra.name").value("must not be empty"));
    }

    @Test
    void shouldDeleteHike_WithAdmin_WhenHikeExists() throws Exception {
        Hike hike = hikeRepository.findAll().getFirst();

        UsernamePasswordAuthenticationToken auth = AuthenticationManagerUtil.mockAuthenticationManager(authenticationManager, UserSeeder.ADMIN);

        mockMvc.perform(delete("/administration/hikes/{id}", hike.getId())
                        .contentType(MediaType.APPLICATION_JSON)
                        .with(authentication(auth)))
                .andDo(MockMvcResultHandlers.print())
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.i18nKey").value("hike.deleted"))
                .andExpect(jsonPath("$.message").value("Hike successfully deleted"));
    }

    @Test
    void shouldReturnNotFound_WhenDeleteNonExistentHike() throws Exception {
        Long nonExistentId = 999999999L;

        UsernamePasswordAuthenticationToken auth = AuthenticationManagerUtil.mockAuthenticationManager(authenticationManager, UserSeeder.ADMIN);

        mockMvc.perform(delete("/administration/hikes/{id}", nonExistentId)
                        .contentType(MediaType.APPLICATION_JSON)
                        .with(authentication(auth)))
                .andDo(MockMvcResultHandlers.print())
                .andExpect(status().isNotFound())
                .andExpect(jsonPath("$.i18nKey").value("hike.not_found"))
                .andExpect(jsonPath("$.message").value("Hike not found"))
                .andExpect(jsonPath("$.extra").doesNotExist());
    }

    @Test
    void shouldReturnForbidden_WhenUserDeletesHikeWithoutAdminRole() throws Exception {
        Hike hike = hikeRepository.findAll().getFirst();

        UsernamePasswordAuthenticationToken auth = AuthenticationManagerUtil.mockAuthenticationManager(authenticationManager, UserSeeder.USER);

        mockMvc.perform(delete("/administration/hikes/{id}", hike.getId())
                        .contentType(MediaType.APPLICATION_JSON)
                        .with(authentication(auth)))
                .andDo(MockMvcResultHandlers.print())
                .andExpect(status().isForbidden())
                .andExpect(jsonPath("$.message").value("Access denied. You do not have the necessary permissions to access this resource"));
    }


    @Test
    void shouldReturnUnauthorized_WhenDeleteHikeWithoutAuthentication() throws Exception {
        Hike hike = hikeRepository.findAll().getFirst();

        mockMvc.perform(delete("/administration/hikes/{id}", hike.getId())
                        .contentType(MediaType.APPLICATION_JSON))
                .andDo(MockMvcResultHandlers.print())
                .andExpect(status().isUnauthorized())
                .andExpect(jsonPath("$.message").value("Unauthorized access. You must be authenticated to access this resource."));
    }

    @Test
    void shouldReturnUserHistory_WhenAdminRequestsUserHistory() throws Exception {
        List<Hike> hikes = hikeRepository.findAll();
        hikeHistorySeeder.seedHistory(UserSeeder.USER, hikes);

        UsernamePasswordAuthenticationToken auth = AuthenticationManagerUtil.mockAuthenticationManager(authenticationManager, UserSeeder.ADMIN);

        mockMvc.perform(get("/administration/hikes/history/user/{id}", UserSeeder.USER.getId())
                        .with(authentication(auth)))
                .andDo(MockMvcResultHandlers.print())
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.items").isArray())
                .andExpect(jsonPath("$.totalItems").value(hikes.size()))
                .andExpect(jsonPath("$.totalPages").value(2))
                .andExpect(jsonPath("$.currentPage").value(1))
                .andExpect(jsonPath("$.nextPage").value(2))
                .andExpect(jsonPath("$.previousPage").doesNotExist());
    }

    @Test
    void shouldReturnForbidden_WhenNonAdminRequestsUserHistory() throws Exception {
        List<Hike> hikes = hikeRepository.findAll();
        hikeHistorySeeder.seedHistory(UserSeeder.USER, hikes);

        UsernamePasswordAuthenticationToken auth = AuthenticationManagerUtil.mockAuthenticationManager(authenticationManager, UserSeeder.USER);

        mockMvc.perform(get("/administration/hikes/history/user/{id}", UserSeeder.USER.getId())
                        .with(authentication(auth)))
                .andDo(MockMvcResultHandlers.print())
                .andExpect(status().isForbidden())
                .andExpect(jsonPath("$.message").value("Access denied. You do not have the necessary permissions to access this resource"));
    }

    @Test
    void shouldReturnUnauthorized_WhenGetUserHistoryWithoutAuthentication() throws Exception {
        List<Hike> hikes = hikeRepository.findAll();
        hikeHistorySeeder.seedHistory(UserSeeder.USER, hikes);

        mockMvc.perform(get("/administration/hikes/history/user/{id}", UserSeeder.USER.getId()))
                .andDo(MockMvcResultHandlers.print())
                .andExpect(status().isUnauthorized())
                .andExpect(jsonPath("$.message").value("Unauthorized access. You must be authenticated to access this resource."));
    }

    @Test
    void shouldReturnPaginatedHikes_WithCorrectCoordinates_AsAdmin() throws Exception {
        String[] coords = HikeSeeder.COORDINATES.get(0).split(",");

        UsernamePasswordAuthenticationToken auth = AuthenticationManagerUtil.mockAuthenticationManager(authenticationManager, UserSeeder.ADMIN);

        mockMvc.perform(get("/hikes")
                        .contentType(MediaType.APPLICATION_JSON)
                        .param("latitude", coords[1])
                        .param("longitude", coords[2])
                        .with(authentication(auth)))
                .andDo(MockMvcResultHandlers.print())
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.items").isArray())
                .andExpect(jsonPath("$.totalItems").value(15))
                .andExpect(jsonPath("$.totalPages").value(1))
                .andExpect(jsonPath("$.currentPage").value(1))
                .andExpect(jsonPath("$.nextPage").doesNotExist())
                .andExpect(jsonPath("$.previousPage").doesNotExist());
    }

    @Test
    void shouldReturnForbidden_WhenUserIsNotAdmin() throws Exception {
        String[] coords = HikeSeeder.COORDINATES.get(0).split(",");

        UsernamePasswordAuthenticationToken auth = AuthenticationManagerUtil.mockAuthenticationManager(authenticationManager, UserSeeder.USER);

        mockMvc.perform(get("/administration/hikes")
                        .contentType(MediaType.APPLICATION_JSON)
                        .param("latitude", coords[1])
                        .param("longitude", coords[2])
                        .with(authentication(auth)))
                .andDo(MockMvcResultHandlers.print())
                .andExpect(status().isForbidden());
    }

    @Test
    void shouldReturnValidationError_WhenCoordinatesAreInvalid_AsAdmin() throws Exception {
        UsernamePasswordAuthenticationToken auth = AuthenticationManagerUtil.mockAuthenticationManager(authenticationManager, UserSeeder.ADMIN);

        mockMvc.perform(get("/administration/hikes")
                        .contentType(MediaType.APPLICATION_JSON)
                        .param("latitude", "")
                        .param("longitude", "")
                        .with(authentication(auth)))
                .andDo(MockMvcResultHandlers.print())
                .andExpect(status().isUnprocessableContent())
                .andExpect(jsonPath("$.i18nKey").value("validation.failed"))
                .andExpect(jsonPath("$.message").value("Validation failed"))
                .andExpect(jsonPath("$.extra").isMap())
                .andExpect(jsonPath("$.extra.latitude").value("must not be null"))
                .andExpect(jsonPath("$.extra.longitude").value("must not be null"));
    }
}
