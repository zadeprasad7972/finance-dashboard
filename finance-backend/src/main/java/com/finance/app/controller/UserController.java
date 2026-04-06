package com.finance.app.controller;

import com.finance.app.dto.Dto;
import com.finance.app.service.UserService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/users")
@RequiredArgsConstructor
@PreAuthorize("hasRole('ADMIN')")
@Tag(name = "User Management", description = "Admin-only user management endpoints")
public class UserController {

    private final UserService userService;

    @Operation(summary = "List all users")
    @GetMapping
    public ResponseEntity<?> getAll() {
        return ResponseEntity.ok(Dto.ApiResponse.ok(userService.getAll()));
    }

    @Operation(summary = "Get user by ID")
    @GetMapping("/{id}")
    public ResponseEntity<?> getById(@PathVariable Long id) {
        return ResponseEntity.ok(Dto.ApiResponse.ok(userService.getById(id)));
    }

    @Operation(summary = "Update user role or status")
    @PutMapping("/{id}")
    public ResponseEntity<?> update(@PathVariable Long id,
                                    @RequestBody Dto.UpdateUserRequest req) {
        return ResponseEntity.ok(Dto.ApiResponse.ok("User updated", userService.update(id, req)));
    }

    @Operation(summary = "Deactivate a user (soft delete)")
    @DeleteMapping("/{id}")
    public ResponseEntity<?> delete(@PathVariable Long id) {
        userService.deactivate(id);
        return ResponseEntity.ok(Dto.ApiResponse.ok("User deactivated", null));
    }
}
