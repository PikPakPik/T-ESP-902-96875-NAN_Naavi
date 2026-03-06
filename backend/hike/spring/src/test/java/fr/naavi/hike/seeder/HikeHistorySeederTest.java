package fr.naavi.hike.seeder;

import fr.naavi.hike.entity.Hike;
import fr.naavi.hike.repository.HikeHistoryRepository;
import fr.naavi.hike.repository.HikeRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.stereotype.Component;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.context.TestPropertySource;

import java.util.List;

import static org.junit.jupiter.api.Assertions.assertEquals;

@SpringBootTest
@ActiveProfiles("ci")
@TestPropertySource(locations = "classpath:application-ci.properties")
public class HikeHistorySeederTest {
    @Autowired
    private HikeHistoryRepository hikeHistoryRepository;

    @Autowired
    private HikeRepository hikeRepository;

    @Autowired
    private HikeHistorySeeder hikeHistorySeeder;

    @Autowired
    private HikeSeeder hikeSeeder;

    @Autowired
    private UserSeeder userSeeder;

    @BeforeEach
    void setUp() {
        hikeHistoryRepository.deleteAll();
        hikeSeeder.seedHikes();
        userSeeder.seedUsers();
    }

    @Test
    void seedHistory() {
        List<Hike> hikes = hikeRepository.findAll();
        hikeHistorySeeder.seedHistory(UserSeeder.USER, hikes);
        long count = hikeHistoryRepository.count();
        assertEquals(hikes.size(), count);
    }
}
