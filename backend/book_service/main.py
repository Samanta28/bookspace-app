from fastapi import FastAPI

app = FastAPI()

@app.get("/")
def root():
    return {"message": "Book Service running"}

@app.get("/books")
def get_books():
    return []

@app.post("/books")
def add_book():
    return {"message": "Book added"}