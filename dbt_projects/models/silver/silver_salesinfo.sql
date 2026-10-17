

with sales as (
    select
        sales_id,
        product_sk,
        customer_sk,
        {{ multiply('unit_price', 'quantity') }} as calculated_gross_amount,
        gross_amount,
        payment_method
    from {{ ref('bronze_sales') }}
),

products as (
    select
        product_sk,
        category
    from {{ ref('bronze_products') }}
),

customers as (
    select
        customer_sk,
        gender
    from {{ ref('bronze_customers') }}
),
joined_query as (
    select
        sales.sales_id,
        sales.calculated_gross_amount,
        sales.gross_amount,
        sales.payment_method,
        products.category,
        customers.gender
    from sales
    inner join products
        on sales.product_sk = products.product_sk
    inner join customers
        on sales.customer_sk = customers.customer_sk
)

select 
    category,
    gender,
    sum(gross_amount) as total_sales
from joined_query
group by category, gender
order by total_sales 