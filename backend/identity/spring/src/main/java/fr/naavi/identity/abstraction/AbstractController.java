package fr.naavi.identity.abstraction;

import fr.naavi.core.abstraction.BaseController;
import fr.naavi.identity.entity.User;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;

public abstract class AbstractController extends BaseController {
    /**
     * @return The current authenticated user, or null if not authenticated.
     */
    protected User getUser() {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        if (authentication.getPrincipal() instanceof User) {
            return (User) authentication.getPrincipal();
        }
        return null;
    }
}
