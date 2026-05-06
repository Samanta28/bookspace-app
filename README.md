# BookSpace

BookSpace is a Flutter Web application with a FastAPI backend for managing books, reviews and reading lists. The project is built as a small microservice system with JWT authentication and a PostgreSQL database.

The active frontend is `frontend_flutter`. The legacy `frontend/index.html` is not part of the current application.

## Features

- user registration, login and logout
- JWT-based authorization
- password hashing with bcrypt
- book catalog with genres
- adding custom books with title, author, publication year, genre, description and cover image
- cover image as a URL or uploaded image converted in the browser
- editing and deleting books added by the current user
- adding books to the To Read list
- tracking reading progress with a slider
- moving books from To Read to My Read Books
- adding, editing and deleting the current user's reviews
- star ratings based on user reviews
- review count displayed next to every rating
- dynamic Highest Rated ranking based on user reviews
- New Books view based on books published in 2026
- light and dark mode
- local browser cache fallback when the Book Service is unavailable

## Architecture

The project uses two backend services:

### Auth Service

Location: `backend/auth_service`

Responsibilities:

- user registration
- user login
- password reset
- JWT token generation
- user table initialization

Default URL:

```text
http://127.0.0.1:8000
```

### Book Service

Location: `backend/book_service`

Responsibilities:

- book CRUD
- review CRUD
- reading list CRUD
- rating/review data
- database schema initialization for book-related tables
- JWT verification via Auth Service (`GET /auth/verify`)

Default URL:

```text
http://127.0.0.1:8001
```

## Technology Stack

Backend:

- Python
- FastAPI
- SQLAlchemy
- PostgreSQL
- python-jose for JWT
- passlib with bcrypt
- python-dotenv
- Uvicorn

Frontend:

- Flutter Web
- Dart
- Material 3
- browser `localStorage` for local UI state/cache

## Project Structure

```text
bookspace-app/
  backend/
    .env
    requirements.txt
    auth_service/
      main.py
      database.py
      models.py
    book_service/
      main.py
      database.py
      models.py
  frontend_flutter/
    lib/main.dart
    pubspec.yaml
    web/index.html
  README.md
```

## Environment

Create `backend/.env` with values matching your local PostgreSQL setup:

```env
DATABASE_URL=postgresql://USER:PASSWORD@localhost:5432/DB_NAME
SECRET_KEY=your-secret-key
JWT_ALGORITHM=HS256
AUTH_SERVICE_URL=http://127.0.0.1:8000
```

`ALGORITHM` is also supported by the backend as a fallback name, but `JWT_ALGORITHM` is preferred.

## Installation

Install backend dependencies:

```bash
pip install -r backend/requirements.txt
```

Install Flutter dependencies:

```bash
cd frontend_flutter
flutter pub get
```

## Running Locally

Start Auth Service:

```bash
cd backend/auth_service
python -m uvicorn main:app --host 127.0.0.1 --port 8000 --reload
```

Start Book Service in a second terminal:

```bash
cd backend/book_service
python -m uvicorn main:app --host 127.0.0.1 --port 8001 --reload
```

Start Flutter Web in a third terminal:

```bash
cd frontend_flutter
flutter run -d chrome
```

If Flutter reports that hot reload cannot apply class shape changes, perform a hot restart or stop and run the app again.

## API Documentation

FastAPI exposes Swagger documentation here:

```text
http://127.0.0.1:8000/docs
http://127.0.0.1:8001/docs
```

## Communication Diagram

Architecture diagram is available here:

- [docs/diagram.md](docs/diagram.md)

## Main API Areas

Auth Service:

- `POST /auth/register`
- `POST /auth/login`
- `POST /auth/reset-password`

Book Service:

- `GET /books`
- `GET /books/{id}`
- `POST /books`
- `PUT /books/{id}`
- `DELETE /books/{id}`
- `GET /reviews`
- `GET /reviews/book/{id}`
- `POST /reviews`
- `PUT /reviews/{id}`
- `DELETE /reviews/{id}`
- `GET /reading-list`
- `POST /reading-list`
- `PUT /reading-list/{id}`
- `DELETE /reading-list/{id}`

Protected endpoints require:

```text
Authorization: Bearer <JWT_TOKEN>
```

## Git Workflow

The project workflow is:

```text
feature -> develop -> main
```

Direct pushes to `main` are avoided. Changes should be merged through Pull Requests.

## Status

The MVP is complete and includes authentication, book management, reviews, reading list handling and the Flutter Web interface.
