from fastapi import FastAPI

from app.routers import health, hello

app = FastAPI()


# Include routers
app.include_router(health.router)
app.include_router(hello.router)
