package fr.naavi.hike.seeder;

import fr.naavi.core.enums.RoleEnum;
import fr.naavi.hike.dto.UserDTO;
import org.springframework.stereotype.Component;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.context.TestPropertySource;

import java.util.List;

@Component
@ActiveProfiles("ci")
@TestPropertySource(locations = "classpath:application-ci.properties")
public class UserSeeder {
    public static UserDTO USER = null;
    public static UserDTO ADMIN = null;

    public void seedUsers() {
        USER = new UserDTO();
        USER.setId(1L);
        USER.setFirstname("User");
        USER.setLastname("Logged");
        USER.setEmail("user@naavi.local");
        USER.setRoles(List.of(RoleEnum.ROLE_USER));

        ADMIN = new UserDTO();
        ADMIN.setId(2L);
        ADMIN.setFirstname("User");
        ADMIN.setLastname("Admin");
        ADMIN.setEmail("admin@naavi.local");
        ADMIN.setRoles(List.of(RoleEnum.ROLE_USER, RoleEnum.ROLE_ADMIN));
    }
}
