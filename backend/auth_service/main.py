import os
from pathlib import Path
from typing import Optional

from dotenv import load_dotenv
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from jose import jwt
from passlib.context import CryptContext
from pydantic import BaseModel
from sqlalchemy import text

try:
    from .database import SessionLocal, engine
    from .models import Base, User
except ImportError:
    from database import SessionLocal, engine
    from models import Base, User

app = FastAPI()

load_dotenv(Path(__file__).resolve().parents[1] / ".env")

app.add_middleware(
    CORSMiddleware,
    allow_origins=[
        "http://localhost:5500",
        "http://127.0.0.1:5500",
    ],
    allow_origin_regex=r"http://(localhost|127\.0\.0\.1)(:\d+)?",
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

SECRET_KEY = os.getenv("SECRET_KEY")
ALGORITHM = os.getenv("JWT_ALGORITHM") or os.getenv("ALGORITHM")

if not SECRET_KEY or not ALGORITHM:
    raise RuntimeError("SECRET_KEY and JWT_ALGORITHM must be set")

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

fake_db = {}


class UserRequest(BaseModel):
    username: str
    password: str
    email: Optional[str] = None


class ResetPasswordRequest(BaseModel):
    username: str
    new_password: str


def api_error(status_code: int, code: str, message: str, details: object = None):
    raise HTTPException(
        status_code=status_code,
        detail={
            "code": code,
            "message": message,
            "details": details,
        },
    )


def ensure_schema():
    Base.metadata.create_all(bind=engine)
    with engine.begin() as connection:
        connection.execute(text("ALTER TABLE users ADD COLUMN IF NOT EXISTS email VARCHAR"))


ensure_schema()


@app.post("/auth/register")
def register(user: UserRequest):
    db = SessionLocal()
    try:
        existing_user = db.query(User).filter(User.username == user.username).first()
        if existing_user:
            api_error(400, "user_exists", "User already exists", {"username": user.username})

        hashed_password = pwd_context.hash(user.password)

        new_user = User(username=user.username, email=user.email, password=hashed_password)
        db.add(new_user)
        db.commit()

        return {"message": "User registered"}
    finally:
        db.close()


@app.post("/auth/login")
def login(user: UserRequest):
    db = SessionLocal()
    try:
        db_user = db.query(User).filter(User.username == user.username).first()
        if not db_user:
            api_error(400, "user_not_found", "User not found", {"username": user.username})

        if not pwd_context.verify(user.password, db_user.password):
            api_error(400, "wrong_password", "Wrong password")

        token = jwt.encode({"sub": user.username}, SECRET_KEY, algorithm=ALGORITHM)

        return {"access_token": token}
    finally:
        db.close()


@app.post("/auth/reset-password")
def reset_password(request: ResetPasswordRequest):
    db = SessionLocal()
    try:
        db_user = db.query(User).filter(User.username == request.username).first()
        if not db_user:
            api_error(400, "user_not_found", "User not found", {"username": request.username})

        db_user.password = pwd_context.hash(request.new_password)
        db.commit()
        return {"message": "Password changed"}
    finally:
        db.close()

@app.get("/db-test")
def db_test():
    return {"message": "Database works"}
