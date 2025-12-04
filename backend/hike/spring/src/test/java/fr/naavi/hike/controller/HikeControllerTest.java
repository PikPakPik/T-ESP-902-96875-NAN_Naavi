package fr.naavi.hike.controller;

import com.fasterxml.jackson.databind.ObjectMapper;
import fr.naavi.core.dto.PaginationDTO;
import fr.naavi.core.dto.PaginatorDTO;
import fr.naavi.core.enums.RoleEnum;
import fr.naavi.core.exception.GlobalExceptionHandler;
import fr.naavi.hike.configuration.SecurityConfigurationTest;
import fr.naavi.hike.dto.UserDTO;
import fr.naavi.hike.dto.input.HikeDTO;
import fr.naavi.hike.dto.input.HikeHistoryDTO;
import fr.naavi.hike.dto.input.GeoPaginationDTO;
import fr.naavi.hike.dto.output.HikeDto;
import fr.naavi.hike.dto.output.HikeHistoryDto;
import fr.naavi.hike.entity.Hike;
import fr.naavi.hike.entity.HikeHistory;
import fr.naavi.hike.enums.DifficultyEnum;
import fr.naavi.hike.enums.SeasonEnum;
import fr.naavi.hike.enums.SourceEnum;
import fr.naavi.hike.enums.StatusEnum;
import fr.naavi.hike.repository.HikeHistoryRepository;
import fr.naavi.hike.repository.HikeRepository;
import fr.naavi.hike.service.HikeService;
import fr.naavi.hike.util.DtoFactory;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.context.annotation.Import;
import org.springframework.http.MediaType;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.context.TestPropertySource;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.request.RequestPostProcessor;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;
import org.springframework.web.context.WebApplicationContext;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.Random;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.doNothing;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;
import static org.springframework.security.test.web.servlet.setup.SecurityMockMvcConfigurers.springSecurity;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.delete;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@ActiveProfiles("ci")
@WebMvcTest(HikeController.class)
@Import({GlobalExceptionHandler.class, SecurityConfigurationTest.class})
@TestPropertySource(locations = "classpath:application-ci.properties")
public class HikeControllerTest {
    private final Random random = new Random();

    @MockitoBean
    private HikeRepository hikeRepository;

    @MockitoBean
    private HikeHistoryRepository hikeHistoryRepository;

    @MockitoBean
    private HikeService hikeService;

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private WebApplicationContext webApplicationContext;

    @Autowired
    private ObjectMapper objectMapper;

    @BeforeEach
    void setUp() {
        mockMvc = MockMvcBuilders
                .webAppContextSetup(webApplicationContext)
                .apply(springSecurity())
                .build();
    }

    @Test
    void testHikes_shouldReturnPaginatedHikes() throws Exception {
        Hike hike = this.createMockHike();
        Hike hike2 = this.createMockHike();

        List<HikeDto> hikeList = List.of(
                new HikeDto(hike, true),
                new HikeDto(hike2, true)
        );

        PaginationDTO paginationDTO = new PaginationDTO();
        paginationDTO.setPage(1);
        paginationDTO.setLimit(10);

        PaginatorDTO<HikeDto> paginatorDTO = new PaginatorDTO<>(hikeList, hikeList.toArray().length, paginationDTO);

        when(hikeRepository.findAllHikeWithPagination(any(GeoPaginationDTO.class)))
                .thenReturn(paginatorDTO);

        mockMvc.perform(get("/hikes")
                        .param("latitude", "47.2180438")
                        .param("longitude", "-1.5549507")
                        .param("page", "1")
                        .param("limit", "10"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.items").isArray())
                .andExpect(jsonPath("$.totalItems").value(hikeList.toArray().length))
                .andExpect(jsonPath("$.totalPages").value(1))
                .andExpect(jsonPath("$.currentPage").value(1))
                .andExpect(jsonPath("$.nextPage").doesNotExist())
                .andExpect(jsonPath("$.previousPage").doesNotExist());

        verify(hikeRepository).findAllHikeWithPagination(any(GeoPaginationDTO.class));
    }

    @Test
    void testGetHike_shouldReturnHikeById() throws Exception {
        Long hikeId = 1L;
        Hike hike = this.createMockHike();

        when(hikeRepository.findById(hikeId)).thenReturn(Optional.of(hike));

        mockMvc.perform(get("/hikes/{id}", hikeId))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.name").value(hike.getName()))
                .andExpect(jsonPath("$.startingPointLatitude").value(hike.getStartingPointLatitude()))
                .andExpect(jsonPath("$.startingPointLongitude").value(hike.getStartingPointLongitude()))
                .andExpect(jsonPath("$.startingElevation").value(hike.getStartingElevation()))
                .andExpect(jsonPath("$.arrivalPointLatitude").value(hike.getArrivalPointLatitude()))
                .andExpect(jsonPath("$.arrivalPointLongitude").value(hike.getArrivalPointLongitude()))
                .andExpect(jsonPath("$.arrivalElevation").value(hike.getArrivalElevation()))
                .andExpect(jsonPath("$.distance").value(hike.getDistance()))
                .andExpect(jsonPath("$.location").value(hike.getLocation()))
                .andExpect(jsonPath("$.difficulty").value(hike.getDifficulty().toString()))
                .andExpect(jsonPath("$.status").value(hike.getStatus().toString()))
                .andExpect(jsonPath("$.createdAt").exists())
                .andExpect(jsonPath("$.updatedAt").exists());

        verify(hikeRepository).findById(hikeId);
    }

    @Test
    void testGetHike_shouldReturn404WhenHikeNotFound() throws Exception {
        Long hikeId = 999L;

        when(hikeRepository.findById(hikeId)).thenReturn(Optional.empty());

        mockMvc.perform(get("/hikes/{id}", hikeId))
                .andExpect(status().isNotFound())
                .andExpect(jsonPath("$.i18nKey").value("hike.not_found"))
                .andExpect(jsonPath("$.message").value("Hike not found"));

        verify(hikeRepository).findById(hikeId);
    }

    @Test
    void testCreateHike_shouldReturnCreatedHike() throws Exception {
        HikeDTO hikeDTO = DtoFactory.createDto(HikeDTO.class, Map.ofEntries(
                Map.entry("name", "Nouvelle randonnée"),
                Map.entry("startingPointLatitude", 47.2180438348419),
                Map.entry("startingPointLongitude", -1.5549507712791397),
                Map.entry("startingElevation", 100),
                Map.entry("arrivalPointLatitude", 47.2180438348419),
                Map.entry("arrivalPointLongitude", -1.5549507712791397),
                Map.entry("arrivalElevation", 200),
                Map.entry("wkbGeometry", "NONE"),
                Map.entry("wkbWaypoints", "NONE"),
                Map.entry("distance", 5000),
                Map.entry("duration", 7200),
                Map.entry("difficulty", "MODERATE"),
                Map.entry("status", "PUBLISHED")
        ));

        Hike createdHike = this.createMockHike();
        createdHike.setName("Nouvelle randonnée");
        HikeDto hikeDto = new HikeDto(createdHike, true);

        when(hikeService.createHike(any(HikeDTO.class)))
                .thenReturn(hikeDto);

        mockMvc.perform(post("/hikes")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(hikeDTO)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.name").value("Nouvelle randonnée"))
                .andExpect(jsonPath("$.startingPointLatitude").value(47.2180438348419))
                .andExpect(jsonPath("$.startingPointLongitude").value(-1.5549507712791397))
                .andExpect(jsonPath("$.startingElevation").value(100))
                .andExpect(jsonPath("$.arrivalPointLatitude").value(47.2180438348419))
                .andExpect(jsonPath("$.arrivalPointLongitude").value(-1.5549507712791397))
                .andExpect(jsonPath("$.arrivalElevation").value(200))
                .andExpect(jsonPath("$.distance").exists())
                .andExpect(jsonPath("$.location").exists())
                .andExpect(jsonPath("$.difficulty").exists())
                .andExpect(jsonPath("$.status").exists())
                .andExpect(jsonPath("$.createdAt").exists())
                .andExpect(jsonPath("$.updatedAt").exists());

        verify(hikeService).createHike(any(HikeDTO.class));
    }

    @Test
    void testCreateHike_shouldReturn422WhenNameIsNull() throws Exception {
        HikeDTO hikeDTO = DtoFactory.createDto(HikeDTO.class, Map.ofEntries(
                Map.entry("startingPointLatitude", 47.2180438348419),
                Map.entry("startingPointLongitude", -1.5549507712791397),
                Map.entry("startingElevation", 100),
                Map.entry("arrivalPointLatitude", 47.2180438348419),
                Map.entry("arrivalPointLongitude", -1.5549507712791397),
                Map.entry("arrivalElevation", 200),
                Map.entry("wkbGeometry", "LINESTRING(0 0, 1 1)"),
                Map.entry("wkbWaypoints", "LINESTRING(0 0, 1 1)"),
                Map.entry("distance", 5000),
                Map.entry("duration", 7200),
                Map.entry("seasons", List.of()),
                Map.entry("difficulty", "EASY"),
                Map.entry("status", "DRAFT")
        ));

        mockMvc.perform(post("/hikes")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(hikeDTO)))
                .andExpect(status().isUnprocessableEntity())
                .andExpect(jsonPath("$.i18nKey").exists())
                .andExpect(jsonPath("$.message").exists())
                .andExpect(jsonPath("$.extra").exists());
    }

    @Test
    void testCreateHike_shouldReturn422WhenValidationFails() throws Exception {
        HikeDTO invalidHikeDTO = DtoFactory.createDto(HikeDTO.class, Map.of(
                "startingPointLatitude", 47.2180438348419,
                "startingPointLongitude", -1.5549507712791397
        ));

        mockMvc.perform(post("/hikes")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(invalidHikeDTO)))
                .andExpect(status().isUnprocessableEntity());
    }

    @Test
    void testUpdateHike_shouldReturnUpdatedHike() throws Exception {
        Long hikeId = 1L;

        HikeDTO hikeDTO = DtoFactory.createDto(HikeDTO.class, Map.of(
                "name", "Randonnée mise à jour",
                "distance", 8000,
                "duration", 10800,
                "difficulty", "HARD",
                "status", "DRAFT"
        ));

        Hike existingHike = this.createMockHike();
        Hike updatedHike = this.createMockHike();
        updatedHike.setName("Randonnée mise à jour");
        updatedHike.setDistance(8000);
        updatedHike.setDuration(10800);
        updatedHike.setDifficulty(DifficultyEnum.HARD);
        updatedHike.setStatus(StatusEnum.DRAFT);

        HikeDto hikeDto = new HikeDto(updatedHike, true);

        when(hikeRepository.findById(hikeId))
                .thenReturn(Optional.of(existingHike));
        when(hikeService.updateHike(any(Hike.class), any(HikeDTO.class)))
                .thenReturn(hikeDto);

        mockMvc.perform(put("/administration/hikes/{id}", hikeId)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(hikeDTO)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.name").value("Randonnée mise à jour"))
                .andExpect(jsonPath("$.distance").value(8000))
                .andExpect(jsonPath("$.difficulty").value("HARD"))
                .andExpect(jsonPath("$.status").value("DRAFT"))
                .andExpect(jsonPath("$.createdAt").exists())
                .andExpect(jsonPath("$.updatedAt").exists());

        verify(hikeRepository).findById(hikeId);
        verify(hikeService).updateHike(any(Hike.class), any(HikeDTO.class));
    }

    @Test
    void testUpdateHike_shouldReturn404WhenHikeNotFound() throws Exception {
        Long hikeId = 999L;

        HikeDTO hikeDTO = DtoFactory.createDto(HikeDTO.class, Map.of(
                "name", "Randonnée mise à jour"
        ));

        when(hikeRepository.findById(hikeId))
                .thenReturn(Optional.empty());

        mockMvc.perform(put("/administration/hikes/{id}", hikeId)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(hikeDTO)))
                .andExpect(status().isNotFound())
                .andExpect(jsonPath("$.i18nKey").value("hike.not_found"))
                .andExpect(jsonPath("$.message").value("Hike not found"));

        verify(hikeRepository).findById(hikeId);
    }

    @Test
    void testUpdateHike_shouldReturn422WhenNameIsNull() throws Exception {
        Long hikeId = 1L;

        HikeDTO hikeDTO = DtoFactory.createDto(HikeDTO.class, Map.of(
                "distance", 8000,
                "duration", 10800
        ));

        mockMvc.perform(put("/administration/hikes/{id}", hikeId)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(hikeDTO)))
                .andExpect(status().isUnprocessableEntity())
                .andExpect(jsonPath("$.i18nKey").exists())
                .andExpect(jsonPath("$.message").exists())
                .andExpect(jsonPath("$.extra").exists());
    }

    @Test
    void testDeleteHike_shouldReturnSuccessMessage() throws Exception {
        Long hikeId = 1L;
        Hike hike = this.createMockHike();

        when(hikeRepository.findById(hikeId))
                .thenReturn(Optional.of(hike));
        doNothing().when(hikeService).deleteHike(any(Hike.class));

        mockMvc.perform(delete("/administration/hikes/{id}", hikeId))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.i18nKey").value("hike.deleted"))
                .andExpect(jsonPath("$.message").value("Hike successfully deleted"));

        verify(hikeRepository).findById(hikeId);
        verify(hikeService).deleteHike(any(Hike.class));
    }

    @Test
    void testDeleteHike_shouldReturn404WhenHikeNotFound() throws Exception {
        Long hikeId = 999L;

        when(hikeRepository.findById(hikeId))
                .thenReturn(Optional.empty());

        mockMvc.perform(delete("/administration/hikes/{id}", hikeId))
                .andExpect(status().isNotFound())
                .andExpect(jsonPath("$.i18nKey").value("hike.not_found"))
                .andExpect(jsonPath("$.message").value("Hike not found"));

        verify(hikeRepository).findById(hikeId);
    }

    @Test
    void testGetHistory_shouldReturnPaginatedHikeHistory() throws Exception {
        UserDTO authenticatedUser = createMockUser();

        Hike hike1 = this.createMockHike();
        Hike hike2 = this.createMockHike();

        HikeHistory hikeHistory1 = new HikeHistory();
        hikeHistory1.setUser(authenticatedUser.getId());
        hikeHistory1.setHike(hike1);

        HikeHistory hikeHistory2 = new HikeHistory();
        hikeHistory2.setUser(authenticatedUser.getId());
        hikeHistory2.setHike(hike2);

        List<HikeHistoryDto> historyList = List.of(
                new HikeHistoryDto(hikeHistory1, true),
                new HikeHistoryDto(hikeHistory2, true)
        );

        PaginationDTO paginationDTO = new PaginationDTO();
        paginationDTO.setPage(1);
        paginationDTO.setLimit(10);

        PaginatorDTO<HikeHistoryDto> paginatorDTO = new PaginatorDTO<>(historyList, historyList.size(), paginationDTO);

        when(hikeHistoryRepository.findAllWithPagination(any(PaginationDTO.class), any(Long.class)))
                .thenReturn(paginatorDTO);

        mockMvc.perform(get("/hikes/history")
                        .param("page", "1")
                        .param("limit", "10")
                        .with(createAuthenticatedUser(authenticatedUser)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.items").isArray())
                .andExpect(jsonPath("$.items.length()").value(2))
                .andExpect(jsonPath("$.totalItems").value(2))
                .andExpect(jsonPath("$.totalPages").value(1))
                .andExpect(jsonPath("$.currentPage").value(1))
                .andExpect(jsonPath("$.nextPage").doesNotExist())
                .andExpect(jsonPath("$.previousPage").doesNotExist());

        verify(hikeHistoryRepository).findAllWithPagination(any(PaginationDTO.class), any(Long.class));
    }

    @Test
    void testSaveHistory_shouldReturnSuccessMessage() throws Exception {
        UserDTO authenticatedUser = createMockUser();

        Long hikeId = 1L;
        Hike hike = this.createMockHike();

        HikeHistoryDTO hikeHistoryDTO = DtoFactory.createDto(HikeHistoryDTO.class, Map.of(
                "hikeId", hikeId,
                "duration", 3600
        ));

        when(hikeRepository.findById(hikeId))
                .thenReturn(Optional.of(hike));
        doNothing().when(hikeService).saveHikeHistory(any(UserDTO.class), any(Hike.class), any(HikeHistoryDTO.class));

        mockMvc.perform(post("/hikes/history")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(hikeHistoryDTO))
                        .with(createAuthenticatedUser(authenticatedUser)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.i18nKey").value("hike.history.success"))
                .andExpect(jsonPath("$.message").value("The hike has been successfully saved."));

        verify(hikeRepository).findById(hikeId);
        verify(hikeService).saveHikeHistory(any(UserDTO.class), any(Hike.class), any(HikeHistoryDTO.class));
    }

    @Test
    void testSaveHistory_shouldReturn404WhenHikeNotFound() throws Exception {
        UserDTO authenticatedUser = createMockUser();

        Long hikeId = 999L;

        HikeHistoryDTO hikeHistoryDTO = DtoFactory.createDto(HikeHistoryDTO.class, Map.of(
                "hikeId", hikeId,
                "duration", 3600
        ));

        when(hikeRepository.findById(hikeId))
                .thenReturn(Optional.empty());

        mockMvc.perform(post("/hikes/history")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(hikeHistoryDTO))
                        .with(createAuthenticatedUser(authenticatedUser)))
                .andExpect(status().isNotFound())
                .andExpect(jsonPath("$.i18nKey").value("hike.not_found"))
                .andExpect(jsonPath("$.message").value("Hike not found"));

        verify(hikeRepository).findById(hikeId);
    }

    @Test
    void testSaveHistory_shouldReturn422WhenValidationFails() throws Exception {
        UserDTO authenticatedUser = createMockUser();

        HikeHistoryDTO invalidHikeHistoryDTO = DtoFactory.createDto(HikeHistoryDTO.class, Map.of(
                "duration", 3600
        ));

        mockMvc.perform(post("/hikes/history")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(invalidHikeHistoryDTO))
                        .with(createAuthenticatedUser(authenticatedUser)))
                .andExpect(status().isUnprocessableEntity())
                .andExpect(jsonPath("$.i18nKey").exists())
                .andExpect(jsonPath("$.message").exists());
    }

    @Test
    void testDeleteHistory_shouldReturnSuccessMessage() throws Exception {
        UserDTO authenticatedUser = createMockUser();

        Long historyId = 1L;
        Hike hike = this.createMockHike();

        HikeHistory hikeHistory = new HikeHistory();
        hikeHistory.setUser(authenticatedUser.getId());
        hikeHistory.setHike(hike);

        when(hikeHistoryRepository.findById(historyId))
                .thenReturn(Optional.of(hikeHistory));
        doNothing().when(hikeHistoryRepository).delete(any(HikeHistory.class));

        mockMvc.perform(delete("/hikes/history/{id}", historyId)
                        .with(createAuthenticatedUser(authenticatedUser)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.i18nKey").value("hike.history.success"))
                .andExpect(jsonPath("$.message").value("The hike has been successfully deleted."));

        verify(hikeHistoryRepository).findById(historyId);
        verify(hikeHistoryRepository).delete(any(HikeHistory.class));
    }

    @Test
    void testDeleteHistory_shouldReturn404WhenHistoryNotFound() throws Exception {
        UserDTO authenticatedUser = createMockUser();

        Long historyId = 999L;

        when(hikeHistoryRepository.findById(historyId))
                .thenReturn(Optional.empty());

        mockMvc.perform(delete("/hikes/history/{id}", historyId)
                        .with(createAuthenticatedUser(authenticatedUser)))
                .andExpect(status().isNotFound())
                .andExpect(jsonPath("$.i18nKey").value("hike.history.not_found"))
                .andExpect(jsonPath("$.message").value("Hike history not found"));

        verify(hikeHistoryRepository).findById(historyId);
    }

    @Test
    void testDeleteHistory_shouldReturn403WhenUserNotOwnerAndNotAdmin() throws Exception {
        UserDTO authenticatedUser = createMockUser();
        UserDTO otherUser = createMockUser();
        otherUser.setId(2L);

        Long historyId = 1L;
        Hike hike = this.createMockHike();

        HikeHistory hikeHistory = new HikeHistory();
        hikeHistory.setUser(otherUser.getId());
        hikeHistory.setHike(hike);

        when(hikeHistoryRepository.findById(historyId))
                .thenReturn(Optional.of(hikeHistory));

        mockMvc.perform(delete("/hikes/history/{id}", historyId)
                        .with(createAuthenticatedUser(authenticatedUser)))
                .andExpect(status().isForbidden())
                .andExpect(jsonPath("$.i18nKey").value("hike.history.forbidden"))
                .andExpect(jsonPath("$.message").value("You are not allowed to delete this hike history."));

        verify(hikeHistoryRepository).findById(historyId);
    }

    @Test
    void testDeleteHistory_shouldAllowAdminToDeleteAnyHistory() throws Exception {
        UserDTO adminUser = createMockUser();
        adminUser.setRoles(List.of(RoleEnum.ROLE_ADMIN));

        UserDTO otherUser = createMockUser();
        otherUser.setId(2L);

        Long historyId = 1L;
        Hike hike = this.createMockHike();

        HikeHistory hikeHistory = new HikeHistory();
        hikeHistory.setUser(otherUser.getId());
        hikeHistory.setHike(hike);

        when(hikeHistoryRepository.findById(historyId))
                .thenReturn(Optional.of(hikeHistory));
        doNothing().when(hikeHistoryRepository).delete(any(HikeHistory.class));

        mockMvc.perform(delete("/hikes/history/{id}", historyId)
                        .with(createAuthenticatedUser(adminUser)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.i18nKey").value("hike.history.success"))
                .andExpect(jsonPath("$.message").value("The hike has been successfully deleted."));

        verify(hikeHistoryRepository).findById(historyId);
        verify(hikeHistoryRepository).delete(any(HikeHistory.class));
    }

    @Test
    void testDeleteHistory_shouldAllowModeratorToDeleteAnyHistory() throws Exception {
        UserDTO moderatorUser = createMockUser();
        moderatorUser.setRoles(List.of(RoleEnum.ROLE_MODERATOR));

        UserDTO otherUser = createMockUser();
        otherUser.setId(2L);

        Long historyId = 1L;
        Hike hike = this.createMockHike();

        HikeHistory hikeHistory = new HikeHistory();
        hikeHistory.setUser(otherUser.getId());
        hikeHistory.setHike(hike);

        when(hikeHistoryRepository.findById(historyId))
                .thenReturn(Optional.of(hikeHistory));
        doNothing().when(hikeHistoryRepository).delete(any(HikeHistory.class));

        mockMvc.perform(delete("/hikes/history/{id}", historyId)
                        .with(createAuthenticatedUser(moderatorUser)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.i18nKey").value("hike.history.success"))
                .andExpect(jsonPath("$.message").value("The hike has been successfully deleted."));

        verify(hikeHistoryRepository).findById(historyId);
        verify(hikeHistoryRepository).delete(any(HikeHistory.class));
    }

    private Hike createMockHike() {
        Hike hike = new Hike();
        hike.setName("Test hike " + this.random.nextInt());
        hike.setStartingPointLatitude(47.2180438348419);
        hike.setStartingPointLongitude(-1.5549507712791397);
        hike.setStartingElevation(100);
        hike.setArrivalPointLatitude(47.2180438348419);
        hike.setArrivalPointLongitude(-1.5549507712791397);
        hike.setArrivalElevation(200);
        hike.setWkbGeometry("NONE");
        hike.setWkbWaypoints("NONE");
        hike.setDistance(3600);
        hike.setDuration(3600);
        hike.setLocation("Mayenne");
        hike.setSeasons(List.of(SeasonEnum.SPRING, SeasonEnum.SUMMER));
        hike.setSource(SourceEnum.OFFICIAL);
        hike.setDifficulty(DifficultyEnum.EASY);
        hike.setStatus(StatusEnum.PUBLISHED);
        hike.setCreatedAt(LocalDateTime.now().minusDays(10));
        hike.setUpdatedAt(LocalDateTime.now());
        return hike;
    }

    private UserDTO createMockUser() {
        UserDTO userDTO = new UserDTO();
        userDTO.setId(1L);
        userDTO.setFirstname("Firstname");
        userDTO.setLastname("Lastname");
        userDTO.setEmail("firstname.lastname@domain.tdl");
        userDTO.setRoles(List.of(RoleEnum.ROLE_USER));
        userDTO.setPermissions(List.of());
        return userDTO;
    }

    private RequestPostProcessor createAuthenticatedUser(UserDTO user) {
        List<SimpleGrantedAuthority> authorities = user.getRoles().stream()
                .map(Enum::name)
                .map(SimpleGrantedAuthority::new)
                .toList();
        return SecurityMockMvcRequestPostProcessors.authentication(
                new UsernamePasswordAuthenticationToken(user, null, authorities)
        );
    }
}
