package fr.naavi.identity.dto.input;

import fr.naavi.core.enums.PermissionEnum;
import fr.naavi.core.enums.RoleEnum;
import fr.naavi.identity.enums.StatusEnum;
import fr.naavi.identity.validation.ValidationGroups;
import io.swagger.v3.oas.annotations.media.ArraySchema;
import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;

import java.util.List;

public class UserDTO {
    @Schema(description = "Prénom de l'utilisateur", example = "Jean")
    @NotBlank(groups = ValidationGroups.OnCreate.class)
    private String firstname;

    @Schema(description = "Nom de l'utilisateur", example = "Dupont")
    @NotBlank(groups = ValidationGroups.OnCreate.class)
    private String lastname;

    @Schema(description = "Email de l'utilisateur", example = "jean.dupont@email.com")
    @NotBlank(groups = ValidationGroups.OnCreate.class)
    @Email(groups = ValidationGroups.OnCreate.class)
    private String email;

    @ArraySchema(schema = @Schema(
            description = "Liste des rôles de l'utilisateur",
            implementation = RoleEnum.class)
    )
    private List<String> roles;

    @ArraySchema(schema = @Schema(
            description = "Liste des permissions de l'utilisateur",
            implementation = PermissionEnum.class)
    )
    private List<String> permissions;

    @Schema(description = "Statut de l'utilisateur", implementation = StatusEnum.class)
    private String status;

    public String getFirstname() {
        return firstname;
    }

    public String getLastname() {
        return lastname;
    }

    public String getEmail() {
        return email;
    }

    public List<String> getRoles() {
        return roles;
    }

    public List<String> getPermissions() {
        return permissions;
    }

    public String getStatus() {
        return status;
    }
}
