package fr.naavi.identity.security;

import fr.naavi.identity.dto.output.AuthenticationDTO;
import fr.naavi.identity.entity.User;
import fr.naavi.identity.enums.StatusEnum;
import fr.naavi.identity.exception.BannedException;
import fr.naavi.identity.exception.UnverifiedException;
import fr.naavi.identity.service.AuthenticationService;
import fr.naavi.identity.service.UserService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.authentication.AuthenticationProvider;
import org.springframework.security.authentication.BadCredentialsException;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.AuthenticationException;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Component;

import java.util.Map;

@Component
public class LoginAuthenticationProvider implements AuthenticationProvider {
    private final UserService userService;
    private final PasswordEncoder passwordEncoder;
    private final AuthenticationService authenticationService;

    /**
     * Constructor for LoginAuthenticationProvider.
     *
     * @param userService        the user service to check user existence and credentials
     * @param passwordEncoder    the password encoder to verify user passwords
     * @param authenticationService the authentication service to generate JWT tokens
     */
    @Autowired
    public LoginAuthenticationProvider(
            UserService userService,
            PasswordEncoder passwordEncoder,
            AuthenticationService authenticationService
    ) {
        this.userService = userService;
        this.passwordEncoder = passwordEncoder;
        this.authenticationService = authenticationService;
    }

    /**
     * Checks if the authentication provider supports the given authentication type.
     *
     * @param authentication the authentication type to check
     * @return true if the authentication type is supported, false otherwise
     */
    @Override
    public boolean supports(Class<?> authentication) {
        return UsernamePasswordAuthenticationToken.class.isAssignableFrom(authentication);
    }

    /**
     * Authenticates the user based on the provided authentication details.
     *
     * @param authentication the authentication details containing username and password
     * @return an authenticated token with user details and JWT
     * @throws AuthenticationException if authentication fails
     */
    @Override
    public Authentication authenticate(Authentication authentication) throws AuthenticationException {
        String email = authentication.getName();
        String password = authentication.getCredentials().toString();

        User user = userService.checkIfUserExists(email);
        if (user == null) {
            throw new BadCredentialsException("User not found");
        }

        if (!this.passwordEncoder.matches(password, user.getPassword())) {
            throw new BadCredentialsException("Invalid credentials provided.");
        }

        if (user.getStatus() != StatusEnum.VERIFIED) {
            throw new UnverifiedException();
        }

        if (user.getStatus().equals(StatusEnum.BANNED)) {
            throw new BannedException();
        }

        Map<String, String> accessToken = this.authenticationService.accessToken();
        Map<String, String> refreshToken = this.authenticationService.refreshToken();

        this.authenticationService.createSession(user, accessToken.get("sessId"), refreshToken.get("sessId"));

        UsernamePasswordAuthenticationToken authToken = new UsernamePasswordAuthenticationToken(user, password, null);
        authToken.setDetails(new AuthenticationDTO(accessToken.get("token"), refreshToken.get("token")));

        return authToken;
    }
}
