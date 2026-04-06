package com.finance.app.service;

import com.finance.app.dto.Dto;
import com.finance.app.model.User;
import com.finance.app.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import java.util.List;

@Service
@RequiredArgsConstructor
public class UserService {

    private final UserRepository userRepo;

    public List<Dto.UserResponse> getAll() {
        return userRepo.findAll().stream().map(Dto.UserResponse::new).toList();
    }

    public Dto.UserResponse getById(Long id) {
        return userRepo.findById(id)
                .map(Dto.UserResponse::new)
                .orElseThrow(() -> new IllegalArgumentException("User not found"));
    }

    public Dto.UserResponse update(Long id, Dto.UpdateUserRequest req) {
        User user = userRepo.findById(id)
                .orElseThrow(() -> new IllegalArgumentException("User not found"));
        if (req.getRole() != null) user.setRole(req.getRole());
        if (req.getStatus() != null) user.setStatus(req.getStatus());
        return new Dto.UserResponse(userRepo.save(user));
    }

    public void deactivate(Long id) {
        User user = userRepo.findById(id)
                .orElseThrow(() -> new IllegalArgumentException("User not found"));
        user.setStatus(User.Status.INACTIVE);
        userRepo.save(user);
    }
}
