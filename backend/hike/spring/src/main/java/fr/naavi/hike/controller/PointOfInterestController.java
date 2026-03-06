package fr.naavi.hike.controller;

import fr.naavi.core.annotation.AuthenticationNotRequired;
import fr.naavi.core.dto.ApiResponseDTO;
import fr.naavi.core.dto.PaginatorDTO;
import fr.naavi.core.enums.S3Enum;
import fr.naavi.core.exception.children.NaaviBadRequestException;
import fr.naavi.core.exception.children.NaaviNotFoundException;
import fr.naavi.core.service.S3Service;
import fr.naavi.core.validation.ValidationGroups;
import fr.naavi.hike.abstraction.AbstractController;
import fr.naavi.hike.dto.input.GeoPaginationDTO;
import fr.naavi.hike.dto.input.PointOfInterestDTO;
import fr.naavi.hike.dto.output.PointOfInterestDto;
import fr.naavi.hike.entity.Media;
import fr.naavi.hike.entity.PointOfInterest;
import fr.naavi.hike.repository.MediaRepository;
import fr.naavi.hike.repository.PointOfInterestRepository;
import fr.naavi.hike.service.MediaService;
import fr.naavi.hike.service.PointOfInterestService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.enums.SecuritySchemeIn;
import io.swagger.v3.oas.annotations.enums.SecuritySchemeType;
import io.swagger.v3.oas.annotations.media.Content;
import io.swagger.v3.oas.annotations.media.ExampleObject;
import io.swagger.v3.oas.annotations.media.Schema;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.responses.ApiResponses;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.security.SecurityScheme;
import jakarta.validation.Valid;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.util.HashSet;
import java.util.Set;

@SecurityScheme(
        type = SecuritySchemeType.HTTP,
        name = "bearerAuth",
        scheme = "bearer",
        bearerFormat = "JWT",
        paramName = "Authorization: Bearer <token>",
        in = SecuritySchemeIn.HEADER
)
@RestController
public class PointOfInterestController extends AbstractController {
    @Autowired
    private PointOfInterestRepository pointOfInterestRepository;

    @Autowired
    private MediaRepository mediaRepository;

    @Autowired
    private PointOfInterestService pointOfInterestService;

    @Autowired
    private S3Service s3Service;

    @Autowired
    private MediaService mediaService;

    /**
     * Endpoint to retrieve all points of interest.
     *
     * @param geoPaginationDTO Pagination parameters.
     * @return Paginated list of points of interest.
     */
    @Operation(
            summary = "Rechercher des point d'intérêt",
            description = "Retourner la liste des points d'intérêt",
            tags = {"Point d'intérêt"}
    )
    @ApiResponses(value = {
            @ApiResponse(
                    responseCode = "200",
                    description = "Liste paginée des points d'intérêt retournée avec succès.",
                    content = @Content(
                            mediaType = "application/json",
                            schema = @Schema(implementation = PaginatorDTO.class)
                    )
            ),
            @ApiResponse(responseCode = "422", ref = "#/components/responses/ValidationError")
    })
    @AuthenticationNotRequired
    @GetMapping("/pois")
    public PaginatorDTO<PointOfInterestDto> pointsOfInterest(@Valid @ModelAttribute GeoPaginationDTO geoPaginationDTO) {
        return this.pointOfInterestRepository.findAllPointOfInterestWithPagination(geoPaginationDTO);
    }

    /**
     * Endpoint to retrieve a specific point of interest by ID.
     *
     * @param id Point of interest ID.
     * @return Point of interest DTO.
     */
    @Operation(
            summary = "Récupérer un point d'intéret par ID",
            description = "Retourne les informations d'un point d'intérêt spécifique en fonction de son ID.",
            tags = {"Point d'intérêt"}
    )
    @ApiResponses(value = {
            @ApiResponse(
                    responseCode = "200",
                    description = "Informations du point d'intérêt",
                    content = @Content(
                            mediaType = "application/json",
                            schema = @Schema(implementation = PointOfInterestDto.class)
                    )
            ),
            @ApiResponse(
                    responseCode = "404",
                    description = "Point d'intérêt non trouvé",
                    content = @Content(
                            mediaType = "application/json",
                            schema = @Schema(
                                    implementation = ApiResponseDTO.class,
                                    example = "{"
                                            + "\"i18nKey\": \"point_of_interest.not_found\",\n"
                                            + "\"message\": \"Point of interest not found\",\n"
                                            + "\"extra\": null\n"
                                            + "}"
                            )
                    )
            )
    })
    @AuthenticationNotRequired
    @GetMapping("/pois/{id}")
    public PointOfInterestDto getPointOfInterest(@PathVariable Long id) {
        return this.pointOfInterestRepository.findById(id)
                .map(poi -> new PointOfInterestDto(poi, true))
                .orElseThrow(() -> new NaaviNotFoundException("point_of_interest.not_found", "Point of interest not found"));
    }

    /**
     * Endpoint to create a new point of interest.
     *
     * @param pointOfInterestDTO Point of interest DTO.
     * @return Created point of interest DTO.
     */
    @Operation(
            summary = "Créer un point d'intéret",
            description = "Permet a un membre de créer un nouveau point d'intérêt",
            security = @SecurityRequirement(name = "bearerAuth"),
            tags = {"Point d'intérêt"}
    )
    @ApiResponses(value = {
            @ApiResponse(
                    responseCode = "200",
                    description = "Informations du point d'intérêt",
                    content = @Content(
                            mediaType = "application/json",
                            schema = @Schema(implementation = PointOfInterestDto.class)
                    )
            ),
            @ApiResponse(
                    responseCode = "400",
                    description = "Bad request",
                    content = @Content(
                            mediaType = "application/json",
                            examples = {
                                    @ExampleObject(
                                            name = "If status is invalid",
                                            value = "{"
                                                    + "\"i18nKey\": \"point_of_interest.status_invalid\","
                                                    + "\"message\": \"The status '...' does not exist.\","
                                                    + "\"extra\": null"
                                                    + "}"
                                    ),
                                    @ExampleObject(
                                            name = "If category is invalid",
                                            value = "{"
                                                    + "\"i18nKey\": \"point_of_interest.category_invalid\","
                                                    + "\"message\": \"The category '...' does not exist.\","
                                                    + "\"extra\": null"
                                                    + "}"
                                    )
                            }
                    )
            ),
            @ApiResponse(responseCode = "401", ref = "#/components/responses/UnauthorizedError"),
            @ApiResponse(responseCode = "403", ref = "#/components/responses/AccessDeniedError"),
            @ApiResponse(responseCode = "422", ref = "#/components/responses/ValidationError")
    })
    @PostMapping("/pois")
    public PointOfInterestDto createPointOfInterest(@RequestBody @Validated(ValidationGroups.OnCreate.class) PointOfInterestDTO pointOfInterestDTO) {
        return this.pointOfInterestService.createPointOfInterest(pointOfInterestDTO);
    }

    /**
     * Endpoint to update a point of interest.
     *
     * @param id Point of interest ID.
     * @param file MultipartFile
     * @return ApiResponseDTO
     */
    @Operation(
            summary = "Uploader une image pour un point d'intérêt",
            description = "Permet à un membre d'uploader une image pour un point d'intérêt spécifique en fonction de son ID",
            security = @SecurityRequirement(name = "bearerAuth"),
            tags = {"Point d'intérêt"}
    )
    @ApiResponses(value = {
            @ApiResponse(
                    responseCode = "200",
                    description = "Image uploadée avec succès.",
                    content = @Content(
                            mediaType = "application/json",
                            schema = @Schema(
                                    implementation = ApiResponseDTO.class,
                                    example = "{"
                                            + "\"i18nKey\": \"point_of_interest.image.uploaded\","
                                            + "\"message\": \"The image was successfully uploaded.\","
                                            + "\"extra\": null"
                                            + "}"
                            )
                    )
            ),
            @ApiResponse(responseCode = "401", ref = "#/components/responses/UnauthorizedError"),
            @ApiResponse(
                    responseCode = "400",
                    description = "Bad request",
                    content = @Content(
                            mediaType = "application/json",
                            examples = {
                                    @ExampleObject(
                                            name = "If the file is too large",
                                            value = "{"
                                                    + "\"i18nKey\": \"point_of_interest.image.too_large\","
                                                    + "\"message\": \"The file exceeds the maximum size of 5MB.\","
                                                    + "\"extra\": null"
                                                    + "}"
                                    ),
                                    @ExampleObject(
                                            name = "If the file name is invalid",
                                            value = "{"
                                                    + "\"i18nKey\": \"point_of_interest.image.invalid_file\","
                                                    + "\"message\": \"The file is empty or invalid.\","
                                                    + "\"extra\": null"
                                                    + "}"
                                    ),
                                    @ExampleObject(
                                            name = "If the file format is invalid",
                                            value = "{"
                                                    + "\"i18nKey\": \"point_of_interest.image.invalid_file\","
                                                    + "\"message\": \"Only image files are allowed.\","
                                                    + "\"extra\": [\n"
                                                    + "\"image/png\",\n"
                                                    + "\"image/svg+xml\",\n"
                                                    + "\"image/jpg\",\n"
                                                    + "\"image/jpeg\",\n"
                                                    + "\"image/heic\",\n"
                                                    + "\"image/webp\"\n"
                                                    + "],\n"
                                                    + "}"
                                    ),
                                    @ExampleObject(
                                            name = "If there is an error during upload",
                                            value = "{"
                                                    + "\"i18nKey\": \"point_of_interest.image.failed_upload\","
                                                    + "\"message\": \"Failed to upload the image. Please try again later.\","
                                                    + "\"extra\": null"
                                                    + "}"
                                    )
                            }
                    )
            ),
            @ApiResponse(
                    responseCode = "404",
                    description = "Not Found",
                    content = @Content(
                            mediaType = "application/json",
                            schema = @Schema(
                                    implementation = ApiResponseDTO.class,
                                    example = "{"
                                            + "\"i18nKey\": \"point_of_interest.not_found\","
                                            + "\"message\": \"Point of interest not found.\","
                                            + "\"extra\": null"
                                            + "}"
                            )
                    )
            ),
    })
    @PostMapping("/pois/{id}/images")
    public ApiResponseDTO PointOfInterestUploadImage(@PathVariable Long id, @RequestParam("image") MultipartFile file) {
        PointOfInterest poi = this.pointOfInterestRepository.findById(id)
                .orElseThrow(() -> new NaaviNotFoundException("point_of_interest.not_found", "Point of interest not found"));

        final long MAX_SIZE = 5 * 1024 * 1024L;
        if (file.getSize() > MAX_SIZE) {
            throw new NaaviBadRequestException(
                    "point_of_interest.image.too_large",
                    "The file exceeds the maximum size of 5MB."
            );
        }

        String fileName = file.getOriginalFilename();
        if (file.isEmpty() || fileName == null) {
            throw new NaaviBadRequestException("point_of_interest.image.invalid_file", "The file is empty or invalid.");
        }

        String contentType = file.getContentType() != null ? file.getContentType().toLowerCase() : "";
        Set<String> allowedContentTypes = Set.of(
                "image/png", "image/jpeg", "image/jpg", "image/webp", "image/svg+xml", "image/heic"
        );
        if (!allowedContentTypes.contains(contentType)) {
            throw new NaaviBadRequestException("point_of_interest.image.invalid_file", "Only image files are allowed.", allowedContentTypes);
        }
        String extension = fileName.substring(fileName.lastIndexOf(".") + 1).toLowerCase();

        try {
            String toHash = fileName + "_" + System.currentTimeMillis();

            MessageDigest md = MessageDigest.getInstance("MD5");
            byte[] digest = md.digest(toHash.getBytes(StandardCharsets.UTF_8));
            StringBuilder hex = new StringBuilder();
            for (byte b : digest) {
                hex.append(String.format("%02x", b));
            }
            fileName = hex + "." + extension;

            s3Service.upload(S3Enum.POINTS_OF_INTEREST, file.getInputStream(), fileName, poi.getId().toString());
            Media media = mediaService.save(this.getUser(), fileName);
            pointOfInterestService.addMedia(poi, media);

            return new ApiResponseDTO(
                    "point_of_interest.image.uploaded",
                    "The image was successfully uploaded."
            );
        } catch (Exception e) {
            throw new NaaviBadRequestException(
                    "point_of_interest.image.failed_upload",
                    "Failed to upload the image. Please try again later."
            );
        }
    }

    //////////////////////
    /// ADMINISTRATION ///
    //////////////////////

    /**
     * Endpoint to update a point of interest.
     *
     * @param id Point of interest ID.
     * @param pointOfInterestDTO Point of interest DTO.
     * @return Updated point of interest.
     */
    @Operation(
            summary = "Mettre à jour un point d'intéret par son ID",
            description = "Permet de mettre à jour les informations d'un point d'intérêt spécifique en fonction de son ID",
            security = @SecurityRequirement(name = "bearerAuth"),
            tags = {"Administration"}
    )
    @ApiResponses(value = {
            @ApiResponse(
                    responseCode = "200",
                    description = "Informations du point d'intérêt",
                    content = @Content(
                            mediaType = "application/json",
                            schema = @Schema(implementation = PointOfInterestDto.class)
                    )
            ),
            @ApiResponse(
                    responseCode = "400",
                    description = "Bad request",
                    content = @Content(
                            mediaType = "application/json",
                            examples = {
                                    @ExampleObject(
                                            name = "If status is invalid",
                                            value = "{"
                                                    + "\"i18nKey\": \"point_of_interest.status_invalid\","
                                                    + "\"message\": \"The status '...' does not exist.\","
                                                    + "\"extra\": null"
                                                    + "}"
                                    ),
                                    @ExampleObject(
                                            name = "If category is invalid",
                                            value = "{"
                                                    + "\"i18nKey\": \"point_of_interest.category_invalid\","
                                                    + "\"message\": \"The category '...' does not exist.\","
                                                    + "\"extra\": null"
                                                    + "}"
                                    )
                            }
                    )
            ),
            @ApiResponse(responseCode = "401", ref = "#/components/responses/UnauthorizedError"),
            @ApiResponse(responseCode = "403", ref = "#/components/responses/AccessDeniedError"),
            @ApiResponse(
                    responseCode = "404",
                    description = "Point d'intérêt non trouvé",
                    content = @Content(
                            mediaType = "application/json",
                            schema = @Schema(
                                    implementation = ApiResponseDTO.class,
                                    example = "{\n"
                                            + "\"i18nKey\": \"point_of_interest.not_found\",\n"
                                            + "\"message\": \"Point of interest not found\",\n"
                                            + "\"extra\": null\n"
                                            + "}"
                            )
                    )
            ),
            @ApiResponse(responseCode = "422", ref = "#/components/responses/ValidationError")
    })
    @PreAuthorize("hasRole('ADMIN')")
    @PutMapping("/administration/pois/{id}")
    public PointOfInterestDto updatePointOfInterest(
            @PathVariable Long id,
            @RequestBody @Validated(ValidationGroups.OnUpdate.class) PointOfInterestDTO pointOfInterestDTO
    ) {
        PointOfInterest pointOfInterest = this.pointOfInterestRepository.findById(id)
                .orElseThrow(() -> new NaaviNotFoundException("point_of_interest.not_found", "Point of interest not found"));

        return this.pointOfInterestService.updatePointOfInterest(pointOfInterest, pointOfInterestDTO);
    }

    /**
     * Endpoint to delete a point of interest media.
     *
     * @param poiId Point of interest ID.
     * @param imageId Image ID.
     * @return ApiResponseDTO
     */
    @Operation(
            summary = "Supprimer une image d'un point d'intérêt",
            description = "Permet à un administrateur de supprimer une image d'un point d'intérêt spécifique en fonction de son ID",
            security = @SecurityRequirement(name = "bearerAuth"),
            tags = {"Administration"}
    )
    @ApiResponses(value = {
            @ApiResponse(
                    responseCode = "200",
                    description = "Image supprimée avec succès.",
                    content = @Content(
                            mediaType = "application/json",
                            schema = @Schema(
                                    implementation = ApiResponseDTO.class,
                                    example = "{\n"
                                            + "\"i18nKey\": \"point_of_interest.image.deleted\",\n"
                                            + "\"message\": \"The image was successfully deleted.\",\n"
                                            + "\"extra\": null\n"
                                            + "}"
                            )
                    )
            ),
            @ApiResponse(
                    responseCode = "400",
                    description = "Bad Request",
                    content = @Content(
                            mediaType = "application/json",
                            schema = @Schema(
                                    implementation = ApiResponseDTO.class,
                                    example = "{\n"
                                            + "\"i18nKey\": \"point_of_interest.image.not_linked\",\n"
                                            + "\"message\": \"The media is not linked to this point of interest.\",\n"
                                            + "\"extra\": null\n"
                                            + "}"
                            )
                    )
            ),
            @ApiResponse(responseCode = "401", ref = "#/components/responses/UnauthorizedError"),
            @ApiResponse(responseCode = "403", ref = "#/components/responses/AccessDeniedError"),
            @ApiResponse(
                    responseCode = "404",
                    description = "Not Found",
                    content = @Content(
                            mediaType = "application/json",
                            examples = {
                                    @ExampleObject(
                                            name = "If the point of interest is not found",
                                            value = "{"
                                                    + "\"i18nKey\": \"point_of_interest.not_found\","
                                                    + "\"message\": \"Point of interest not found\","
                                                    + "\"extra\": null"
                                                    + "}"
                                    ),
                                    @ExampleObject(
                                            name = "If the media is not found",
                                            value = "{"
                                                    + "\"i18nKey\": \"media.not_found\","
                                                    + "\"message\": \"Media not found\","
                                                    + "\"extra\": null"
                                                    + "}"
                                    )
                            }
                    )
            ),
    })
    @PreAuthorize("hasRole('ADMIN')")
    @DeleteMapping("/administration/pois/{poiId}/images/{imageId}")
    public ApiResponseDTO hikeDeleteImage(@PathVariable Long poiId, @PathVariable Long imageId) {
        PointOfInterest poi = this.pointOfInterestRepository.findById(poiId)
                .orElseThrow(() -> new NaaviNotFoundException("point_of_interest.not_found", "Point of interest not found"));

        Media media = this.mediaRepository.findById(imageId)
                .orElseThrow(() -> new NaaviNotFoundException("media.not_found", "Media not found"));

        boolean linked = poi.getImages().stream()
                .anyMatch(m -> m.getId().equals(media.getId()));

        if (!linked) {
            throw new NaaviBadRequestException(
                    "point_of_interest.image.not_linked",
                    "The media is not linked to this point of interest."
            );
        }

        s3Service.delete(S3Enum.POINTS_OF_INTEREST, media.getFilename(), poi.getId().toString());
        pointOfInterestService.deleteMedia(poi, media);
        mediaService.delete(media);

        return new ApiResponseDTO(
                "point_of_interest.image.deleted",
                "The image was successfully deleted."
        );
    }

    /**
     * Endpoint to delete a point of interest.
     *
     * @param id Point of interest ID.
     * @return Deleted point of interest.
     */
    @Operation(
            summary = "Supprimer un point d'intéret par son ID",
            description = "Permet de supprimer un point d'intérêt spécifique en fonction de son ID",
            security = @SecurityRequirement(name = "bearerAuth"),
            tags = {"Administration"}
    )
    @ApiResponses(value = {
            @ApiResponse(
                    responseCode = "200",
                    description = "Point d'intérêt supprimé avec succès.",
                    content = @Content(
                            mediaType = "application/json",
                            schema = @Schema(
                                    implementation = ApiResponseDTO.class,
                                    example = "{\n"
                                            + "\"i18nKey\": \"point_of_interest.deleted\",\n"
                                            + "\"message\": \"Point of interest successfully deleted\",\n"
                                            + "\"extra\": null\n"
                                            + "}"
                            )
                    )
            ),
            @ApiResponse(responseCode = "401", ref = "#/components/responses/UnauthorizedError"),
            @ApiResponse(responseCode = "403", ref = "#/components/responses/AccessDeniedError"),
            @ApiResponse(
                    responseCode = "404",
                    description = "Point d'intérêt non trouvé",
                    content = @Content(
                            mediaType = "application/json",
                            schema = @Schema(
                                    implementation = ApiResponseDTO.class,
                                    example = "{\n"
                                            + "\"i18nKey\": \"point_of_interest.not_found\",\n"
                                            + "\"message\": \"Point of interest not found\",\n"
                                            + "\"extra\": null\n"
                                            + "}"
                            )
                    )
            )
    })
    @PreAuthorize("hasRole('ADMIN')")
    @DeleteMapping("/administration/pois/{id}")
    public ApiResponseDTO deletePointOfInterest(@PathVariable Long id) {
        PointOfInterest pointOfInterest = this.pointOfInterestRepository.findById(id)
                .orElseThrow(() -> new NaaviNotFoundException("point_of_interest.not_found", "Point of interest not found"));

        for (Media media : new HashSet<>(pointOfInterest.getImages())) {
            s3Service.delete(S3Enum.POINTS_OF_INTEREST, media.getFilename(), pointOfInterest.getId().toString());
            pointOfInterestService.deleteMedia(pointOfInterest, media);
            mediaService.delete(media);
        }

        this.pointOfInterestService.deletePointOfInterest(pointOfInterest);

        return new ApiResponseDTO("point_of_interest.deleted", "Point of interest successfully deleted");
    }
}
