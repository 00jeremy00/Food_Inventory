import { useEffect, useState } from "react"
import { fetchProducts } from "../api/productsApi"
import ProductList  from "../components/products/ProductList"
import type {Product} from "../types/product"

function Dashboard(){
    const [products, setProducts] = useState<Product[]>([])

    useEffect(() => {
        async function loadProducts(){
            try {
                const data = await fetchProducts()
                setProducts(data)
            }
            catch (error){
                console.error(ErrorEvent)
            }
        }
        loadProducts()
    } , [])

    return (
        <main>
            <h1> Inventory Dashboard</h1>
            <section>
                <h2>Products</h2>
                <ProductList products={products}/>
            </section>
        </main>
    )
}
export default Dashboard