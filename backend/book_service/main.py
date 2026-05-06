import os
from typing import Optional

from dotenv import load_dotenv
from fastapi import Depends, FastAPI, HTTPException, Query
from fastapi.middleware.cors import CORSMiddleware
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from jose import JWTError, jwt
from pydantic import BaseModel, Field
from sqlalchemy import text

try:
    from .database import SessionLocal, engine
    from .models import Base, Book, ReadingList, Review
except ImportError:
    from database import SessionLocal, engine
    from models import Base, Book, ReadingList, Review

load_dotenv("../.env")

SECRET_KEY = os.getenv("SECRET_KEY")
ALGORITHM = os.getenv("JWT_ALGORITHM") or os.getenv("ALGORITHM")

if not SECRET_KEY or not ALGORITHM:
    raise RuntimeError("SECRET_KEY and ALGORITHM must be set")

app = FastAPI(title="BookSpace Book Service")

app.add_middleware(
    CORSMiddleware,
    allow_origins=[
        "http://localhost:8000",
        "http://127.0.0.1:8000",
    ],
    allow_origin_regex=r"http://(localhost|127\.0\.0\.1)(:\d+)?",
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

security = HTTPBearer()


class BookRequest(BaseModel):
    title: str
    author: str
    description: Optional[str] = None
    year: Optional[str] = None
    rating: Optional[float] = None
    genre: Optional[str] = None
    image_url: Optional[str] = None
    status: Optional[str] = "read"


class ReviewRequest(BaseModel):
    content: str
    rating: int = Field(ge=1, le=5)
    book_id: int


class ReadingListRequest(BaseModel):
    book_id: int
    progress: int = Field(default=0, ge=0, le=100)
    status: str = "to_read"


def api_error(status_code: int, code: str, message: str, details: object = None):
    raise HTTPException(
        status_code=status_code,
        detail={
            "code": code,
            "message": message,
            "details": details,
        },
    )


def get_current_user(credentials: HTTPAuthorizationCredentials = Depends(security)):
    try:
        payload = jwt.decode(credentials.credentials, SECRET_KEY, algorithms=[ALGORITHM])
    except JWTError:
        api_error(401, "invalid_token", "Invalid token")

    username = payload.get("sub")
    if not username:
        api_error(401, "invalid_token", "Invalid token")

    return username


def update_book_fields(db_book: Book, book: BookRequest):
    db_book.title = book.title
    db_book.author = book.author
    db_book.description = book.description
    db_book.year = book.year
    db_book.rating = book.rating
    db_book.genre = book.genre
    db_book.image_url = book.image_url
    db_book.status = book.status


def reading_list_response(item: ReadingList, book: Optional[Book]):
    return {
        "id": book.id if book else None,
        "readingListId": item.id,
        "title": book.title if book else "",
        "author": book.author if book else "",
        "description": book.description if book else None,
        "year": book.year if book else "",
        "rating": book.rating if book else 0,
        "genre": book.genre if book else "All",
        "image_url": book.image_url if book else "",
        "progress": item.progress or 0,
        "reading_status": item.status or "to_read",
    }


def review_response(review: Review, book: Optional[Book] = None):
    return {
        "id": review.id,
        "content": review.content,
        "rating": review.rating,
        "book_id": review.book_id,
        "book_title": book.title if book else None,
        "user_id": review.user_id,
    }


def ensure_schema():
    Base.metadata.create_all(bind=engine)
    with engine.begin() as connection:
        connection.execute(text("ALTER TABLE books ADD COLUMN IF NOT EXISTS description VARCHAR"))
        connection.execute(text("ALTER TABLE books ADD COLUMN IF NOT EXISTS year VARCHAR"))
        connection.execute(text("ALTER TABLE books ADD COLUMN IF NOT EXISTS rating FLOAT"))
        connection.execute(text("ALTER TABLE books ADD COLUMN IF NOT EXISTS genre VARCHAR"))
        connection.execute(text("ALTER TABLE books ADD COLUMN IF NOT EXISTS image_url VARCHAR"))
        connection.execute(text("ALTER TABLE books ADD COLUMN IF NOT EXISTS status VARCHAR"))
        connection.execute(text("ALTER TABLE reading_list ADD COLUMN IF NOT EXISTS progress INTEGER"))
        connection.execute(text("ALTER TABLE reading_list ADD COLUMN IF NOT EXISTS status VARCHAR"))


ensure_schema()


@app.get("/")
def root():
    return {"message": "Book Service running"}


@app.get("/books")
def get_books(user: Optional[str] = Query(default=None), status: Optional[str] = Query(default=None)):
    db = SessionLocal()
    try:
        query = db.query(Book)
        if user:
            query = query.filter(Book.user_id == user)
        if status:
            query = query.filter(Book.status == status)
        return query.all()
    finally:
        db.close()


@app.get("/books/{id}")
def get_book(id: int):
    db = SessionLocal()
    try:
        book = db.query(Book).filter(Book.id == id).first()
        if not book:
            api_error(404, "book_not_found", "Book not found", {"id": id})
        return book
    finally:
        db.close()


@app.post("/books")
def add_book(book: BookRequest, user: str = Depends(get_current_user)):
    db = SessionLocal()
    try:
        existing = (
            db.query(Book)
            .filter(
                Book.user_id == user,
                Book.title == book.title,
                Book.author == book.author,
                Book.status == book.status,
            )
            .first()
        )
        if existing:
            return existing

        new_book = Book(user_id=user)
        update_book_fields(new_book, book)
        db.add(new_book)
        db.commit()
        db.refresh(new_book)
        return new_book
    finally:
        db.close()


@app.put("/books/{id}")
def update_book(id: int, book: BookRequest, user: str = Depends(get_current_user)):
    db = SessionLocal()
    try:
        db_book = db.query(Book).filter(Book.id == id, Book.user_id == user).first()
        if not db_book:
            api_error(404, "book_not_found", "Book not found", {"id": id})

        update_book_fields(db_book, book)
        db.commit()
        db.refresh(db_book)
        return db_book
    finally:
        db.close()


@app.delete("/books/{id}")
def delete_book(id: int, user: str = Depends(get_current_user)):
    db = SessionLocal()
    try:
        book = db.query(Book).filter(Book.id == id, Book.user_id == user).first()
        if not book:
            api_error(404, "book_not_found", "Book not found", {"id": id})

        db.delete(book)
        db.commit()
        return {"message": "Deleted"}
    finally:
        db.close()


@app.get("/reviews/book/{id}")
def get_reviews(id: int):
    db = SessionLocal()
    try:
        book = db.query(Book).filter(Book.id == id).first()
        return [
            review_response(review, book)
            for review in db.query(Review).filter(Review.book_id == id).all()
        ]
    finally:
        db.close()


@app.get("/reviews")
def get_all_reviews():
    db = SessionLocal()
    try:
        reviews = db.query(Review).all()
        return [
            review_response(
                review,
                db.query(Book).filter(Book.id == review.book_id).first(),
            )
            for review in reviews
        ]
    finally:
        db.close()


@app.post("/reviews")
def add_review(review: ReviewRequest, user: str = Depends(get_current_user)):
    db = SessionLocal()
    try:
        book = db.query(Book).filter(Book.id == review.book_id).first()
        if not book:
            api_error(404, "book_not_found", "Book not found", {"id": review.book_id})

        new_review = Review(
            content=review.content,
            rating=review.rating,
            book_id=review.book_id,
            user_id=user,
        )
        db.add(new_review)
        db.commit()
        db.refresh(new_review)
        return review_response(new_review, book)
    finally:
        db.close()


@app.put("/reviews/{id}")
def update_review(id: int, review: ReviewRequest, user: str = Depends(get_current_user)):
    db = SessionLocal()
    try:
        db_review = db.query(Review).filter(Review.id == id, Review.user_id == user).first()
        if not db_review:
            api_error(404, "review_not_found", "Review not found", {"id": id})

        db_review.content = review.content
        db_review.rating = review.rating
        db_review.book_id = review.book_id
        db.commit()
        db.refresh(db_review)
        book = db.query(Book).filter(Book.id == db_review.book_id).first()
        return review_response(db_review, book)
    finally:
        db.close()


@app.delete("/reviews/{id}")
def delete_review(id: int, user: str = Depends(get_current_user)):
    db = SessionLocal()
    try:
        review = db.query(Review).filter(Review.id == id, Review.user_id == user).first()
        if not review:
            api_error(404, "review_not_found", "Review not found", {"id": id})

        db.delete(review)
        db.commit()
        return {"message": "Deleted"}
    finally:
        db.close()


@app.get("/reading-list")
def get_reading_list(user: str = Depends(get_current_user)):
    db = SessionLocal()
    try:
        items = db.query(ReadingList).filter(ReadingList.user_id == user).all()
        return [
            reading_list_response(
                item,
                db.query(Book).filter(Book.id == item.book_id).first(),
            )
            for item in items
        ]
    finally:
        db.close()


@app.post("/reading-list")
def add_to_reading_list(item: ReadingListRequest, user: str = Depends(get_current_user)):
    db = SessionLocal()
    try:
        book = db.query(Book).filter(Book.id == item.book_id).first()
        if not book:
            api_error(404, "book_not_found", "Book not found", {"id": item.book_id})

        existing = (
            db.query(ReadingList)
            .filter(ReadingList.book_id == item.book_id, ReadingList.user_id == user)
            .first()
        )
        if existing:
            existing.progress = item.progress
            existing.status = item.status
            db.commit()
            db.refresh(existing)
            return reading_list_response(existing, book)

        new_item = ReadingList(
            book_id=item.book_id,
            user_id=user,
            progress=item.progress,
            status=item.status,
        )
        db.add(new_item)
        db.commit()
        db.refresh(new_item)
        return reading_list_response(new_item, book)
    finally:
        db.close()


@app.put("/reading-list/{id}")
def update_reading_list(id: int, item: ReadingListRequest, user: str = Depends(get_current_user)):
    db = SessionLocal()
    try:
        db_item = db.query(ReadingList).filter(ReadingList.id == id, ReadingList.user_id == user).first()
        if not db_item:
            api_error(404, "reading_list_item_not_found", "Reading list item not found", {"id": id})

        db_item.book_id = item.book_id
        db_item.progress = item.progress
        db_item.status = item.status
        db.commit()
        db.refresh(db_item)
        book = db.query(Book).filter(Book.id == db_item.book_id).first()
        return reading_list_response(db_item, book)
    finally:
        db.close()


@app.delete("/reading-list/{id}")
def delete_from_reading_list(id: int, user: str = Depends(get_current_user)):
    db = SessionLocal()
    try:
        item = db.query(ReadingList).filter(ReadingList.id == id, ReadingList.user_id == user).first()
        if not item:
            api_error(404, "reading_list_item_not_found", "Reading list item not found", {"id": id})

        db.delete(item)
        db.commit()
        return {"message": "Removed from reading list"}
    finally:
        db.close()
