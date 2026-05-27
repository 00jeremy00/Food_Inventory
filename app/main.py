from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.routers import (
    invoices, 
    items, 
    products, 
    vendors, 
    batches, 
    recipes, 
    inventory_transactions, 
    batch_transactions,
    invoice_lines,
    ingredients
    )
app = FastAPI(
    title="Restaurant Inventory API"
)

app.add_middleware(
    CORSMiddleware,
    allow_origins="http://localhost:5173",
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
    )


app.include_router(products.router)
app.include_router(batch_transactions.router)
app.include_router(items.router)
app.include_router(vendors.router)
app.include_router(batches.router)
app.include_router(recipes.router)
app.include_router(inventory_transactions.router)
app.include_router(invoices.router)
app.include_router(invoice_lines.router)
app.include_router(ingredients.router)

@app.get("/")
def root():
    return {"message": "Inventory API Running"}