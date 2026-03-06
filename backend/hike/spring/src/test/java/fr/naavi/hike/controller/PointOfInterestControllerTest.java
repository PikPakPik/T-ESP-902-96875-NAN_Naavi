package fr.naavi.hike.controller;

import fr.naavi.core.exception.GlobalExceptionHandler;
import fr.naavi.hike.configuration.CacheConfigurationTest;
import fr.naavi.hike.dto.input.HikeDTO;
import fr.naavi.hike.dto.input.PointOfInterestDTO;
import fr.naavi.hike.enums.PointOfInterestCategoryEnum;
import fr.naavi.hike.repository.PointOfInterestRepository;
import fr.naavi.hike.seeder.HikeSeeder;
import fr.naavi.hike.seeder.PointOfInterestSeeder;
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
public class PointOfInterestControllerTest {
    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private UserSeeder userSeeder;

    @Autowired
    private PointOfInterestSeeder pointOfInterestSeeder;

    @Autowired
    private PointOfInterestRepository pointOfInterestRepository;

    @MockitoBean
    private AuthenticationManager authenticationManager;

    @BeforeEach
    void setUp() {
        pointOfInterestSeeder.seedPointsOfInterest();
        userSeeder.seedUsers();
    }

    /*
     * POIS ENDPOINT TESTS
     */
    @Test
    void shouldReturnPointsOfInterest_WhenRequestWithoutAuthentication() throws Exception {
        String[] coords = PointOfInterestSeeder.COORDINATES.get(0).split(",");

        mockMvc.perform(get("/pois")
                        .contentType(MediaType.APPLICATION_JSON)
                        .param("latitude", coords[1])
                        .param("longitude", coords[2]))
                .andDo(MockMvcResultHandlers.print())
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.items").isArray())
                .andExpect(jsonPath("$.totalItems").value(1))
                .andExpect(jsonPath("$.totalPages").value(1))
                .andExpect(jsonPath("$.currentPage").value(1))
                .andExpect(jsonPath("$.nextPage").doesNotExist())
                .andExpect(jsonPath("$.previousPage").doesNotExist());
    }

    @Test
    void shouldReturnPointOfInterest_WhenValidIdProvided() throws Exception {
        Long poiId = pointOfInterestRepository.findAll().getFirst().getId();

        mockMvc.perform(get("/pois/{id}", poiId)
                        .contentType(MediaType.APPLICATION_JSON))
                .andDo(MockMvcResultHandlers.print())
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.id").value(poiId))
                .andExpect(jsonPath("$.name").exists())
                .andExpect(jsonPath("$.description").exists())
                .andExpect(jsonPath("$.latitude").exists())
                .andExpect(jsonPath("$.longitude").exists());
    }

    @Test
    void shouldReturn404_WhenPointOfInterestNotFound() throws Exception {
        Long nonExistentId = 999999999L;

        mockMvc.perform(get("/pois/{id}", nonExistentId)
                        .contentType(MediaType.APPLICATION_JSON))
                .andDo(MockMvcResultHandlers.print())
                .andExpect(status().isNotFound())
                .andExpect(jsonPath("$.i18nKey").value("point_of_interest.not_found"))
                .andExpect(jsonPath("$.message").value("Point of interest not found"));
    }

    @Test
    void shouldReturn401_WhenCreatingPointOfInterestWithoutAuthentication() throws Exception {
        PointOfInterestDTO pointOfInterestDTO = DtoFactory.createDto(PointOfInterestDTO.class, Map.of(
                "name", "Nouveau POI",
                "description", "Description du nouveau POI",
                "latitude", Double.parseDouble("47.2180438348419"),
                "longitude", Double.parseDouble("-1.5549507712791397"),
                "categories", List.of(PointOfInterestCategoryEnum.ACTIVITY.name(), PointOfInterestCategoryEnum.RESTAURANT.name())
        ));

        mockMvc.perform(post("/pois")
                        .contentType(MediaType.APPLICATION_JSON)
                    .content(DtoFactory.toJson(pointOfInterestDTO)))
                .andDo(MockMvcResultHandlers.print())
                .andExpect(status().isUnauthorized());
    }

    @Test
    void shouldCreatePointOfInterest_WhenValidDataProvidedWithAuthentication() throws Exception {
        UsernamePasswordAuthenticationToken auth = AuthenticationManagerUtil.mockAuthenticationManager(authenticationManager, UserSeeder.USER);

        PointOfInterestDTO pointOfInterestDTO = DtoFactory.createDto(PointOfInterestDTO.class, Map.of(
                "name", "Nouveau POI",
                "description", "Description du nouveau POI",
                "latitude", Double.parseDouble("47.2180438348419"),
                "longitude", Double.parseDouble("-1.5549507712791397"),
                "categories", List.of(PointOfInterestCategoryEnum.ACTIVITY.name(), PointOfInterestCategoryEnum.RESTAURANT.name())
        ));

        mockMvc.perform(post("/pois")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(DtoFactory.toJson(pointOfInterestDTO))
                        .with(authentication(auth)))
                .andDo(MockMvcResultHandlers.print())
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.name").value("Nouveau POI"))
                .andExpect(jsonPath("$.description").value("Description du nouveau POI"))
                .andExpect(jsonPath("$.latitude").value(47.2180438348419))
                .andExpect(jsonPath("$.longitude").value(-1.5549507712791397))
                .andExpect(jsonPath("$.categories").isArray());
    }

    @Test
    void shouldReturn422_WhenCreatingPointOfInterestWithMissingName() throws Exception {
        UsernamePasswordAuthenticationToken auth = AuthenticationManagerUtil.mockAuthenticationManager(authenticationManager, UserSeeder.USER);

        PointOfInterestDTO pointOfInterestDTO = DtoFactory.createDto(PointOfInterestDTO.class, Map.of(
                "name", "Nouveau POI",
                "description", "Description du nouveau POI",
                "latitude", Double.parseDouble("47.2180438348419")
        ));

        mockMvc.perform(post("/pois")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(DtoFactory.toJson(pointOfInterestDTO))
                        .with(authentication(auth)))
                .andDo(MockMvcResultHandlers.print())
                .andExpect(status().isUnprocessableContent());
    }

    // ---

    @Test
    void shouldReturn401_WhenUpdatingPointOfInterestWithoutAuthentication() throws Exception {
        Long poiId = pointOfInterestRepository.findAll().getFirst().getId();

        PointOfInterestDTO pointOfInterestDTO = DtoFactory.createDto(PointOfInterestDTO.class, Map.of(
                "name", "POI Modifié",
                "description", "Description modifiée",
                "latitude", Double.parseDouble("47.2180438348419"),
                "longitude", Double.parseDouble("-1.5549507712791397")
        ));

        mockMvc.perform(put("/administration/pois/{id}", poiId)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(DtoFactory.toJson(pointOfInterestDTO)))
                .andDo(MockMvcResultHandlers.print())
                .andExpect(status().isUnauthorized());
    }

    @Test
    void shouldReturn403_WhenUpdatingPointOfInterestAsNonAdmin() throws Exception {
        UsernamePasswordAuthenticationToken auth = AuthenticationManagerUtil.mockAuthenticationManager(authenticationManager, UserSeeder.USER);
        Long poiId = pointOfInterestRepository.findAll().getFirst().getId();

        PointOfInterestDTO pointOfInterestDTO = DtoFactory.createDto(PointOfInterestDTO.class, Map.of(
                "name", "POI Modifié",
                "description", "Description modifiée",
                "latitude", Double.parseDouble("47.2180438348419"),
                "longitude", Double.parseDouble("-1.5549507712791397")
        ));

        mockMvc.perform(put("/administration/pois/{id}", poiId)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(DtoFactory.toJson(pointOfInterestDTO))
                        .with(authentication(auth)))
                .andDo(MockMvcResultHandlers.print())
                .andExpect(status().isForbidden());
    }

    @Test
    void shouldUpdatePointOfInterest_WhenValidDataProvidedAsAdmin() throws Exception {
        UsernamePasswordAuthenticationToken auth = AuthenticationManagerUtil.mockAuthenticationManager(authenticationManager, UserSeeder.ADMIN);
        Long poiId = pointOfInterestRepository.findAll().getFirst().getId();

        PointOfInterestDTO pointOfInterestDTO = DtoFactory.createDto(PointOfInterestDTO.class, Map.of(
                "name", "POI Modifié",
                "description", "Description modifiée",
                "latitude", Double.parseDouble("47.2180438348419"),
                "longitude", Double.parseDouble("-1.5549507712791397"),
                "categories", List.of(PointOfInterestCategoryEnum.ACTIVITY.name())
        ));

        mockMvc.perform(put("/administration/pois/{id}", poiId)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(DtoFactory.toJson(pointOfInterestDTO))
                        .with(authentication(auth)))
                .andDo(MockMvcResultHandlers.print())
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.id").value(poiId))
                .andExpect(jsonPath("$.name").value("POI Modifié"))
                .andExpect(jsonPath("$.description").value("Description modifiée"))
                .andExpect(jsonPath("$.latitude").value(47.2180438348419))
                .andExpect(jsonPath("$.longitude").value(-1.5549507712791397));
    }

    @Test
    void shouldReturn404_WhenUpdatingNonExistentPointOfInterest() throws Exception {
        UsernamePasswordAuthenticationToken auth = AuthenticationManagerUtil.mockAuthenticationManager(authenticationManager, UserSeeder.ADMIN);
        Long nonExistentId = 999999999L;

        PointOfInterestDTO pointOfInterestDTO = DtoFactory.createDto(PointOfInterestDTO.class, Map.of(
                "name", "POI Modifié",
                "description", "Description modifiée",
                "latitude", Double.parseDouble("47.2180438348419"),
                "longitude", Double.parseDouble("-1.5549507712791397")
        ));

        mockMvc.perform(put("/administration/pois/{id}", nonExistentId)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(DtoFactory.toJson(pointOfInterestDTO))
                        .with(authentication(auth)))
                .andDo(MockMvcResultHandlers.print())
                .andExpect(status().isNotFound())
                .andExpect(jsonPath("$.i18nKey").value("point_of_interest.not_found"))
                .andExpect(jsonPath("$.message").value("Point of interest not found"));
    }

    @Test
    void shouldReturn422_WhenUpdatingPointOfInterestWithMissingName() throws Exception {
        UsernamePasswordAuthenticationToken auth = AuthenticationManagerUtil.mockAuthenticationManager(authenticationManager, UserSeeder.ADMIN);
        Long poiId = pointOfInterestRepository.findAll().getFirst().getId();

        PointOfInterestDTO pointOfInterestDTO = DtoFactory.createDto(PointOfInterestDTO.class, Map.of(
                "description", "Description modifiée",
                "latitude", Double.parseDouble("47.2180438348419"),
                "longitude", Double.parseDouble("-1.5549507712791397")
        ));

        mockMvc.perform(put("/administration/pois/{id}", poiId)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(DtoFactory.toJson(pointOfInterestDTO))
                        .with(authentication(auth)))
                .andDo(MockMvcResultHandlers.print())
                .andExpect(status().isUnprocessableEntity());
    }

    @Test
    void shouldReturn400_WhenUpdatingPointOfInterestWithInvalidCategory() throws Exception {
        UsernamePasswordAuthenticationToken auth = AuthenticationManagerUtil.mockAuthenticationManager(authenticationManager, UserSeeder.ADMIN);
        Long poiId = pointOfInterestRepository.findAll().getFirst().getId();

        PointOfInterestDTO pointOfInterestDTO = DtoFactory.createDto(PointOfInterestDTO.class, Map.of(
                "name", "POI Modifié",
                "description", "Description modifiée",
                "latitude", Double.parseDouble("47.2180438348419"),
                "longitude", Double.parseDouble("-1.5549507712791397"),
                "categories", List.of("INVALID_CATEGORY")
        ));

        mockMvc.perform(put("/administration/pois/{id}", poiId)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(DtoFactory.toJson(pointOfInterestDTO))
                        .with(authentication(auth)))
                .andDo(MockMvcResultHandlers.print())
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.i18nKey").value("point_of_interest.category_invalid"));
    }

    @Test
    void shouldReturn400_WhenUpdatingPointOfInterestWithInvalidStatus() throws Exception {
        UsernamePasswordAuthenticationToken auth = AuthenticationManagerUtil.mockAuthenticationManager(authenticationManager, UserSeeder.ADMIN);
        Long poiId = pointOfInterestRepository.findAll().getFirst().getId();

        PointOfInterestDTO pointOfInterestDTO = DtoFactory.createDto(PointOfInterestDTO.class, Map.of(
                "name", "POI Modifié",
                "description", "Description modifiée",
                "latitude", Double.parseDouble("47.2180438348419"),
                "longitude", Double.parseDouble("-1.5549507712791397"),
                "status", "INVALID_STATUS"
        ));

        mockMvc.perform(put("/administration/pois/{id}", poiId)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(DtoFactory.toJson(pointOfInterestDTO))
                        .with(authentication(auth)))
                .andDo(MockMvcResultHandlers.print())
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.i18nKey").value("point_of_interest.status_invalid"));
    }

    @Test
    void shouldReturn401_WhenDeletingPointOfInterestWithoutAuthentication() throws Exception {
        Long poiId = pointOfInterestRepository.findAll().getFirst().getId();

        mockMvc.perform(delete("/administration/pois/{id}", poiId)
                        .contentType(MediaType.APPLICATION_JSON))
                .andDo(MockMvcResultHandlers.print())
                .andExpect(status().isUnauthorized());
    }

    @Test
    void shouldReturn403_WhenDeletingPointOfInterestAsNonAdmin() throws Exception {
        UsernamePasswordAuthenticationToken auth = AuthenticationManagerUtil.mockAuthenticationManager(authenticationManager, UserSeeder.USER);
        Long poiId = pointOfInterestRepository.findAll().getFirst().getId();

        mockMvc.perform(delete("/administration/pois/{id}", poiId)
                        .contentType(MediaType.APPLICATION_JSON)
                        .with(authentication(auth)))
                .andDo(MockMvcResultHandlers.print())
                .andExpect(status().isForbidden());
    }

    @Test
    void shouldDeletePointOfInterest_WhenValidIdProvidedAsAdmin() throws Exception {
        UsernamePasswordAuthenticationToken auth = AuthenticationManagerUtil.mockAuthenticationManager(authenticationManager, UserSeeder.ADMIN);
        Long poiId = pointOfInterestRepository.findAll().getFirst().getId();

        mockMvc.perform(delete("/administration/pois/{id}", poiId)
                        .contentType(MediaType.APPLICATION_JSON)
                        .with(authentication(auth)))
                .andDo(MockMvcResultHandlers.print())
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.i18nKey").value("point_of_interest.deleted"))
                .andExpect(jsonPath("$.message").value("Point of interest successfully deleted"));
    }

    @Test
    void shouldReturn404_WhenDeletingNonExistentPointOfInterest() throws Exception {
        UsernamePasswordAuthenticationToken auth = AuthenticationManagerUtil.mockAuthenticationManager(authenticationManager, UserSeeder.ADMIN);
        Long nonExistentId = 999999999L;

        mockMvc.perform(delete("/administration/pois/{id}", nonExistentId)
                        .contentType(MediaType.APPLICATION_JSON)
                        .with(authentication(auth)))
                .andDo(MockMvcResultHandlers.print())
                .andExpect(status().isNotFound())
                .andExpect(jsonPath("$.i18nKey").value("point_of_interest.not_found"))
                .andExpect(jsonPath("$.message").value("Point of interest not found"));
    }
}
