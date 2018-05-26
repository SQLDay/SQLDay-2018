USE ContosoRetailDW_2016
GO 

SET Statistics TIME ON; 

--Enable Execution Plan

; WITH sales AS ( 
	SELECT TOP 100 
		CustomerKey,
		COUNT(*) as SalesCount
FROM [dbo].[FactSales_] 
GROUP BY CustomerKey
ORDER BY COUNT(*) DESC
)
SELECT
    u.CompanyName,
    s.SalesCount
FROM sales AS s
JOIN dbo.DimCustomer AS  u on u.CustomerKey=s.CustomerKey;
GO

; WITH sales AS ( 
	SELECT TOP 100 
		CustomerKey,
		COUNT(*) as SalesCount
FROM [dbo].[FactSales_Part]
GROUP BY CustomerKey
ORDER BY COUNT(*) DESC
)
SELECT
    u.CompanyName,
    s.SalesCount
FROM sales AS s
JOIN dbo.DimCustomer AS  u on u.CustomerKey=s.CustomerKey;
GO