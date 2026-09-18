from sqlmodel import Session
from backend.app.database.connection import engine

def get_session():
    with Session(engine) as session:
        yield session