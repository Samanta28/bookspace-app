from fastapi import FastAPI

app = FastAPI()

@app.get("/")
def root():
    return {"message": "Auth Service running"}

@app.post("/auth/register")
def register():
    return {"message": "User registered"}

@app.post("/auth/login")
def login():
    return {"message": "User logged in"}