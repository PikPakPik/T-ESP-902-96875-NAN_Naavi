package fr.naavi.hike.seeder;

import fr.naavi.hike.repository.HikeRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.context.TestPropertySource;

import static org.junit.jupiter.api.Assertions.assertEquals;

@SpringBootTest
@ActiveProfiles("ci")
@TestPropertySource(locations = "classpath:application-ci.properties")
public class HikeSeederTest {
    @Autowired
    private HikeRepository hikeRepository;

    @Autowired
    private HikeSeeder hikeSeeder;

    @BeforeEach
    void setUp() {
        hikeRepository.deleteAll();
        hikeSeeder.seedHikes();
    }

    @Test
    void seedHikes_shouldSaveHikes() {
        long count = hikeRepository.count();
        assertEquals(HikeSeeder.COORDINATES.size() + HikeSeeder.VENDEE_COORDINATES.size(), count);
    }
}
