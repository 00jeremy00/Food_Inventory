from pydantic import BaseModel
from decimal import Decimal
from app.enums import RecipeStatus

class Recipe(BaseModel):
    recipe_num: int
    recipe_name: str
    recipe_status: RecipeStatus
    shelflife: Decimal
    recipe_yield: Decimal
    recipe_unit: str
    par: Decimal