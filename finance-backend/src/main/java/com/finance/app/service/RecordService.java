package com.finance.app.service;

import com.finance.app.dto.Dto;
import com.finance.app.model.FinancialRecord;
import com.finance.app.model.User;
import com.finance.app.repository.FinancialRecordRepository;
import com.finance.app.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.stereotype.Service;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;

@Service
@RequiredArgsConstructor
public class RecordService {

    private final FinancialRecordRepository recordRepo;
    private final UserRepository userRepo;

    public Dto.PagedResponse<Dto.RecordResponse> getAll(
            FinancialRecord.Type type, String category,
            LocalDate from, LocalDate to, String search,
            int page, int size) {

        Pageable pageable = PageRequest.of(page, size, Sort.by("date").descending());
        Page<FinancialRecord> result;

        if (search != null && !search.isBlank()) {
            result = recordRepo.search(search.trim(), pageable);
        } else if (type != null && from != null && to != null) {
            result = recordRepo.findByTypeAndDateBetweenAndDeletedFalse(type, from, to, pageable);
        } else if (type != null) {
            result = recordRepo.findByTypeAndDeletedFalse(type, pageable);
        } else if (category != null) {
            result = recordRepo.findByCategoryIgnoreCaseAndDeletedFalse(category, pageable);
        } else if (from != null && to != null) {
            result = recordRepo.findByDateBetweenAndDeletedFalse(from, to, pageable);
        } else {
            result = recordRepo.findByDeletedFalseOrderByDateDesc(pageable);
        }

        List<Dto.RecordResponse> content = result.getContent().stream()
                .map(Dto.RecordResponse::new).toList();
        return new Dto.PagedResponse<>(content, page, size, result.getTotalElements());
    }

    public Dto.RecordResponse getById(Long id) {
        return recordRepo.findById(id)
                .filter(r -> !r.isDeleted())
                .map(Dto.RecordResponse::new)
                .orElseThrow(() -> new IllegalArgumentException("Record not found"));
    }

    public Dto.RecordResponse create(Dto.RecordRequest req, String username) {
        User user = userRepo.findByUsername(username).orElseThrow();
        FinancialRecord record = new FinancialRecord();
        record.setAmount(req.getAmount());
        record.setType(req.getType());
        record.setCategory(req.getCategory());
        record.setDate(req.getDate());
        record.setNotes(req.getNotes());
        record.setCreatedBy(user);
        return new Dto.RecordResponse(recordRepo.save(record));
    }

    public Dto.RecordResponse update(Long id, Dto.RecordRequest req) {
        FinancialRecord record = recordRepo.findById(id)
                .filter(r -> !r.isDeleted())
                .orElseThrow(() -> new IllegalArgumentException("Record not found"));
        record.setAmount(req.getAmount());
        record.setType(req.getType());
        record.setCategory(req.getCategory());
        record.setDate(req.getDate());
        record.setNotes(req.getNotes());
        record.setUpdatedAt(LocalDateTime.now());
        return new Dto.RecordResponse(recordRepo.save(record));
    }

    public void delete(Long id) {
        FinancialRecord record = recordRepo.findById(id)
                .filter(r -> !r.isDeleted())
                .orElseThrow(() -> new IllegalArgumentException("Record not found"));
        record.setDeleted(true);
        recordRepo.save(record);
    }
}
