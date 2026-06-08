import type { Item } from "../../types/items"
//import "./item.css"
type ItemCardProps = {
    item: Item
}

function ItemCard({ item }: ItemCardProps) {
    return (
        <div className = "itemCard">
            <h3>{item.internal_num}: {item.internal_name}</h3>
            <p>{item.category}</p>
            <p>{item.total_quantity} {item.internal_unit}</p>
            <p>${item.total_value}</p>
        </div>
    )
}

export default ItemCard