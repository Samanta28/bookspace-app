from database import SessionLocal
from fastapi import Depends, FastAPI, HTTPException
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from jose import jwt
from models import Book, Review
from pydantic import BaseModel

app = FastAPI()

SECRET_KEY = "secret"
ALGORITHM = "HS256"

security = HTTPBearer()


class BookRequest(BaseModel):
    title: str
    author: str


class ReviewRequest(BaseModel):
    content: str
    rating: int
    book_id: int


def get_current_user(credentials: HTTPAuthorizationCredentials = Depends(security)):
    try:
        token = credentials.credentials
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        username = payload.get("sub")
        return username
    except:
        raise HTTPException(status_code=401, detail="Invalid token")


@app.get("/")
def root():
    return {"message": "Book Service running"}


# ---------------- BOOKS ----------------


@app.get("/books")
def get_books(user: str = Depends(get_current_user)):
    db = SessionLocal()
    books = db.query(Book).filter(Book.user_id == user).all()
    return books


@app.post("/books")
def add_book(book: BookRequest, user: str = Depends(get_current_user)):
    db = SessionLocal()

    new_book = Book(
        title=book.title,
        author=book.author,
        user_id=user,
    )

    db.add(new_book)
    db.commit()

    return {"message": "Book added"}


@app.delete("/books/{id}")
def delete_book(id: int, user: str = Depends(get_current_user)):
    db = SessionLocal()

    book = db.query(Book).filter(Book.id == id, Book.user_id == user).first()

    if not book:
        raise HTTPException(status_code=404, detail="Not found")

    db.delete(book)
    db.commit()

    return {"message": "Deleted"}


# ---------------- REVIEWS ----------------


@app.post("/reviews")
def add_review(review: ReviewRequest, user: str = Depends(get_current_user)):
    db = SessionLocal()

    new_review = Review(
        content=review.content,
        rating=review.rating,
        book_id=review.book_id,
        user_id=user,
    )

    db.add(new_review)
    db.commit()

    return {"message": "Review added"}


@app.get("/reviews/book/{id}")
def get_reviews(id: int):
    db = SessionLocal()
    reviews = db.query(Review).filter(Review.book_id == id).all()
    return reviews


@app.delete("/reviews/{id}")
def delete_review(id: int, user: str = Depends(get_current_user)):
    db = SessionLocal()

    review = db.query(Review).filter(Review.id == id, Review.user_id == user).first()

    if not review:
        raise HTTPException(status_code=404, detail="Not found")

    db.delete(review)
    db.commit()

    return {"message": "Deleted"}
