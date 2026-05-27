import type { Product } from "../../types/product"

type ProductTableProps = {
    products: Product[]
}

function ProductTable({ products }: ProductTableProps) {

    return (
        <table>
            <thead>
                <tr>
                    <th>Product</th>
                    <th>Vendor</th>
                    <th>Quantity</th>
                </tr>
            </thead>

            <tbody>

                {products.map((product) => (
                    <tr key={product.product_num}>
                        <td>{product.vendor_pname}</td>
                        <td>{product.vendor_name}</td>
                        <td>{product.inventory_quantity}</td>
                    </tr>
                ))}

            </tbody>
        </table>
    )
}

export default ProductTable