/* 1.-

¿Cuáles fueron los 5 productos más vendidos (por cantidad total), y 
cuál fue el vendedor que más unidades vendió de cada uno? 

análisis responde: 
¿Hay algún vendedor que aparece más de una vez como el que más vendió un producto? 
¿Algunos de estos vendedores representan más del 10% de la ventas de este producto?
*/
WITH 
top_ventas AS (
    SELECT
        p.ProductID,
        p.ProductName,
        SUM(s.Quantity) AS total_Quantity
    FROM 
        sales s
    JOIN 
        products p ON s.ProductID = p.ProductID
    GROUP BY 
        p.ProductID, p.ProductName
    ORDER BY 
        total_Quantity DESC
    LIMIT 5
),
vendedor_producto AS (
    SELECT 
        s.ProductID,
        s.SalesPersonID,
        SUM(s.Quantity) AS total_vendido,
        e.FirstName,
        e.LastName
    FROM 
        sales s
    JOIN 
        employees e 
    ON 
        s.SalesPersonID = e.EmployeeID
    GROUP BY 
        s.ProductID, s.SalesPersonID, e.FirstName, e.LastName
),
ventas_maxima_por_producto AS (
    SELECT
        ProductID,
        MAX(total_vendido) AS max_vendida
    FROM 
        vendedor_producto
    GROUP BY 
        ProductID
),
ventas_vendedor_producto AS (
    SELECT
        vp.ProductID,
        vp.SalesPersonID,
        vp.FirstName,
        vp.LastName,
        vp.total_vendido
    FROM 
        vendedor_producto vp
    JOIN 
        ventas_maxima_por_producto maxp
    ON 
        vp.ProductID = maxp.ProductID AND vp.total_vendido = maxp.max_vendida
)
SELECT
    tv.ProductID,
    tv.ProductName,
    tv.total_Quantity AS cantidad_total,
    vvp.SalesPersonID,
    vvp.FirstName,
    vvp.LastName,
    vvp.total_vendido AS cantidad_vendida_por_vendedor
FROM 
    top_ventas tv
JOIN 
    ventas_vendedor_producto vvp 
ON 
    tv.ProductID = vvp.ProductID
ORDER BY 
    tv.total_Quantity DESC;
--33.5 seg

/* 2.-
Entre los 5 productos más vendidos, ¿cuántos clientes únicos compraron cada uno y qué proporción representa sobre el total de clientes? 
Analiza si ese porcentaje sugiere que el producto fue ampliamente adoptado entre los clientes o si, por el contrario, 
fue comprado por un grupo reducido que generó un volumen alto de ventas. Compara los porcentajes entre productos e identifica si alguno de ellos depende más de un segmento específico de clientes
*/

WITH
    productos_mas_vendidos AS(
        SELECT
            `ProductID`,
            SUM(`Quantity`) AS cantidad_total
        FROM
            sales
        GROUP BY `ProductID`
        ORDER BY cantidad_total DESC
        LIMIT 5
    ),
    clientes_por_producto AS(
        SELECT
            s.`ProductID`,
            COUNT(DISTINCT s.`CustomerID`) AS clientes_unicos
        FROM    
            sales s
        WHERE   
            s.`ProductID` IN(
                SELECT
                    `ProductID`
                FROM
                    productos_mas_vendidos
            )
        GROUP BY
            s.`ProductID`
    ),
    total_clientes AS(
        SELECT
            COUNT(DISTINCT `CustomerID`) AS total
        FROM
            sales
    )
SELECT
    p.`ProductID`,
    p.`ProductName`,
    cpp.clientes_unicos,
    tc.total,
    ROUND(cpp.clientes_unicos * 100 / tc.total, 2) porcentaje
FROM    
    clientes_por_producto cpp
JOIN
    products p
ON cpp.`ProductID` = p.`ProductID`
CROSS JOIN total_clientes tc
ORDER BY porcentaje DESC

/* 3.-
¿A qué categorías pertenecen los 5 productos más vendidos y qué proporción representan dentro del total de unidades vendidas de su categoría? 
Utiliza funciones de ventana para comparar la relevancia de cada producto dentro de su propia categoría.
*/

WITH 
    ventas_por_producto AS(
        SELECT
            s.`ProductID`,
            p.`ProductName`,
            p.`CategoryID`,
            c.`CategoryName`,
            SUM(s.`Quantity`) AS unidades_producto
        FROM    
            sales s
        JOIN 
            products p ON s.`ProductID` = p.`ProductID`
        JOIN 
            categories c ON p.`CategoryID` = c.`CategoryID`
        GROUP BY s.`ProductID`, p.`ProductName`, p.`CategoryID`, c.`CategoryName`
    ),
    ventas_con_porcentaje AS(
        SELECT
            `ProductID`,
            `ProductName`,
            `CategoryID`,
            `CategoryName`,
            unidades_producto,
            SUM(unidades_producto) OVER (PARTITION BY `CategoryID`) AS total_categoria,
            RANK() OVER (ORDER BY unidades_producto DESC) AS ranking_global
        FROM
            ventas_por_producto
    )
SELECT
        `ProductID`,
        `ProductName`,
        `CategoryName`,
        unidades_producto,
        total_categoria,
        ROUND(unidades_producto * 100.0 / total_categoria, 2) AS porcentaje_categoria
    FROM
        ventas_con_porcentaje
    WHERE ranking_global <=5
    ORDER BY porcentaje_categoria DESC

/* 4.-
--¿Cuáles son los 10 productos con mayor cantidad de unidades vendidas en todo el catálogo y cuál es su posición dentro de su propia categoría? 
Utiliza funciones de ventana para identificar el ranking de cada producto en su categoría. 
Luego, analiza si estos productos son también los líderes dentro de sus categorías o si compiten estrechamente con otros productos de alto rendimiento. 
¿Qué observas sobre la concentración de ventas dentro de algunas categorías?
*/

SELECT
    p.`ProductID`,
    p.`ProductName`,
    SUM(s.`Quantity`) AS unidades_vendidas,
    RANK()
        OVER(
            PARTITION BY p.`CategoryID` 
            ORDER BY SUM(s.`Quantity`)DESC
        ) AS ranking_catalogo
FROM
    sales s
JOIN
    products p ON s.`ProductID` = p.`ProductID`
JOIN 
    categories c ON c.`CategoryID` = p.`CategoryID`
GROUP BY p.`ProductID`, p.`ProductName`, p.`CategoryID`, c.`CategoryName`
ORDER BY unidades_vendidas DESC
LIMIT 10