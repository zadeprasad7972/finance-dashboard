# Finance Data Processing and Access Control Backend

A full-stack finance dashboard — **Java Spring Boot** backend + **Flutter** frontend.

---

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Backend | Java 17, Spring Boot 3.2, Spring Security, JWT |
| Database | H2 In-Memory (auto-seeded on startup) |
| API Docs | SpringDoc OpenAPI 2.3 (Swagger UI) |
| Frontend | Flutter 3.x, Provider, fl_chart |

---

## Project Structure

```
├── finance-backend/
│   └── src/main/java/com/finance/app/
│       ├── config/       SecurityConfig, OpenApiConfig, DataSeeder, GlobalExceptionHandler
│       ├── controller/   AuthController, FinancialRecordController, DashboardController, UserController
│       ├── service/      AuthService, RecordService, DashboardService, UserService
│       ├── dto/          Dto.java (all request/response DTOs + pagination)
│       ├── model/        User, FinancialRecord
│       ├── repository/   UserRepository, FinancialRecordRepository
│       └── security/     JwtUtil, JwtFilter, UserDetailsServiceImpl
│   └── src/test/         FinanceApplicationTests (integration tests)
│
└── finance_flutter/
    └── lib/
        ├── models/       models.dart
        ├── providers/    AuthProvider
        ├── screens/      Login, Register, Home, Dashboard, Records, Users, Profile
        ├── services/     ApiService
        └── widgets/      AppCard, AppTextField, AppButton, RoleBadge, EmptyState, ErrorState
```

---

## Quick Start

### Backend

**Prerequisites:** Java 17+

```bash
cd finance-backend
mvnw.cmd spring-boot:run        # Windows
./mvnw spring-boot:run          # Mac/Linux
```

- API: `http://localhost:8080`
- Swagger UI: `http://localhost:8080/swagger-ui.html`
- H2 Console: `http://localhost:8080/h2-console`
  - JDBC URL: `jdbc:h2:mem:financedb` | Username: `sa` | Password: *(empty)*

### Flutter App

**Prerequisites:** Flutter 3.x

```bash
cd finance_flutter
flutter pub get
flutter run -d chrome
```

> Start the backend before launching Flutter.

---

## Demo Accounts (auto-seeded)

| Username | Password | Role | Permissions |
|----------|----------|------|-------------|
| admin | admin123 | ADMIN | Full access |
| analyst | analyst123 | ANALYST | View + Create/Edit records |
| viewer | viewer123 | VIEWER | Read only |

---

## API Reference

### Auth
| Method | Endpoint | Auth | Description |
|--------|----------|------|-------------|
| POST | `/api/auth/login` | Public | Login, returns JWT |
| POST | `/api/auth/register` | Public | Register (VIEWER by default) |
| GET | `/api/auth/me` | Any | Current user profile |

### Financial Records
| Method | Endpoint | Access | Description |
|--------|----------|--------|-------------|
| GET | `/api/records` | All | Paginated list. Params: `type`, `category`, `from`, `to`, `search`, `page`, `size` |
| GET | `/api/records/{id}` | All | Get single record |
| POST | `/api/records` | ANALYST, ADMIN | Create record |
| PUT | `/api/records/{id}` | ANALYST, ADMIN | Update record |
| DELETE | `/api/records/{id}` | ADMIN | Soft delete |

### Dashboard
| Method | Endpoint | Access | Description |
|--------|----------|--------|-------------|
| GET | `/api/dashboard/summary` | All | Income, expenses, net balance, total records, category totals, monthly trends, recent activity |

### Users
| Method | Endpoint | Access | Description |
|--------|----------|--------|-------------|
| GET | `/api/users` | ADMIN | List all users |
| GET | `/api/users/{id}` | ADMIN | Get user |
| PUT | `/api/users/{id}` | ADMIN | Update role/status |
| DELETE | `/api/users/{id}` | ADMIN | Deactivate user |

---

## Access Control Matrix

| Action | VIEWER | ANALYST | ADMIN |
|--------|--------|---------|-------|
| View records & dashboard | ✅ | ✅ | ✅ |
| Create / Update records | ❌ | ✅ | ✅ |
| Delete records | ❌ | ❌ | ✅ |
| Manage users | ❌ | ❌ | ✅ |

---

## Features Implemented

- ✅ JWT Authentication (stateless, token carries username + role)
- ✅ Role-based access control (URL-level + `@PreAuthorize` method-level)
- ✅ User management (create, assign roles, activate/deactivate)
- ✅ Financial records CRUD with soft delete
- ✅ Filtering by type, category, date range, and full-text search
- ✅ Pagination on all record listings
- ✅ Dashboard aggregation (totals, net balance, category breakdown, monthly trends)
- ✅ Input validation with Jakarta Bean Validation
- ✅ Global error handling (400, 401, 403, 500)
- ✅ Swagger UI API documentation
- ✅ Integration tests (17 test cases covering all roles and endpoints)
- ✅ Flutter UI with role-aware screens

---

## Key Design Decisions

1. **Service Layer** — Business logic lives in `AuthService`, `RecordService`, `UserService`, `DashboardService`. Controllers are thin and only handle HTTP concerns.
2. **Two-layer access control** — Spring Security URL rules as the first gate, `@PreAuthorize` as the second. Both must pass.
3. **Soft Delete** — Records flagged `deleted=true`, never physically removed. Preserves audit history.
4. **H2 In-Memory DB** — Zero setup. Swap to PostgreSQL by changing 3 lines in `application.properties`.
5. **Dashboard aggregation in DB** — `SUM`, `GROUP BY` done via JPQL queries, not in-memory. Scales correctly.
6. **Pagination** — All record listings return `PagedResponse` with `content`, `page`, `totalPages`, `totalElements`.

---

## Sample curl Requests

```bash
# Login
curl -X POST http://localhost:8080/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"admin123"}'

# Get dashboard
curl http://localhost:8080/api/dashboard/summary \
  -H "Authorization: Bearer <token>"

# Create a record
curl -X POST http://localhost:8080/api/records \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -d '{"amount":1500,"type":"INCOME","category":"Freelance","date":"2024-04-01","notes":"Project X"}'

# Search records
curl "http://localhost:8080/api/records?search=salary&page=0&size=5" \
  -H "Authorization: Bearer <token>"

# Filter by type and date range
curl "http://localhost:8080/api/records?type=EXPENSE&from=2024-01-01&to=2024-03-31" \
  -H "Authorization: Bearer <token>"
```

---

## Running Tests

```bash
cd finance-backend
mvnw.cmd test        # Windows
./mvnw test          # Mac/Linux
```

17 integration tests covering: login, validation, role enforcement, CRUD, dashboard, and user management.
