# 📚 BookSpace

BookSpace to backendowy system do zarządzania książkami, recenzjami oraz listą „do przeczytania”.
Projekt został zbudowany w architekturze mikroserwisowej i umożliwia użytkownikom zarządzanie własną biblioteką książek oraz interakcję poprzez recenzje.

---

## Funkcjonalności

### Autoryzacja

* rejestracja użytkownika
* logowanie użytkownika
* autoryzacja przy użyciu JWT

###  Zarządzanie książkami

* dodawanie książek
* przeglądanie listy książek
* edycja książek
* usuwanie książek
* wyświetlanie szczegółów książki

### Recenzje

* dodawanie recenzji i ocen
* przeglądanie recenzji dla książki
* edycja recenzji
* usuwanie recenzji

### Lista „do przeczytania”

* dodawanie książek do listy
* przeglądanie listy użytkownika
* usuwanie książek z listy

---

## Architektura

Projekt składa się z dwóch mikroserwisów:

* **Auth Service**
  odpowiada za rejestrację, logowanie oraz generowanie tokenów JWT

* **Book Service**
  zarządza książkami, recenzjami oraz listą „do przeczytania”

Komunikacja odbywa się przez REST API.

---

## Technologie

* Python
* FastAPI
* SQLAlchemy
* SQLite *(z możliwością migracji do PostgreSQL)*
* Git (workflow: feature → develop → main)

---

## Bezpieczeństwo

* hashowanie haseł
* autoryzacja JWT
* walidacja danych wejściowych
* brak sekretów w repozytorium

---

## API

Dokumentacja API dostępna jest automatycznie po uruchomieniu aplikacji:

```bash
http://localhost:8000/docs
```

---

## Uruchomienie projektu

1. Sklonuj repozytorium:

```bash
git clone https://github.com/Samanta28/bookspace-app.git
cd bookspace-app
```

2. Zainstaluj zależności:

```bash
pip install -r requirements.txt
```

3. Uruchom serwer:

```bash
uvicorn main:app --reload
```

---

## Git Workflow

Projekt był rozwijany zgodnie z zasadami:

* brak bezpośrednich pushy do `main`
* każda zmiana przez Pull Request
* struktura branchy:

  * `main`
  * `develop`
  * `feature/*`

---

## Status projektu

Projekt ukończony – spełnia wszystkie wymagania MVP.

---

## Autor

Simona Bazhenava
