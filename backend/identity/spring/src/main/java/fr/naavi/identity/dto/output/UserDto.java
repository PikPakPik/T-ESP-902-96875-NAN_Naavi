package fr.naavi.identity.dto.output;

import fr.naavi.core.enums.PermissionEnum;
import fr.naavi.core.enums.RoleEnum;
import fr.naavi.core.enums.S3Enum;
import fr.naavi.identity.entity.User;
import fr.naavi.identity.enums.StatusEnum;
import io.swagger.v3.oas.annotations.media.ArraySchema;
import io.swagger.v3.oas.annotations.media.Schema;

import java.time.LocalDateTime;
import java.util.List;

@Schema(description = "Informations sur un utilisateur")
public class UserDto {
    @Schema(description = "Identifiant de l'utilisateur", example = "1")
    private final Long id;

    @Schema(description = "Prénom de l'utilisateur", example = "Jean")
    private final String firstname;

    @Schema(description = "Nom de l'utilisateur", example = "Dupont")
    private final String lastname;

    @Schema(description = "Email de l'utilisateur", example = "jean.dupont@email.com")
    private final String email;

    @Schema(description = "URL vers l'image de profil stockée sur S3", example = "https://s3.example.com/users/file.jpg")
    private final String profilePicture;

    @ArraySchema(schema = @Schema(
            description = "Liste des rôles de l'utilisateur",
            implementation = RoleEnum.class)
    )
    private List<RoleEnum> roles;

    @ArraySchema(schema = @Schema(
            description = "Liste des permissions de l'utilisateur",
            implementation = PermissionEnum.class)
    )
    private List<PermissionEnum> permissions;

    @Schema(description = "Statut de l'utilisateur", example = "ACTIVE")
    private final StatusEnum status;

    @Schema(description = "Date de création du compte", example = "2024-06-01T12:00:00")
    private final LocalDateTime createdAt;

    @Schema(description = "Date de dernière modification du compte", example = "2024-06-10T15:30:00")
    private final LocalDateTime updatedAt;

    /**
     * Constructor.
     *
     * @param user The user to create the DTO from.
     * @param showId Whether to show the id of the user or not.
     */
    public UserDto(User user, boolean showId) {
        this.id = showId ? user.getId() : null;
        this.firstname = user.getFirstname();
        this.lastname = user.getLastname();
        this.email = user.getEmail();
        this.profilePicture = user.getProfilePicture() == null ?
                null :
                S3Enum.USERS.toString().toLowerCase() + "/" + user.getProfilePicture();
        this.roles = user.getRoles();
        this.permissions = user.getPermissions();
        this.status = user.getStatus();
        this.createdAt = user.getCreatedAt();
        this.updatedAt = user.getUpdatedAt();
    }

    /**
     * Get the id of the user.
     *
     * @return The id of the user.
     */
    public Long getId() {
        return id;
    }

    /**
     * Get the firstname of the user.
     *
     * @return The firstname of the user.
     */
    public String getFirstname() {
        return firstname;
    }

    /**
     * Get the lastname of the user.
     *
     * @return The lastname of the user.
     */
    public String getLastname() {
        return lastname;
    }

    /**
     * Get the full name of the user, combining first and last names.
     *
     * @return The full name of the user, combining first and last names.
     */
    public String getFullName() {
        return firstname + " " + lastname;
    }

    /**
     * Get the email of the user.
     *
     * @return The email of the user.
     */
    public String getEmail() {
        return email;
    }

    /**
     * Get the profile picture URL of the user.
     *
     * @return The profile picture URL of the user, or null if not set.
     */
    public String getProfilePicture() {
        return profilePicture;
    }

    /**
     * Get the roles of the user.
     *
     * @return The roles of the user.
     */
    public List<RoleEnum> getRoles() {
        return roles;
    }

    /**
     * Get the permissions of the user.
     *
     * @return The permissions of the user.
     */
    public List<PermissionEnum> getPermissions() {
        return permissions;
    }

    /**
     * Get the status of the user.
     *
     * @return The status of the user.
     */
    public StatusEnum getStatus() {
        return status;
    }

    /**
     * Get the creation date of the user.
     *
     * @return The creation date of the user.
     */
    public LocalDateTime getCreatedAt() {
        return createdAt;
    }

    /**
     * Get the last update date of the user.
     *
     * @return The last update date of the user.
     */
    public LocalDateTime getUpdatedAt() {
        return updatedAt;
    }
}
