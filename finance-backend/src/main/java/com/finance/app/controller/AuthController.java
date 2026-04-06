package com.finance.app.controller;

import com.finance.app.dto.Dto;
import com.finance.app.service.AuthService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/auth")
@RequiredArgsConstructor
@Tag(name = "Authentication", description = "Login, register, and profile endpoints")
public class AuthController {

    private final AuthService authService;

    @Operation(summary = "Login and receive JWT token")
    @PostMapping("/login")
    public ResponseEntity<?> login(@Valid @RequestBody Dto.LoginRequest req) {
        return ResponseEntity.ok(Dto.ApiResponse.ok(authService.login(req)));
    }

    @Operation(summary = "Register a new account (VIEWER role by default)")
    @PostMapping("/register")
    public ResponseEntity<?> register(@Valid @RequestBody Dto.RegisterRequest req) {
        authService.register(req);
        return ResponseEntity.ok(Dto.ApiResponse.ok("Registered successfully", null));
    }

    @Operation(summary = "Get current logged-in user profile")
    @GetMapping("/me")
    public ResponseEntity<?> me(@AuthenticationPrincipal UserDetails userDetails) {
        return ResponseEntity.ok(Dto.ApiResponse.ok(authService.getProfile(userDetails.getUsername())));
    }
}
