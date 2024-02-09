--1. Create a list of Products and their units balance.
SELECT
  DimProduct.EnglishProductName,
  SUM(FactProductInventory.UnitsBalance) AS UnitsBalance 
FROM
  dbo.FactProductInventory AS FactProductInventory 
  INNER JOIN
    dbo.DimProduct AS DimProduct 
    ON FactProductInventory.ProductKey = DimProduct.ProductKey 
GROUP BY
  DimProduct.EnglishProductName 
ORDER BY
  DimProduct.EnglishProductName


--2. Create a list of Countries and their salesamount.
SELECT
  DimSalesTerritory.SalesTerritoryCountry,
  SUM(FactInternetSales.SalesAmount) AS SalesAmount 
FROM
  dbo.DimSalesTerritory AS DimSalesTerritory 
  INNER JOIN
    dbo.FactInternetSales AS FactInternetSales 
    ON DimSalesTerritory.SalesTerritoryKey = FactInternetSales.SalesTerritoryKey 
GROUP BY
  DimSalesTerritory.SalesTerritoryCountry 
ORDER BY
  DimSalesTerritory.SalesTerritoryCountry


--3. Create a stored procedure that runs the above created SQL statement dynamically so that the user specifies the Sales country. 
CREATE PROCEDURE SaleCountry @SalesTerritoryCountry nvarchar(50) AS BEGIN
  SELECT
    DimSalesTerritory.SalesTerritoryCountry,
    SUM(FactInternetSales.SalesAmount) AS SalesAmount 
  FROM
    dbo.DimSalesTerritory AS DimSalesTerritory 
    INNER JOIN
      dbo.FactInternetSales AS FactInternetSales 
      ON DimSalesTerritory.SalesTerritoryKey = FactInternetSales.SalesTerritoryKey 
  WHERE
    DimSalesTerritory.SalesTerritoryCountry = @SalesTerritoryCountry 
  GROUP BY
    DimSalesTerritory.SalesTerritoryCountry 
END
GO


--4. Execute the above stored procedure and provide the sales for Canada
EXEC SaleCountry @SalesTerritoryCountry = 'Canada'


--5. Create another stored procedure that will create a table whenever it runs. The table will be CustomerGeography. 
CREATE PROCEDURE CustomerGeography AS BEGIN
  DECLARE @RowCount int 
  SELECT
    DimCustomer.*,
    DimGeography.City,
    DimGeography.EnglishCountryRegionName 
  FROM
    dbo.DimCustomer AS DimCustomer 
    INNER JOIN
      dbo.DimGeography AS DimGeography 
      ON DimCustomer.GeographyKey = DimGeography.GeographyKey 
  SET
    @RowCount = @@ROWCOUNT 
    INSERT INTO
      MyLogTable (Username, ExecutionTime, row_count) 
    VALUES
      (CURRENT_USER, GETDATE(), @RowCount)
END
GO EXEC CustomerGeography


-- 6. Create a log table that has log_date_time, row_count as columns and use this table to log the above stored procedures executions.
CREATE TABLE MyLogTable
(Username nvarchar(50) NOT NULL,
ExecutionTime datetime NOT NULL,
row_count int NOT NULL)
SELECT
  * 
FROM
  MyLogTable


-- 7. Create a stored procedure named “GetAverageProductSalesAmountUSD” which will first calculate the USD equivalence of all transactions for the SalesAmount column according to Order Date seen within the entire FactInternetSales table. 
CREATE PROCEDURE GetAverageProductSalesAmountUSD AS BEGIN
  SELECT
    DimProduct.EnglishProductName,
    FactInternetSales.ProductKey,
    FactInternetSales.OrderDateKey,
    ROUND(AVG(FactInternetSales.SalesAmount * CurrencyAvg.EndOfDayRate), 2) AS AverageSalesAmountUSD 
  FROM
    dbo.FactInternetSales AS FactInternetSales 
    INNER JOIN
      dbo.DimProduct AS DimProduct 
      ON FactInternetSales.ProductKey = DimProduct.ProductKey
INNER JOIN
   (SELECT
      CurrencyKey,
      DateKey,
      AVG(EndOfDayRate) AS EndOfDayRate 
    FROM
      dbo.FactCurrencyRate AS FactCurrencyRate 
    WHERE
      DateKey BETWEEN 20120101 and 20131231 
    GROUP BY
      CurrencyKey,
      DateKey)
  AS CurrencyAvg 
  ON FactInternetSales.CurrencyKey = CurrencyAvg.CurrencyKey 
  AND FactInternetSales.OrderDateKey = CurrencyAvg.DateKey 
  WHERE
    FactInternetSales.OrderDateKey BETWEEN 20120101 and 20131231 
    GROUP BY
      DimProduct.EnglishProductName,
      FactInternetSales.ProductKey,
      FactInternetSales.OrderDateKey 
     ORDER BY
       FactInternetSales.OrderDateKey 
     INSERT INTO
       MyLogTable_2 (Username, ExecutionTime) 
     VALUES
       (CURRENT_USER, GETDATE())
END
GO

EXEC GetAverageProductSalesAmountUSD

CREATE TABLE MyLogTable_2
(Username nvarchar(50) NOT NULL,
ExecutionTime datetime NOT NULL)

SELECT
  * 
FROM
  MyLogTable_2