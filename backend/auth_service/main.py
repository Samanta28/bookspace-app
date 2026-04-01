from database import SessionLocal
from fastapi import FastAPI, HTTPException
from jose import jwt
from models import User
from passlib.context import CryptContext
from pydantic import BaseModel

app = FastAPI()

SECRET_KEY = "secret"
ALGORITHM = "HS256"

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

fake_db = {}


class UserRequest(BaseModel):
    username: str
    password: str


@app.post("/auth/register")
def register(user: UserRequest):
    db = SessionLocal()

    existing_user = db.query(User).filter(User.username == user.username).first()
    if existing_user:
        raise HTTPException(status_code=400, detail="User exists")

    hashed_password = pwd_context.hash(user.password)

    new_user = User(username=user.username, password=hashed_password)
    db.add(new_user)
    db.commit()

    return {"message": "User registered"}


@app.post("/auth/login")
def login(user: UserRequest):
    db = SessionLocal()

    db_user = db.query(User).filter(User.username == user.username).first()
    if not db_user:
        raise HTTPException(status_code=400, detail="User not found")

    if not pwd_context.verify(user.password, db_user.password):
        raise HTTPException(status_code=400, detail="Wrong password")

    token = jwt.encode({"sub": user.username}, SECRET_KEY, algorithm=ALGORITHM)

    return {"access_token": token}
    
# database connected