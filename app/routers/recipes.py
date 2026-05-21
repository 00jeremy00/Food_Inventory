from fastapi import APIRouter, HTTPException
from app.schema.recipe import Recipe
from app.services.recipes_service import get_all_recipes

router = APIRouter(prefix='/recipes', tags = ['Recipes'])

@router.get('/', response_model=list[Recipe])
def read_recipes():
    return get_all_recipes()