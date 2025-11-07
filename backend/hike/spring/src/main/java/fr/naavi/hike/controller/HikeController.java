package fr.naavi.hike.controller;

import fr.naavi.core.annotation.AuthenticationNotRequired;
import fr.naavi.core.dto.ApiResponseDTO;
import fr.naavi.core.dto.PaginatorDTO;
import fr.naavi.core.exception.children.NaaviNotFoundException;
import fr.naavi.core.validation.ValidationGroups;
import fr.naavi.hike.abstraction.AbstractController;
import fr.naavi.hike.dto.input.HikeDTO;
import fr.naavi.hike.dto.input.HikePaginationDTO;
import fr.naavi.hike.dto.output.HikeDto;
import fr.naavi.hike.entity.Hike;
import fr.naavi.hike.repository.HikeRepository;
import fr.naavi.hike.service.HikeService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.enums.SecuritySchemeIn;
import io.swagger.v3.oas.annotations.enums.SecuritySchemeType;
import io.swagger.v3.oas.annotations.media.Content;
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
public class HikeController extends AbstractController {
    @Autowired
    private HikeRepository hikeRepository;

    @Autowired
    private HikeService hikeService;

    /**
     * Endpoint to retrieve all hikes.
     *
     * @param hikePaginationDTO Pagination parameters.
     * @return Paginator of hikes.
     */
    @Operation(
            summary = "Rechercher une randonnée",
            description = "Retourner la liste de randonnée",
            tags = {"Randonnée"}
    )
    @ApiResponses(value = {
            @ApiResponse(
                    responseCode = "200",
                    description = "Liste paginée des utilisateurs retournée avec succès.",
                    content = @Content(
                            mediaType = "application/json",
                            schema = @Schema(implementation = PaginatorDTO.class)
                    )
            ),
            @ApiResponse(responseCode = "422", ref = "#/components/responses/ValidationError")
    })
    @AuthenticationNotRequired
    @GetMapping("/hikes")
    public PaginatorDTO<HikeDto> hikes(@Valid @ModelAttribute HikePaginationDTO hikePaginationDTO) {
        return this.hikeRepository.findAllHikeWithPagination(hikePaginationDTO);
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
            @ApiResponse(responseCode = "401", ref = "#/components/responses/UnauthorizedError"),
            @ApiResponse(responseCode = "403", ref = "#/components/responses/AccessDeniedError"),
            @ApiResponse(responseCode = "422", ref = "#/components/responses/ValidationError")
    })
    @PostMapping("/hikes")
    public HikeDto createHike(@RequestBody @Validated(ValidationGroups.OnCreate.class) HikeDTO hikeDto) {
        return this.hikeService.createHike(hikeDto);
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
            @ApiResponse(responseCode = "401", ref = "#/components/responses/UnauthorizedError"),
            @ApiResponse(responseCode = "403", ref = "#/components/responses/AccessDeniedError"),
            @ApiResponse(
                    responseCode = "404",
                    description = "Randonnée non trouvé",
                    content = @Content(
                            mediaType = "application/json",
                            schema = @Schema(
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
}
