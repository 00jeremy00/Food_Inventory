from fastapi import APIRouter, HTTPException
from app.schema.batch import BatchResponse
from app.services.batches_service import get_all_batches, get_batch_by_num, get_active_batches, get_pending_batches

router = APIRouter(
    prefix='/batches',
    tags=["Batches"]
)

@router.get('/', response_model=list[BatchResponse])
def read_batches():
    return get_all_batches()

@router.get('/active', response_model=list[BatchResponse])
def read_active_batches():
    return get_active_batches()

@router.get('/pending', response_model = list[BatchResponse])
def read_pending_batches():
    return get_pending_batches()

@router.get('/{batch_num}', response_model = BatchResponse)
def read_batch(batch_num):
    return get_batch_by_num(batch_num)
