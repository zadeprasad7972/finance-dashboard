package com.finance.app.repository;

import com.finance.app.model.FinancialRecord;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;

public interface FinancialRecordRepository extends JpaRepository<FinancialRecord, Long> {

    List<FinancialRecord> findByDeletedFalseOrderByDateDesc();

    Page<FinancialRecord> findByDeletedFalseOrderByDateDesc(Pageable pageable);

    Page<FinancialRecord> findByTypeAndDeletedFalse(FinancialRecord.Type type, Pageable pageable);

    Page<FinancialRecord> findByCategoryIgnoreCaseAndDeletedFalse(String category, Pageable pageable);

    Page<FinancialRecord> findByDateBetweenAndDeletedFalse(LocalDate from, LocalDate to, Pageable pageable);

    Page<FinancialRecord> findByTypeAndDateBetweenAndDeletedFalse(
            FinancialRecord.Type type, LocalDate from, LocalDate to, Pageable pageable);

    @Query("SELECT r FROM FinancialRecord r WHERE r.deleted = false AND " +
           "(LOWER(r.category) LIKE LOWER(CONCAT('%', :q, '%')) OR LOWER(r.notes) LIKE LOWER(CONCAT('%', :q, '%')))")
    Page<FinancialRecord> search(@Param("q") String query, Pageable pageable);

    long countByDeletedFalse();

    @Query("SELECT COALESCE(SUM(r.amount), 0) FROM FinancialRecord r WHERE r.type = :type AND r.deleted = false")
    BigDecimal sumByType(@Param("type") FinancialRecord.Type type);

    @Query("SELECT r.category, SUM(r.amount) FROM FinancialRecord r WHERE r.deleted = false GROUP BY r.category")
    List<Object[]> sumByCategory();

    @Query("SELECT FUNCTION('MONTH', r.date), FUNCTION('YEAR', r.date), r.type, SUM(r.amount) " +
           "FROM FinancialRecord r WHERE r.deleted = false " +
           "GROUP BY FUNCTION('YEAR', r.date), FUNCTION('MONTH', r.date), r.type " +
           "ORDER BY FUNCTION('YEAR', r.date), FUNCTION('MONTH', r.date)")
    List<Object[]> monthlyTrends();

    List<FinancialRecord> findTop5ByDeletedFalseOrderByCreatedAtDesc();
}
