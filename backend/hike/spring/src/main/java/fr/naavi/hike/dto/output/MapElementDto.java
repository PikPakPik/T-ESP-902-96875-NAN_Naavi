package fr.naavi.hike.dto.output;

import fr.naavi.core.enums.S3Enum;
import fr.naavi.hike.entity.MapElement;
import fr.naavi.hike.enums.MapElementEnum;
import fr.naavi.hike.enums.SourceEnum;
import fr.naavi.hike.enums.TypeMapElementEnum;
import fr.naavi.hike.enums.StatusEnum;
import io.swagger.v3.oas.annotations.media.ArraySchema;
import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Getter;

import java.time.LocalDateTime;
import java.util.List;

@Getter
@Schema(description = "Informations génériques sur un élément de carte")
public class MapElementDto {

    @Schema(description = "Identifiant", example = "1")
    protected final Long id;

    @Schema(description = "Nom", example = "Parc national des Paysages")
    protected final String name;

    @Schema(description = "Description")
    protected final String description;

    @Schema(description = "Latitude", example = "47.2180438348419")
    protected final Double latitude;

    @Schema(description = "Longitude", example = "-1.5549507712791397")
    protected final Double longitude;

    @Schema(description = "Liste des images du point d'intérêt")
    private final List<MediaDto> images;

    @Schema(description = "Statut", example = "PUBLISHED")
    protected final StatusEnum status;

    @Schema(description = "Date de création")
    protected final LocalDateTime createdAt;

    @Schema(description = "Date de modification")
    protected final LocalDateTime updatedAt;

    @Schema(description = "Type de l'élément", example = "POINT_OF_INTEREST")
    protected final TypeMapElementEnum type;

    @Schema(description = "Source de l'élément", example = "COMMUNITY", implementation = SourceEnum.class)
    protected final SourceEnum source;

    @Schema(description = "Identifiant utilisateur propriétaire (null pour un élément officiel)", example = "12")
    protected final Long userId;

    @ArraySchema(schema = @Schema(
            description = "Liste des catégories de l'élément",
            implementation = MapElementEnum.class)
    )
    protected final List<MapElementEnum> categories;

    @Schema(description = "Nombre de likes", example = "10")
    protected final Long likes;

    @Schema(description = "Nombre de dislikes", example = "2")
    protected final Long dislikes;

    /**
     * Constructor for MapElementDto.
     */
    public MapElementDto(MapElement element, boolean showId) {
        this.id = showId ? element.getId() : null;
        this.name = element.getName();
        this.description = element.getDescription();
        this.latitude = element.getLatitude();
        this.longitude = element.getLongitude();
        this.status = element.getStatus();
        Long elementId = element.getId();
        this.images = elementId == null
                ? List.of()
                : element.getImages().stream()
                .map(media -> new MediaDto(
                        media, false, S3Enum.POINTS_OF_INTEREST, elementId))
                .toList();
        this.createdAt = element.getCreatedAt();
        this.updatedAt = element.getUpdatedAt();
        this.type = element.getType();
        this.source = element.getSource();
        this.userId = element.getUserId();
        this.categories = element.getCategories();
        this.likes = element.getLikesCount();
        this.dislikes = element.getDislikesCount();
    }
}
