package fr.naavi.identity.controller;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.context.TestPropertySource;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;
import org.springframework.web.context.WebApplicationContext;

import javax.sql.DataSource;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@ActiveProfiles("ci")
@WebMvcTest(HealthcheckController.class)
@TestPropertySource(locations = "classpath:application-ci.properties")
class HealthcheckControllerTest {

    @Autowired
    private WebApplicationContext webApplicationContext;

    @Autowired
    private MockMvc mockMvc;

    @MockitoBean
    private DataSource dataSource;

    @BeforeEach
    void setUp() {
        mockMvc = MockMvcBuilders.webAppContextSetup(webApplicationContext).build();
    }

    @Test
    void healthCheck_ShouldReturnHealthStatus() throws Exception {
        mockMvc.perform(get("/healthcheck"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.service").value("identity"))
                .andExpect(jsonPath("$.i18nKey").value("healthcheck.success"))
                .andExpect(jsonPath("$.message").value("Service is running"))
                .andExpect(jsonPath("$.timestamp").exists());
    }

//    @Test
//    void healthCheck_ShouldReturnError_WhenDatabaseIsDown() throws Exception {
//        when(dataSource.getConnection()).thenThrow(new SQLException("DB KO"));
//
//        mockMvc.perform(get("/healthcheck"))
//                .andExpect(status().is5xxServerError())
//                .andExpect(jsonPath("$.service").value("identity"))
//                .andExpect(jsonPath("$.i18nKey").value("healthcheck.error"))
//                .andExpect(jsonPath("$.message").value("Service is down"))
//                .andExpect(jsonPath("$.timestamp").exists());
//    }
}
