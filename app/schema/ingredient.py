from pydantic import BaseModel
from decimal import Decimal

class Ingredient(BaseModel):
    recipe_num: int
    internal_num: int
    ingredient_name: str
    quantity: Decimal
    internal_unit: str