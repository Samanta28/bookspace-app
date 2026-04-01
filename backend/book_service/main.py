from database import SessionLocal
from fastapi import Depends, FastAPI, HTTPException
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from jose import jwt
from models import Book
from pydantic import BaseModel

app = FastAPI()

SECRET_KEY = "secret"
ALGORITHM = "HS256"

security = HTTPBearer()


class BookRequest(BaseModel):
    title: str
    author: str


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

    @app.get("/books/{id}")
def get_book(id: int):
    db = SessionLocal()
    book = db.query(Book).filter(Book.id == id).first()

    if not book:
        raise HTTPException(status_code=404, detail="Not found")

    return book

    @app.put("/books/{id}")
def update_book(id: int, book: BookRequest, user: str = Depends(get_current_user)):
    db = SessionLocal()

    db_book = db.query(Book).filter(Book.id == id, Book.user_id == user).first()

    if not db_book:
        raise HTTPException(status_code=404, detail="Not found")

    db_book.title = book.title
    db_book.author = book.author

    db.commit()

    return {"message": "Updated"}
