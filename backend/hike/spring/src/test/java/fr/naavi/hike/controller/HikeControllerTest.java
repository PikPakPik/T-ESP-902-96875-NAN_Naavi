package fr.naavi.hike.controller;

import fr.naavi.core.enums.S3Enum;
import fr.naavi.core.exception.GlobalExceptionHandler;
import fr.naavi.core.service.S3Service;
import fr.naavi.hike.configuration.CacheConfigurationTest;
import fr.naavi.hike.dto.UserDTO;
import fr.naavi.hike.dto.input.HikeDTO;
import fr.naavi.hike.dto.input.HikeHistoryDTO;
import fr.naavi.hike.entity.Hike;
import fr.naavi.hike.entity.HikeHistory;
import fr.naavi.hike.entity.Media;
import fr.naavi.hike.enums.SourceEnum;
import fr.naavi.hike.repository.HikeHistoryRepository;
import fr.naavi.hike.repository.HikeReactionRepository;
import fr.naavi.hike.repository.HikeRepository;
import fr.naavi.hike.repository.MediaRepository;
import fr.naavi.hike.seeder.HikeHistorySeeder;
import fr.naavi.hike.seeder.HikeSeeder;
import fr.naavi.hike.seeder.UserSeeder;
import fr.naavi.hike.utils.AuthenticationManagerUtil;
import fr.naavi.hike.utils.DtoFactory;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.Mockito;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.webmvc.test.autoconfigure.AutoConfigureMockMvc;
import org.springframework.context.annotation.Import;
import org.springframework.http.MediaType;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.mock.web.MockMultipartFile;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.context.TestPropertySource;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.result.MockMvcResultHandlers;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.concurrent.ThreadLocalRandom;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.authentication;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
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

    @Autowired
    private MediaRepository mediaRepository;

    @Autowired
    private HikeReactionRepository hikeReactionRepository;

    @MockitoBean
    private AuthenticationManager authenticationManager;

    @MockitoBean
    private S3Service s3Service;

    @Autowired
    private JdbcTemplate jdbcTemplate;

    @BeforeEach
    void setUp() {
        jdbcTemplate.execute("DELETE FROM hikes_images");

        mediaRepository.deleteAll();
        hikeHistoryRepository.deleteAll();
        hikeReactionRepository.deleteAll();
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
    void shouldUploadImage_WithUnauthenticatedUser_ReturnsUnauthorized() throws Exception {
        Hike hike = hikeRepository.findAll().getFirst();

        MockMultipartFile image = new MockMultipartFile(
                "image", "photo.png", "image/png", "fake-image-content".getBytes()
        );

        mockMvc.perform(multipart("/hikes/{id}/images", hike.getId()).file(image))
                .andDo(MockMvcResultHandlers.print())
                .andExpect(status().isUnauthorized());
    }

    @Test
    void shouldUploadImage_WithEmptyFile_ReturnsBadRequest() throws Exception {
        Hike hike = hikeRepository.findAll().getFirst();
        UsernamePasswordAuthenticationToken authToken = AuthenticationManagerUtil.mockAuthenticationManager(authenticationManager, UserSeeder.USER);

        MockMultipartFile image = new MockMultipartFile(
                "image", "photo.png", "image/png", new byte[0]
        );

        mockMvc.perform(multipart("/hikes/{id}/images", hike.getId())
                        .file(image)
                        .with(authentication(authToken)))
                .andDo(MockMvcResultHandlers.print())
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.i18nKey").value("hike.image.invalid_file"))
                .andExpect(jsonPath("$.message").value("The file is empty or invalid."));
    }

    @Test
    void shouldUploadImage_WithInvalidContentType_ReturnsBadRequest() throws Exception {
        Hike hike = hikeRepository.findAll().getFirst();
        UsernamePasswordAuthenticationToken authToken = AuthenticationManagerUtil.mockAuthenticationManager(authenticationManager, UserSeeder.USER);

        MockMultipartFile image = new MockMultipartFile(
                "image", "document.pdf", "application/pdf", "fake-pdf-content".getBytes()
        );

        mockMvc.perform(multipart("/hikes/{id}/images", hike.getId())
                        .file(image)
                        .with(authentication(authToken)))
                .andDo(MockMvcResultHandlers.print())
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.i18nKey").value("hike.image.invalid_file"))
                .andExpect(jsonPath("$.message").value("Only image files are allowed."));
    }

    @Test
    void shouldUploadImage_WithValidFile_ReturnsSuccess() throws Exception {
        Hike hike = hikeRepository.findAll().getFirst();
        UsernamePasswordAuthenticationToken authToken = AuthenticationManagerUtil.mockAuthenticationManager(authenticationManager, UserSeeder.USER);

        MockMultipartFile image = new MockMultipartFile(
                "image", "photo.png", "image/png", "fake-image-content".getBytes()
        );

        mockMvc.perform(multipart("/hikes/{id}/images", hike.getId())
                        .file(image)
                        .with(authentication(authToken)))
                .andDo(MockMvcResultHandlers.print())
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.i18nKey").value("hike.image.uploaded"))
                .andExpect(jsonPath("$.message").value("The image was successfully uploaded."));
    }

    @Test
    void shouldUploadImage_WhenS3Fails_ReturnsBadRequest() throws Exception {
        Hike hike = hikeRepository.findAll().getFirst();
        UsernamePasswordAuthenticationToken authToken = AuthenticationManagerUtil.mockAuthenticationManager(authenticationManager, UserSeeder.USER);

        Mockito.doThrow(new RuntimeException("S3 unavailable"))
                .when(s3Service).upload(Mockito.any(S3Enum.class), Mockito.any(), Mockito.anyString(), Mockito.any());

        MockMultipartFile image = new MockMultipartFile(
                "image", "photo.png", "image/png", "fake-image-content".getBytes()
        );

        mockMvc.perform(multipart("/hikes/{id}/images", hike.getId())
                        .file(image)
                        .with(authentication(authToken)))
                .andDo(MockMvcResultHandlers.print())
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.i18nKey").value("hike.image.failed_upload"))
                .andExpect(jsonPath("$.message").value("Failed to upload the image. Please try again later."));
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
    void shouldForceCommunityAndOwner_WhenUserCreatesOfficialHikePayload() throws Exception {
        int size = HikeSeeder.SARTHE_COORDINATES.size();
        int randomIndex = ThreadLocalRandom.current().nextInt(size);
        String[] coords = HikeSeeder.SARTHE_COORDINATES.get(randomIndex).split(",");

        HikeDTO hikeDTO = DtoFactory.createDto(HikeDTO.class, Map.ofEntries(
                Map.entry("name", coords[0]),
                Map.entry("startingPointLatitude", Double.parseDouble(coords[1])),
                Map.entry("startingPointLongitude", Double.parseDouble(coords[2])),
                Map.entry("startingElevation", 0),
                Map.entry("arrivalPointLatitude", Double.parseDouble(coords[1])),
                Map.entry("arrivalPointLongitude", Double.parseDouble(coords[2])),
                Map.entry("arrivalElevation", 0),
                Map.entry("wkbGeometry", "none"),
                Map.entry("wkbWaypoints", "none"),
                Map.entry("source", SourceEnum.OFFICIAL.name()),
                Map.entry("userId", UserSeeder.ADMIN.getId())
        ));

        UsernamePasswordAuthenticationToken auth =
                AuthenticationManagerUtil.mockAuthenticationManager(authenticationManager, UserSeeder.USER);

        mockMvc.perform(post("/hikes")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(DtoFactory.toJson(hikeDTO))
                        .with(authentication(auth)))
                .andDo(MockMvcResultHandlers.print())
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.source").value(SourceEnum.COMMUNITY.name()))
                .andExpect(jsonPath("$.userId").value(UserSeeder.USER.getId()));
    }

    @Test
    void shouldRejectOfficialWithOwner_WhenAdminCreatesHike() throws Exception {
        int size = HikeSeeder.SARTHE_COORDINATES.size();
        int randomIndex = ThreadLocalRandom.current().nextInt(size);
        String[] coords = HikeSeeder.SARTHE_COORDINATES.get(randomIndex).split(",");

        HikeDTO hikeDTO = DtoFactory.createDto(HikeDTO.class, Map.ofEntries(
                Map.entry("name", coords[0]),
                Map.entry("startingPointLatitude", Double.parseDouble(coords[1])),
                Map.entry("startingPointLongitude", Double.parseDouble(coords[2])),
                Map.entry("startingElevation", 0),
                Map.entry("arrivalPointLatitude", Double.parseDouble(coords[1])),
                Map.entry("arrivalPointLongitude", Double.parseDouble(coords[2])),
                Map.entry("arrivalElevation", 0),
                Map.entry("wkbGeometry", "none"),
                Map.entry("wkbWaypoints", "none"),
                Map.entry("source", SourceEnum.OFFICIAL.name()),
                Map.entry("userId", UserSeeder.USER.getId())
        ));

        UsernamePasswordAuthenticationToken auth =
                AuthenticationManagerUtil.mockAuthenticationManager(authenticationManager, UserSeeder.ADMIN);

        mockMvc.perform(post("/hikes")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(DtoFactory.toJson(hikeDTO))
                        .with(authentication(auth)))
                .andDo(MockMvcResultHandlers.print())
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.i18nKey").value("hike.source_user_incompatible"));
    }

    @Test
        void shouldCreateCommunityForCurrentAdmin_WhenAdminCreatesHikeWithoutOwner() throws Exception {
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
                "wkbWaypoints", "none",
                "source", SourceEnum.COMMUNITY.name()
        ));

        UsernamePasswordAuthenticationToken auth =
                AuthenticationManagerUtil.mockAuthenticationManager(authenticationManager, UserSeeder.ADMIN);

        mockMvc.perform(post("/hikes")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(DtoFactory.toJson(hikeDTO))
                        .with(authentication(auth)))
                .andDo(MockMvcResultHandlers.print())
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.source").value(SourceEnum.COMMUNITY.name()))
                .andExpect(jsonPath("$.userId").value(UserSeeder.ADMIN.getId()));
    }

    @Test
    void shouldRejectOfficialPrivateVisibility_WhenAdminCreatesHike() throws Exception {
        int size = HikeSeeder.SARTHE_COORDINATES.size();
        int randomIndex = ThreadLocalRandom.current().nextInt(size);
        String[] coords = HikeSeeder.SARTHE_COORDINATES.get(randomIndex).split(",");

        HikeDTO hikeDTO = DtoFactory.createDto(HikeDTO.class, Map.ofEntries(
                Map.entry("name", coords[0]),
                Map.entry("startingPointLatitude", Double.parseDouble(coords[1])),
                Map.entry("startingPointLongitude", Double.parseDouble(coords[2])),
                Map.entry("startingElevation", 0),
                Map.entry("arrivalPointLatitude", Double.parseDouble(coords[1])),
                Map.entry("arrivalPointLongitude", Double.parseDouble(coords[2])),
                Map.entry("arrivalElevation", 0),
                Map.entry("wkbGeometry", "none"),
                Map.entry("wkbWaypoints", "none"),
                Map.entry("source", SourceEnum.OFFICIAL.name()),
                Map.entry("visibility", "PRIVATE")
        ));

        UsernamePasswordAuthenticationToken auth =
                AuthenticationManagerUtil.mockAuthenticationManager(authenticationManager, UserSeeder.ADMIN);

        mockMvc.perform(post("/hikes")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(DtoFactory.toJson(hikeDTO))
                        .with(authentication(auth)))
                .andDo(MockMvcResultHandlers.print())
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.i18nKey").value("hike.official_visibility_invalid"));
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
    void shouldReturnHistorySortedByCreatedAtDescending() throws Exception {
        hikeHistoryRepository.deleteAll();
        List<Hike> hikes = hikeRepository.findAll();
        Hike h0 = hikes.get(0);
        Hike h1 = hikes.get(1);
        Hike h2 = hikes.get(2);

        LocalDateTime base = LocalDateTime.now().withNano(0);

        HikeHistory oldest = new HikeHistory();
        oldest.setUser(UserSeeder.USER.getId());
        oldest.setHike(h0);
        oldest.setDuration(100);
        oldest.setCreatedAt(base.minusDays(10));

        HikeHistory middle = new HikeHistory();
        middle.setUser(UserSeeder.USER.getId());
        middle.setHike(h1);
        middle.setDuration(200);
        middle.setCreatedAt(base.minusDays(5));

        HikeHistory newest = new HikeHistory();
        newest.setUser(UserSeeder.USER.getId());
        newest.setHike(h2);
        newest.setDuration(300);
        newest.setCreatedAt(base.minusDays(1));

        hikeHistoryRepository.saveAll(List.of(oldest, newest, middle));

        UsernamePasswordAuthenticationToken auth =
                AuthenticationManagerUtil.mockAuthenticationManager(
                        authenticationManager, UserSeeder.USER);

        mockMvc.perform(get("/hikes/history")
                        .param("page", "1")
                        .param("limit", "10")
                        .contentType(MediaType.APPLICATION_JSON)
                        .with(authentication(auth)))
                .andDo(MockMvcResultHandlers.print())
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.items.length()").value(3))
                .andExpect(jsonPath("$.items[0].hike").value(h2.getName()))
                .andExpect(jsonPath("$.items[1].hike").value(h1.getName()))
                .andExpect(jsonPath("$.items[2].hike").value(h0.getName()));
    }

    @Test
    void shouldReturnHistorySecondPageWithPreviousPage() throws Exception {
        UsernamePasswordAuthenticationToken auth =
                AuthenticationManagerUtil.mockAuthenticationManager(
                        authenticationManager, UserSeeder.USER);

        List<Hike> hikes = hikeRepository.findAll();
        hikeHistorySeeder.seedHistory(UserSeeder.USER, hikes);

        int limit = 20;
        int expectedSecondPageSize = hikes.size() - limit;

        mockMvc.perform(get("/hikes/history")
                        .param("page", "2")
                        .param("limit", String.valueOf(limit))
                        .contentType(MediaType.APPLICATION_JSON)
                        .with(authentication(auth)))
                .andDo(MockMvcResultHandlers.print())
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.currentPage").value(2))
                .andExpect(jsonPath("$.previousPage").value(1))
                .andExpect(jsonPath("$.nextPage").doesNotExist())
                .andExpect(jsonPath("$.totalItems").value(hikes.size()))
                .andExpect(jsonPath("$.items.length()").value(expectedSecondPageSize));
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
    void shouldSaveHistory_WithExtendedPayload_WhenHikeExists() throws Exception {
        Hike hike = hikeRepository.findAll().getFirst();
        int durationSeconds = ThreadLocalRandom.current().nextInt(1, 3600);

        Map<String, Object> payload = new HashMap<>();
        payload.put("hikeId", hike.getId());
        payload.put("duration", durationSeconds);
        payload.put("hike", hike.getName());
        payload.put("distance", hike.getDistance());
        payload.put("elevationGain", 42);
        payload.put("averageSpeed", 4.2);
        payload.put("wkbGeometry", hike.getWkbGeometry());
        payload.put("startingPointLatitude", hike.getStartingPointLatitude());
        payload.put("startingPointLongitude", hike.getStartingPointLongitude());
        payload.put("arrivalPointLatitude", hike.getArrivalPointLatitude());
        payload.put("arrivalPointLongitude", hike.getArrivalPointLongitude());

        HikeHistoryDTO dto = DtoFactory.createDto(HikeHistoryDTO.class, payload);

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
    void shouldUpdateOwnHike_WithOwner_WhenValidRequest() throws Exception {
        Hike hike = hikeRepository.findAll().getFirst();
        String newName = hike.getName() + " - owner updated";

        HikeDTO hikeDTO = DtoFactory.createDto(HikeDTO.class, Map.of(
                "name", newName,
                "visibility", "PRIVATE"
        ));

        UsernamePasswordAuthenticationToken auth = AuthenticationManagerUtil.mockAuthenticationManager(
                authenticationManager,
                UserSeeder.USER
        );

        mockMvc.perform(put("/hikes/{id}", hike.getId())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(DtoFactory.toJson(hikeDTO))
                        .with(authentication(auth)))
                .andDo(MockMvcResultHandlers.print())
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.id").value(hike.getId()))
                .andExpect(jsonPath("$.name").value(newName))
                .andExpect(jsonPath("$.visibility").value("PRIVATE"));
    }

    @Test
    void shouldReturnForbidden_WhenNonOwnerUpdatesHike() throws Exception {
        Hike hike = hikeRepository.findAll().getFirst();

        HikeDTO hikeDTO = DtoFactory.createDto(HikeDTO.class, Map.of(
                "name", "attempted update",
                "visibility", "PUBLIC"
        ));

        UserDTO anotherUser = new UserDTO();
        anotherUser.setId(999L);
        anotherUser.setRoles(List.of(fr.naavi.core.enums.RoleEnum.ROLE_USER));

        UsernamePasswordAuthenticationToken auth = AuthenticationManagerUtil.mockAuthenticationManager(
                authenticationManager,
                anotherUser
        );

        mockMvc.perform(put("/hikes/{id}", hike.getId())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(DtoFactory.toJson(hikeDTO))
                        .with(authentication(auth)))
                .andDo(MockMvcResultHandlers.print())
                .andExpect(status().isForbidden())
                .andExpect(jsonPath("$.i18nKey").value("hike.forbidden"));
    }

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

    @Test
    @Transactional
    void shouldDeleteImage_WithAdmin_WhenHikeAndMediaExist() throws Exception {
        Hike hike = hikeRepository.findAll().getFirst();

        Media media = new Media();
        media.setFilename("test-image.jpg");
        media.setUser(UserSeeder.ADMIN.getId());
        media = mediaRepository.save(media);
        hike.getImages().add(media);
        hikeRepository.save(hike);

        UsernamePasswordAuthenticationToken auth = AuthenticationManagerUtil.mockAuthenticationManager(authenticationManager, UserSeeder.ADMIN);

        mockMvc.perform(delete("/administration/hikes/{hikeId}/images/{imageId}", hike.getId(), media.getId())
                        .with(authentication(auth)))
                .andDo(MockMvcResultHandlers.print())
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.i18nKey").value("hike.image.deleted"))
                .andExpect(jsonPath("$.message").value("The image was successfully deleted."));
    }

    @Test
    void shouldReturnNotFound_WhenHikeDoesNotExistOnDeleteImage() throws Exception {
        Long nonExistentHikeId = 999999999L;
        Long anyImageId = 1L;

        UsernamePasswordAuthenticationToken auth = AuthenticationManagerUtil.mockAuthenticationManager(authenticationManager, UserSeeder.ADMIN);

        mockMvc.perform(delete("/administration/hikes/{hikeId}/images/{imageId}", nonExistentHikeId, anyImageId)
                        .with(authentication(auth)))
                .andDo(MockMvcResultHandlers.print())
                .andExpect(status().isNotFound())
                .andExpect(jsonPath("$.i18nKey").value("hike.not_found"))
                .andExpect(jsonPath("$.message").value("Hike not found"))
                .andExpect(jsonPath("$.extra").doesNotExist());
    }

    @Test
    @Transactional
    void shouldReturnNotFound_WhenMediaDoesNotExistOnDeleteImage() throws Exception {
        Hike hike = hikeRepository.findAll().getFirst();
        Long nonExistentMediaId = 999999999L;

        UsernamePasswordAuthenticationToken auth = AuthenticationManagerUtil.mockAuthenticationManager(authenticationManager, UserSeeder.ADMIN);

        mockMvc.perform(delete("/administration/hikes/{hikeId}/images/{imageId}", hike.getId(), nonExistentMediaId)
                        .with(authentication(auth)))
                .andDo(MockMvcResultHandlers.print())
                .andExpect(status().isNotFound())
                .andExpect(jsonPath("$.i18nKey").value("media.not_found"))
                .andExpect(jsonPath("$.message").value("Media not found"))
                .andExpect(jsonPath("$.extra").doesNotExist());
    }

    @Test
    @Transactional
    void shouldReturnBadRequest_WhenMediaIsNotLinkedToHike() throws Exception {
        Hike hike = hikeRepository.findAll().getFirst();

        Media media = new Media();
        media.setFilename("unlinked-image.jpg");
        media.setUser(UserSeeder.ADMIN.getId());
        media = mediaRepository.save(media);

        UsernamePasswordAuthenticationToken auth = AuthenticationManagerUtil.mockAuthenticationManager(authenticationManager, UserSeeder.ADMIN);

        mockMvc.perform(delete("/administration/hikes/{hikeId}/images/{imageId}", hike.getId(), media.getId())
                        .with(authentication(auth)))
                .andDo(MockMvcResultHandlers.print())
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.i18nKey").value("hike.image.not_linked"))
                .andExpect(jsonPath("$.message").value("The media is not linked to this hike."));
    }

    @Test
    void shouldReturnUnauthorized_WhenDeleteImageWithoutAuthentication() throws Exception {
        Hike hike = hikeRepository.findAll().getFirst();

        mockMvc.perform(delete("/administration/hikes/{hikeId}/images/{imageId}", hike.getId(), 1L))
                .andDo(MockMvcResultHandlers.print())
                .andExpect(status().isUnauthorized())
                .andExpect(jsonPath("$.message").value("Unauthorized access. You must be authenticated to access this resource."));
    }

    @Test
    void shouldReturnForbidden_WhenUserDeletesImageWithoutAdminRole() throws Exception {
        Hike hike = hikeRepository.findAll().getFirst();

        UsernamePasswordAuthenticationToken auth = AuthenticationManagerUtil.mockAuthenticationManager(authenticationManager, UserSeeder.USER);

        mockMvc.perform(delete("/administration/hikes/{hikeId}/images/{imageId}", hike.getId(), 1L)
                        .with(authentication(auth)))
                .andDo(MockMvcResultHandlers.print())
                .andExpect(status().isForbidden())
                .andExpect(jsonPath("$.message").value("Access denied. You do not have the necessary permissions to access this resource"));
    }

    /*
     * DELETE /hikes/{id} — SOFT DELETE TESTS
     */

    @Test
    void shouldSoftDeleteOwnHike_WhenOwnerDeletes_Returns200() throws Exception {
        // Le seeder crée les hikes avec userId=1 qui correspond à UserSeeder.USER.getId()
        Hike hike = hikeRepository.findAll().stream()
                .filter(h -> UserSeeder.USER.getId().equals(h.getUserId()))
                .findFirst()
                .orElseThrow();

        UsernamePasswordAuthenticationToken auth =
                AuthenticationManagerUtil.mockAuthenticationManager(authenticationManager, UserSeeder.USER);

        mockMvc.perform(delete("/hikes/{id}", hike.getId())
                        .with(authentication(auth)))
                .andDo(MockMvcResultHandlers.print())
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.i18nKey").value("hike.deleted"))
                .andExpect(jsonPath("$.message").value("Hike successfully deleted."));
    }

    @Test
    void shouldReturnForbidden_WhenNonOwnerSoftDeletesHike() throws Exception {
        Hike hike = hikeRepository.findAll().stream()
                .filter(h -> UserSeeder.USER.getId().equals(h.getUserId()))
                .findFirst()
                .orElseThrow();

        // Utilisateur différent du propriétaire
        UserDTO anotherUser = new UserDTO();
        anotherUser.setId(999L);
        anotherUser.setRoles(List.of(fr.naavi.core.enums.RoleEnum.ROLE_USER));

        UsernamePasswordAuthenticationToken auth =
                AuthenticationManagerUtil.mockAuthenticationManager(authenticationManager, anotherUser);

        mockMvc.perform(delete("/hikes/{id}", hike.getId())
                        .with(authentication(auth)))
                .andDo(MockMvcResultHandlers.print())
                .andExpect(status().isForbidden())
                .andExpect(jsonPath("$.i18nKey").value("hike.forbidden"))
                .andExpect(jsonPath("$.message").value("You are not allowed to delete this hike."));
    }

    @Test
    void shouldSetStatusToDeleted_WhenOwnerSoftDeletesHike() throws Exception {
        Hike hike = hikeRepository.findAll().stream()
                .filter(h -> UserSeeder.USER.getId().equals(h.getUserId()))
                .findFirst()
                .orElseThrow();
        Long hikeId = hike.getId();

        UsernamePasswordAuthenticationToken auth =
                AuthenticationManagerUtil.mockAuthenticationManager(authenticationManager, UserSeeder.USER);

        mockMvc.perform(delete("/hikes/{id}", hikeId)
                        .with(authentication(auth)))
                .andDo(MockMvcResultHandlers.print())
                .andExpect(status().isOk());

        Hike updated = hikeRepository.findById(hikeId).orElseThrow();
        assertEquals(fr.naavi.hike.enums.StatusEnum.DELETED, updated.getStatus());
    }

    @Test
    void shouldReturnNotFound_WhenSoftDeleteNonExistentHike() throws Exception {
        Long nonExistentId = 999999999L;

        UsernamePasswordAuthenticationToken auth =
                AuthenticationManagerUtil.mockAuthenticationManager(authenticationManager, UserSeeder.USER);

        mockMvc.perform(delete("/hikes/{id}", nonExistentId)
                        .with(authentication(auth)))
                .andDo(MockMvcResultHandlers.print())
                .andExpect(status().isNotFound())
                .andExpect(jsonPath("$.i18nKey").value("hike.not_found"))
                .andExpect(jsonPath("$.message").value("Hike not found"));
    }

    @Test
    void shouldReturnUnauthorized_WhenSoftDeleteWithoutAuthentication() throws Exception {
        Hike hike = hikeRepository.findAll().getFirst();

        mockMvc.perform(delete("/hikes/{id}", hike.getId()))
                .andDo(MockMvcResultHandlers.print())
                .andExpect(status().isUnauthorized())
                .andExpect(jsonPath("$.message").value("Unauthorized access. You must be authenticated to access this resource."));
    }

    @Test
    void shouldAddLike_WhenUserLikesHike() throws Exception {
        Hike hike = hikeRepository.findAll().getFirst();
        UsernamePasswordAuthenticationToken auth =
                AuthenticationManagerUtil.mockAuthenticationManager(authenticationManager, UserSeeder.USER);

        mockMvc.perform(post("/hikes/{id}/like", hike.getId())
                        .with(authentication(auth)))
                .andDo(MockMvcResultHandlers.print())
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.i18nKey").value("hike.like.added"))
                .andExpect(jsonPath("$.message").value("The like was successfully added."));
    }

    @Test
    void shouldRemoveLike_WhenUserLikesHikeAlreadyLiked() throws Exception {
        Hike hike = hikeRepository.findAll().getFirst();
        UsernamePasswordAuthenticationToken auth =
                AuthenticationManagerUtil.mockAuthenticationManager(authenticationManager, UserSeeder.USER);

        mockMvc.perform(post("/hikes/{id}/like", hike.getId())
                .with(authentication(auth)));

        mockMvc.perform(post("/hikes/{id}/like", hike.getId())
                        .with(authentication(auth)))
                .andDo(MockMvcResultHandlers.print())
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.i18nKey").value("hike.like.removed"))
                .andExpect(jsonPath("$.message").value("Your reaction was removed to like."));
    }

    @Test
    void shouldReturnUnauthorized_WhenLikeHikeWithoutAuthentication() throws Exception {
        Hike hike = hikeRepository.findAll().getFirst();

        mockMvc.perform(post("/hikes/{id}/like", hike.getId()))
                .andDo(MockMvcResultHandlers.print())
                .andExpect(status().isUnauthorized())
                .andExpect(jsonPath("$.message").value("Unauthorized access. You must be authenticated to access this resource."));
    }

    @Test
    void shouldReturnNotFound_WhenLikeNonExistentHike() throws Exception {
        Long nonExistentId = 999999999L;
        UsernamePasswordAuthenticationToken auth =
                AuthenticationManagerUtil.mockAuthenticationManager(authenticationManager, UserSeeder.USER);

        mockMvc.perform(post("/hikes/{id}/like", nonExistentId)
                        .with(authentication(auth)))
                .andDo(MockMvcResultHandlers.print())
                .andExpect(status().isNotFound())
                .andExpect(jsonPath("$.i18nKey").value("hike.not_found"))
                .andExpect(jsonPath("$.message").value("Hike not found"));
    }

    @Test
    void shouldAddDislike_WhenUserDislikesHike() throws Exception {
        Hike hike = hikeRepository.findAll().getFirst();
        UsernamePasswordAuthenticationToken auth =
                AuthenticationManagerUtil.mockAuthenticationManager(authenticationManager, UserSeeder.USER);

        mockMvc.perform(post("/hikes/{id}/dislike", hike.getId())
                        .with(authentication(auth)))
                .andDo(MockMvcResultHandlers.print())
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.i18nKey").value("hike.dislike.added"))
                .andExpect(jsonPath("$.message").value("The dislike was successfully added."));
    }

    @Test
    void shouldRemoveDislike_WhenUserDislikesHikeAlreadyDisliked() throws Exception {
        Hike hike = hikeRepository.findAll().getFirst();
        UsernamePasswordAuthenticationToken auth =
                AuthenticationManagerUtil.mockAuthenticationManager(authenticationManager, UserSeeder.USER);

        mockMvc.perform(post("/hikes/{id}/dislike", hike.getId())
                .with(authentication(auth)));

        mockMvc.perform(post("/hikes/{id}/dislike", hike.getId())
                        .with(authentication(auth)))
                .andDo(MockMvcResultHandlers.print())
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.i18nKey").value("hike.dislike.removed"))
                .andExpect(jsonPath("$.message").value("Your reaction was removed to dislike."));
    }

    @Test
    void shouldReturnUnauthorized_WhenDislikeHikeWithoutAuthentication() throws Exception {
        Hike hike = hikeRepository.findAll().getFirst();

        mockMvc.perform(post("/hikes/{id}/dislike", hike.getId()))
                .andDo(MockMvcResultHandlers.print())
                .andExpect(status().isUnauthorized())
                .andExpect(jsonPath("$.message").value("Unauthorized access. You must be authenticated to access this resource."));
    }

    @Test
    void shouldReturnNotFound_WhenDislikeNonExistentHike() throws Exception {
        Long nonExistentId = 999999999L;
        UsernamePasswordAuthenticationToken auth =
                AuthenticationManagerUtil.mockAuthenticationManager(authenticationManager, UserSeeder.USER);

        mockMvc.perform(post("/hikes/{id}/dislike", nonExistentId)
                        .with(authentication(auth)))
                .andDo(MockMvcResultHandlers.print())
                .andExpect(status().isNotFound())
                .andExpect(jsonPath("$.i18nKey").value("hike.not_found"))
                .andExpect(jsonPath("$.message").value("Hike not found"));
    }
}
