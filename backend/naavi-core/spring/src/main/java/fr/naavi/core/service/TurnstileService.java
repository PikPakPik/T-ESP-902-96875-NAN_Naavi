package fr.naavi.core.service;

import fr.naavi.core.properties.TurnstileProperties;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpEntity;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Service;
import org.springframework.util.LinkedMultiValueMap;
import org.springframework.util.MultiValueMap;
import org.springframework.web.client.RestTemplate;

import java.util.Map;

@Service
public class TurnstileService {
    private final RestTemplate restTemplate = new RestTemplate();

    @Autowired
    private TurnstileProperties turnstileProperties;

    /**
     * Validates a Turnstile token with the Cloudflare API.
     * Sends a verification request to Cloudflare's Turnstile service to determine
     * if the provided token is valid and the request is legitimate.
     *
     * @param token the Turnstile token to validate, obtained from the client-side widget
     * @param remoteIp the IP address of the user, optional parameter for additional validation
     * @return true if the token is valid and the request is legitimate, false otherwise
     */
    public boolean validate(String token, String remoteIp) {
        HttpHeaders headers = new HttpHeaders();
        headers.setContentType(MediaType.APPLICATION_FORM_URLENCODED);

        MultiValueMap<String, String> params = new LinkedMultiValueMap<>();
        params.add("secret", turnstileProperties.getSecretKey());
        params.add("response", token);
        if (remoteIp != null) {
            params.add("remoteip", remoteIp);
        }

        HttpEntity<MultiValueMap<String, String>> request = new HttpEntity<>(params, headers);

        try {
            Map<String, Object> response = restTemplate.postForObject(
                    turnstileProperties.getVerifyUrl(),
                    request,
                    Map.class
            );

            return response != null && Boolean.TRUE.equals(response.get("success"));
        } catch (Throwable e) {
            return false;
        }
    }
}
