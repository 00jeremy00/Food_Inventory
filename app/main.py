from fastapi import FastAPI
from app.routers import products, items

app = FastAPI(
    title="Restaurant Inventory API"
)

app.include_router(products.router)
app.include_router(items.router)

@app.get("/")
def root():
    return {"message": "Inventory API Running"}