from fastapi import APIRouter

router = APIRouter()


@router.get("/hello", tags=["hello"])
async def get_hello():
    return {"message": "Hello, World!"}
