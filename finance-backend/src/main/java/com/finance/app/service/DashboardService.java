package com.finance.app.service;

import com.finance.app.dto.Dto;
import com.finance.app.model.FinancialRecord;
import com.finance.app.repository.FinancialRecordRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import java.math.BigDecimal;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

@Service
@RequiredArgsConstructor
public class DashboardService {

    private final FinancialRecordRepository recordRepo;

    public Dto.DashboardSummary getSummary() {
        BigDecimal income = recordRepo.sumByType(FinancialRecord.Type.INCOME);
        BigDecimal expenses = recordRepo.sumByType(FinancialRecord.Type.EXPENSE);

        Map<String, BigDecimal> categoryTotals = new LinkedHashMap<>();
        for (Object[] row : recordRepo.sumByCategory())
            categoryTotals.put((String) row[0], (BigDecimal) row[1]);

        List<Dto.MonthlyTrend> trends = recordRepo.monthlyTrends().stream()
                .map(row -> new Dto.MonthlyTrend(
                        ((Number) row[1]).intValue(),
                        ((Number) row[0]).intValue(),
                        row[2].toString(),
                        (BigDecimal) row[3]))
                .toList();

        List<Dto.RecordResponse> recent = recordRepo
                .findTop5ByDeletedFalseOrderByCreatedAtDesc()
                .stream().map(Dto.RecordResponse::new).toList();

        Dto.DashboardSummary summary = new Dto.DashboardSummary();
        summary.setTotalIncome(income);
        summary.setTotalExpenses(expenses);
        summary.setNetBalance(income.subtract(expenses));
        summary.setTotalRecords(recordRepo.countByDeletedFalse());
        summary.setCategoryTotals(categoryTotals);
        summary.setRecentActivity(recent);
        summary.setMonthlyTrends(trends);
        return summary;
    }
}
