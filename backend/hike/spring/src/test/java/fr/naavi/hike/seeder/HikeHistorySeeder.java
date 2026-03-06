package fr.naavi.hike.seeder;

import fr.naavi.hike.dto.UserDTO;
import fr.naavi.hike.entity.Hike;
import fr.naavi.hike.entity.HikeHistory;
import fr.naavi.hike.repository.HikeHistoryRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Component;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.context.TestPropertySource;

import java.util.ArrayList;
import java.util.List;
import java.util.concurrent.ThreadLocalRandom;

@Component
@ActiveProfiles("ci")
@TestPropertySource(locations = "classpath:application-ci.properties")
public class HikeHistorySeeder {
    @Autowired
    private HikeHistoryRepository hikeHistoryRepository;

    public void seedHistory(UserDTO userDTO, List<Hike> hikes) {
        hikeHistoryRepository.deleteAll();

        List<HikeHistory> histories = new ArrayList<>();
        for (Hike hike : hikes) {
            HikeHistory hikeHistory = new HikeHistory();
            hikeHistory.setUser(userDTO.getId());
            hikeHistory.setHike(hike);
            int randomDurationMinutes = ThreadLocalRandom.current().nextInt(1, 3600);
            hikeHistory.setDuration(randomDurationMinutes);
            histories.add(hikeHistory);
        }
        hikeHistoryRepository.saveAll(histories);
    }
}
