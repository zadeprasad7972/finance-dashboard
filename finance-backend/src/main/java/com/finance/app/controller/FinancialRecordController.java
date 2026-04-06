package com.finance.app.controller;

import com.finance.app.dto.Dto;
import com.finance.app.model.FinancialRecord;
import com.finance.app.service.RecordService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.web.bind.annotation.*;
import java.time.LocalDate;

@RestController
@RequestMapping("/api/records")
@RequiredArgsConstructor
@Tag(name = "Financial Records", description = "CRUD and filtering for financial records")
public class FinancialRecordController {

    private final RecordService recordService;

    @Operation(summary = "List records with optional filters: type, category, from, to, search, page, size")
    @GetMapping
    public ResponseEntity<?> getAll(
            @RequestParam(required = false) FinancialRecord.Type type,
            @RequestParam(required = false) String category,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate from,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate to,
            @RequestParam(required = false) String search,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "10") int size) {
        return ResponseEntity.ok(Dto.ApiResponse.ok(
                recordService.getAll(type, category, from, to, search, page, size)));
    }

    @Operation(summary = "Get a single record by ID")
    @GetMapping("/{id}")
    public ResponseEntity<?> getById(@PathVariable Long id) {
        return ResponseEntity.ok(Dto.ApiResponse.ok(recordService.getById(id)));
    }

    @Operation(summary = "Create a new record (ANALYST, ADMIN only)")
    @PostMapping
    @PreAuthorize("hasAnyRole('ANALYST', 'ADMIN')")
    public ResponseEntity<?> create(@Valid @RequestBody Dto.RecordRequest req,
                                    @AuthenticationPrincipal UserDetails userDetails) {
        return ResponseEntity.ok(Dto.ApiResponse.ok("Record created",
                recordService.create(req, userDetails.getUsername())));
    }

    @Operation(summary = "Update an existing record (ANALYST, ADMIN only)")
    @PutMapping("/{id}")
    @PreAuthorize("hasAnyRole('ANALYST', 'ADMIN')")
    public ResponseEntity<?> update(@PathVariable Long id,
                                    @Valid @RequestBody Dto.RecordRequest req) {
        return ResponseEntity.ok(Dto.ApiResponse.ok("Record updated", recordService.update(id, req)));
    }

    @Operation(summary = "Soft-delete a record (ADMIN only)")
    @DeleteMapping("/{id}")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<?> delete(@PathVariable Long id) {
        recordService.delete(id);
        return ResponseEntity.ok(Dto.ApiResponse.ok("Record deleted", null));
    }
}
