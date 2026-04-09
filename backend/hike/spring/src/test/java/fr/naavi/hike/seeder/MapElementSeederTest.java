package fr.naavi.hike.seeder;

import fr.naavi.hike.repository.MapElementRepository;
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
public class MapElementSeederTest {
    @Autowired
    private MapElementRepository mapElementRepository;

    @Autowired
    private MapElementSeeder mapElementRepositorySeeder;

    @BeforeEach
    void setUp() {
        mapElementRepository.deleteAll();
        mapElementRepositorySeeder.seedMapElements();
    }

    @Test
    void seedPointsOfInterest_shouldSavePointsOfInterest() {
        long count = mapElementRepository.count();
        assertEquals(MapElementSeeder.COORDINATES.size() + MapElementSeeder.EXTRA_COORDINATES.size(), count);
    }
}
