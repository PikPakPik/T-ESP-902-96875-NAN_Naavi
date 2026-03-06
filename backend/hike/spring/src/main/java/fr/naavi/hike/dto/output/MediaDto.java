package fr.naavi.hike.dto.output;

import fr.naavi.hike.entity.Media;
import io.swagger.v3.oas.annotations.media.Schema;

import java.time.LocalDateTime;

@Schema(description = "Informations sur une randonnée")
public class MediaDto {
    @Schema(description = "Identifiant du media", example = "1")
    private final Long id;

    @Schema(description = "Nom du fichier", example = "super-file.png")
    private final String filename;

    @Schema(description = "Identifiant de l'utilisateur ayant uploadé le media", example = "1")
    private final Long userId;

    @Schema(description = "Date de création du media", example = "2024-06-01T12:00:00")
    private final LocalDateTime createdAt;

    /**
     * Constructor for MediaDto.
     *
     * @param media The media to output.
     * @param showUserId The flag to show the user id.
     * @param customPath The custom path to prepend to the filename.
     */
    public MediaDto(Media media, boolean showUserId, String customPath) {
        this.id = media.getId();
        this.filename = customPath.toLowerCase() + "/" + media.getFilename();
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
