import { useEffect, useState } from "react"

import { fetchProducts } from "../api/productsApi"

import ProductTable from "../components/products/ProductTable"

import type { Product } from "../types/product"


function ProductsPage() {

    const [products, setProducts] = useState<Product[]>([])

    useEffect(() => {

        async function loadProducts() {

            try {

                const data = await fetchProducts()

                setProducts(data)

            } catch (error) {

                console.error(error)
            }
        }

        loadProducts()

    }, [])

    return (
        <div>

            <h1>Products</h1>

            <ProductTable products={products} />

        </div>
    )
}

export default ProductsPage