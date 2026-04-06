package com.finance.app.dto;

import com.finance.app.model.FinancialRecord;
import com.finance.app.model.User;
import jakarta.validation.constraints.*;
import lombok.Data;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.Map;
import java.util.List;

public class Dto {

    // ---- Auth ----
    @Data
    public static class LoginRequest {
        @NotBlank String username;
        @NotBlank String password;
    }

    @Data
    public static class RegisterRequest {
        @NotBlank @Size(min = 3, max = 50) String username;
        @NotBlank @Email String email;
        @NotBlank @Size(min = 6) String password;
    }

    @Data
    public static class AuthResponse {
        String token;
        String username;
        String role;
        public AuthResponse(String token, String username, String role) {
            this.token = token; this.username = username; this.role = role;
        }
    }

    // ---- User ----
    @Data
    public static class UserResponse {
        Long id; String username; String email;
        String role; String status; LocalDateTime createdAt;
        public UserResponse(User u) {
            id = u.getId(); username = u.getUsername(); email = u.getEmail();
            role = u.getRole().name(); status = u.getStatus().name(); createdAt = u.getCreatedAt();
        }
    }

    @Data
    public static class UpdateUserRequest {
        User.Role role;
        User.Status status;
    }

    // ---- Financial Record ----
    @Data
    public static class RecordRequest {
        @NotNull @Positive BigDecimal amount;
        @NotNull FinancialRecord.Type type;
        @NotBlank String category;
        @NotNull LocalDate date;
        String notes;
    }

    @Data
    public static class RecordResponse {
        Long id; BigDecimal amount; String type; String category;
        LocalDate date; String notes; String createdBy; LocalDateTime createdAt;
        public RecordResponse(FinancialRecord r) {
            id = r.getId(); amount = r.getAmount(); type = r.getType().name();
            category = r.getCategory(); date = r.getDate(); notes = r.getNotes();
            createdBy = r.getCreatedBy() != null ? r.getCreatedBy().getUsername() : null;
            createdAt = r.getCreatedAt();
        }
    }

    // ---- Dashboard ----
    @Data
    public static class DashboardSummary {
        BigDecimal totalIncome;
        BigDecimal totalExpenses;
        BigDecimal netBalance;
        long totalRecords;
        Map<String, BigDecimal> categoryTotals;
        List<RecordResponse> recentActivity;
        List<MonthlyTrend> monthlyTrends;
    }

    @Data
    public static class MonthlyTrend {
        int year; int month; String type; BigDecimal amount;
        public MonthlyTrend(int year, int month, String type, BigDecimal amount) {
            this.year = year; this.month = month; this.type = type; this.amount = amount;
        }
    }

    // ---- Pagination ----
    @Data
    public static class PagedResponse<T> {
        List<T> content;
        int page;
        int size;
        long totalElements;
        int totalPages;
        public PagedResponse(List<T> content, int page, int size, long totalElements) {
            this.content = content; this.page = page; this.size = size;
            this.totalElements = totalElements;
            this.totalPages = (int) Math.ceil((double) totalElements / size);
        }
    }

    // ---- Generic ----
    @Data
    public static class ApiResponse<T> {
        boolean success; String message; T data;
        public ApiResponse(boolean success, String message, T data) {
            this.success = success; this.message = message; this.data = data;
        }
        public static <T> ApiResponse<T> ok(T data) { return new ApiResponse<>(true, "Success", data); }
        public static <T> ApiResponse<T> ok(String msg, T data) { return new ApiResponse<>(true, msg, data); }
        public static <T> ApiResponse<T> error(String msg) { return new ApiResponse<>(false, msg, null); }
    }
}
