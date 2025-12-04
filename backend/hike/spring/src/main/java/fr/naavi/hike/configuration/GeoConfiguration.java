package fr.naavi.hike.configuration;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
public class GeoConfiguration {
    /**
     * Gets the earth radius in kilometers.
     *
     * @return the earth radius in km
     */
    @Bean
    public Double earthRadius() {
        return 6371.0;
    }
}