from fastapi import APIRouter, HTTPException
from app.schema.ingredient import Ingredient
from app.services.ingredients_service import get_all_ingredients

router = APIRouter(prefix='/ingredients', tags=['Ingredients'])

@router.get('/', response_model=list[Ingredient])
def read_ingredients():
    ingredients = get_all_ingredients()
    if not ingredients:
        raise HTTPException(status_code=404, detail="No ingredients found")
    return ingredients
