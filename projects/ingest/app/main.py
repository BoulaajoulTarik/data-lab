import os
from contextlib import asynccontextmanager

from fastapi import FastAPI, HTTPException

from .s3 import get_summary, run_ingest

VERSION = os.getenv("APP_VERSION", "0.1.0")


@asynccontextmanager
async def lifespan(app: FastAPI):
    try:
        run_ingest(rows=500)
    except Exception:
        pass  # Don't block startup if MinIO isn't reachable yet
    yield


app = FastAPI(lifespan=lifespan)


@app.get("/")
def root() -> dict:
    return {"service": "ingest", "version": VERSION, **get_summary()}


@app.get("/health")
def health() -> dict:
    return {"status": "ok"}


@app.post("/ingest")
def ingest(rows: int = 1000) -> dict:
    try:
        return run_ingest(rows=rows)
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@app.get("/summary")
def summary() -> dict:
    return get_summary()
