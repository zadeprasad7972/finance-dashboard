package com.finance.app.config;

import com.finance.app.model.FinancialRecord;
import com.finance.app.model.User;
import com.finance.app.repository.FinancialRecordRepository;
import com.finance.app.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.boot.CommandLineRunner;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Component;
import java.math.BigDecimal;
import java.time.LocalDate;

@Component
@RequiredArgsConstructor
public class DataSeeder implements CommandLineRunner {

    private final UserRepository userRepo;
    private final FinancialRecordRepository recordRepo;
    private final PasswordEncoder encoder;

    @Override
    public void run(String... args) {
        User admin = new User();
        admin.setUsername("admin"); admin.setEmail("admin@finance.com");
        admin.setPassword(encoder.encode("admin123")); admin.setRole(User.Role.ADMIN);
        userRepo.save(admin);

        User analyst = new User();
        analyst.setUsername("analyst"); analyst.setEmail("analyst@finance.com");
        analyst.setPassword(encoder.encode("analyst123")); analyst.setRole(User.Role.ANALYST);
        userRepo.save(analyst);

        User viewer = new User();
        viewer.setUsername("viewer"); viewer.setEmail("viewer@finance.com");
        viewer.setPassword(encoder.encode("viewer123")); viewer.setRole(User.Role.VIEWER);
        userRepo.save(viewer);

        String[][] samples = {
            {"5000", "INCOME", "Salary", "2024-01-15", "Monthly salary"},
            {"1200", "EXPENSE", "Rent", "2024-01-01", "January rent"},
            {"300", "EXPENSE", "Groceries", "2024-01-10", "Weekly groceries"},
            {"8000", "INCOME", "Freelance", "2024-02-20", "Project payment"},
            {"500", "EXPENSE", "Utilities", "2024-02-05", "Electricity bill"},
            {"5000", "INCOME", "Salary", "2024-02-15", "Monthly salary"},
            {"150", "EXPENSE", "Transport", "2024-02-18", "Monthly pass"},
            {"2000", "INCOME", "Bonus", "2024-03-01", "Q1 bonus"},
            {"5000", "INCOME", "Salary", "2024-03-15", "Monthly salary"},
            {"800", "EXPENSE", "Dining", "2024-03-22", "Team dinner"},
        };

        for (String[] s : samples) {
            FinancialRecord r = new FinancialRecord();
            r.setAmount(new BigDecimal(s[0]));
            r.setType(FinancialRecord.Type.valueOf(s[1]));
            r.setCategory(s[2]);
            r.setDate(LocalDate.parse(s[3]));
            r.setNotes(s[4]);
            r.setCreatedBy(admin);
            recordRepo.save(r);
        }
    }
}
