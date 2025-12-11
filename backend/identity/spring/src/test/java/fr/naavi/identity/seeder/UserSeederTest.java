package fr.naavi.identity.seeder;

import fr.naavi.identity.entity.User;
import fr.naavi.identity.repository.UserRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.context.TestPropertySource;

import java.util.Optional;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;

@SpringBootTest
@ActiveProfiles("ci")
@TestPropertySource(locations = "classpath:application-ci.properties")
class UserSeederTest {
    @Autowired
    private UserRepository userRepository;

    @Autowired
    private UserSeeder userSeeder;

    @BeforeEach
    void setUp() {
        userRepository.deleteAll();
        userSeeder.seedUsers();
    }

    @Test
    void seedUsers_shouldSaveUsers() {
        long count = userRepository.count();
        assertEquals(2, count);
    }

    @Test
    void shouldRetrieveUserByEmail() {
        String email = UserSeeder.USER_EMAIL;
        Optional<User> user = userRepository.findByEmail(email);

        assertTrue(user.isPresent());
        assertEquals(email, user.get().getEmail());
        assertEquals("user", user.get().getFirstname());
    }
}
