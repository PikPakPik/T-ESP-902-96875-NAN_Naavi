package fr.naavi.hike.seeder;

import fr.naavi.hike.repository.PointOfInterestRepository;
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
public class PointOfInterestSeederTest {
    @Autowired
    private PointOfInterestRepository pointOfInterestRepository;

    @Autowired
    private PointOfInterestSeeder pointOfInterestSeeder;

    @BeforeEach
    void setUp() {
        pointOfInterestRepository.deleteAll();
        pointOfInterestSeeder.seedPointsOfInterest();
    }

    @Test
    void seedPointsOfInterest_shouldSavePointsOfInterest() {
        long count = pointOfInterestRepository.count();
        assertEquals(PointOfInterestSeeder.COORDINATES.size() + PointOfInterestSeeder.EXTRA_COORDINATES.size(), count);
    }
}
