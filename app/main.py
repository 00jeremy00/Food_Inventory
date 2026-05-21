from fastapi import FastAPI
from app.routers import items, products, vendors, batches, recipes, inventory_transactions
app = FastAPI(
    title="Restaurant Inventory API"
)

app.include_router(products.router)
app.include_router(items.router)
app.include_router(vendors.router)
app.include_router(batches.router)
app.include_router(recipes.router)
app.include_router(inventory_transactions.router)

@app.get("/")
def root():
    return {"message": "Inventory API Running"}