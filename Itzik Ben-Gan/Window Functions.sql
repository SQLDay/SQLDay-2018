---------------------------------------------------------------------
-- T-SQL Window Functions
-- © Itzik Ben-Gan, SolidQ
-- For more, see 5-day Advanced T-SQL class: http://tsql.solidq.com/t-sql-courses/
---------------------------------------------------------------------

-- Sample database
SET NOCOUNT ON;
USE TSQLV4; -- http://tsql.solidq.com/SampleDatabases/TSQLV4.zip

-- Extra Sample data

-- OrderValues table
IF OBJECT_ID(N'dbo.OrderValues', N'U') IS NOT NULL DROP TABLE dbo.OrderValues;

SELECT * INTO dbo.OrderValues FROM Sales.OrderValues;

ALTER TABLE dbo.OrderValues ADD CONSTRAINT PK_OrderValues PRIMARY KEY(orderid);
GO

-- Extra sample data
DROP TABLE IF EXISTS dbo.Accounts, dbo.Transactions;

CREATE TABLE dbo.Accounts
(
  actid INT NOT NULL CONSTRAINT PK_Accounts PRIMARY KEY
);

CREATE TABLE dbo.Transactions
(
  actid  INT   NOT NULL,
  tranid INT   NOT NULL,
  val    MONEY NOT NULL,
  CONSTRAINT PK_Transactions PRIMARY KEY(actid, tranid) -- creates POC index
);

DECLARE
  @num_partitions     AS INT = 100,
  @rows_per_partition AS INT = 20000;

INSERT INTO dbo.Accounts WITH (TABLOCK) (actid)
  SELECT NP.n
  FROM dbo.GetNums(1, @num_partitions) AS NP;

INSERT INTO dbo.Transactions WITH (TABLOCK) (actid, tranid, val)
  SELECT NP.n, RPP.n,
    (ABS(CHECKSUM(NEWID())%2)*2-1) * (1 + ABS(CHECKSUM(NEWID())%5))
  FROM dbo.GetNums(1, @num_partitions) AS NP
    CROSS JOIN dbo.GetNums(1, @rows_per_partition) AS RPP;
GO

---------------------------------------------------------------------
-- Window functions, described
---------------------------------------------------------------------

-- Compute bank acount balances after every transaction
SELECT actid, tranid, val,
  SUM(val) OVER(PARTITION BY actid
                ORDER BY tranid
                ROWS UNBOUNDED PRECEDING) AS balance
FROM dbo.Transactions;

---------------------------------------------------------------------
-- Limitations of alternative tools
---------------------------------------------------------------------

-- Grouped queries—discard the detail; need to join grouped data with detailed data
WITH GrandTotal AS
(
  SELECT SUM(val) AS sumvalall
  FROM Sales.OrderValues
  WHERE orderdate >= '20150101'
),
CustTotals AS
(
  SELECT custid, SUM(val) AS sumvalcust
  FROM Sales.OrderValues
  WHERE orderdate >= '20150101'
  GROUP BY custid
)
SELECT O.orderid, O.custid, O.val,
  CAST(100. * O.val / sumvalall  AS NUMERIC(5, 2)) AS pctall,
  CAST(100. * O.val / sumvalcust AS NUMERIC(5, 2)) AS pctcust
FROM Sales.OrderValues AS O
  CROSS JOIN GrandTotal AS G
  INNER JOIN CustTotals AS C
    ON O.custid = C.custid
WHERE orderdate >= '20150101';

-- Subqueries—look at an independent view of the data; need to repeat logic from underlying query
SELECT O1.orderid, O1.custid, O1.val,
  CAST(100. * O1.val / 
         ( SELECT SUM(val) FROM Sales.OrderValues
           WHERE orderdate >= '20150101' )
    AS NUMERIC(5, 2)) AS pctall,
  CAST(100. * O1.val / 
         ( SELECT SUM(O2.val) FROM Sales.OrderValues AS O2
           WHERE O2.custid = O1.custid
             AND O2.orderdate >= '20150101' )
    AS NUMERIC(5, 2)) AS pctcust
FROM Sales.OrderValues AS O1
WHERE O1.orderdate >= '20150101';

-- With aggregate window function
SELECT orderid, custid, val,
  CAST(100. * val / SUM(val) OVER()                    AS NUMERIC(5, 2)) AS pctall,
  CAST(100. * val / SUM(val) OVER(PARTITION BY custid) AS NUMERIC(5, 2)) AS pctcust
FROM Sales.OrderValues
WHERE orderdate >= '20150101';

---------------------------------------------------------------------
-- Window frame 
---------------------------------------------------------------------

-- Compute bank account balances (running total)
SELECT actid, tranid, val,
  SUM(val) OVER(PARTITION BY actid
                ORDER BY tranid
                /* shorter version: ROWS UNBOUNDED PRECEDING */
                ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS balance
FROM dbo.Transactions;

-- Alternative without window functions
/*
SELECT T1.actid, T1.tranid, T1.val, SUM(T2.val) AS balance
FROM dbo.Transactions AS T1
  INNER JOIN dbo.Transactions AS T2
    ON T1.actid = T2.actid
    AND T2.tranid <= T1.tranid
GROUP BY T1.actid, T1.tranid, T1.val;
*/

-- Batch mode Window Aggregate operator
-- Requires at least one columnstore index present
-- Create below index then rerun above query
CREATE NONCLUSTERED COLUMNSTORE INDEX idx_cs_dummy ON dbo.Transactions(actid) WHERE actid = -1 AND actid = -2;
-- DROP INDEX IF EXISTS idx_cs_dummy ON dbo.Transactions;

---------------------------------------------------------------------
-- Ranking window functions
---------------------------------------------------------------------

-- Creating and populating the Orders table
SET NOCOUNT ON;
USE tempdb;

DROP TABLE IF EXISTS dbo.Orders;

CREATE TABLE dbo.Orders
(
  orderid   INT        NOT NULL,
  orderdate DATE       NOT NULL,
  empid     INT        NOT NULL,
  custid    VARCHAR(5) NOT NULL,
  qty       INT        NOT NULL,
  CONSTRAINT PK_Orders PRIMARY KEY NONCLUSTERED(orderid)
);
GO

CREATE UNIQUE CLUSTERED INDEX idx_UC_orderdate_orderid
  ON dbo.Orders(orderdate, orderid);

INSERT INTO dbo.Orders(orderid, orderdate, empid, custid, qty)
  VALUES(30001, '20130802', 3, 'B', 10),
        (10001, '20131224', 1, 'C', 10),
        (10005, '20131224', 1, 'A', 30),
        (40001, '20140109', 4, 'A', 40),
        (10006, '20140118', 1, 'C', 10),
        (20001, '20140212', 2, 'B', 20),
        (40005, '20140212', 4, 'A', 10),
        (20002, '20140216', 2, 'C', 20),
        (30003, '20140418', 3, 'B', 15),
        (30004, '20140418', 3, 'B', 20),
        (30007, '20140907', 3, 'C', 30);
GO

-- ranking
SELECT orderid, qty,
  ROW_NUMBER() OVER(ORDER BY qty) AS rownum,
  RANK()       OVER(ORDER BY qty) AS rnk,
  DENSE_RANK() OVER(ORDER BY qty) AS densernk,
  NTILE(4)     OVER(ORDER BY qty) AS ntile4
FROM dbo.Orders;

-- example with partitioning
SELECT custid, orderid, qty,
  ROW_NUMBER() OVER(PARTITION BY custid ORDER BY orderid) AS rownum
FROM dbo.Orders
ORDER BY custid, orderid;

---------------------------------------------------------------------
-- Offset Window functions
---------------------------------------------------------------------

-- LAG and LEAD
SELECT custid, orderid, orderdate, qty,
  LAG(qty)  OVER(PARTITION BY custid
                 ORDER BY orderdate, orderid) AS prevqty,
  LEAD(qty) OVER(PARTITION BY custid
                 ORDER BY orderdate, orderid) AS nextqty
FROM dbo.Orders
ORDER BY custid, orderdate, orderid;

-- FIRST_VALUE and LAST_VALUE
SELECT custid, orderid, orderdate, qty,
  FIRST_VALUE(qty) OVER(PARTITION BY custid
                        ORDER BY orderdate, orderid
                        ROWS BETWEEN UNBOUNDED PRECEDING
                                 AND CURRENT ROW) AS firstqty,
  LAST_VALUE(qty)  OVER(PARTITION BY custid
                        ORDER BY orderdate, orderid
                        ROWS BETWEEN CURRENT ROW
                                 AND UNBOUNDED FOLLOWING) AS lastqty
FROM dbo.Orders
ORDER BY custid, orderdate, orderid;
GO

---------------------------------------------------------------------
-- Creative uses of window functions(as time permits)
---------------------------------------------------------------------

-- Stocks table
SET NOCOUNT ON;
USE tempdb;

DROP TABLE IF EXISTS dbo.Stocks;

CREATE TABLE dbo.Stocks
(
  stockid  INT  NOT NULL,
  dt       DATE NOT NULL,
  val      INT  NOT NULL,
  CONSTRAINT PK_Stocks PRIMARY KEY(stockid, dt)
);
GO

INSERT INTO dbo.Stocks VALUES
  (1, '2014-08-01', 13),
  (1, '2014-08-02', 14),
  (1, '2014-08-03', 17),
  (1, '2014-08-04', 40),
  (1, '2014-08-05', 45),
  (1, '2014-08-06', 52),
  (1, '2014-08-07', 56),
  (1, '2014-08-08', 60),
  (1, '2014-08-09', 70),
  (1, '2014-08-10', 30),
  (1, '2014-08-11', 29),
  (1, '2014-08-12', 35),
  (1, '2014-08-13', 40),
  (1, '2014-08-14', 45),
  (1, '2014-08-15', 60),
  (1, '2014-08-16', 60),
  (1, '2014-08-17', 55),
  (1, '2014-08-18', 60),
  (1, '2014-08-19', 20),
  (1, '2014-08-20', 15),
  (1, '2014-08-21', 20),
  (1, '2014-08-22', 30),
  (1, '2014-08-23', 40),
  (1, '2014-08-24', 20),
  (1, '2014-08-25', 60),
  (1, '2014-08-26', 80),
  (1, '2014-08-27', 70),
  (1, '2014-08-28', 70),
  (1, '2014-08-29', 40),
  (1, '2014-08-30', 30),
  (1, '2014-08-31', 10),
  (2, '2014-08-01', 3),
  (2, '2014-08-02', 4),
  (2, '2014-08-03', 7),
  (2, '2014-08-04', 30),
  (2, '2014-08-05', 35),
  (2, '2014-08-06', 42),
  (2, '2014-08-07', 46),
  (2, '2014-08-08', 50),
  (2, '2014-08-09', 60),
  (2, '2014-08-10', 20),
  (2, '2014-08-11', 19),
  (2, '2014-08-12', 25),
  (2, '2014-08-13', 30),
  (2, '2014-08-14', 35),
  (2, '2014-08-15', 50),
  (2, '2014-08-16', 50),
  (2, '2014-08-17', 45),
  (2, '2014-08-18', 50),
  (2, '2014-08-19', 10),
  (2, '2014-08-20', 5),
  (2, '2014-08-21', 10),
  (2, '2014-08-22', 20),
  (2, '2014-08-23', 30),
  (2, '2014-08-24', 10),
  (2, '2014-08-25', 50),
  (2, '2014-08-26', 70),
  (2, '2014-08-27', 60),
  (2, '2014-08-28', 60),
  (2, '2014-08-29', 30),
  (2, '2014-08-30', 20),
  (2, '2014-08-31', 1);

-- Identify consecutive periods where stock values were greater than or equal to 50
WITH C AS
(
  SELECT *, 
    DATEADD(day, -1*DENSE_RANK() OVER(PARTITION BY stockid ORDER BY dt), dt) AS grp
  FROM dbo.Stocks
  WHERE val >= 50
)
SELECT stockid, MIN(dt) AS startdt, MAX(dt) AS enddt, MAX(val) AS mx
FROM C
GROUP BY stockid, grp
ORDER BY stockid, startdt;

-- Need to be able to tolerate a gap of less than a week
WITH C1 AS
(
  SELECT *, 
    CASE
      WHEN DATEDIFF(day,
             LAG(dt) OVER(PARTITION BY stockid ORDER BY dt),
             dt) < 7 THEN 0
      ELSE 1
    END AS isstart
  FROM dbo.Stocks
  WHERE val >= 50
),
C2 AS
(
  SELECT *,
    SUM(isstart) OVER(PARTITION BY stockid ORDER BY dt
                      ROWS UNBOUNDED PRECEDING) AS grp
  FROM C1
)
SELECT stockid, MIN(dt) AS startdt, MAX(dt) AS enddt, MAX(val) AS mx
FROM C2
GROUP BY stockid, grp
ORDER BY stockid, startdt;

-- Cleanup
DROP TABLE IF EXISTS TSQLV4.dbo.Accounts, TSQLV4.dbo.Transactions, tempdb.Orders, tempdb.dbo.Stocks;

-- Max concurrent intervals
SET NOCOUNT ON;
USE tempdb;

IF OBJECT_ID('dbo.Sessions') IS NOT NULL DROP TABLE dbo.Sessions;
IF OBJECT_ID('dbo.Users') IS NOT NULL DROP TABLE dbo.Users;

CREATE TABLE dbo.Users
(
  username  VARCHAR(14)  NOT NULL,
  CONSTRAINT PK_Users PRIMARY KEY(username)
);
GO

INSERT INTO dbo.Users(username) VALUES('User1'), ('User2'), ('User3');

CREATE TABLE dbo.Sessions
(
  id        INT          NOT NULL IDENTITY(1, 1),
  username  VARCHAR(14)  NOT NULL,
  starttime DATETIME2(3) NOT NULL,
  endtime   DATETIME2(3) NOT NULL,
  CONSTRAINT PK_Sessions PRIMARY KEY(id),
  CONSTRAINT CHK_endtime_gteq_starttime
    CHECK (endtime >= starttime)
);
GO

INSERT INTO dbo.Sessions VALUES
  ('User1', '20181201 08:00:00.000', '20181201 08:30:00.000'),
  ('User1', '20181201 08:30:00.000', '20181201 09:00:00.000'),
  ('User1', '20181201 09:00:00.000', '20181201 09:30:00.000'),
  ('User1', '20181201 10:00:00.000', '20181201 11:00:00.000'),
  ('User1', '20181201 10:30:00.000', '20181201 12:00:00.000'),
  ('User1', '20181201 11:30:00.000', '20181201 12:30:00.000'),
  ('User2', '20181201 08:00:00.000', '20181201 10:30:00.000'),
  ('User2', '20181201 08:30:00.000', '20181201 10:00:00.000'),
  ('User2', '20181201 09:00:00.000', '20181201 09:30:00.000'),
  ('User2', '20181201 11:00:00.000', '20181201 11:30:00.000'),
  ('User2', '20181201 11:32:00.000', '20181201 12:00:00.000'),
  ('User2', '20181201 12:04:00.000', '20181201 12:30:00.000'),
  ('User3', '20181201 08:00:00.000', '20181201 09:00:00.000'),
  ('User3', '20181201 08:00:00.000', '20181201 08:30:00.000'),
  ('User3', '20181201 08:30:00.000', '20181201 09:00:00.000'),
  ('User3', '20181201 09:30:00.000', '20181201 09:30:00.000');
GO

-- Predicate approach
CREATE UNIQUE INDEX idx_username_st_et_id ON dbo.Sessions(username, starttime, endtime, id);

WITH C AS
(
  SELECT username, starttime,
    ( SELECT COUNT(*)
      FROM dbo.Sessions AS S WITH (FORCESEEK)
      WHERE S.username = P.username
        AND P.starttime >= S.starttime
        AND P.starttime < S.endtime ) AS cnt
  FROM dbo.Sessions AS P
)
SELECT username, MAX(cnt) AS mx
FROM C
GROUP BY username;

DROP INDEX idx_username_st_et_id ON dbo.Sessions;

-- Window-function approach
CREATE UNIQUE INDEX idx_start ON dbo.Sessions(username, starttime, id);
CREATE UNIQUE INDEX idx_end ON dbo.Sessions(username, endtime, id);

WITH C1 AS
(
  SELECT id, username, starttime as eventtime, +1 AS eventtype
  FROM dbo.Sessions
  
  UNION ALL
  
  SELECT id, username, endtime as eventtime, -1 AS eventtype
  FROM dbo.Sessions
),
C2 AS
(
  SELECT *,
    SUM(eventtype) OVER(PARTITION BY username
                        ORDER BY eventtime, eventtype, id
                        ROWS UNBOUNDED PRECEDING) AS cnt
  FROM C1
)
SELECT username, MAX(cnt) AS mx
FROM C2
GROUP BY username;

-- Packing intervals
WITH C1 AS
(
  SELECT id, username, starttime as eventtime, +1 AS eventtype
  FROM dbo.Sessions
  
  UNION ALL
  
  SELECT id, username, endtime as eventtime, -1 AS eventtype
  FROM dbo.Sessions
),
C2 AS
(
  SELECT *,
    SUM(eventtype) OVER(PARTITION BY username
                        ORDER BY eventtime, eventtype DESC, id
                        ROWS UNBOUNDED PRECEDING) AS cnt
  FROM C1
),
C3 AS
(
  SELECT *,
    (ROW_NUMBER() OVER(PARTITION BY username ORDER BY eventtime, eventtype DESC, id) - 1) / 2 + 1 AS pair
  FROM C2
  WHERE (eventtype = 1 AND cnt = 1)
     OR (eventtype = -1 AND cnt = 0)
)
SELECT username, MIN(eventtime) AS starttime, MAX(eventtime) AS endtime
FROM C3
GROUP BY username, pair;

DROP INDEX idx_start ON dbo.Sessions;
DROP INDEX idx_end ON dbo.Sessions;
