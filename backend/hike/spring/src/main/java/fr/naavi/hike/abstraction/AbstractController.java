package fr.naavi.hike.abstraction;

import fr.naavi.core.abstraction.BaseController;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;

public abstract class AbstractController extends BaseController {
    /**
     * @return The current authenticated user, or null if not authenticated.
     */
    protected Object getUser() {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        if (authentication != null) {
            return authentication.getPrincipal();
        }
        return null;
    }
}
