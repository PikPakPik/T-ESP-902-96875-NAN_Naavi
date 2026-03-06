package fr.naavi.identity.entity;

import fr.naavi.core.enums.PermissionEnum;
import fr.naavi.core.enums.RoleEnum;
import fr.naavi.identity.converter.PermissionsConverter;
import fr.naavi.identity.converter.RolesConverter;
import fr.naavi.identity.entitylistener.UserListener;
import fr.naavi.identity.enums.StatusEnum;
import jakarta.persistence.CascadeType;
import jakarta.persistence.Column;
import jakarta.persistence.Convert;
import jakarta.persistence.Entity;
import jakarta.persistence.EntityListeners;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.OneToMany;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;

@Entity(name = "users")
@EntityListeners(UserListener.class)
public class User {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false)
    private String firstname;

    @Column(nullable = false)
    private String lastname;

    @Column(nullable = false, unique = true)
    private String email;

    @Column(nullable = false)
    private String password;

    @Column
    private String profilePicture;

    @Column(columnDefinition = "text")
    @Convert(converter = RolesConverter.class)
    private List<RoleEnum> roles = new ArrayList<>();

    @Column(columnDefinition = "text")
    @Convert(converter = PermissionsConverter.class)
    private List<PermissionEnum> permissions = new ArrayList<>();

    @Enumerated(EnumType.STRING)
    private StatusEnum status;

    @Column(nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @Column
    private LocalDateTime updatedAt;

    @OneToMany(mappedBy = "user", cascade = CascadeType.REMOVE, orphanRemoval = true)
    private List<Authorization> authorizations = new ArrayList<>();

    @OneToMany(mappedBy = "user", cascade = CascadeType.REMOVE, orphanRemoval = true)
    private List<ResetPasswordRequest> resetPasswordRequests = new ArrayList<>();

    /**
     * @return The unique identifier of the user.
     */
    public Long getId() {
        return id;
    }

    /**
     * @return The first name of the user.
     */
    public String getFirstname() {
        return firstname;
    }

    /**
     * @param firstname The first name to set for the user.
     */
    public void setFirstname(String firstname) {
        this.firstname = firstname;
    }

    /**
     * @return The last name of the user.
     */
    public String getLastname() {
        return lastname;
    }

    /**
     * @param lastname The last name to set for the user.
     */
    public void setLastname(String lastname) {
        this.lastname = lastname;
    }

    /**
     * @return The full name of the user, combining first and last names.
     */
    public String getFullName() {
        return firstname + " " + lastname;
    }

    /**
     * @return The email address of the user.
     */
    public String getEmail() {
        return email;
    }

    /**
     * @param email The email address to set for the user.
     */
    public void setEmail(String email) {
        this.email = email;
    }

    /**
     * @return The hashed password of the user.
     */
    public String getPassword() {
        return password;
    }

    /**
     * @param password The hashed password to set for the user.
     */
    public void setPassword(String password) {
        this.password = password;
    }

    /**
     * @return The URL or path to the user's profile picture.
     */
    public String getProfilePicture() {
        return profilePicture;
    }

    /**
     * @param profilePicture The URL or path to set for the user's profile picture.
     */
    public void setProfilePicture(String profilePicture) {
        this.profilePicture = profilePicture;
    }

    /**
     * @return The list of roles assigned to the user.
     */
    public List<RoleEnum> getRoles() {
        List<RoleEnum> result = new ArrayList<>(roles);
        result.addFirst(RoleEnum.ROLE_USER);
        return result.stream().distinct().toList();
    }

    /**
     * @param roles The list of roles to set for the user.
     */
    public void setRoles(List<RoleEnum> roles) {
        this.roles = roles;
    }

    /**
     * @return The list of permissions assigned to the user.
     */
    public List<PermissionEnum> getPermissions() {
        return permissions;
    }

    /**
     * @param permissions The list of permissions to set for the user.
     */
    public void setPermissions(List<PermissionEnum> permissions) {
        this.permissions = permissions;
    }

    /**
     * @return The status of the user, indicating their verification and access level.
     */
    public StatusEnum getStatus() {
        return status;
    }

    /**
     * @param status The status to set for the user, indicating their verification and access level.
     */
    public void setStatus(StatusEnum status) {
        this.status = status;
    }

    /**
     * @return The timestamp when the user was created.
     */
    public LocalDateTime getCreatedAt() {
        return createdAt;
    }

    /**
     * @param createdAt The timestamp to set for when the user was created.
     */
    public void setCreatedAt(LocalDateTime createdAt) {
        this.createdAt = createdAt;
    }

    /**
     * @return The timestamp when the user was last updated.
     */
    public LocalDateTime getUpdatedAt() {
        return updatedAt;
    }

    /**
     * @param updatedAt The timestamp to set for when the user was last updated.
     */
    public void setUpdatedAt(LocalDateTime updatedAt) {
        this.updatedAt = updatedAt;
    }
}
