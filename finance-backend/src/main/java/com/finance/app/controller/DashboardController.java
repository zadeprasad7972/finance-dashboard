package com.finance.app.controller;

import com.finance.app.dto.Dto;
import com.finance.app.service.DashboardService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/dashboard")
@RequiredArgsConstructor
@Tag(name = "Dashboard", description = "Aggregated summary and analytics endpoints")
public class DashboardController {

    private final DashboardService dashboardService;

    @Operation(summary = "Get full dashboard summary: totals, trends, category breakdown, recent activity")
    @GetMapping("/summary")
    public ResponseEntity<?> getSummary() {
        return ResponseEntity.ok(Dto.ApiResponse.ok(dashboardService.getSummary()));
    }
}
