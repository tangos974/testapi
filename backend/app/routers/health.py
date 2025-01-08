""" Health check router """

from fastapi import APIRouter

router = APIRouter()


@router.get("/health", tags=["health"])
async def health():
    """Health check"""
    return {"status": "okey"}
