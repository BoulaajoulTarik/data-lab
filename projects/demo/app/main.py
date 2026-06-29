import os

from fastapi import FastAPI

VERSION = os.getenv("APP_VERSION", "0.1.0")

app = FastAPI()


@app.get("/")
def root() -> dict:
    return {"service": "demo", "version": VERSION}


@app.get("/health")
def health() -> dict:
    return {"status": "ok"}
