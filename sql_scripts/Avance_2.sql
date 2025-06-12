-- Crea un trigger que registre en una tabla de monitoreo cada vez que un producto supere las 200.000 unidades vendidas acumuladas.
--  El trigger debe activarse después de insertar una nueva venta y registrar en la tabla el ID del producto, su nombre, la nueva cantidad total de unidades vendidas, 
-- y la fecha en que se superó el umbral.

CREATE TABLE monitore_ventas (
    id INT AUTO_INCREMENT PRIMARY KEY,
    producto_id INT NOT NULL,
    producto_nombre VARCHAR(255) NOT NULL,
    cantidad_total INT NOT NULL,
    fecha_superacion DATETIME NOT NULL
);

DELIMITER //
CREATE TRIGGER trigger_ventas_superadas
AFTER INSERT ON sales
FOR EACH ROW
BEGIN
    DECLARE total_vendido INT;
    DECLARE nombre_producto VARCHAR(255);

    -- Obtiene el nombre del producto desde la tabla products
    SELECT p.ProductName INTO nombre_producto
    FROM products p
    WHERE p.ProductID = NEW.ProductID;

    -- Calcula la cantidad total vendida del producto
    SELECT SUM(s.Quantity) INTO total_vendido
    FROM sales s
    WHERE s.ProductID = NEW.ProductID;

    -- Si supera el umbral, inserta un registro en monitoreo
    IF total_vendido > 200000 THEN
        INSERT INTO monitore_ventas (producto_id, producto_nombre, cantidad_total, fecha_superacion)
        VALUES (NEW.ProductID, nombre_producto, total_vendido, NOW());
    END IF;
END;//
DELIMITER ;

-- Registra una venta correspondiente al vendedor con ID 9, al cliente con ID 84, del producto con ID 103, 
-- por una cantidad de 1.876 unidades y un valor de 1200 unidades.

INSERT INTO sales (
    `SalesID`,`SalesPersonID`, 
    `CustomerID`, `ProductID`, 
    `Quantity`,
    `Discount`,
    `TotalPrice`,
    `SalesDate`,
    `TransactionNumber`)
VALUES (99999999,9, 84, 103, 1876, 0, 1200, NOW(), 'TEST-001');

-- Consulta la tabla de monitoreo, toma captura de los resultados y realiza un análisis breve de lo ocurrido.

-- Selecciona dos consultas del avance 1 y crea los índices que consideres más adecuados para optimizar su ejecución.
-- Prueba con índices individuales y compuestos, según la lógica de cada consulta. 
-- Luego, vuelve a ejecutar ambas consultas y compara los tiempos de ejecución antes y después de aplicar los índices.
-- Finalmente, describe brevemente el impacto que tuvieron los índices en el rendimiento y en qué tipo de columnas resultan más efectivos 
-- para este tipo de operaciones.   


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
   
    -- sin indiex 29.610
    -- con indiex 5.1s
    
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
ORDER BY porcentaje DESC;

    -- sin index 8.078
    -- con index 7.4


-- Accelera agregaciones por producto y vendedor
CREATE INDEX idx_sales_productid_salespersonid ON products(ProductID, ProductName);

CREATE INDEX idx_sales_productid_salespersonid_quantity ON sales(ProductID, SalesPersonID, Quantity);

