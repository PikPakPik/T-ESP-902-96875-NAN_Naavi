package fr.naavi.hike.controller;

import fr.naavi.core.annotation.AuthenticationNotRequired;
import fr.naavi.core.dto.ApiResponseDTO;
import fr.naavi.core.dto.PaginatorDTO;
import fr.naavi.core.exception.children.NaaviNotFoundException;
import fr.naavi.core.validation.ValidationGroups;
import fr.naavi.hike.dto.input.GeoPaginationDTO;
import fr.naavi.hike.dto.input.PointOfInterestDTO;
import fr.naavi.hike.dto.output.PointOfInterestDto;
import fr.naavi.hike.entity.PointOfInterest;
import fr.naavi.hike.repository.PointOfInterestRepository;
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
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.ModelAttribute;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RestController;

@SecurityScheme(
        type = SecuritySchemeType.HTTP,
        name = "bearerAuth",
        scheme = "bearer",
        bearerFormat = "JWT",
        paramName = "Authorization: Bearer <token>",
        in = SecuritySchemeIn.HEADER
)
@RestController
public class PointOfInterestController {
    @Autowired
    private PointOfInterestRepository pointOfInterestRepository;

    @Autowired
    private PointOfInterestService pointOfInterestService;

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

        this.pointOfInterestService.deletePointOfInterest(pointOfInterest);

        return new ApiResponseDTO("point_of_interest.deleted", "Point of interest successfully deleted");
    }
}
