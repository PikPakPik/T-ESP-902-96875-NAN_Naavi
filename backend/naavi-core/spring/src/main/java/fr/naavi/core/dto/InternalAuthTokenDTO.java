package fr.naavi.core.dto;

import fr.naavi.core.enums.PermissionEnum;
import fr.naavi.core.enums.RoleEnum;
import fr.naavi.core.enums.TokenType;

import java.util.List;

public class InternalAuthTokenDTO {
    private TokenType type;
    private Long id;
    private String firstname;
    private String lastname;
    private String email;
    private List<RoleEnum> roles;
    private List<PermissionEnum> permissions;

    //<editor-fold desc="Constructor">
    /**
     * Constructs an InternalAuthTokenDto with the specified type.
     *
     * @param type The type of the token.
     */
    public InternalAuthTokenDTO(TokenType type) {
        this.type = type;
    }
    //</editor-fold>

    //<editor-fold desc="Getters/Setters">
    public TokenType getType() {
        return type;
    }

    public void setType(TokenType type) {
        this.type = type;
    }

    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id = id;
    }

    public String getFirstname() {
        return firstname;
    }

    public void setFirstname(String firstname) {
        this.firstname = firstname;
    }

    public String getLastname() {
        return lastname;
    }

    public void setLastname(String lastname) {
        this.lastname = lastname;
    }

    public String getEmail() {
        return email;
    }

    public void setEmail(String email) {
        this.email = email;
    }

    public List<RoleEnum> getRoles() {
        return List.copyOf(roles);
    }

    public void setRoles(List<RoleEnum> roles) {
        this.roles = List.copyOf(roles);
    }

    public List<PermissionEnum> getPermissions() {
        return List.copyOf(permissions);
    }

    public void setPermissions(List<PermissionEnum> permissions) {
        this.permissions = List.copyOf(permissions);
    }
    //</editor-fold>
}
