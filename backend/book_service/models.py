from sqlalchemy import Column, Integer, String
from sqlalchemy.orm import declarative_base
from database import engine

Base = declarative_base()


class Book(Base):
    __tablename__ = "books"

    id = Column(Integer, primary_key=True, index=True)
    title = Column(String)
    author = Column(String)
    user_id = Column(String)


class Review(Base):
    __tablename__ = "reviews"

    id = Column(Integer, primary_key=True, index=True)
    content = Column(String)
    rating = Column(Integer)
    book_id = Column(Integer)
    user_id = Column(String)


Base.metadata.create_all(bind=engine)