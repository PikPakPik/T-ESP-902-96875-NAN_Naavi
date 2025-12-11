package fr.naavi.identity.seeder;

import fr.naavi.core.enums.PermissionEnum;
import fr.naavi.core.enums.RoleEnum;
import fr.naavi.identity.entity.User;
import fr.naavi.identity.enums.StatusEnum;
import fr.naavi.identity.repository.UserRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.stereotype.Component;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.context.TestPropertySource;

import java.util.List;

@Component
@ActiveProfiles("ci")
@TestPropertySource(locations = "classpath:application-ci.properties")
public class UserSeeder {
    @Autowired
    private UserRepository userRepository;

    public static final String NEW_USER_EMAIL = "newUser@naavi.local";
    public static final String INVALID_USER_EMAIL = "invalidUser@naavi.local";

    public static final String USER_EMAIL = "user@naavi.local";
    public static User USER = null;

    public static final String ADMIN_EMAIL = "admin@naavi.local";
    public static User ADMIN = null;

    public static final String USER_DEFAULT_PASSWORD = "azertyuiop";

    public void seedUsers() {
        userRepository.deleteAll();
        User user = this.createUser(
                "user",
                "user",
                USER_EMAIL,
                List.of(),
                List.of(),
                StatusEnum.VERIFIED
        );
        User admin = this.createUser(
                "user",
                "admin",
                ADMIN_EMAIL,
                List.of(RoleEnum.ROLE_ADMIN),
                List.of(),
                StatusEnum.VERIFIED
        );
        USER = user;
        ADMIN = admin;
        userRepository.saveAll(List.of(user, admin));
    }

    private User createUser(
            String firstname,
            String lastname,
            String email,
            List<RoleEnum> roles,
            List<PermissionEnum> permissions,
            StatusEnum status
    ) {
        User user = new User();
        user.setFirstname(firstname);
        user.setLastname(lastname);
        user.setEmail(email);
        String hashedPassword = new BCryptPasswordEncoder().encode(USER_DEFAULT_PASSWORD);
        user.setPassword(hashedPassword);
        user.setRoles(roles);
        user.setPermissions(permissions);
        user.setStatus(status);
        return user;
    }
}
