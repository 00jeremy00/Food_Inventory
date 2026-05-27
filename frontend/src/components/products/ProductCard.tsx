import type { Product } from "../../types/product"
import "../../styles/product.css"

type ProductCardProps = {
    product: Product
}

function ProductCard({ product }: ProductCardProps) {
    return (
        <div className="ProductCard">
            <h2>{product.vendor_pname}</h2>
            <p>Product Num: {product.product_num}</p>
            <p>Vendor: {product.vendor_name}</p>
            <p>Quantity: {product.inventory_quantity}</p>
        </div>
    )
}

export default ProductCard