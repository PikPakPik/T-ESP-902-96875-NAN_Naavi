package fr.naavi.hike;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.cache.annotation.EnableCaching;

@EnableCaching
@SpringBootApplication
public class HikeApplication {
	/**
	 * @param args Command line arguments
	 */
	public static void main(String[] args) {
		SpringApplication.run(HikeApplication.class, args);
	}
}