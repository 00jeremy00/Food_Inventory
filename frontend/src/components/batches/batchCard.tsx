import type { Batch } from "../../types/batches"

type BatchCardProps = {
    batch: Batch
}

function BatchCard({batch}: BatchCardProps){
    return (
        <div className="batchCard">
            <h3>Batch #{batch.batch_num}</h3>
            <p>Recipe: {batch.recipe_name} (#{batch.recipe_num})</p>
            <p>Created on: {new Date(batch.created_on).toLocaleDateString()} by {batch.created_by_name}</p>
            <p>Expires on: {new Date(batch.expires_at).toLocaleDateString()}</p>
            <p>Approved by: {batch.approver_name ? batch.approver_name : "Not approved"}</p>
            <p>Prepared Quantity: {batch.prepared_quanity} {batch.recipe_unit}</p>
            <p>Remaining Quantity: {batch.remaining_quantity} {batch.recipe_unit}</p>
            <p>Status: {batch.batch_status}</p>
        </div>
    )
}

export default BatchCard