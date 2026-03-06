package fr.naavi.hike.service;

import org.springframework.core.ParameterizedTypeReference;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestClient;

import java.util.Map;

@Service
public class OpenStreetMapService {
    private final RestClient restClient;

    /**
     * Constructor for OpenStreetMapService.
     *
     * @param nominatimRestClient The RestClient for Nominatim (with trace propagation).
     */
    public OpenStreetMapService(RestClient nominatimRestClient) {
        this.restClient = nominatimRestClient;
    }

    /**
     * Performs reverse geocoding using OpenStreetMap's Nominatim service.
     *
     * @param lat The latitude.
     * @param lon The longitude.
     * @return null if an error occurred, the response otherwise.
     */
    public Map<String, Object> reverseGeocode(double lat, double lon) {
        Map<String, Object> response = restClient.get()
                .uri(uriBuilder -> uriBuilder
                        .path("/reverse")
                        .queryParam("lat", lat)
                        .queryParam("lon", lon)
                        .queryParam("format", "jsonv2")
                        .queryParam("zoom", 8)
                        .build())
                .retrieve()
                .body(new ParameterizedTypeReference<Map<String, Object>>() {});

        if (response != null && response.containsKey("error")) {
            return null;
        }

        return response;
    }
}
