package fr.naavi.identity.controller;

import fr.naavi.identity.configuration.CacheConfigurationTest;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.webmvc.test.autoconfigure.WebMvcTest;
import org.springframework.context.annotation.Import;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.context.TestPropertySource;
import org.springframework.test.web.servlet.MockMvc;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.content;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@ActiveProfiles("ci")
@WebMvcTest(HealthcheckController.class)
@TestPropertySource(locations = "classpath:application-ci.properties")
@Import(CacheConfigurationTest.class)
public class HealthcheckControllerTest {
    @Autowired
    private MockMvc mockMvc;

    @Test
    void healthCheck_shouldReturnOk() throws Exception {
        mockMvc.perform(get("/healthcheck"))
                .andExpect(status().isOk())
                .andExpect(content().contentType("application/json"))
                .andExpect(jsonPath("$.service").value("identity"))
                .andExpect(jsonPath("$.i18nKey").value("healthcheck.success"))
                .andExpect(jsonPath("$.message").value("Service is running"))
                .andExpect(jsonPath("$.timestamp").isNumber());
    }

//    @Test
//    void healthCheck_ShouldReturnError_WhenDatabaseIsDown() throws Exception {
//        when(dataSource.getConnection()).thenThrow(new SQLException("Database is down"));
//
//        mockMvc.perform(get("/healthcheck"))
//                .andExpect(status().is5xxServerError())
//                .andExpect(jsonPath("$.service").value("identity"))
//                .andExpect(jsonPath("$.i18nKey").value("healthcheck.error"))
//                .andExpect(jsonPath("$.message").value("Service is down"))
//                .andExpect(jsonPath("$.timestamp").exists());
//    }
}
