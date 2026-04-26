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
import fr.naavi.hike.dto.input.MapElementDTO;
import fr.naavi.hike.dto.input.PointOfInterestAdministrationPaginationDTO;
import fr.naavi.hike.dto.output.MapElementDto;
import fr.naavi.hike.entity.MapElement;
import fr.naavi.hike.entity.Media;
import fr.naavi.hike.enums.ReactionEnum;
import fr.naavi.hike.enums.TypeMapElementEnum;
import fr.naavi.hike.repository.MapElementReactionRepository;
import fr.naavi.hike.repository.MediaRepository;
import fr.naavi.hike.repository.interfaces.MapElementRepositoryInterface;
import fr.naavi.hike.service.MapElementService;
import fr.naavi.hike.service.MediaService;
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
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.util.HashSet;
import java.util.List;
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
public class MapElementController extends AbstractController {
    private final MapElementRepositoryInterface mapElementRepository;
    private final MapElementReactionRepository mapElementReactionRepository;
    private final MapElementService mapElementService;
    private final MediaRepository mediaRepository;
    private final MediaService mediaService;
    private final S3Service s3Service;

    /**
     * Constructor for MapElementController.
     */
    public MapElementController(
            MapElementRepositoryInterface mapElementRepository,
            MapElementReactionRepository mapElementReactionRepository,
            MapElementService mapElementService,
            MediaRepository mediaRepository,
            MediaService mediaService,
            S3Service s3Service
    ) {
        this.mapElementRepository = mapElementRepository;
        this.mapElementReactionRepository = mapElementReactionRepository;
        this.mapElementService = mapElementService;
        this.mediaRepository = mediaRepository;
        this.mediaService = mediaService;
        this.s3Service = s3Service;
    }

    /**
     * Endpoint to retrieve all map elements.
     *
     * @param geoPaginationDTO Pagination parameters.
     * @return Paginated list of map elements.
     */
    @Operation(
            summary = "Rechercher des point d'intérêt",
            description = "Retourner la liste des points d'intérêt",
            tags = {"MapElement"}
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
    @GetMapping("/mapElements")
    public PaginatorDTO<MapElementDto> mapElements(
            @Valid @ModelAttribute GeoPaginationDTO geoPaginationDTO,
            @RequestParam TypeMapElementEnum type
    ) {
        return mapElementRepository.findAllWithPagination(geoPaginationDTO, type, false);
    }

    @Operation(
            summary = "Récupérer les éléments de carte en attente de l'utilisateur",
            description = "Retourne les éléments de carte au statut DRAFT pour l'utilisateur connecté (tous les types).",
            security = @SecurityRequirement(name = "bearerAuth"),
            tags = {"MapElement"}
    )
    @ApiResponses(value = {
            @ApiResponse(
                    responseCode = "200",
                    description = "Liste des éléments de carte en attente de l'utilisateur.",
                    content = @Content(
                            mediaType = "application/json",
                            schema = @Schema(implementation = MapElementDto.class)
                    )
            ),
            @ApiResponse(responseCode = "401", ref = "#/components/responses/UnauthorizedError")
    })
    @GetMapping("/mapElements/pending")
    public List<MapElementDto> mapElementsPending(
            @RequestParam(required = false) TypeMapElementEnum type
    ) {
        return mapElementRepository.findAllPendingByUserId(getUser().getId(), type).stream()
                .map(element -> new MapElementDto(element, true))
                .toList();
    }

    /**
     * Endpoint to retrieve a specific map element by ID.
     *
     * @param id Map element  ID.
     * @return Map element  DTO.
     */
    @Operation(
            summary = "Récupérer un élément de carte par ID",
            description = "Retourne les informations d'un point d'intérêt ou d'une alerte spécifique en fonction de son ID et de son type.",
            tags = {"MapElement"}
    )
    @ApiResponses(value = {
            @ApiResponse(
                    responseCode = "200",
                    description = "Informations de l'élément de carte",
                    content = @Content(
                            mediaType = "application/json",
                            schema = @Schema(implementation = MapElementDto.class)
                    )
            ),
            @ApiResponse(
                    responseCode = "404",
                    description = "Élément de carte non trouvé",
                    content = @Content(
                            mediaType = "application/json",
                            schema = @Schema(
                                    implementation = ApiResponseDTO.class,
                                    example = "{"
                                            + "\"i18nKey\": \"map_element.not_found\",\n"
                                            + "\"message\": \"Map element not found\",\n"
                                            + "\"extra\": null\n"
                                            + "}"
                            )
                    )
            )
    })
    @AuthenticationNotRequired
    @GetMapping("/mapElement/{id}")
    public MapElementDto getMapElement(
            @PathVariable Long id,
            @RequestParam TypeMapElementEnum type
    ) {
        return mapElementRepository.findByIdAndType(id, type)
                .map(element -> new MapElementDto(element, true))
                .orElseThrow(() -> new NaaviNotFoundException(
                        "map_element.not_found", "Map element not found"
                ));
    }

    /**
     * Endpoint to create a new map element.
     *
     * @param dto Map element DTO.
     * @return Created map element DTO.
     */
    @PostMapping("/mapElement")
    @Operation(
            summary = "Créer un élément de carte",
            description = "Permet à un membre de créer un nouveau point d'intérêt ou une alerte en fonction du type",
            security = @SecurityRequirement(name = "bearerAuth"),
            tags = {"MapElement"}
    )
    @ApiResponses(value = {
            @ApiResponse(
                    responseCode = "200",
                    description = "Élément de carte créé avec succès",
                    content = @Content(
                            mediaType = "application/json",
                            schema = @Schema(implementation = MapElementDto.class)
                    )
            ),
            @ApiResponse(
                    responseCode = "400",
                    description = "Mauvaise requête",
                    content = @Content(
                            mediaType = "application/json",
                            examples = {
                                    @ExampleObject(
                                            name = "Si le statut est invalide",
                                            value = "{"
                                                    + "\"i18nKey\": \"map_element.status_invalid\","
                                                    + "\"message\": \"The status '...' does not exist.\","
                                                    + "\"extra\": null"
                                                    + "}"
                                    ),
                                    @ExampleObject(
                                            name = "Si la catégorie est invalide",
                                            value = "{"
                                                    + "\"i18nKey\": \"map_element.category_invalid\","
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
    public MapElementDto createMapElement(@RequestBody @Validated(ValidationGroups.OnCreate.class) MapElementDTO dto) {

        MapElement element = new MapElement();
        element.setType(TypeMapElementEnum.valueOf(dto.getType()));

        MapElement saved = mapElementService.save(element, dto, TypeMapElementEnum.valueOf(dto.getType()), getUser());
        return new MapElementDto(saved, true);
    }

    /**
     * Endpoint to upload a photo for a mapElement.
     *
     * @param id Map element  ID.
     * @param file multipartFile
     * @return ApiResponseDTO
     */
    @Operation(
            summary = "Uploader une image pour un point d'intérêt",
            description = "Permet à un membre d'uploader une image pour un point d'intérêt spécifique en fonction de son ID",
            security = @SecurityRequirement(name = "bearerAuth"),
            tags = {"MapElement"}
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
                                            + "\"i18nKey\": \"map_element.image.uploaded\","
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
                                                    + "\"i18nKey\": \"map_element.image.too_large\","
                                                    + "\"message\": \"The file exceeds the maximum size of 5MB.\","
                                                    + "\"extra\": null"
                                                    + "}"
                                    ),
                                    @ExampleObject(
                                            name = "If the file name is invalid",
                                            value = "{"
                                                    + "\"i18nKey\": \"map_element.image.invalid_file\","
                                                    + "\"message\": \"The file is empty or invalid.\","
                                                    + "\"extra\": null"
                                                    + "}"
                                    ),
                                    @ExampleObject(
                                            name = "If the file format is invalid",
                                            value = "{"
                                                    + "\"i18nKey\": \"map_element.image.invalid_file\","
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
                                                    + "\"i18nKey\": \"map_element.image.failed_upload\","
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
                                            + "\"i18nKey\": \"map_element.not_found\","
                                            + "\"message\": \"Map element  not found.\","
                                            + "\"extra\": null"
                                            + "}"
                            )
                    )
            ),
    })
    @PostMapping("/mapElement/{id}/images")
    public ApiResponseDTO mapElementUploadImage(
            @PathVariable Long id,
            @RequestParam TypeMapElementEnum type,
            @RequestParam("image") MultipartFile file) {
        MapElement mapElement = this.mapElementRepository.findByIdAndType(id, type)
                .orElseThrow(() -> new NaaviNotFoundException("map_element.not_found", "Map element  not found"));

        final long MAX_SIZE = 5 * 1024 * 1024L;
        if (file.getSize() > MAX_SIZE) {
            throw new NaaviBadRequestException(
                    "map_element.image.too_large",
                    "The file exceeds the maximum size of 5MB."
            );
        }

        String fileName = file.getOriginalFilename();
        if (file.isEmpty() || fileName == null) {
            throw new NaaviBadRequestException("map_element.image.invalid_file", "The file is empty or invalid.");
        }

        String contentType = file.getContentType() != null ? file.getContentType().toLowerCase() : "";
        Set<String> allowedContentTypes = Set.of(
                "image/png", "image/jpeg", "image/jpg", "image/webp", "image/svg+xml", "image/heic"
        );
        if (!allowedContentTypes.contains(contentType)) {
            throw new NaaviBadRequestException("map_element.image.invalid_file", "Only image files are allowed.", allowedContentTypes);
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

            s3Service.upload(S3Enum.POINTS_OF_INTEREST, file.getInputStream(), fileName, mapElement.getId().toString());
            Media media = mediaService.save(this.getUser(), fileName);
            mapElementService.addMedia(mapElement, media);

            return new ApiResponseDTO(
                    "map_element.image.uploaded",
                    "The image was successfully uploaded."
            );
        } catch (Exception e) {
            throw new NaaviBadRequestException(
                    "map_element.image.failed_upload",
                    "Failed to upload the image. Please try again later."
            );
        }
    }

    /**
     * Endpoint to add/remove like to a map element .
     *
     * @param id Map element  ID.
     * @return ApiResponseDTO
     */
    @Operation(
            summary = "Ajouter/retirer un like à un élément de carte",
            description = "Permet à un membre d'ajouter ou de retirer un like à un point d'intérêt ou une alerte spécifique en fonction de son ID et de son type",
            security = @SecurityRequirement(name = "bearerAuth"),
            tags = {"MapElement"}
    )
    @ApiResponses(value = {
            @ApiResponse(
                    responseCode = "200",
                    description = "Success",
                    content = @Content(
                            mediaType = "application/json",
                            examples = {
                                    @ExampleObject(
                                            name = "If the like was added",
                                            value = "{"
                                                    + "\"i18nKey\": \"map_element.like.added\","
                                                    + "\"message\": \"The like was successfully added.\","
                                                    + "\"extra\": null"
                                                    + "}"
                                    ),
                                    @ExampleObject(
                                            name = "If the like was removed",
                                            value = "{"
                                                    + "\"i18nKey\": \"map_element.like.removed\","
                                                    + "\"message\": \"Your reaction was removed to like.\","
                                                    + "\"extra\": null"
                                                    + "}"
                                    )
                            }
                    )
            ),
            @ApiResponse(responseCode = "401", ref = "#/components/responses/UnauthorizedError"),
            @ApiResponse(
                    responseCode = "404",
                    description = "Not Found",
                    content = @Content(
                            mediaType = "application/json",
                            schema = @Schema(
                                    implementation = ApiResponseDTO.class,
                                    example = "{"
                                            + "\"i18nKey\": \"map_element.not_found\","
                                            + "\"message\": \"Map element not found.\","
                                            + "\"extra\": null"
                                            + "}"
                            )
                    )
            )
    })
    @PostMapping("/mapElement/{id}/like")
    public ApiResponseDTO likeMapElement(
            @PathVariable Long id,
            @RequestParam TypeMapElementEnum type
    ) {
        // Récupération générique du MapElement
        MapElement element = mapElementRepository.findByIdAndType(id, type)
                .orElseThrow(() -> new NaaviNotFoundException(
                        "map_element.not_found",
                        "Map element not found"
                ));

        boolean hasLiked = mapElementReactionRepository.existsByUserAndMapElementAndReaction(
                getUser().getId(),
                element.getId(),
                ReactionEnum.LIKE
        );

        if (hasLiked) {
            mapElementService.removeReaction(element, getUser(), ReactionEnum.LIKE);
            return new ApiResponseDTO(
                    "map_element.like.removed",
                    "Your reaction was removed to like."
            );
        }

        mapElementService.addReaction(element, getUser(), ReactionEnum.LIKE);
        return new ApiResponseDTO(
                "map_element.like.added",
                "The like was successfully added."
        );
    }

    /**
     * Endpoint to add/remove dislike to a map element.
     *
     * @param id Map element  ID.
     * @return ApiResponseDTO
     */
    @Operation(
            summary = "Ajouter/retirer un dislike à un élément de carte",
            description = "Permet à un membre d'ajouter ou de retirer un dislike à un point d'intérêt ou une alerte spécifique en fonction de son ID et de son type",
            security = @SecurityRequirement(name = "bearerAuth"),
            tags = {"MapElement"}
    )
    @ApiResponses(value = {
            @ApiResponse(
                    responseCode = "200",
                    description = "Success",
                    content = @Content(
                            mediaType = "application/json",
                            examples = {
                                    @ExampleObject(
                                            name = "If the dislike was added",
                                            value = "{"
                                                    + "\"i18nKey\": \"map_element.dislike.added\","
                                                    + "\"message\": \"The dislike was successfully added.\","
                                                    + "\"extra\": null"
                                                    + "}"
                                    ),
                                    @ExampleObject(
                                            name = "If the dislike was removed",
                                            value = "{"
                                                    + "\"i18nKey\": \"map_element.dislike.removed\","
                                                    + "\"message\": \"Your reaction was removed to dislike.\","
                                                    + "\"extra\": null"
                                                    + "}"
                                    )
                            }
                    )
            ),
            @ApiResponse(responseCode = "401", ref = "#/components/responses/UnauthorizedError"),
            @ApiResponse(
                    responseCode = "404",
                    description = "Not Found",
                    content = @Content(
                            mediaType = "application/json",
                            schema = @Schema(
                                    implementation = ApiResponseDTO.class,
                                    example = "{"
                                            + "\"i18nKey\": \"map_element.not_found\","
                                            + "\"message\": \"Map element not found.\","
                                            + "\"extra\": null"
                                            + "}"
                            )
                    )
            )
    })
    @PostMapping("/mapElement/{id}/dislike")
    public ApiResponseDTO dislikeMapElement(
            @PathVariable Long id,
            @RequestParam TypeMapElementEnum type
    ) {
        // Récupération générique du MapElement
        MapElement element = mapElementRepository.findByIdAndType(id, type)
                .orElseThrow(() -> new NaaviNotFoundException(
                        "map_element.not_found",
                        "Map element not found"
                ));

        boolean hasDisliked = mapElementReactionRepository.existsByUserAndMapElementAndReaction(
                getUser().getId(),
                element.getId(),
                ReactionEnum.DISLIKE
        );

        if (hasDisliked) {
            mapElementService.removeReaction(element, getUser(), ReactionEnum.DISLIKE);
            return new ApiResponseDTO(
                    "map_element.dislike.removed",
                    "Your reaction was removed to dislike."
            );
        }

        mapElementService.addReaction(element, getUser(), ReactionEnum.DISLIKE);
        return new ApiResponseDTO(
                "map_element.dislike.added",
                "The dislike was successfully added."
        );
    }

    //////////////////////
    /// ADMINISTRATION ///
    //////////////////////

    @Operation(
            summary = "Lister les points d'intérêt pour le backoffice",
            description = "Retourne les points d'intérêt avec tous les statuts pour la modération backoffice",
            security = @SecurityRequirement(name = "bearerAuth"),
            tags = {"Administration"}
    )
    @ApiResponses(value = {
            @ApiResponse(
                    responseCode = "200",
                    description = "Liste paginée des points d'intérêt",
                    content = @Content(
                            mediaType = "application/json",
                            schema = @Schema(implementation = PaginatorDTO.class)
                    )
            ),
            @ApiResponse(responseCode = "401", ref = "#/components/responses/UnauthorizedError"),
            @ApiResponse(responseCode = "403", ref = "#/components/responses/AccessDeniedError"),
            @ApiResponse(responseCode = "422", ref = "#/components/responses/ValidationError")
    })
    @PreAuthorize("hasRole('ADMIN')")
    @GetMapping("/administration/pois")
    public PaginatorDTO<MapElementDto> administrationPointsOfInterest(
            @Valid @ModelAttribute PointOfInterestAdministrationPaginationDTO paginationDTO
    ) {
        PaginatorDTO<MapElement> paginator = this.mapElementRepository.findAllAdministrationWithPagination(
                paginationDTO,
                TypeMapElementEnum.POINT_OF_INTEREST
        );

        List<MapElementDto> dtos = paginator.getItems().stream()
                .map(element -> new MapElementDto(element, true))
                .toList();

        return PaginatorDTO.of(dtos, paginator.getTotalItems(), paginationDTO);
    }

    /**
     * Endpoint to retrieve all hikes.
     *
     * @param geoPaginationDTO Pagination parameters.
     * @return Paginator of hikes.
     */
    @Operation(
            summary = "Rechercher des randonnées",
            description = "Retourner la liste des randonnées (même les brouillons) avec des filtres de recherche",
            tags = {"Administration"}
    )
    @ApiResponses(value = {
            @ApiResponse(
                    responseCode = "200",
                    description = "Liste paginée des randonnées retournée avec succès.",
                    content = @Content(
                            mediaType = "application/json",
                            schema = @Schema(implementation = PaginatorDTO.class)
                    )
            ),
            @ApiResponse(responseCode = "401", ref = "#/components/responses/UnauthorizedError"),
            @ApiResponse(responseCode = "403", ref = "#/components/responses/AccessDeniedError"),
            @ApiResponse(responseCode = "422", ref = "#/components/responses/ValidationError"),
    })
    @PreAuthorize("hasRole('ADMIN')")
    @GetMapping("/administration/mapElements")
    public PaginatorDTO<MapElementDto> getMapElements(
            @Valid @ModelAttribute GeoPaginationDTO geoPaginationDTO,
            @RequestParam TypeMapElementEnum type
    ) {
        return this.mapElementRepository.findAllWithPagination(geoPaginationDTO, type, true);
    }
    /**
     * Endpoint to update a map element .
     *
     * @param id Map element ID.
     * @param dto Map element DTO.
     * @return Updated map element.
     */
    @Operation(
            summary = "Mettre à jour un élément de carte par son ID",
            description = "Permet à un administrateur de mettre à jour les informations d'un point d'intérêt ou d'une alerte spécifique en fonction de son ID et de son type",
            security = @SecurityRequirement(name = "bearerAuth"),
            tags = {"Administration"}
    )
    @ApiResponses(value = {
            @ApiResponse(
                    responseCode = "200",
                    description = "Informations de l'élément de carte",
                    content = @Content(
                            mediaType = "application/json",
                            schema = @Schema(implementation = MapElementDto.class)
                    )
            ),
            @ApiResponse(responseCode = "400", ref = "#/components/responses/BadRequest"),
            @ApiResponse(responseCode = "401", ref = "#/components/responses/UnauthorizedError"),
            @ApiResponse(responseCode = "403", ref = "#/components/responses/AccessDeniedError"),
            @ApiResponse(responseCode = "404", description = "Élément de carte non trouvé"),
            @ApiResponse(responseCode = "422", ref = "#/components/responses/ValidationError")
    })
    @PreAuthorize("hasRole('ADMIN')")
    @PutMapping("/administration/mapElement/{id}")
    public MapElementDto updateMapElementAdmin(
            @PathVariable Long id,
            @RequestBody @Validated(ValidationGroups.OnUpdate.class) MapElementDTO dto
    ) {
        MapElement element = mapElementRepository.findByIdAndType(id, TypeMapElementEnum.valueOf(dto.getType()))
                .orElseThrow(() -> new NaaviNotFoundException(
                        "map_element.not_found",
                        "Map element not found"
                ));

        MapElement updated = mapElementService.save(element, dto, TypeMapElementEnum.valueOf(dto.getType()), getUser());
        return new MapElementDto(updated, true);
    }

    /**
     * Endpoint to delete a map element  media.
     *
     * @param elementId Map element ID.
     * @param imageId Image ID.
     * @return ApiResponseDTO
     */
    @Operation(
            summary = "Supprimer une image d'un élément de carte",
            description = "Permet à un administrateur de supprimer une image d'un point d'intérêt ou d'une alerte spécifique",
            security = @SecurityRequirement(name = "bearerAuth"),
            tags = {"Administration"}
    )
    @ApiResponses(value = {
            @ApiResponse(responseCode = "200", description = "Image supprimée avec succès", content = @Content(schema = @Schema(implementation = ApiResponseDTO.class))),
            @ApiResponse(responseCode = "400", description = "Bad Request", content = @Content(schema = @Schema(implementation = ApiResponseDTO.class))),
            @ApiResponse(responseCode = "401", ref = "#/components/responses/UnauthorizedError"),
            @ApiResponse(responseCode = "403", ref = "#/components/responses/AccessDeniedError"),
            @ApiResponse(responseCode = "404", description = "Élément ou media non trouvé", content = @Content(schema = @Schema(implementation = ApiResponseDTO.class)))
    })
    @PreAuthorize("hasRole('ADMIN')")
    @DeleteMapping("/administration/mapElement/{elementId}/images/{imageId}")
    public ApiResponseDTO deleteMapElementImage(
            @PathVariable Long elementId,
            @RequestParam TypeMapElementEnum type,
            @PathVariable Long imageId
    ) {
        MapElement element = mapElementRepository.findByIdAndType(elementId, type)
                .orElseThrow(() -> new NaaviNotFoundException("map_element.not_found", "Map element not found"));

        Media media = mediaRepository.findById(imageId)
                .orElseThrow(() -> new NaaviNotFoundException("media.not_found", "Media not found"));

        if (element.getImages().stream().noneMatch(m -> m.getId().equals(media.getId()))) {
            throw new NaaviBadRequestException(
                    "map_element.image.not_linked",
                    "The media is not linked to this element."
            );
        }

        s3Service.delete(S3Enum.POINTS_OF_INTEREST, media.getFilename(), element.getId().toString());
        mapElementService.deleteMedia(element, media);
        mediaService.delete(media);

        return new ApiResponseDTO(
                "map_element.image.deleted",
                "The image was successfully deleted"
        );
    }

    /**
     * Endpoint to delete a map element .
     *
     * @param id Map element  ID.
     * @return Deleted map element.
     */
    @Operation(
            summary = "Supprimer un élément de carte par son ID",
            description = "Permet à un administrateur de supprimer un point d'intérêt ou une alerte spécifique en fonction de son ID",
            security = @SecurityRequirement(name = "bearerAuth"),
            tags = {"Administration"}
    )
    @ApiResponses(value = {
            @ApiResponse(responseCode = "200", description = "Élément supprimé avec succès", content = @Content(schema = @Schema(implementation = ApiResponseDTO.class))),
            @ApiResponse(responseCode = "401", ref = "#/components/responses/UnauthorizedError"),
            @ApiResponse(responseCode = "403", ref = "#/components/responses/AccessDeniedError"),
            @ApiResponse(responseCode = "404", description = "Élément non trouvé", content = @Content(schema = @Schema(implementation = ApiResponseDTO.class)))
    })
    @PreAuthorize("hasRole('ADMIN')")
    @DeleteMapping("/administration/mapElement/{id}")
    public ApiResponseDTO deleteMapElement(
            @PathVariable Long id,
            @RequestParam TypeMapElementEnum type
    ) {
        MapElement element = mapElementRepository.findByIdAndType(id, type)
                .orElseThrow(() -> new NaaviNotFoundException("map_element.not_found", "Map element not found"));

        for (Media media : new HashSet<>(element.getImages())) {
            s3Service.delete(S3Enum.POINTS_OF_INTEREST, media.getFilename(), element.getId().toString());
            mapElementService.deleteMedia(element, media);
            mediaService.delete(media);
        }

        mapElementService.delete(element);

        return new ApiResponseDTO(
                "map_element.deleted",
                "Map element successfully deleted"
        );
    }
}
