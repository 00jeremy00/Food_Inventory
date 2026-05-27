import type { Product } from "../../types/product";
import ProductCard from "./ProductCard";

type ProductListProps = {
    products: Product[]
}

function ProductList({ products }: ProductListProps) {
    return (
        <div>
            {products.map((product) => (
                <ProductCard key={product.product_num} product={product} />
            ))}
        </div>
    )
}

export default ProductList