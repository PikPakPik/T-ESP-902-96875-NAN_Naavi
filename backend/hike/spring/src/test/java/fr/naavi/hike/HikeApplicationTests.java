package fr.naavi.hike;

import org.junit.jupiter.api.Test;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.context.TestPropertySource;

@ActiveProfiles("ci")
@SpringBootTest
@TestPropertySource(locations = "classpath:application-ci.properties")
class HikeApplicationTests {

	@Test
	void contextLoads() {
	}

}
