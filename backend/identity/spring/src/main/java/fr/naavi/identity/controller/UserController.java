package fr.naavi.identity.controller;

import fr.naavi.identity.abstraction.AbstractController;
import fr.naavi.identity.entity.User;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class UserController extends AbstractController {
    /**
     * Endpoint to retrieve the current authenticated user.
     * This endpoint returns the details of the user currently authenticated in the session.
     *
     * @return the User object representing the current user
     */
    @GetMapping("/user")
    public User user() {
        return this.getUser();
    }
}