package fr.naavi.hike.controller;

import fr.naavi.core.enums.S3Enum;
import fr.naavi.core.exception.GlobalExceptionHandler;
import fr.naavi.core.service.S3Service;
import fr.naavi.hike.configuration.CacheConfigurationTest;
import fr.naavi.hike.dto.input.MapElementDTO;
import fr.naavi.hike.entity.MapElement;
import fr.naavi.hike.entity.Media;
import fr.naavi.hike.enums.MapElementEnum;
import fr.naavi.hike.enums.TypeMapElementEnum;
import fr.naavi.hike.repository.MapElementReactionRepository;
import fr.naavi.hike.repository.MapElementRepository;
import fr.naavi.hike.repository.MediaRepository;
import fr.naavi.hike.seeder.MapElementSeeder;
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
import java.util.Random;

import static org.hamcrest.Matchers.containsString;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.authentication;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("ci")
@TestPropertySource(locations = "classpath:application-ci.properties")
@Import({GlobalExceptionHandler.class, CacheConfigurationTest.class})
public class MapElementControllerTest {
    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private UserSeeder userSeeder;

    @Autowired
    private MapElementSeeder mapElementSeeder;

    @Autowired
    private MapElementRepository mapElementRepository;

    @Autowired
    private MapElementReactionRepository mapElementReactionRepository;

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

        mapElementReactionRepository.deleteAll();
        mapElementSeeder.seedMapElements();
        userSeeder.seedUsers();
    }

    @Test
    void shouldReturnMapElement_WhenRequestWithoutAuthentication() throws Exception {
        String[] coords = MapElementSeeder.COORDINATES.get(0).split(",");

        mockMvc.perform(get("/mapElements")
                        .contentType(MediaType.APPLICATION_JSON)
                        .param("latitude", coords[1])
                        .param("longitude", coords[2])
                        .param("type", "POINT_OF_INTEREST"))
                .andDo(MockMvcResultHandlers.print())
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.items").isArray())
                .andExpect(jsonPath("$.items[0].images").isArray())
                .andExpect(jsonPath("$.totalItems").value(1))
                .andExpect(jsonPath("$.totalPages").value(1))
                .andExpect(jsonPath("$.currentPage").value(1))
                .andExpect(jsonPath("$.nextPage").doesNotExist())
                .andExpect(jsonPath("$.previousPage").doesNotExist());
    }

    @Test
    void shouldReturnMapElement_WhenValidIdProvided() throws Exception {
        Long elementId = mapElementRepository.findAll().getFirst().getId();

        mockMvc.perform(get("/mapElement/{id}", elementId)
                        .contentType(MediaType.APPLICATION_JSON)
                        .param("type", "POINT_OF_INTEREST"))
                .andDo(MockMvcResultHandlers.print())
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.id").value(elementId))
                .andExpect(jsonPath("$.name").exists())
                .andExpect(jsonPath("$.description").exists())
                .andExpect(jsonPath("$.latitude").exists())
                .andExpect(jsonPath("$.longitude").exists())
                .andExpect(jsonPath("$.images").isArray());
    }

    @Test
    void shouldReturn404_WhenMapElementNotFound() throws Exception {
        Long nonExistentId = 999999999L;

        mockMvc.perform(get("/mapElement/{id}", nonExistentId)
                        .contentType(MediaType.APPLICATION_JSON)
                .param("type", "POINT_OF_INTEREST"))
                .andDo(MockMvcResultHandlers.print())
                .andExpect(status().isNotFound())
                .andExpect(jsonPath("$.i18nKey").value("map_element.not_found"))
                .andExpect(jsonPath("$.message").value("Map element not found"));
    }

    @Test
    void shouldUploadImage_WithUnauthenticatedUser_ReturnsUnauthorized() throws Exception {
        MapElement mapElement = mapElementRepository.findAll().getFirst();

        MockMultipartFile image = new MockMultipartFile(
                "image", "photo.png", "image/png", "fake-image-content".getBytes()
        );

        mockMvc.perform(multipart("/mapElement/{id}/images", mapElement.getId()).file(image))
                .andDo(MockMvcResultHandlers.print())
                .andExpect(status().isUnauthorized());
    }

    @Test
    void shouldUploadImage_WithEmptyFile_ReturnsBadRequest() throws Exception {
        MapElement mapElement = mapElementRepository.findAll().getFirst();
        UsernamePasswordAuthenticationToken authToken = AuthenticationManagerUtil.mockAuthenticationManager(authenticationManager, UserSeeder.USER);

        MockMultipartFile image = new MockMultipartFile(
                "image", "photo.png", "image/png", new byte[0]
        );

        mockMvc.perform(multipart("/mapElement/{id}/images", mapElement.getId())
                        .file(image)
                        .param("type", mapElement.getType().name())
                        .with(authentication(authToken)))
                .andDo(MockMvcResultHandlers.print())
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.i18nKey").value("map_element.image.invalid_file"))
                .andExpect(jsonPath("$.message").value("The file is empty or invalid."));
    }

    @Test
    void shouldUploadImage_WithInvalidContentType_ReturnsBadRequest() throws Exception {
        MapElement mapElement = mapElementRepository.findAll().getFirst();
        UsernamePasswordAuthenticationToken authToken = AuthenticationManagerUtil.mockAuthenticationManager(authenticationManager, UserSeeder.USER);

        MockMultipartFile image = new MockMultipartFile(
                "image", "document.pdf", "application/pdf", "fake-pdf-content".getBytes()
        );

        mockMvc.perform(multipart("/mapElement/{id}/images", mapElement.getId())
                        .file(image)
                        .param("type", mapElement.getType().name())
                        .with(authentication(authToken)))
                .andDo(MockMvcResultHandlers.print())
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.i18nKey").value("map_element.image.invalid_file"))
                .andExpect(jsonPath("$.message").value("Only image files are allowed."));
    }

    @Test
    void shouldUploadImage_WithValidFile_ReturnsSuccess() throws Exception {
        MapElement mapElement = mapElementRepository.findAll().getFirst();
        UsernamePasswordAuthenticationToken authToken = AuthenticationManagerUtil.mockAuthenticationManager(authenticationManager, UserSeeder.USER);

        MockMultipartFile image = new MockMultipartFile(
                "image", "photo.png", "image/png", "fake-image-content".getBytes()
        );

        mockMvc.perform(multipart("/mapElement/{id}/images", mapElement.getId())
                        .file(image)
                        .param("type", mapElement.getType().name())
                        .with(authentication(authToken)))
                .andDo(MockMvcResultHandlers.print())
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.i18nKey").value("map_element.image.uploaded"))
                .andExpect(jsonPath("$.message").value("The image was successfully uploaded."));
    }

    @Test
    void shouldExposeImagesOnGet_WhenUploadSucceeded() throws Exception {
        MapElement mapElement = mapElementRepository.findAll().getFirst();
        Long mapElementId = mapElement.getId();
        UsernamePasswordAuthenticationToken authToken = AuthenticationManagerUtil.mockAuthenticationManager(
                authenticationManager, UserSeeder.USER);

        MockMultipartFile image = new MockMultipartFile(
                "image", "photo.png", "image/png", "fake-image-content".getBytes()
        );

        mockMvc.perform(multipart("/mapElement/{id}/images", mapElementId)
                        .file(image)
                        .param("type", mapElement.getType().name())
                .with(authentication(authToken)))
                .andExpect(status().isOk());

        mockMvc.perform(get("/mapElement/{id}", mapElementId)
                        .contentType(MediaType.APPLICATION_JSON)
                        .param("type", mapElement.getType().name()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.images[0].id").exists())
                .andExpect(jsonPath("$.images[0].filename", containsString("points_of_interest/" + mapElementId + "/")));
    }

    @Test
    void shouldUploadImage_WhenS3Fails_ReturnsBadRequest() throws Exception {
        MapElement mapElement = mapElementRepository.findAll().getFirst();
        UsernamePasswordAuthenticationToken authToken = AuthenticationManagerUtil.mockAuthenticationManager(authenticationManager, UserSeeder.USER);

        Mockito.doThrow(new RuntimeException("S3 unavailable"))
                .when(s3Service).upload(Mockito.any(S3Enum.class), Mockito.any(), Mockito.anyString(), Mockito.any());

        MockMultipartFile image = new MockMultipartFile(
                "image", "photo.png", "image/png", "fake-image-content".getBytes()
        );

        mockMvc.perform(multipart("/mapElement/{id}/images", mapElement.getId())
                        .file(image)
                        .param("type", mapElement.getType().name())
                        .with(authentication(authToken)))
                .andDo(MockMvcResultHandlers.print())
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.i18nKey").value("map_element.image.failed_upload"))
                .andExpect(jsonPath("$.message").value("Failed to upload the image. Please try again later."));
    }

    @Test
    void shouldReturn401_WhenCreatingMapElementWithoutAuthentication() throws Exception {
        MapElementDTO mapElementDTO = DtoFactory.createDto(MapElementDTO.class, Map.of(
                "name", "Nouveau POI",
                "description", "Description du nouveau POI",
                "latitude", Double.parseDouble("47.2180438348419"),
                "longitude", Double.parseDouble("-1.5549507712791397"),
                "categories", List.of(MapElementEnum.ACTIVITY.name(), MapElementEnum.RESTAURANT.name())
        ));

        mockMvc.perform(post("/mapElement")
                        .contentType(MediaType.APPLICATION_JSON)
                    .content(DtoFactory.toJson(mapElementDTO)))
                .andDo(MockMvcResultHandlers.print())
                .andExpect(status().isUnauthorized());
    }

    @Test
    void shouldCreateMapElement_WhenValidDataProvidedWithAuthentication() throws Exception {
        UsernamePasswordAuthenticationToken auth = AuthenticationManagerUtil.mockAuthenticationManager(authenticationManager, UserSeeder.USER);

        MapElementDTO mapElementDTO = DtoFactory.createDto(MapElementDTO.class, Map.of(
                "name", "Nouveau POI",
                "description", "Description du nouveau POI",
                "latitude", Double.parseDouble("47.2180438348419"),
                "longitude", Double.parseDouble("-1.5549507712791397"),
                "type","POINT_OF_INTEREST",
                "categories", List.of(MapElementEnum.ACTIVITY.name(), MapElementEnum.RESTAURANT.name())
        ));

        mockMvc.perform(post("/mapElement")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(DtoFactory.toJson(mapElementDTO))
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
    void shouldReturn422_WhenCreatingMapElementWithMissingName() throws Exception {
        UsernamePasswordAuthenticationToken auth = AuthenticationManagerUtil.mockAuthenticationManager(authenticationManager, UserSeeder.USER);

        MapElementDTO mapElementDTO = DtoFactory.createDto(MapElementDTO.class, Map.of(
                "description", "Description du nouveau POI",
                "type","POINT_OF_INTEREST",
                "latitude", Double.parseDouble("47.2180438348419")
        ));

        mockMvc.perform(post("/mapElement")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(DtoFactory.toJson(mapElementDTO))
                        .with(authentication(auth)))
                .andDo(MockMvcResultHandlers.print())
                .andExpect(status().isUnprocessableContent());
    }

    @Test
    void shouldReturn401_WhenUpdatingMapElementWithoutAuthentication() throws Exception {
        Long elementId = mapElementRepository.findAll().getFirst().getId();

        MapElementDTO mapElementDTO = DtoFactory.createDto(MapElementDTO.class, Map.of(
                "name", "POI Modifié",
                "description", "Description modifiée",
                "latitude", Double.parseDouble("47.2180438348419"),
                "longitude", Double.parseDouble("-1.5549507712791397"),
                "type","POINT_OF_INTEREST"
        ));

        mockMvc.perform(put("/administration/mapElement/{id}", elementId)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(DtoFactory.toJson(mapElementDTO)))
                .andDo(MockMvcResultHandlers.print())
                .andExpect(status().isUnauthorized());
    }

    @Test
    void shouldReturn403_WhenUpdatingMapElementAsNonAdmin() throws Exception {
        UsernamePasswordAuthenticationToken auth = AuthenticationManagerUtil.mockAuthenticationManager(authenticationManager, UserSeeder.USER);
        Long elementId = mapElementRepository.findAll().getFirst().getId();

        MapElementDTO mapElementDTO = DtoFactory.createDto(MapElementDTO.class, Map.of(
                "name", "POI Modifié",
                "description", "Description modifiée",
                "latitude", Double.parseDouble("47.2180438348419"),
                "longitude", Double.parseDouble("-1.5549507712791397"),
                "type","POINT_OF_INTEREST"
        ));

        mockMvc.perform(put("/administration/mapElement/{id}", elementId)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(DtoFactory.toJson(mapElementDTO))
                        .with(authentication(auth)))
                .andDo(MockMvcResultHandlers.print())
                .andExpect(status().isForbidden());
    }

    @Test
    void shouldUpdateMapElement_WhenValidDataProvidedAsAdmin() throws Exception {
        UsernamePasswordAuthenticationToken auth = AuthenticationManagerUtil.mockAuthenticationManager(authenticationManager, UserSeeder.ADMIN);
        Long elementId = mapElementRepository.findAll().getFirst().getId();

        MapElementDTO mapElementDTO = DtoFactory.createDto(MapElementDTO.class, Map.of(
                "name", "POI Modifié",
                "description", "Description modifiée",
                "latitude", Double.parseDouble("47.2180438348419"),
                "longitude", Double.parseDouble("-1.5549507712791397"),
                "type","POINT_OF_INTEREST",
                "categories", List.of(MapElementEnum.ACTIVITY.name())
        ));

        mockMvc.perform(put("/administration/mapElement/{id}", elementId)
                        .param("type", "POINT_OF_INTEREST")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(DtoFactory.toJson(mapElementDTO))
                        .with(authentication(auth)))
                .andDo(MockMvcResultHandlers.print())
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.id").value(elementId))
                .andExpect(jsonPath("$.name").value("POI Modifié"))
                .andExpect(jsonPath("$.description").value("Description modifiée"))
                .andExpect(jsonPath("$.latitude").value(47.2180438348419))
                .andExpect(jsonPath("$.longitude").value(-1.5549507712791397));
    }

    @Test
    void shouldReturn404_WhenUpdatingNonExistentMapElement() throws Exception {
        UsernamePasswordAuthenticationToken auth = AuthenticationManagerUtil.mockAuthenticationManager(authenticationManager, UserSeeder.ADMIN);
        Long nonExistentId = 999999999L;

        MapElementDTO mapElementDTO = DtoFactory.createDto(MapElementDTO.class, Map.of(
                "name", "POI Modifié",
                "description", "Description modifiée",
                "type","POINT_OF_INTEREST",
                "latitude", Double.parseDouble("47.2180438348419"),
                "longitude", Double.parseDouble("-1.5549507712791397")
        ));

        mockMvc.perform(put("/administration/mapElement/{id}", nonExistentId)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(DtoFactory.toJson(mapElementDTO))
                        .with(authentication(auth)))
                .andDo(MockMvcResultHandlers.print())
                .andExpect(status().isNotFound())
                .andExpect(jsonPath("$.i18nKey").value("map_element.not_found"))
                .andExpect(jsonPath("$.message").value("Map element not found"));
    }

    @Test
    void shouldReturn422_WhenUpdatingMapElementWithMissingName() throws Exception {
        UsernamePasswordAuthenticationToken auth = AuthenticationManagerUtil.mockAuthenticationManager(authenticationManager, UserSeeder.ADMIN);
        Long elementId = mapElementRepository.findAll().getFirst().getId();

        MapElementDTO mapElementDTO = DtoFactory.createDto(MapElementDTO.class, Map.of(
                "description", "Description modifiée",
                "latitude", Double.parseDouble("47.2180438348419"),
                "longitude", Double.parseDouble("-1.5549507712791397"),
                "type","POINT_OF_INTEREST"
        ));

        mockMvc.perform(put("/administration/mapElement/{id}", elementId)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(DtoFactory.toJson(mapElementDTO))
                        .with(authentication(auth)))
                .andDo(MockMvcResultHandlers.print())
                .andExpect(status().isUnprocessableEntity());
    }

    @Test
    void shouldReturn400_WhenUpdatingMapElementWithInvalidCategory() throws Exception {
        UsernamePasswordAuthenticationToken auth = AuthenticationManagerUtil.mockAuthenticationManager(authenticationManager, UserSeeder.ADMIN);
        Long elementId = mapElementRepository.findAll().getFirst().getId();

        MapElementDTO mapElementDTO = DtoFactory.createDto(MapElementDTO.class, Map.of(
                "name", "POI Modifié",
                "description", "Description modifiée",
                "latitude", Double.parseDouble("47.2180438348419"),
                "longitude", Double.parseDouble("-1.5549507712791397"),
                "type","POINT_OF_INTEREST",
                "categories", List.of("INVALID_CATEGORY")
        ));

        mockMvc.perform(put("/administration/mapElement/{id}", elementId)
                        .param("type", "POINT_OF_INTEREST")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(DtoFactory.toJson(mapElementDTO))
                        .with(authentication(auth)))
                .andDo(MockMvcResultHandlers.print())
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.i18nKey").value("map_element.category_invalid"));
    }

    @Test
    void shouldReturn400_WhenUpdatingMapElementWithInvalidStatus() throws Exception {
        UsernamePasswordAuthenticationToken auth = AuthenticationManagerUtil.mockAuthenticationManager(authenticationManager, UserSeeder.ADMIN);
        Long elementId = mapElementRepository.findAll().getFirst().getId();

        MapElementDTO mapElementDTO = DtoFactory.createDto(MapElementDTO.class, Map.of(
                "name", "POI Modifié",
                "description", "Description modifiée",
                "latitude", Double.parseDouble("47.2180438348419"),
                "longitude", Double.parseDouble("-1.5549507712791397"),
                "type","POINT_OF_INTEREST",
                "status", "INVALID_STATUS"
        ));

        mockMvc.perform(put("/administration/mapElement/{id}", elementId)
                        .param("type", "POINT_OF_INTEREST")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(DtoFactory.toJson(mapElementDTO))
                        .with(authentication(auth)))
                .andDo(MockMvcResultHandlers.print())
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.i18nKey").value("map_element.status_invalid"));
    }

    @Test
    void shouldReturn401_WhenDeletingMapElementWithoutAuthentication() throws Exception {
        Long elementId = mapElementRepository.findAll().getFirst().getId();

        mockMvc.perform(delete("/administration/mapElement/{id}", elementId)
                        .contentType(MediaType.APPLICATION_JSON))
                .andDo(MockMvcResultHandlers.print())
                .andExpect(status().isUnauthorized());
    }

    @Test
    void shouldReturn403_WhenDeletingMapElementAsNonAdmin() throws Exception {
        UsernamePasswordAuthenticationToken auth = AuthenticationManagerUtil.mockAuthenticationManager(authenticationManager, UserSeeder.USER);
        Long elementId = mapElementRepository.findAll().getFirst().getId();

        mockMvc.perform(delete("/administration/mapElement/{id}", elementId)
                        .param("type", "POINT_OF_INTEREST")
                        .contentType(MediaType.APPLICATION_JSON)
                        .with(authentication(auth)))
                .andDo(MockMvcResultHandlers.print())
                .andExpect(status().isForbidden());
    }

    @Test
    void shouldDeleteMapElement_WhenValidIdProvidedAsAdmin() throws Exception {
        UsernamePasswordAuthenticationToken auth = AuthenticationManagerUtil.mockAuthenticationManager(authenticationManager, UserSeeder.ADMIN);
        Long elementId = mapElementRepository.findAll().getFirst().getId();

        mockMvc.perform(delete("/administration/mapElement/{id}", elementId)
                        .contentType(MediaType.APPLICATION_JSON)
                        .param("type", "POINT_OF_INTEREST")
                        .with(authentication(auth)))
                .andDo(MockMvcResultHandlers.print())
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.i18nKey").value("map_element.deleted"))
                .andExpect(jsonPath("$.message").value("Map element successfully deleted"));
    }

    @Test
    void shouldReturn404_WhenDeletingNonExistentMapElement() throws Exception {
        UsernamePasswordAuthenticationToken auth = AuthenticationManagerUtil.mockAuthenticationManager(authenticationManager, UserSeeder.ADMIN);
        Long nonExistentId = 999999999L;

        mockMvc.perform(delete("/administration/mapElement/{id}", nonExistentId)
                        .param("type", "POINT_OF_INTEREST")
                        .contentType(MediaType.APPLICATION_JSON)
                        .with(authentication(auth)))
                .andDo(MockMvcResultHandlers.print())
                .andExpect(status().isNotFound())
                .andExpect(jsonPath("$.i18nKey").value("map_element.not_found"))
                .andExpect(jsonPath("$.message").value("Map element not found"));
    }

    @Test
    @Transactional
    void shouldDeleteImage_WithAdmin_WhenHikeAndMediaExist() throws Exception {
        MapElement mapElement = mapElementRepository.findAll().getFirst();

        Media media = new Media();
        media.setFilename("test-image.jpg");
        media.setUser(UserSeeder.ADMIN.getId());
        media = mediaRepository.save(media);
        mapElement.getImages().add(media);
        mapElementRepository.save(mapElement);

        UsernamePasswordAuthenticationToken auth = AuthenticationManagerUtil.mockAuthenticationManager(authenticationManager, UserSeeder.ADMIN);

        mockMvc.perform(delete("/administration/mapElement/{hikeId}/images/{imageId}", mapElement.getId(), media.getId())
                        .param("type", mapElement.getType().name())
                        .with(authentication(auth)))
                .andDo(MockMvcResultHandlers.print())
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.i18nKey").value("map_element.image.deleted"))
                .andExpect(jsonPath("$.message").value("The image was successfully deleted"));
    }

    @Test
    void shouldReturnNotFound_WhenHikeDoesNotExistOnDeleteImage() throws Exception {
        MapElement mapElement = mapElementRepository.findAll().getFirst();
        Long nonExistentHikeId = 999999999L;
        Long anyImageId = 1L;

        UsernamePasswordAuthenticationToken auth = AuthenticationManagerUtil.mockAuthenticationManager(authenticationManager, UserSeeder.ADMIN);

        mockMvc.perform(delete("/administration/mapElement/{hikeId}/images/{imageId}", nonExistentHikeId, anyImageId)
                        .param("type", mapElement.getType().name())
                        .with(authentication(auth)))
                .andDo(MockMvcResultHandlers.print())
                .andExpect(status().isNotFound())
                .andExpect(jsonPath("$.i18nKey").value("map_element.not_found"))
                .andExpect(jsonPath("$.message").value("Map element not found"))
                .andExpect(jsonPath("$.extra").doesNotExist());
    }

    @Test
    @Transactional
    void shouldReturnNotFound_WhenMediaDoesNotExistOnDeleteImage() throws Exception {
        MapElement mapElement = mapElementRepository.findAll().getFirst();
        Long nonExistentMediaId = 999999999L;

        UsernamePasswordAuthenticationToken auth = AuthenticationManagerUtil.mockAuthenticationManager(authenticationManager, UserSeeder.ADMIN);

        mockMvc.perform(delete("/administration/mapElement/{elementId}/images/{imageId}", mapElement.getId(), nonExistentMediaId)
                        .param("type", mapElement.getType().name())
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
        MapElement mapElement = mapElementRepository.findAll().getFirst();

        Media media = new Media();
        media.setFilename("unlinked-image.jpg");
        media.setUser(UserSeeder.ADMIN.getId());
        media = mediaRepository.save(media);

        UsernamePasswordAuthenticationToken auth = AuthenticationManagerUtil.mockAuthenticationManager(authenticationManager, UserSeeder.ADMIN);

        mockMvc.perform(delete("/administration/mapElement/{elementId}/images/{imageId}", mapElement.getId(), media.getId())
                        .param("type", mapElement.getType().name())
                        .with(authentication(auth)))
                .andDo(MockMvcResultHandlers.print())
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.i18nKey").value("map_element.image.not_linked"))
                .andExpect(jsonPath("$.message").value("The media is not linked to this element."));
    }

    @Test
    void shouldReturnUnauthorized_WhenDeleteImageWithoutAuthentication() throws Exception {
        MapElement mapElement = mapElementRepository.findAll().getFirst();

        mockMvc.perform(delete("/administration/mapElement/{elementId}/images/{imageId}", mapElement.getId(), 1L)
                        .param("type", mapElement.getType().name()))
                .andDo(MockMvcResultHandlers.print())
                .andExpect(status().isUnauthorized())
                .andExpect(jsonPath("$.message").value("Unauthorized access. You must be authenticated to access this resource."));
    }

    @Test
    void shouldReturnForbidden_WhenUserDeletesImageWithoutAdminRole() throws Exception {
        MapElement mapElement = mapElementRepository.findAll().getFirst();

        UsernamePasswordAuthenticationToken auth = AuthenticationManagerUtil.mockAuthenticationManager(authenticationManager, UserSeeder.USER);

        mockMvc.perform(delete("/administration/mapElement/{elementId}/images/{imageId}", mapElement.getId(), 1L)
                        .param("type", mapElement.getType().name())
                        .with(authentication(auth)))
                .andDo(MockMvcResultHandlers.print())
                .andExpect(status().isForbidden())
                .andExpect(jsonPath("$.message").value("Access denied. You do not have the necessary permissions to access this resource"));
    }

    @Test
    void shouldAddLike_WhenUserLikesMapElement() throws Exception {
        MapElement mapElement = mapElementRepository.findAll().getFirst();
        UsernamePasswordAuthenticationToken auth =
                AuthenticationManagerUtil.mockAuthenticationManager(authenticationManager, UserSeeder.USER);

        mockMvc.perform(post("/mapElement/{id}/like", mapElement.getId())
                        .param("type", mapElement.getType().name())
                        .with(authentication(auth)))
                .andDo(MockMvcResultHandlers.print())
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.i18nKey").value("map_element.like.added"))
                .andExpect(jsonPath("$.message").value("The like was successfully added."));
    }

    @Test
    void shouldRemoveLike_WhenUserLikesMapElementAlreadyLiked() throws Exception {
        MapElement mapElement = mapElementRepository.findAll().getFirst();
        UsernamePasswordAuthenticationToken auth =
                AuthenticationManagerUtil.mockAuthenticationManager(authenticationManager, UserSeeder.USER);

        mockMvc.perform(post("/mapElement/{id}/like", mapElement.getId())
                .param("type", mapElement.getType().name())
                .with(authentication(auth)));

        mockMvc.perform(post("/mapElement/{id}/like", mapElement.getId())
                        .param("type", mapElement.getType().name())
                        .with(authentication(auth)))
                .andDo(MockMvcResultHandlers.print())
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.i18nKey").value("map_element.like.removed"))
                .andExpect(jsonPath("$.message").value("Your reaction was removed to like."));
    }

    @Test
    void shouldReturnUnauthorized_WhenLikeMapElementWithoutAuthentication() throws Exception {
        MapElement mapElement = mapElementRepository.findAll().getFirst();

        mockMvc.perform(post("/mapElement/{id}/like", mapElement.getId()))
                .andDo(MockMvcResultHandlers.print())
                .andExpect(status().isUnauthorized())
                .andExpect(jsonPath("$.message").value("Unauthorized access. You must be authenticated to access this resource."));
    }

    @Test
    void shouldReturnNotFound_WhenLikeNonExistentMapElement() throws Exception {
        Long nonExistentId = 999999999L;
        UsernamePasswordAuthenticationToken auth =
                AuthenticationManagerUtil.mockAuthenticationManager(authenticationManager, UserSeeder.USER);
        TypeMapElementEnum[] types = {TypeMapElementEnum.ALERT, TypeMapElementEnum.POINT_OF_INTEREST};
        TypeMapElementEnum randomType = types[new Random().nextInt(types.length)];

        mockMvc.perform(post("/mapElement/{id}/like", nonExistentId)
                        .param("type", randomType.name())
                        .with(authentication(auth)))
                .andDo(MockMvcResultHandlers.print())
                .andExpect(status().isNotFound())
                .andExpect(jsonPath("$.i18nKey").value("map_element.not_found"))
                .andExpect(jsonPath("$.message").value("Map element not found"));
    }

    @Test
    void shouldAddDislike_WhenUserDislikesMapElement() throws Exception {
        MapElement mapElement = mapElementRepository.findAll().getFirst();
        UsernamePasswordAuthenticationToken auth =
                AuthenticationManagerUtil.mockAuthenticationManager(authenticationManager, UserSeeder.USER);

        mockMvc.perform(post("/mapElement/{id}/dislike", mapElement.getId())
                        .param("type", mapElement.getType().name())
                        .with(authentication(auth)))
                .andDo(MockMvcResultHandlers.print())
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.i18nKey").value("map_element.dislike.added"))
                .andExpect(jsonPath("$.message").value("The dislike was successfully added."));
    }

    @Test
    void shouldRemoveDislike_WhenUserDislikesMapElementAlreadyDisliked() throws Exception {
        MapElement mapElement = mapElementRepository.findAll().getFirst();
        UsernamePasswordAuthenticationToken auth =
                AuthenticationManagerUtil.mockAuthenticationManager(authenticationManager, UserSeeder.USER);

        mockMvc.perform(post("/mapElement/{id}/dislike", mapElement.getId())
                .param("type", mapElement.getType().name())
                .with(authentication(auth)));

        mockMvc.perform(post("/mapElement/{id}/dislike", mapElement.getId())
                        .param("type", mapElement.getType().name())
                        .with(authentication(auth)))
                .andDo(MockMvcResultHandlers.print())
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.i18nKey").value("map_element.dislike.removed"))
                .andExpect(jsonPath("$.message").value("Your reaction was removed to dislike."));
    }

    @Test
    void shouldReturnUnauthorized_WhenDislikeMapElementWithoutAuthentication() throws Exception {
        MapElement mapElement = mapElementRepository.findAll().getFirst();

        mockMvc.perform(post("/mapElement/{id}/dislike", mapElement.getId()))
                .andDo(MockMvcResultHandlers.print())
                .andExpect(status().isUnauthorized())
                .andExpect(jsonPath("$.message").value("Unauthorized access. You must be authenticated to access this resource."));
    }

    @Test
    void shouldReturnNotFound_WhenDislikeNonExistentMapElement() throws Exception {
        Long nonExistentId = 999999999L;
        UsernamePasswordAuthenticationToken auth =
                AuthenticationManagerUtil.mockAuthenticationManager(authenticationManager, UserSeeder.USER);
        TypeMapElementEnum[] types = {TypeMapElementEnum.ALERT, TypeMapElementEnum.POINT_OF_INTEREST};
        TypeMapElementEnum randomType = types[new Random().nextInt(types.length)];

        mockMvc.perform(post("/mapElement/{id}/dislike", nonExistentId)
                        .param("type", randomType.name())
                        .with(authentication(auth)))
                .andDo(MockMvcResultHandlers.print())
                .andExpect(status().isNotFound())
                .andExpect(jsonPath("$.i18nKey").value("map_element.not_found"))
                .andExpect(jsonPath("$.message").value("Map element not found"));
    }
}
