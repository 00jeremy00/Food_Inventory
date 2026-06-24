import type { Batch } from "../../types/batches"

type BatchCardProps = {
    batch: Batch
}

function BatchCard({batch}: BatchCardProps){
    const belowPar = batch.remaining_quantity < batch.par;
    const headerClass = belowPar ? "headerGreen" : "headerRed";
    return (
        <div className="batchCard">
        <div className={`cardHeader ${headerClass}`}>
            <h3>Batch #{batch.batch_num}</h3>
        </div>
        <div className='cardContent'>
            <p>Recipe: {batch.recipe_name} (#{batch.recipe_num})</p>
            <p>Created on: {new Date(batch.created_on).toLocaleDateString()} by {batch.created_by_name}</p>
            <p>Expires on: {batch.expires_at ? new Date(batch.expires_at).toLocaleDateString() : "No expiry"}</p>
            <p>Approved by: {batch.approved_by_name ? batch.approved_by_name : "Not approved"}</p>
            <p>Prepared Quantity: {batch.prepared_quantity ? batch.prepared_quantity : "0"} {batch.recipe_unit}</p>
            <p>Remaining Quantity: {batch.remaining_quantity ? batch.remaining_quantity : " "} {batch.recipe_unit}</p>
            <p>Status: {batch.batch_status}</p>
        </div>
        </div>
    )
}

export default BatchCard
