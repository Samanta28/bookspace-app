# BookSpace Communication Diagram

```mermaid
flowchart LR
    FE[Flutter Web Client]
    AUTH[Auth Service\nFastAPI :8000]
    BOOK[Book Service\nFastAPI :8001]
    DB[(PostgreSQL)]

    FE -->|POST /auth/register\nPOST /auth/login\nPOST /auth/reset-password| AUTH
    FE -->|Books/Reviews/ReadingList REST + JWT| BOOK

    BOOK -->|GET /auth/verify (Bearer JWT)| AUTH

    AUTH -->|users table| DB
    BOOK -->|books, reviews,\nreading_list tables| DB
```

