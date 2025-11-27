package fr.naavi.hike.abstraction;

import fr.naavi.core.abstraction.BaseController;
import fr.naavi.core.enums.RoleEnum;
import fr.naavi.hike.dto.UserDTO;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;

public abstract class AbstractController extends BaseController {
    /**
     * @return The current authenticated user, or null if not authenticated.
     */
    protected UserDTO getUser() {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        if (authentication.getPrincipal() instanceof UserDTO) {
            return (UserDTO) authentication.getPrincipal();
        }
        return null;
    }

    /**
     * Check if the current user has the given role.
     *
     * @param role The role to check.
     * @return True if the user has the role, false otherwise.
     */
    protected boolean isGranted(RoleEnum role) {
        UserDTO user = this.getUser();
        if (user == null) {
            return false;
        }

        return user.getRoles().stream()
                .anyMatch(userRole -> userRole.equals(role));
    }
}
