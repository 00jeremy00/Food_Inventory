import type { Item } from "../../types/items"
import ItemCard from "./itemCard"

type ItemListProps = {
    items: Item[]
}

function ItemList({ items }: ItemListProps) {
    return (
        <div className="itemList">
            {items.map((item) => (
                <ItemCard key={item.internal_num} item={item} />
            ))}
        </div>
    )
}
export default ItemList