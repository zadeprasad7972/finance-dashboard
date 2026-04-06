package com.finance.app;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.finance.app.dto.Dto;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.MvcResult;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@SpringBootTest
@AutoConfigureMockMvc
class FinanceApplicationTests {

    @Autowired MockMvc mvc;
    @Autowired ObjectMapper mapper;

    private String adminToken;
    private String analystToken;
    private String viewerToken;

    @BeforeEach
    void setup() throws Exception {
        adminToken   = login("admin",   "admin123");
        analystToken = login("analyst", "analyst123");
        viewerToken  = login("viewer",  "viewer123");
    }

    // ---- Auth ----

    @Test
    void loginSuccess() throws Exception {
        mvc.perform(post("/api/auth/login")
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"username\":\"admin\",\"password\":\"admin123\"}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data.token").isNotEmpty())
                .andExpect(jsonPath("$.data.role").value("ADMIN"));
    }

    @Test
    void loginWrongPassword() throws Exception {
        mvc.perform(post("/api/auth/login")
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"username\":\"admin\",\"password\":\"wrong\"}"))
                .andExpect(status().isUnauthorized());
    }

    @Test
    void loginValidationFails() throws Exception {
        mvc.perform(post("/api/auth/login")
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"username\":\"\",\"password\":\"\"}"))
                .andExpect(status().isBadRequest());
    }

    @Test
    void getProfileRequiresAuth() throws Exception {
        mvc.perform(get("/api/auth/me"))
                .andExpect(status().isForbidden());
    }

    @Test
    void getProfileWithToken() throws Exception {
        mvc.perform(get("/api/auth/me").header("Authorization", "Bearer " + adminToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.username").value("admin"))
                .andExpect(jsonPath("$.data.role").value("ADMIN"));
    }

    // ---- Dashboard ----

    @Test
    void dashboardAccessibleByAllRoles() throws Exception {
        for (String token : new String[]{adminToken, analystToken, viewerToken}) {
            mvc.perform(get("/api/dashboard/summary")
                    .header("Authorization", "Bearer " + token))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$.data.totalIncome").isNumber())
                    .andExpect(jsonPath("$.data.totalExpenses").isNumber())
                    .andExpect(jsonPath("$.data.netBalance").isNumber())
                    .andExpect(jsonPath("$.data.totalRecords").isNumber());
        }
    }

    @Test
    void dashboardRequiresAuth() throws Exception {
        mvc.perform(get("/api/dashboard/summary"))
                .andExpect(status().isForbidden());
    }

    // ---- Records ----

    @Test
    void recordsListAccessibleByAllRoles() throws Exception {
        mvc.perform(get("/api/records").header("Authorization", "Bearer " + viewerToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.content").isArray())
                .andExpect(jsonPath("$.data.totalElements").isNumber());
    }

    @Test
    void recordsFilterByType() throws Exception {
        mvc.perform(get("/api/records?type=INCOME")
                .header("Authorization", "Bearer " + viewerToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.content").isArray());
    }

    @Test
    void recordsSearch() throws Exception {
        mvc.perform(get("/api/records?search=salary")
                .header("Authorization", "Bearer " + viewerToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.content").isArray());
    }

    @Test
    void viewerCannotCreateRecord() throws Exception {
        mvc.perform(post("/api/records")
                .header("Authorization", "Bearer " + viewerToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"amount\":100,\"type\":\"INCOME\",\"category\":\"Test\",\"date\":\"2024-01-01\"}"))
                .andExpect(status().isForbidden());
    }

    @Test
    void analystCanCreateRecord() throws Exception {
        mvc.perform(post("/api/records")
                .header("Authorization", "Bearer " + analystToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"amount\":500,\"type\":\"INCOME\",\"category\":\"Test\",\"date\":\"2024-06-01\",\"notes\":\"Test record\"}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.category").value("Test"));
    }

    @Test
    void viewerCannotDeleteRecord() throws Exception {
        mvc.perform(delete("/api/records/1")
                .header("Authorization", "Bearer " + viewerToken))
                .andExpect(status().isForbidden());
    }

    @Test
    void analystCannotDeleteRecord() throws Exception {
        mvc.perform(delete("/api/records/1")
                .header("Authorization", "Bearer " + analystToken))
                .andExpect(status().isForbidden());
    }

    @Test
    void adminCanDeleteRecord() throws Exception {
        // First create a record to delete
        MvcResult result = mvc.perform(post("/api/records")
                .header("Authorization", "Bearer " + adminToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"amount\":100,\"type\":\"EXPENSE\",\"category\":\"ToDelete\",\"date\":\"2024-01-01\"}"))
                .andExpect(status().isOk())
                .andReturn();
        int id = mapper.readTree(result.getResponse().getContentAsString())
                .path("data").path("id").asInt();

        mvc.perform(delete("/api/records/" + id)
                .header("Authorization", "Bearer " + adminToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true));
    }

    @Test
    void createRecordValidationFails() throws Exception {
        mvc.perform(post("/api/records")
                .header("Authorization", "Bearer " + analystToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"amount\":-100,\"type\":\"INCOME\",\"category\":\"\",\"date\":null}"))
                .andExpect(status().isBadRequest());
    }

    // ---- Users ----

    @Test
    void onlyAdminCanListUsers() throws Exception {
        mvc.perform(get("/api/users").header("Authorization", "Bearer " + viewerToken))
                .andExpect(status().isForbidden());
        mvc.perform(get("/api/users").header("Authorization", "Bearer " + analystToken))
                .andExpect(status().isForbidden());
        mvc.perform(get("/api/users").header("Authorization", "Bearer " + adminToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data").isArray());
    }

    // ---- Helper ----

    private String login(String username, String password) throws Exception {
        MvcResult result = mvc.perform(post("/api/auth/login")
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"username\":\"" + username + "\",\"password\":\"" + password + "\"}"))
                .andReturn();
        return mapper.readTree(result.getResponse().getContentAsString())
                .path("data").path("token").asText();
    }
}
