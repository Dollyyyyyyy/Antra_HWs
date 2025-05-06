

-- 1.      List all cities that have both Employees and Customers.

SELECT DISTINCT City
FROM Employees
WHERE City IN (SELECT DISTINCT City FROM Customers);


-- 2.      List all cities that have Customers but no Employee.

-- a.      Use sub-query
SELECT DISTINCT City
FROM Customers
WHERE City NOT IN (SELECT DISTINCT City FROM Employees);

-- b.      Do not use sub-query
SELECT DISTINCT c.City
FROM Customers c
LEFT JOIN Employees e ON c.City = e.City
WHERE e.City IS NULL;

-- 3.      List all products and their total order quantities throughout all orders.
SELECT p.ProductName, SUM(od.Quantity) AS TotalQuantity
FROM [Order Details] od
JOIN Products p ON od.ProductID = p.ProductID
GROUP BY p.ProductName;

-- 4.      List all Customer Cities and total products ordered by that city.
SELECT c.City, SUM(od.Quantity) AS TotalOrdered
FROM Customers c
JOIN Orders o ON c.CustomerID = o.CustomerID
JOIN [Order Details] od ON o.OrderID = od.OrderID
GROUP BY c.City;

-- 5.      List all Customer Cities that have at least two customers.
SELECT City
FROM Customers
GROUP BY City
HAVING COUNT(CustomerID) >= 2;

-- 6.      List all Customer Cities that have ordered at least two different kinds of products.
SELECT c.City
FROM Customers c
JOIN Orders o ON c.CustomerID = o.CustomerID
JOIN [Order Details] od ON o.OrderID = od.OrderID
GROUP BY c.City
HAVING COUNT(DISTINCT od.ProductID) >= 2;

-- 7.      List all Customers who have ordered products, but have the ‘ship city’ on the order different from their own customer cities.
SELECT DISTINCT c.CustomerID, c.CompanyName, c.City AS CustomerCity, o.ShipCity
FROM Customers c
JOIN Orders o ON c.CustomerID = o.CustomerID
WHERE c.City <> o.ShipCity;

-- 8.      List 5 most popular products, their average price, and the customer city that ordered most quantity of it.
WITH ProductPopularity AS (
    SELECT ProductID, SUM(Quantity) AS TotalQty
    FROM [Order Details]
    GROUP BY ProductID
),
Top5 AS (
    SELECT TOP 5 ProductID
    FROM ProductPopularity
    ORDER BY TotalQty DESC
),
AvgPrice AS (
    SELECT ProductID, AVG(UnitPrice) AS AvgPrice
    FROM [Order Details]
    GROUP BY ProductID
),
TopCity AS (
    SELECT od.ProductID, c.City, SUM(od.Quantity) AS CityQty,
           RANK() OVER (PARTITION BY od.ProductID ORDER BY SUM(od.Quantity) DESC) AS rk
    FROM [Order Details] od
    JOIN Orders o ON od.OrderID = o.OrderID
    JOIN Customers c ON o.CustomerID = c.CustomerID
    GROUP BY od.ProductID, c.City
)
SELECT p.ProductName, ap.AvgPrice, tc.City
FROM Top5 t5
JOIN Products p ON t5.ProductID = p.ProductID
JOIN AvgPrice ap ON t5.ProductID = ap.ProductID
JOIN TopCity tc ON t5.ProductID = tc.ProductID AND tc.rk = 1;

-- 9.      List all cities that have never ordered something but we have employees there.

-- a.      Use sub-query
SELECT DISTINCT e.City
FROM Employees e
WHERE e.City NOT IN (
    SELECT DISTINCT c.City
    FROM Customers c
    JOIN Orders o ON c.CustomerID = o.CustomerID
);

-- b.      Do not use sub-query
SELECT DISTINCT e.City
FROM Employees e
LEFT JOIN Customers c ON e.City = c.City
LEFT JOIN Orders o ON c.CustomerID = o.CustomerID
WHERE o.OrderID IS NULL;

-- 10.  List one city, if exists, that is the city from where the employee sold most orders (not the product quantity) is, and also the city of most total quantity of products ordered from. (tip: join  sub-query)
WITH EmpCityOrders AS (
    SELECT e.City, COUNT(o.OrderID) AS OrderCount
    FROM Employees e
    JOIN Orders o ON e.EmployeeID = o.EmployeeID
    GROUP BY e.City
),
TopEmpCity AS (
    SELECT TOP 1 City
    FROM EmpCityOrders
    ORDER BY OrderCount DESC
),
CustCityQuantities AS (
    SELECT c.City, SUM(od.Quantity) AS TotalQuantity
    FROM Customers c
    JOIN Orders o ON c.CustomerID = o.CustomerID
    JOIN [Order Details] od ON o.OrderID = od.OrderID
    GROUP BY c.City
),
TopCustCity AS (
    SELECT TOP 1 City
    FROM CustCityQuantities
    ORDER BY TotalQuantity DESC
)
SELECT e.City
FROM TopEmpCity e
JOIN TopCustCity c ON e.City = c.City;

-- 11. How do you remove the duplicates record of a table?

-- TO remove duplicate record, i would do this
--         WITH CTE AS (
--             SELECT *, 
--                 ROW_NUMBER() OVER (PARTITION BY Column1, Column2, ..., ColumnN ORDER BY (SELECT NULL)) AS rn
--             FROM TableName
--         )
--         DELETE FROM CTE
--         WHERE rn > 1;
