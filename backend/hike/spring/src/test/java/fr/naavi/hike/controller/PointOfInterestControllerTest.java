package fr.naavi.hike.controller;

import fr.naavi.core.enums.S3Enum;
import fr.naavi.core.exception.GlobalExceptionHandler;
import fr.naavi.core.service.S3Service;
import fr.naavi.hike.configuration.CacheConfigurationTest;
import fr.naavi.hike.dto.input.HikeDTO;
import fr.naavi.hike.dto.input.PointOfInterestDTO;
import fr.naavi.hike.entity.Hike;
import fr.naavi.hike.entity.Media;
import fr.naavi.hike.entity.PointOfInterest;
import fr.naavi.hike.enums.PointOfInterestCategoryEnum;
import fr.naavi.hike.repository.MediaRepository;
import fr.naavi.hike.repository.PointOfInterestRepository;
import fr.naavi.hike.seeder.HikeSeeder;
import fr.naavi.hike.seeder.PointOfInterestSeeder;
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

import java.util.List;
import java.util.Map;

import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.authentication;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.multipart;
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

    @Autowired
    private MediaRepository mediaRepository;

    @MockitoBean
    private S3Service s3Service;

    @Autowired
    private JdbcTemplate jdbcTemplate;

    @BeforeEach
    void setUp() {
        jdbcTemplate.execute("DELETE FROM hikes_images");

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
    void shouldUploadImage_WithUnauthenticatedUser_ReturnsUnauthorized() throws Exception {
        PointOfInterest poi = pointOfInterestRepository.findAll().getFirst();

        MockMultipartFile image = new MockMultipartFile(
                "image", "photo.png", "image/png", "fake-image-content".getBytes()
        );

        mockMvc.perform(multipart("/pois/{id}/images", poi.getId()).file(image))
                .andDo(MockMvcResultHandlers.print())
                .andExpect(status().isUnauthorized());
    }

    @Test
    void shouldUploadImage_WithEmptyFile_ReturnsBadRequest() throws Exception {
        PointOfInterest poi = pointOfInterestRepository.findAll().getFirst();
        UsernamePasswordAuthenticationToken authToken = AuthenticationManagerUtil.mockAuthenticationManager(authenticationManager, UserSeeder.USER);

        MockMultipartFile image = new MockMultipartFile(
                "image", "photo.png", "image/png", new byte[0]
        );

        mockMvc.perform(multipart("/pois/{id}/images", poi.getId())
                        .file(image)
                        .with(authentication(authToken)))
                .andDo(MockMvcResultHandlers.print())
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.i18nKey").value("point_of_interest.image.invalid_file"))
                .andExpect(jsonPath("$.message").value("The file is empty or invalid."));
    }

    @Test
    void shouldUploadImage_WithInvalidContentType_ReturnsBadRequest() throws Exception {
        PointOfInterest poi = pointOfInterestRepository.findAll().getFirst();
        UsernamePasswordAuthenticationToken authToken = AuthenticationManagerUtil.mockAuthenticationManager(authenticationManager, UserSeeder.USER);

        MockMultipartFile image = new MockMultipartFile(
                "image", "document.pdf", "application/pdf", "fake-pdf-content".getBytes()
        );

        mockMvc.perform(multipart("/pois/{id}/images", poi.getId())
                        .file(image)
                        .with(authentication(authToken)))
                .andDo(MockMvcResultHandlers.print())
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.i18nKey").value("point_of_interest.image.invalid_file"))
                .andExpect(jsonPath("$.message").value("Only image files are allowed."));
    }

    @Test
    void shouldUploadImage_WithValidFile_ReturnsSuccess() throws Exception {
        PointOfInterest poi = pointOfInterestRepository.findAll().getFirst();
        UsernamePasswordAuthenticationToken authToken = AuthenticationManagerUtil.mockAuthenticationManager(authenticationManager, UserSeeder.USER);

        MockMultipartFile image = new MockMultipartFile(
                "image", "photo.png", "image/png", "fake-image-content".getBytes()
        );

        mockMvc.perform(multipart("/pois/{id}/images", poi.getId())
                        .file(image)
                        .with(authentication(authToken)))
                .andDo(MockMvcResultHandlers.print())
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.i18nKey").value("point_of_interest.image.uploaded"))
                .andExpect(jsonPath("$.message").value("The image was successfully uploaded."));
    }

    @Test
    void shouldUploadImage_WhenS3Fails_ReturnsBadRequest() throws Exception {
        PointOfInterest poi = pointOfInterestRepository.findAll().getFirst();
        UsernamePasswordAuthenticationToken authToken = AuthenticationManagerUtil.mockAuthenticationManager(authenticationManager, UserSeeder.USER);

        Mockito.doThrow(new RuntimeException("S3 unavailable"))
                .when(s3Service).upload(Mockito.any(S3Enum.class), Mockito.any(), Mockito.anyString(), Mockito.any());

        MockMultipartFile image = new MockMultipartFile(
                "image", "photo.png", "image/png", "fake-image-content".getBytes()
        );

        mockMvc.perform(multipart("/pois/{id}/images", poi.getId())
                        .file(image)
                        .with(authentication(authToken)))
                .andDo(MockMvcResultHandlers.print())
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.i18nKey").value("point_of_interest.image.failed_upload"))
                .andExpect(jsonPath("$.message").value("Failed to upload the image. Please try again later."));
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

    @Test
    @Transactional
    void shouldDeleteImage_WithAdmin_WhenHikeAndMediaExist() throws Exception {
        PointOfInterest poi = pointOfInterestRepository.findAll().getFirst();

        Media media = new Media();
        media.setFilename("test-image.jpg");
        media.setUser(UserSeeder.ADMIN.getId());
        media = mediaRepository.save(media);
        poi.getImages().add(media);
        pointOfInterestRepository.save(poi);

        UsernamePasswordAuthenticationToken auth = AuthenticationManagerUtil.mockAuthenticationManager(authenticationManager, UserSeeder.ADMIN);

        mockMvc.perform(delete("/administration/pois/{hikeId}/images/{imageId}", poi.getId(), media.getId())
                        .with(authentication(auth)))
                .andDo(MockMvcResultHandlers.print())
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.i18nKey").value("point_of_interest.image.deleted"))
                .andExpect(jsonPath("$.message").value("The image was successfully deleted."));
    }

    @Test
    void shouldReturnNotFound_WhenHikeDoesNotExistOnDeleteImage() throws Exception {
        Long nonExistentHikeId = 999999999L;
        Long anyImageId = 1L;

        UsernamePasswordAuthenticationToken auth = AuthenticationManagerUtil.mockAuthenticationManager(authenticationManager, UserSeeder.ADMIN);

        mockMvc.perform(delete("/administration/pois/{hikeId}/images/{imageId}", nonExistentHikeId, anyImageId)
                        .with(authentication(auth)))
                .andDo(MockMvcResultHandlers.print())
                .andExpect(status().isNotFound())
                .andExpect(jsonPath("$.i18nKey").value("point_of_interest.not_found"))
                .andExpect(jsonPath("$.message").value("Point of interest not found"))
                .andExpect(jsonPath("$.extra").doesNotExist());
    }

    @Test
    @Transactional
    void shouldReturnNotFound_WhenMediaDoesNotExistOnDeleteImage() throws Exception {
        PointOfInterest poi = pointOfInterestRepository.findAll().getFirst();
        Long nonExistentMediaId = 999999999L;

        UsernamePasswordAuthenticationToken auth = AuthenticationManagerUtil.mockAuthenticationManager(authenticationManager, UserSeeder.ADMIN);

        mockMvc.perform(delete("/administration/pois/{poiId}/images/{imageId}", poi.getId(), nonExistentMediaId)
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
        PointOfInterest poi = pointOfInterestRepository.findAll().getFirst();

        Media media = new Media();
        media.setFilename("unlinked-image.jpg");
        media.setUser(UserSeeder.ADMIN.getId());
        media = mediaRepository.save(media);

        UsernamePasswordAuthenticationToken auth = AuthenticationManagerUtil.mockAuthenticationManager(authenticationManager, UserSeeder.ADMIN);

        mockMvc.perform(delete("/administration/pois/{poiId}/images/{imageId}", poi.getId(), media.getId())
                        .with(authentication(auth)))
                .andDo(MockMvcResultHandlers.print())
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.i18nKey").value("point_of_interest.image.not_linked"))
                .andExpect(jsonPath("$.message").value("The media is not linked to this point of interest."));
    }

    @Test
    void shouldReturnUnauthorized_WhenDeleteImageWithoutAuthentication() throws Exception {
        PointOfInterest poi = pointOfInterestRepository.findAll().getFirst();

        mockMvc.perform(delete("/administration/pois/{poiId}/images/{imageId}", poi.getId(), 1L))
                .andDo(MockMvcResultHandlers.print())
                .andExpect(status().isUnauthorized())
                .andExpect(jsonPath("$.message").value("Unauthorized access. You must be authenticated to access this resource."));
    }

    @Test
    void shouldReturnForbidden_WhenUserDeletesImageWithoutAdminRole() throws Exception {
        PointOfInterest poi = pointOfInterestRepository.findAll().getFirst();

        UsernamePasswordAuthenticationToken auth = AuthenticationManagerUtil.mockAuthenticationManager(authenticationManager, UserSeeder.USER);

        mockMvc.perform(delete("/administration/pois/{poiId}/images/{imageId}", poi.getId(), 1L)
                        .with(authentication(auth)))
                .andDo(MockMvcResultHandlers.print())
                .andExpect(status().isForbidden())
                .andExpect(jsonPath("$.message").value("Access denied. You do not have the necessary permissions to access this resource"));
    }
}
