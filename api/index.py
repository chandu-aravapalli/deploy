# api/index.py
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import List
import time

app = FastAPI(title="Tiny Feedback Board")

# Simple in-memory store (swap later for Postgres)
FEEDBACK = []  # [{id, text, votes, created_at}]

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # tighten later
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

class NewFeedback(BaseModel):
    text: str

@app.get("/")
def root():
    """Root endpoint - API is running"""
    return {
        "message": "Tiny Feedback Board API",
        "status": "running",
        "endpoints": {
            "GET /api/feedback": "List all feedback",
            "POST /api/feedback": "Create new feedback",
            "POST /api/feedback/{id}/upvote": "Upvote feedback"
        }
    }

@app.get("/health")
def health_check():
    """Health check endpoint"""
    return {"status": "healthy", "feedback_count": len(FEEDBACK)}

@app.get("/api/feedback")
def list_feedback() -> List[dict]:
    # newest first, then by votes
    return sorted(FEEDBACK, key=lambda x: (-x["votes"], -x["created_at"]))

@app.post("/api/feedback", status_code=201)
def create_feedback(item: NewFeedback):
    if not item.text.strip():
        raise HTTPException(400, "Text required")
    doc = {
        "id": len(FEEDBACK) + 1,
        "text": item.text.strip(),
        "votes": 0,
        "created_at": int(time.time())
    }
    FEEDBACK.append(doc)
    return doc

@app.post("/api/feedback/{fid}/upvote")
def upvote(fid: int):
    for f in FEEDBACK:
        if f["id"] == fid:
            f["votes"] += 1
            return f
    raise HTTPException(404, "Not found")

