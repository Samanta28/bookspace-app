from database import SessionLocal
from fastapi import FastAPI
from models import Book
from pydantic import BaseModel

app = FastAPI()


class BookRequest(BaseModel):
    title: str
    author: str
    user_id: str


@app.get("/")
def root():
    return {"message": "Book Service running"}


@app.get("/books")
def get_books():
    db = SessionLocal()
    books = db.query(Book).all()
    return books


@app.post("/books")
def add_book(book: BookRequest):
    db = SessionLocal()

    new_book = Book(
        title=book.title,
        author=book.author,
        user_id=book.user_id,
    )

    db.add(new_book)
    db.commit()

    return {"message": "Book added"}


@app.delete("/books/{id}")
def delete_book(id: int):
    db = SessionLocal()

    book = db.query(Book).filter(Book.id == id).first()
    if not book:
        return {"error": "Not found"}

    db.delete(book)
    db.commit()

    return {"message": "Deleted"}
