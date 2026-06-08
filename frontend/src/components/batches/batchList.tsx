import type { Batch } from "../../types/batches"
import BatchCard from "./batchCard"

type BatchListProps = {
    batches: Batch[]
}

function BatchList({batches}: BatchListProps){
    return (
        <div className="batchList">
            {batches.map(batch => (
                <BatchCard key={batch.batch_num} batch={batch} />
            ))}
        </div>
    )
}

export default BatchList