import type { Item } from "../../types/items"
//import "./item.css"
type ItemCardProps = {
    item: Item
}

function ItemCard({ item }: ItemCardProps) {
    const isLowStock =
        Number(item.total_quantity) <=
        Number(item.par)

    const headerClass = isLowStock
        ? "headerRed"
        : "headerGreen"
    return (
        <div className = "itemCard">
            <div className={`cardHeader ${headerClass}`}>
                <h3>{item.internal_num}: {item.internal_name}</h3>
            </div>
            <p>{item.category}</p>
            <p>{item.total_quantity} {item.internal_unit}</p>
            <p>${item.total_value}</p>
        </div>
    )
}

export default ItemCard