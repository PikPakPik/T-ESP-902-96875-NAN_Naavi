package fr.naavi.identity.dto.input;

import fr.naavi.core.enums.PermissionEnum;
import fr.naavi.core.enums.RoleEnum;
import io.swagger.v3.oas.annotations.media.ArraySchema;
import io.swagger.v3.oas.annotations.media.Schema;

import java.util.List;

public class UserDTO {
    @Schema(description = "Prénom de l'utilisateur", example = "Jean")
    private String firstname;

    @Schema(description = "Nom de l'utilisateur", example = "Dupont")
    private String lastname;

    @Schema(description = "Email de l'utilisateur", example = "jean.dupont@email.com")
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
}
