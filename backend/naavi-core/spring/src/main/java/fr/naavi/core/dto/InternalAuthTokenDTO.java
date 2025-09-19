package fr.naavi.core.dto;

import fr.naavi.core.enums.PermissionEnum;
import fr.naavi.core.enums.RoleEnum;
import fr.naavi.core.enums.TokenType;

import java.util.List;

public class InternalAuthTokenDTO {
    private TokenType type;
    private Long userId;
    private String firstname;
    private String lastname;
    private String email;
    private List<RoleEnum> roles;
    private List<PermissionEnum> permissions;

    //<editor-fold desc="Constructor">
    public InternalAuthTokenDTO(TokenType type){
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

    public Long getUserId() {
        return userId;
    }

    public void setUserId(Long userId) {
        this.userId = userId;
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
        return roles;
    }

    public void setRoles(List<RoleEnum> roles) {
        this.roles = roles;
    }

    public List<PermissionEnum> getPermissions() {
        return permissions;
    }

    public void setPermissions(List<PermissionEnum> permissions) {
        this.permissions = permissions;
    }
    //</editor-fold>

}
