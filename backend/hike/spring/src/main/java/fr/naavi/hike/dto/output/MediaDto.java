package fr.naavi.hike.dto.output;

import fr.naavi.core.enums.S3Enum;
import fr.naavi.hike.entity.Media;
import io.swagger.v3.oas.annotations.media.Schema;

import java.time.LocalDateTime;

@Schema(description = "Informations sur une randonnée")
public class MediaDto {
    @Schema(description = "Identifiant du media", example = "1")
    private final Long id;

    @Schema(
            description = "Chemin relatif dans le bucket (identique à la clé S3 : TYPE/idParent/fichier)",
            example = "hikes/42/abc123.png"
    )
    private final String filename;

    @Schema(description = "Identifiant de l'utilisateur ayant uploadé le media", example = "1")
    private final Long userId;

    @Schema(description = "Date de création du media", example = "2024-06-01T12:00:00")
    private final LocalDateTime createdAt;

    /**
     * Construit le chemin exposé au client pour qu'il corresponde à la clé S3
     * ({@link fr.naavi.core.service.S3Service#upload} : {@code type/path/fileName}).
     *
     * @param pathSegment identifiant du dossier objet (ex. identifiant de la randonnée)
     */
    public MediaDto(Media media, boolean showUserId, S3Enum bucketType, Long pathSegment) {
        this.id = media.getId();
        this.filename = bucketType + "/" + pathSegment + "/" + media.getFilename();
        this.userId = showUserId ? media.getUser() : null;
        this.createdAt = media.getCreatedAt();
    }

    public Long getId() {
        return id;
    }

    public String getFilename() {
        return filename;
    }

    public Long getUserId() {
        return userId;
    }

    public LocalDateTime getCreatedAt() {
        return createdAt;
    }
}
