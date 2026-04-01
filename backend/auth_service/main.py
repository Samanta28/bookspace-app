from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from jose import jwt
from passlib.context import CryptContext

app = FastAPI()

SECRET_KEY = "secret"
ALGORITHM = "HS256"

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

fake_db = {}

class User(BaseModel):
    username: str
    password: str

@app.post("/auth/register")
def register(user: User):
    if user.username in fake_db:
        raise HTTPException(status_code=400, detail="User exists")
    
    hashed_password = pwd_context.hash(user.password)
    fake_db[user.username] = hashed_password
    
    return {"message": "User registered"}

@app.post("/auth/login")
def login(user: User):
    if user.username not in fake_db:
        raise HTTPException(status_code=400, detail="User not found")
    
    hashed_password = fake_db[user.username]
    
    if not pwd_context.verify(user.password, hashed_password):
        raise HTTPException(status_code=400, detail="Wrong password")
    
    token = jwt.encode({"sub": user.username}, SECRET_KEY, algorithm=ALGORITHM)
    
    return {"access_token": token}