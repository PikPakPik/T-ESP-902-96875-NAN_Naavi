package fr.naavi.hike.controller;

import fr.naavi.core.annotation.AuthenticationNotRequired;
import fr.naavi.core.dto.ApiResponseDTO;
import fr.naavi.core.dto.PaginationDTO;
import fr.naavi.core.dto.PaginatorDTO;
import fr.naavi.core.enums.RoleEnum;
import fr.naavi.core.exception.children.NaaviBadRequestException;
import fr.naavi.core.exception.children.NaaviForbiddenException;
import fr.naavi.core.exception.children.NaaviNotFoundException;
import fr.naavi.core.validation.ValidationGroups;
import fr.naavi.hike.abstraction.AbstractController;
import fr.naavi.hike.dto.input.FileMappingDTO;
import fr.naavi.hike.dto.input.GeoPaginationDTO;
import fr.naavi.hike.dto.input.HikeDTO;
import fr.naavi.hike.dto.input.HikeHistoryDTO;
import fr.naavi.hike.dto.output.HikeDto;
import fr.naavi.hike.dto.output.HikeHistoryDto;
import fr.naavi.hike.entity.Hike;
import fr.naavi.hike.entity.HikeHistory;
import fr.naavi.hike.exception.FileImportException;
import fr.naavi.hike.repository.HikeHistoryRepository;
import fr.naavi.hike.repository.HikeRepository;
import fr.naavi.hike.service.HikeService;
import fr.naavi.hike.service.importer.FileImportService;
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
import org.springframework.http.MediaType;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.ModelAttribute;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestPart;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.multipart.MultipartFile;
import tools.jackson.databind.ObjectMapper;

import java.util.Map;

@SecurityScheme(
        type = SecuritySchemeType.HTTP,
        name = "bearerAuth",
        scheme = "bearer",
        bearerFormat = "JWT",
        paramName = "Authorization: Bearer <token>",
        in = SecuritySchemeIn.HEADER
)
@RestController
public class HikeController extends AbstractController {
    @Autowired
    private HikeRepository hikeRepository;

    @Autowired
    private HikeHistoryRepository hikeHistoryRepository;

    @Autowired
    private HikeService hikeService;

    public HikeController(FileImportService fileImportService) {
        this.fileImportService = fileImportService;
    }

    private final FileImportService fileImportService;

    /**
     * Endpoint to import hikes from files.
     */
    @Operation(
            summary = "Importer des randonnées depuis un fichier",
            description = "Permet à un administrateur d'importer des randonnées à partir d'un fichier CSV ou Excel avec un mapping personnalisé",
            security = @SecurityRequirement(name = "bearerAuth"),
            tags = {"Administration"},
            requestBody = @io.swagger.v3.oas.annotations.parameters.RequestBody(
                    description = "Fichier à importer (CSV ou Excel) et mapping des colonnes",
                    required = true,
                    content = @Content(
                            mediaType = MediaType.MULTIPART_FORM_DATA_VALUE,
                            schema = @Schema(type = "object"),
                            examples = @ExampleObject(
                                    name = "Exemple de mapping",
                                    value = "{\n"
                                            + "  \"file\": \"<binary>\",\n"
                                            + "  \"mapping\": {\n"
                                            + "    \"mappings\": {\n"
                                            + "      \"name\": { \"source\": \"Nom du circuit\" },\n"
                                            + "      \"distance\": { \"source\": \"Distance (km)\", \"unit\": \"KILOMETERS\" },\n"
                                            + "      \"duration\": { \"source\": \"Durée (min)\", \"unit\": \"HOURS\" },\n"
                                            + "      \"location\": { \"source\": \"Commune\" },\n"
                                            + "      \"difficulty\": {\n"
                                            + "        \"source\": \"Difficulté\",\n"
                                            + "        \"values\": {\n"
                                            + "          \"Facile\": \"EASY\",\n"
                                            + "          \"Moyen\": \"MEDIUM\",\n"
                                            + "          \"Difficile\": \"HARD\"\n"
                                            + "        }\n"
                                            + "      },\n"
                                            + "      \"startingPointLatitude\": { \"source\": \"Départ\" },\n"
                                            + "}"
                            )
                    )
            )
    )
    @ApiResponses(value = {
            @ApiResponse(
                    responseCode = "200",
                    description = "Import réalisé avec succès.",
                    content = @Content(
                            mediaType = "application/json",
                            schema = @Schema(
                                    implementation = ApiResponseDTO.class,
                                    example = "{\n"
                                            + "  \"i18nKey\": \"import.success\",\n"
                                            + "  \"message\": \"Import completed successfully.\",\n"
                                            + "  \"extra\": null\n"
                                            + "}"
                            )
                    )
            ),
            @ApiResponse(
                    responseCode = "400",
                    description = "Erreur lors du traitement du fichier",
                    content = @Content(
                            mediaType = "application/json",
                            schema = @Schema(
                                    implementation = ApiResponseDTO.class,
                                    example = "{\n"
                                            + "  \"i18nKey\": \"import.error\",\n"
                                            + "  \"message\": \"An error occurred while processing the file.\",\n"
                                            + "  \"extra\": {\n"
                                            + "    \"message\": \"...\"\n"
                                            + "  }\n"
                                            + "}"
                            )
                    )
            ),
            @ApiResponse(responseCode = "401", ref = "#/components/responses/UnauthorizedError"),
            @ApiResponse(responseCode = "403", ref = "#/components/responses/AccessDeniedError"),
    })
    @PostMapping(
            value = "/import/hike",
            consumes = MediaType.MULTIPART_FORM_DATA_VALUE
    )
    @PreAuthorize("hasRole('ADMIN')")
    public ApiResponseDTO importHike(
            @RequestPart("file") MultipartFile file,
            @RequestPart("mapping") String mappingJson
    ) {
        try {
            FileMappingDTO mapping;
            mapping = new ObjectMapper().readValue(mappingJson, FileMappingDTO.class);
            fileImportService.importFile(file, mapping);
        } catch (FileImportException e) {
            throw new NaaviBadRequestException(
                    "import.error",
                    "An error occurred while processing the file.",
                    Map.of(
                       "message", e.getMessage()
                    )
            );
        }

        return new ApiResponseDTO("import.success", "Import completed successfully.");
    }

    /**
     * Endpoint to retrieve all hikes.
     *
     * @param geoPaginationDTO Pagination parameters.
     * @return Paginator of hikes.
     */
    @Operation(
            summary = "Rechercher des randonnées",
            description = "Retourner la liste des randonnées",
            tags = {"Randonnée"}
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
            @ApiResponse(responseCode = "422", ref = "#/components/responses/ValidationError")
    })
    @AuthenticationNotRequired
    @GetMapping("/hikes")
    public PaginatorDTO<HikeDto> hikes(@Valid @ModelAttribute GeoPaginationDTO geoPaginationDTO) {
        return this.hikeRepository.findAllHikeWithPagination(geoPaginationDTO, false);
    }

    /**
     * Endpoint to retrieve a hike by its ID.
     *
     * @param id Hike ID.
     * @return Hike.
     */
    @Operation(
            summary = "Récupérer une randonnée par ID",
            description = "Retourne les informations d'une randonnée spécifique en fonction de son ID.",
            tags = {"Randonnée"}
    )
    @ApiResponses(value = {
            @ApiResponse(
                    responseCode = "200",
                    description = "Informations de la randonnée",
                    content = @Content(
                            mediaType = "application/json",
                            schema = @Schema(implementation = HikeDto.class)
                    )
            ),
            @ApiResponse(
                    responseCode = "404",
                    description = "Randonnée non trouvé",
                    content = @Content(
                            mediaType = "application/json",
                            schema = @Schema(
                                    implementation = ApiResponseDTO.class,
                                    example = "{"
                                            + "\"i18nKey\": \"hike.not_found\",\n"
                                            + "\"message\": \"Hike not found\",\n"
                                            + "\"extra\": null\n"
                                            + "}"
                            )
                    )
            )
    })
    @AuthenticationNotRequired
    @GetMapping("/hikes/{id}")
    public HikeDto getHike(@PathVariable Long id) {
        return this.hikeRepository.findById(id)
                .map(hike -> new HikeDto(hike, true))
                .orElseThrow(() -> new NaaviNotFoundException("hike.not_found", "Hike not found"));
    }

    /**
     * Endpoint to create a hike.
     *
     * @param hikeDto Hike to create.
     * @return Hike.
     */
    @Operation(
            summary = "Créer une randonnée",
            description = "Permet a un membre de créer une randonnée",
            security = @SecurityRequirement(name = "bearerAuth"),
            tags = {"Randonnée"}
    )
    @ApiResponses(value = {
            @ApiResponse(
                    responseCode = "200",
                    description = "Informations de la randonnée",
                    content = @Content(
                            mediaType = "application/json",
                            schema = @Schema(implementation = HikeDto.class)
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
                                                    + "\"i18nKey\": \"hike.status_invalid\","
                                                    + "\"message\": \"The status '...' does not exist.\","
                                                    + "\"extra\": null"
                                                    + "}"
                                    ),
                                    @ExampleObject(
                                            name = "If difficulty is invalid",
                                            value = "{"
                                                    + "\"i18nKey\": \"hike.difficulty_invalid\","
                                                    + "\"message\": \"The difficulty '...' does not exist.\","
                                                    + "\"extra\": null"
                                                    + "}"
                                    )
                            }
                    )
            ),
            @ApiResponse(responseCode = "401", ref = "#/components/responses/UnauthorizedError"),
            @ApiResponse(responseCode = "422", ref = "#/components/responses/ValidationError")
    })
    @PostMapping("/hikes")
    public HikeDto createHike(@RequestBody @Validated(ValidationGroups.OnCreate.class) HikeDTO hikeDto) {
        return this.hikeService.createHike(hikeDto);
    }

    /**
     * Endpoint to retrieve the history of a user.
     *
     * @param paginationDTO Pagination parameters.
     * @return Paginator of history.
     */
    @Operation(
            summary = "Consulter l'historique de randonnée",
            description = "Permet a un membre de consulter son historique de randonnée",
            security = @SecurityRequirement(name = "bearerAuth"),
            tags = {"Randonnée"}
    )
    @ApiResponses(value = {
            @ApiResponse(
                    responseCode = "200",
                    description = "Historique des randonnées",
                    content = @Content(
                            mediaType = "application/json",
                            schema = @Schema(implementation = PaginatorDTO.class)
                    )
            ),
            @ApiResponse(responseCode = "401", ref = "#/components/responses/UnauthorizedError")
    })
    @GetMapping("/hikes/history")
    public PaginatorDTO<HikeHistoryDto> getHistory(@Valid @ModelAttribute PaginationDTO paginationDTO) {
        return this.hikeHistoryRepository.findAllWithPagination(paginationDTO, this.getUser().getId());
    }

    /**
     * Endpoint to save the history of a user.
     *
     * @param hikeHistoryDTO History to save.
     * @return Message of success.
     */
    @Operation(
            summary = "Sauvegarder une randonnée",
            description = "Permet a un membre de sauvegarder une randonnée qu'il vient de faire",
            security = @SecurityRequirement(name = "bearerAuth"),
            tags = {"Randonnée"}
    )
    @ApiResponses(value = {
            @ApiResponse(
                    responseCode = "200",
                    description = "Randonnée sauvegarder avec succès.",
                    content = @Content(
                            mediaType = "application/json",
                            schema = @Schema(
                                    implementation = ApiResponseDTO.class,
                                    example = "{\n"
                                            + "  \"i18nKey\": \"hike.history.success\",\n"
                                            + "  \"message\": \"The hike has been successfully saved.\",\n"
                                            + "  \"extra\": null\n"
                                            + "}"
                            )
                    )
            ),
            @ApiResponse(responseCode = "401", ref = "#/components/responses/UnauthorizedError"),
            @ApiResponse(
                    responseCode = "404",
                    description = "Randonnée introuvable",
                    content = @Content(
                            mediaType = "application/json",
                            schema = @Schema(
                                    implementation = ApiResponseDTO.class,
                                    example = "{\n"
                                            + "  \"i18nKey\": \"hike.not_found\",\n"
                                            + "  \"message\": \"Hike not found\",\n"
                                            + "  \"extra\": null\n"
                                            + "}"
                            )
                    )
            ),
            @ApiResponse(responseCode = "422", ref = "#/components/responses/ValidationError")
    })
    @PostMapping("/hikes/history")
    public ApiResponseDTO saveHistory(@RequestBody @Validated HikeHistoryDTO hikeHistoryDTO) {
        Hike hike = this.hikeRepository.findById(hikeHistoryDTO.getHikeId())
                .orElseThrow(() -> new NaaviNotFoundException("hike.not_found", "Hike not found"));

        this.hikeService.saveHikeHistory(this.getUser(), hike, hikeHistoryDTO);
        return new ApiResponseDTO("hike.history.success", "The hike has been successfully saved.");
    }

    /**
     * Endpoint to delete a history.
     *
     * @param id History ID.
     * @return Message of success.
     */
    @Operation(
            summary = "Supprimer une randonnée sauvegarder",
            description = "Permet a un membre de supprimer une randonnée qu'il a fait",
            security = @SecurityRequirement(name = "bearerAuth"),
            tags = {"Randonnée"}
    )
    @ApiResponses(value = {
            @ApiResponse(
                    responseCode = "200",
                    description = "Randonnée supprimer avec succès.",
                    content = @Content(
                            mediaType = "application/json",
                            schema = @Schema(
                                    implementation = ApiResponseDTO.class,
                                    example = "{\n"
                                            + "  \"i18nKey\": \"hike.history.success\",\n"
                                            + "  \"message\": \"The hike has been successfully deleted.\",\n"
                                            + "  \"extra\": null\n"
                                            + "}"
                            )
                    )
            ),
            @ApiResponse(responseCode = "401", ref = "#/components/responses/UnauthorizedError"),
            @ApiResponse(
                    responseCode = "403",
                    description = "Accès refusé",
                    content = @Content(
                            mediaType = "application/json",
                            schema = @Schema(
                                    implementation = ApiResponseDTO.class,
                                    example = "{\n"
                                            + "  \"i18nKey\": \"hike.history.forbidden\",\n"
                                            + "  \"message\": \"You are not allowed to delete this hike history.\",\n"
                                            + "  \"extra\": null\n"
                                            + "}"
                            )
                    )
            ),
            @ApiResponse(
                    responseCode = "404",
                    description = "Randonnée introuvable",
                    content = @Content(
                            mediaType = "application/json",
                            schema = @Schema(
                                    implementation = ApiResponseDTO.class,
                                    example = "{\n"
                                            + "  \"i18nKey\": \"hike.history.not_found\",\n"
                                            + "  \"message\": \"Hike history not found\",\n"
                                            + "  \"extra\": null\n"
                                            + "}"
                            )
                    )
            )
    })
    @DeleteMapping("/hikes/history/{id}")
    public ApiResponseDTO deleteHistory(@PathVariable Long id) {
        HikeHistory hikeHistory = this.hikeHistoryRepository.findById(id)
                .orElseThrow(() -> new NaaviNotFoundException("hike.history.not_found", "Hike history not found"));

        if (
                !(this.isGranted(RoleEnum.ROLE_ADMIN) || this.isGranted(RoleEnum.ROLE_MODERATOR))
                        && !hikeHistory.getUser().equals(this.getUser().getId())
        ) {
            throw new NaaviForbiddenException("hike.history.forbidden", "You are not allowed to delete this hike history.");
        }

        this.hikeHistoryRepository.delete(hikeHistory);
        return new ApiResponseDTO("hike.history.success", "The hike has been successfully deleted.");
    }

    //////////////////////
    /// ADMINISTRATION ///
    //////////////////////

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
    @GetMapping("/administration/hikes")
    public PaginatorDTO<HikeDto> getHikes(@Valid @ModelAttribute GeoPaginationDTO geoPaginationDTO) {
        return this.hikeRepository.findAllHikeWithPagination(geoPaginationDTO, true);
    }

    /**
     * Endpoint to update a hike.
     *
     * @param id Hike ID.
     * @param hikeDto Hike to update.
     * @return Hike.
     */
    @Operation(
            summary = "Mettre à jour une randonnée par son ID",
            description = "Met à jour les informations d'une randonnée spécifique en fonction de son ID",
            security = @SecurityRequirement(name = "bearerAuth"),
            tags = {"Administration"}
    )
    @ApiResponses(value = {
            @ApiResponse(
                    responseCode = "200",
                    description = "Informations de la randonnée",
                    content = @Content(
                            mediaType = "application/json",
                            schema = @Schema(implementation = HikeDto.class)
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
                                                    + "\"i18nKey\": \"hike.status_invalid\","
                                                    + "\"message\": \"The status '...' does not exist.\","
                                                    + "\"extra\": null"
                                                    + "}"
                                    ),
                                    @ExampleObject(
                                            name = "If difficulty is invalid",
                                            value = "{"
                                                    + "\"i18nKey\": \"hike.difficulty_invalid\","
                                                    + "\"message\": \"The difficulty '...' does not exist.\","
                                                    + "\"extra\": null"
                                                    + "}"
                                    ),
                                    @ExampleObject(
                                            name = "If season is invalid",
                                            value = "{"
                                                    + "\"i18nKey\": \"hike.season_invalid\","
                                                    + "\"message\": \"The season '...' does not exist.\","
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
                    description = "Randonnée non trouvé",
                    content = @Content(
                            mediaType = "application/json",
                            schema = @Schema(
                                    implementation = ApiResponseDTO.class,
                                    example = "{\n"
                                            + "\"i18nKey\": \"hike.not_found\",\n"
                                            + "\"message\": \"Hike not found\",\n"
                                            + "\"extra\": null\n"
                                            + "}"
                            )
                    )
            ),
            @ApiResponse(responseCode = "422", ref = "#/components/responses/ValidationError")
    })
    @PreAuthorize("hasRole('ADMIN')")
    @PutMapping("/administration/hikes/{id}")
    public HikeDto updateHike(@PathVariable Long id, @RequestBody @Validated(ValidationGroups.OnUpdate.class) HikeDTO hikeDto) {
        Hike hike = this.hikeRepository.findById(id)
                .orElseThrow(() -> new NaaviNotFoundException("hike.not_found", "Hike not found"));

        return this.hikeService.updateHike(hike, hikeDto);
    }

    /**
     * Endpoint to delete a hike.
     *
     * @param id Hike ID.
     * @return Message of success.
     */
    @Operation(
            summary = "Supprimer une randonnée par son ID",
            description = "Supprimer une randonnée spécifique en fonction de son ID",
            security = @SecurityRequirement(name = "bearerAuth"),
            tags = {"Administration"}
    )
    @ApiResponses(value = {
            @ApiResponse(
                    responseCode = "200",
                    description = "Randonnée supprimé avec succès.",
                    content = @Content(
                            mediaType = "application/json",
                            schema = @Schema(implementation = ApiResponseDTO.class)
                    )
            ),
            @ApiResponse(responseCode = "401", ref = "#/components/responses/UnauthorizedError"),
            @ApiResponse(responseCode = "403", ref = "#/components/responses/AccessDeniedError"),
            @ApiResponse(
                    responseCode = "404",
                    description = "Randonnée non trouvé",
                    content = @Content(
                            mediaType = "application/json",
                            schema = @Schema(
                                    implementation = ApiResponseDTO.class,
                                    example = "{\n"
                                            + "\"i18nKey\": \"hike.not_found\",\n"
                                            + "\"message\": \"Hike not found\",\n"
                                            + "\"extra\": null\n"
                                            + "}"
                            )
                    )
            )
    })
    @PreAuthorize("hasRole('ADMIN')")
    @DeleteMapping("/administration/hikes/{id}")
    public ApiResponseDTO deleteHike(@PathVariable Long id) {
        Hike hike = this.hikeRepository.findById(id)
                .orElseThrow(() -> new NaaviNotFoundException("hike.not_found", "Hike not found"));

        this.hikeService.deleteHike(hike);

        return new ApiResponseDTO("hike.deleted", "Hike successfully deleted");
    }

    /**
     * Endpoint to retrieve the history of a user.
     *
     * @param id User ID.
     * @param paginationDTO Pagination parameters.
     * @return Paginator of history.
     */
    @Operation(
            summary = "Consulter l'historique de randonnée d'un utilisateur",
            description = "Permet a un administrateur de consulter l'historique de randonnée d'un utilisateur",
            security = @SecurityRequirement(name = "bearerAuth"),
            tags = {"Administration"}
    )
    @ApiResponses(value = {
            @ApiResponse(
                    responseCode = "200",
                    description = "Historique de randonnée",
                    content = @Content(
                            mediaType = "application/json",
                            schema = @Schema(implementation = PaginatorDTO.class)
                    )
            ),
            @ApiResponse(responseCode = "401", ref = "#/components/responses/UnauthorizedError"),
            @ApiResponse(responseCode = "403", ref = "#/components/responses/AccessDeniedError")
    })
    @PreAuthorize("hasRole('ADMIN')")
    @GetMapping("/administration/hikes/history/user/{id}")
    public PaginatorDTO<HikeHistoryDto> getUserHistory(@PathVariable Long id, @Valid @ModelAttribute PaginationDTO paginationDTO) {
        return this.hikeHistoryRepository.findAllWithPagination(paginationDTO, id);
    }
}
