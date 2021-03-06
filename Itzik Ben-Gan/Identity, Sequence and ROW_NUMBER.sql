---------------------------------------------------------------------
-- Identity, Sequence and ROW_NUMBER
-- © Itzik Ben-Gan, SolidQ
-- Advanced T-SQL training: http://tsql.solidq.com/courses.htm
---------------------------------------------------------------------

---------------------------------------------------------------------
-- Sequences vs. Identity
---------------------------------------------------------------------

---------------------------------------------------------------------
-- Removing / Adding IDENTITY
---------------------------------------------------------------------

SET NOCOUNT ON;
USE tempdb;

-- Remove IDENTITY
DROP TABLE IF EXISTS dbo.T1, dbo.T1Temp;
GO

CREATE TABLE dbo.T1
(
  keycol INT NOT NULL IDENTITY
    CONSTRAINT PK_T1 PRIMARY KEY,
  datacol VARCHAR(10) NOT NULL
);

INSERT INTO dbo.T1(datacol) VALUES('A'),('B'),('C');
GO

BEGIN TRAN;

CREATE TABLE dbo.T1Temp
(
  keycol INT NOT NULL
    CONSTRAINT PK_T1Temp PRIMARY KEY,
  datacol VARCHAR(10) NOT NULL
);

ALTER TABLE dbo.T1 SWITCH TO dbo.T1Temp;

DROP TABLE dbo.T1;

CREATE TABLE dbo.T1
(
  keycol INT NOT NULL
    CONSTRAINT PK_T1 PRIMARY KEY,
  datacol VARCHAR(10) NOT NULL
);

ALTER TABLE dbo.T1Temp SWITCH TO dbo.T1;

DROP TABLE dbo.T1Temp;

COMMIT TRAN;

SELECT * FROM dbo.T1;

EXEC sp_help 'dbo.T1';

INSERT INTO dbo.T1(keycol, datacol) VALUES(4, 'D'),(5, 'E'),(6, 'F');

SELECT * FROM dbo.T1;
GO

-- Add IDENTITY
DROP TABLE IF EXISTS dbo.T1, dbo.T1Temp;
GO

CREATE TABLE dbo.T1
(
  keycol INT NOT NULL
    CONSTRAINT PK_T1 PRIMARY KEY,
  datacol VARCHAR(10) NOT NULL
);

INSERT INTO dbo.T1(keycol, datacol) VALUES(1, 'A'),(2, 'B'),(3, 'C');
GO

BEGIN TRAN;

DECLARE @newseed AS INT = ISNULL((SELECT MAX(keycol) FROM dbo.T1 WITH(TABLOCKX)) + 1, 1);

CREATE TABLE dbo.T1Temp
(
  keycol INT NOT NULL IDENTITY
    CONSTRAINT PK_T1Temp PRIMARY KEY,
  datacol VARCHAR(10) NOT NULL
);

ALTER TABLE dbo.T1 SWITCH TO dbo.T1Temp;

DROP TABLE dbo.T1;

CREATE TABLE dbo.T1
(
  keycol INT NOT NULL IDENTITY
    CONSTRAINT PK_T1 PRIMARY KEY,
  datacol VARCHAR(10) NOT NULL
);

ALTER TABLE dbo.T1Temp SWITCH TO dbo.T1;

DBCC CHECKIDENT('dbo.T1', RESEED, @newseed);

DROP TABLE dbo.T1Temp;

COMMIT TRAN;

SELECT * FROM dbo.T1;

EXEC sp_help 'dbo.T1';

INSERT INTO dbo.T1(datacol) VALUES('D'),('E'),('F');

SELECT * FROM dbo.T1;
GO

---------------------------------------------------------------------
-- The Sequence Object
---------------------------------------------------------------------

-- Create sequence for order IDs
USE tempdb;

IF OBJECT_ID(N'dbo.Seqorderids', N'SO') IS NOT NULL DROP SEQUENCE dbo.Seqorderids;
IF OBJECT_ID(N'dbo.Orders', N'U') IS NOT NULL DROP TABLE dbo.Orders;

CREATE TABLE dbo.Orders
(
  orderid INT NOT NULL,
  /* ... other cols ... */
);

CREATE SEQUENCE dbo.Seqorderids AS INT
  MINVALUE 1
  CYCLE
  CACHE 10000;

-- Request new value
SELECT NEXT VALUE FOR dbo.Seqorderids;

-- Query Information about Sequences
SELECT current_value, start_value, increment, minimum_value, maximum_value, is_cycling,
  is_cached, cache_size
FROM sys.Sequences
WHERE object_id = OBJECT_ID(N'dbo.Seqorderids', N'SO');

-- Can be used in DEFAULT constraint
ALTER TABLE dbo.Orders
  ADD CONSTRAINT DFT_Orders_orderid
    DEFAULT(NEXT VALUE FOR dbo.Seqorderids) FOR orderid;

-- Can drop constraint at any point
ALTER TABLE dbo.Orders DROP CONSTRAINT DFT_Orders_orderid;

-- Request value before use
DECLARE @newkey AS INT = NEXT VALUE FOR dbo.Seqorderids;
SELECT @newkey;

-- Create MyOrders table
-- Get sample database PerformanceV3 here: http://tsql.solidq.com/SampleDatabases/PerformanceV3.zip
USE tempdb;
IF OBJECT_ID(N'dbo.MyOrders', N'U') IS NOT NULL DROP TABLE dbo.MyOrders;
SELECT orderid, custid, empid, shipperid, orderdate, filler INTO dbo.MyOrders FROM PerformanceV3.dbo.Orders WHERE empid = 1;
ALTER TABLE dbo.MyOrders ADD CONSTRAINT PK_MyOrders PRIMARY KEY(orderid);

-- Used in UPDATE
UPDATE dbo.MyOrders
  SET orderid = NEXT VALUE FOR dbo.Seqorderids;

-- Supports defining order in multi-row inserts
INSERT INTO dbo.MyOrders(orderid, custid, empid, shipperid, orderdate, filler)
  SELECT NEXT VALUE FOR dbo.Seqorderids OVER(ORDER BY orderid) AS orderid,
    custid, empid, shipperid, orderdate, filler
  FROM PerformanceV3.dbo.Orders
  WHERE empid = 2;
GO

-- Range
DECLARE @first AS SQL_VARIANT;

EXEC sys.sp_sequence_get_range
  @sequence_name     = N'dbo.Seqorderids',
  @range_size        = 1000000,
  @range_first_value = @first OUTPUT ;

SELECT @first;
GO

-- Can have gaps
SELECT NEXT VALUE FOR dbo.Seqorderids;
BEGIN TRAN
  SELECT NEXT VALUE FOR dbo.Seqorderids;
ROLLBACK TRAN
SELECT NEXT VALUE FOR dbo.Seqorderids;

---------------------------------------------------------------------
-- Performance Considerations
---------------------------------------------------------------------

-- Default cache

-- Preparation
IF DB_ID(N'testdb') IS NULL CREATE DATABASE testdb;
USE testdb;

IF OBJECT_ID(N'dbo.SeqTINYINT'  , N'SO') IS NOT NULL DROP SEQUENCE dbo.SeqTINYINT;
IF OBJECT_ID(N'dbo.SeqSMALLINT' , N'SO') IS NOT NULL DROP SEQUENCE dbo.SeqSMALLINT;
IF OBJECT_ID(N'dbo.SeqINT'      , N'SO') IS NOT NULL DROP SEQUENCE dbo.SeqINT;
IF OBJECT_ID(N'dbo.SeqBIGINT'   , N'SO') IS NOT NULL DROP SEQUENCE dbo.SeqBIGINT;
IF OBJECT_ID(N'dbo.SeqNUMERIC9' , N'SO') IS NOT NULL DROP SEQUENCE dbo.SeqNUMERIC9;
IF OBJECT_ID(N'dbo.SeqNUMERIC38', N'SO') IS NOT NULL DROP SEQUENCE dbo.SeqNUMERIC38;

IF OBJECT_ID(N'dbo.TTINYINT'  , N'U') IS NOT NULL DROP TABLE dbo.TTINYINT;
IF OBJECT_ID(N'dbo.TSMALLINT' , N'U') IS NOT NULL DROP TABLE dbo.TSMALLINT;
IF OBJECT_ID(N'dbo.TINT'      , N'U') IS NOT NULL DROP TABLE dbo.TINT;
IF OBJECT_ID(N'dbo.TBIGINT'   , N'U') IS NOT NULL DROP TABLE dbo.TBIGINT;
IF OBJECT_ID(N'dbo.TNUMERIC9' , N'U') IS NOT NULL DROP TABLE dbo.TNUMERIC9;
IF OBJECT_ID(N'dbo.TNUMERIC38', N'U') IS NOT NULL DROP TABLE dbo.TNUMERIC38;

CREATE SEQUENCE dbo.SeqTINYINT   AS TINYINT        MINVALUE 1;
CREATE SEQUENCE dbo.SeqSMALLINT  AS SMALLINT       MINVALUE 1;
CREATE SEQUENCE dbo.SeqINT       AS INT            MINVALUE 1;
CREATE SEQUENCE dbo.SeqBIGINT    AS BIGINT         MINVALUE 1;
CREATE SEQUENCE dbo.SeqNUMERIC9  AS NUMERIC( 9, 0) MINVALUE 1;
CREATE SEQUENCE dbo.SeqNUMERIC38 AS NUMERIC(38, 0) MINVALUE 1;

CREATE TABLE dbo.TTINYINT  (keycol TINYINT        IDENTITY);
CREATE TABLE dbo.TSMALLINT (keycol SMALLINT       IDENTITY);
CREATE TABLE dbo.TINT      (keycol INT            IDENTITY);
CREATE TABLE dbo.TBIGINT   (keycol BIGINT         IDENTITY);
CREATE TABLE dbo.TNUMERIC9 (keycol NUMERIC( 9, 0) IDENTITY);
CREATE TABLE dbo.TNUMERIC38(keycol NUMERIC(38, 0) IDENTITY);
GO

SELECT
  NEXT VALUE FOR dbo.SeqTINYINT  ,
  NEXT VALUE FOR dbo.SeqSMALLINT ,
  NEXT VALUE FOR dbo.SeqINT      ,
  NEXT VALUE FOR dbo.SeqBIGINT   ,
  NEXT VALUE FOR dbo.SeqNUMERIC9 ,
  NEXT VALUE FOR dbo.SeqNUMERIC38;
GO 5

INSERT INTO dbo.TTINYINT   DEFAULT VALUES;
INSERT INTO dbo.TSMALLINT  DEFAULT VALUES;
INSERT INTO dbo.TINT       DEFAULT VALUES;
INSERT INTO dbo.TBIGINT    DEFAULT VALUES;
INSERT INTO dbo.TNUMERIC9  DEFAULT VALUES;
INSERT INTO dbo.TNUMERIC38 DEFAULT VALUES;
GO 5

SELECT name, current_value FROM sys.Sequences
WHERE object_id IN
  ( OBJECT_ID(N'dbo.SeqTINYINT  '),
    OBJECT_ID(N'dbo.SeqSMALLINT '),
    OBJECT_ID(N'dbo.SeqINT      '),
    OBJECT_ID(N'dbo.SeqBIGINT   '),
    OBJECT_ID(N'dbo.SeqNUMERIC9 '),
    OBJECT_ID(N'dbo.SeqNUMERIC38') );

SELECT
  IDENT_CURRENT(N'dbo.TTINYINT  ') AS TTINYINT  ,
  IDENT_CURRENT(N'dbo.TSMALLINT ') AS TSMALLINT ,
  IDENT_CURRENT(N'dbo.TINT      ') AS TINT      ,
  IDENT_CURRENT(N'dbo.TBIGINT   ') AS TBIGINT   ,
  IDENT_CURRENT(N'dbo.TNUMERIC9 ') AS TNUMERIC9 ,
  IDENT_CURRENT(N'dbo.TNUMERIC38') AS TNUMERIC38;

-- Kill the SQL Server service from Task Manager and start the service (not sufficient to restart service)
USE testdb;

SELECT name, current_value FROM sys.Sequences
WHERE object_id IN
  ( OBJECT_ID(N'dbo.SeqTINYINT  '),
    OBJECT_ID(N'dbo.SeqSMALLINT '),
    OBJECT_ID(N'dbo.SeqINT      '),
    OBJECT_ID(N'dbo.SeqBIGINT   '),
    OBJECT_ID(N'dbo.SeqNUMERIC9 '),
    OBJECT_ID(N'dbo.SeqNUMERIC38') );

SELECT
  IDENT_CURRENT(N'dbo.TTINYINT  ') AS TTINYINT  ,
  IDENT_CURRENT(N'dbo.TSMALLINT ') AS TSMALLINT ,
  IDENT_CURRENT(N'dbo.TINT      ') AS TINT      ,
  IDENT_CURRENT(N'dbo.TBIGINT   ') AS TBIGINT   ,
  IDENT_CURRENT(N'dbo.TNUMERIC9 ') AS TNUMERIC9 ,
  IDENT_CURRENT(N'dbo.TNUMERIC38') AS TNUMERIC38;
GO

-- Generate new value
SELECT NEXT VALUE FOR dbo.SeqINT;

INSERT INTO dbo.TINT OUTPUT inserted.$identity DEFAULT VALUES;

-- Cleanup
IF OBJECT_ID(N'dbo.SeqTINYINT'  , N'SO') IS NOT NULL DROP SEQUENCE dbo.SeqTINYINT;
IF OBJECT_ID(N'dbo.SeqSMALLINT' , N'SO') IS NOT NULL DROP SEQUENCE dbo.SeqSMALLINT;
IF OBJECT_ID(N'dbo.SeqINT'      , N'SO') IS NOT NULL DROP SEQUENCE dbo.SeqINT;
IF OBJECT_ID(N'dbo.SeqBIGINT'   , N'SO') IS NOT NULL DROP SEQUENCE dbo.SeqBIGINT;
IF OBJECT_ID(N'dbo.SeqNUMERIC9' , N'SO') IS NOT NULL DROP SEQUENCE dbo.SeqNUMERIC9;
IF OBJECT_ID(N'dbo.SeqNUMERIC38', N'SO') IS NOT NULL DROP SEQUENCE dbo.SeqNUMERIC38;

IF OBJECT_ID(N'dbo.TTINYINT'  , N'U') IS NOT NULL DROP TABLE dbo.TTINYINT;
IF OBJECT_ID(N'dbo.TSMALLINT' , N'U') IS NOT NULL DROP TABLE dbo.TSMALLINT;
IF OBJECT_ID(N'dbo.TINT'      , N'U') IS NOT NULL DROP TABLE dbo.TINT;
IF OBJECT_ID(N'dbo.TBIGINT'   , N'U') IS NOT NULL DROP TABLE dbo.TBIGINT;
IF OBJECT_ID(N'dbo.TNUMERIC9' , N'U') IS NOT NULL DROP TABLE dbo.TNUMERIC9;
IF OBJECT_ID(N'dbo.TNUMERIC38', N'U') IS NOT NULL DROP TABLE dbo.TNUMERIC38;

-- Performance test of sequences with different cache values and identity in tempdb and in a user database

-- First create the user db and a sequence in both the user db and tempdb
IF DB_ID(N'testdb') IS NULL CREATE DATABASE testdb;
ALTER DATABASE testdb SET RECOVERY SIMPLE;

USE testdb;
IF OBJECT_ID(N'dbo.Seq1', N'SO') IS NOT NULL DROP SEQUENCE dbo.Seq1;
CREATE SEQUENCE dbo.Seq1 AS INT MINVALUE 1;

USE tempdb;
IF OBJECT_ID(N'dbo.Seq1', N'SO') IS NOT NULL DROP SEQUENCE dbo.Seq1;
CREATE SEQUENCE dbo.Seq1 AS INT MINVALUE 1;
GO

-- Performance test
-- To enable TF 272: DBCC TRACEON(272, -1), to disable: DBCC TRACEOFF(272, -1)
-- In 2017+ to can use ALTER DATABASE SCOPED CONFIGURATION SET IDENTITY_CACHE = { ON | OFF }
SET NOCOUNT ON;
--USE tempdb; -- to test in tempdb
USE testdb; -- to test in user database testdb

DECLARE @numrecords AS INT, @sizemb AS NUMERIC(12, 2), @logflushes AS INT,
  @starttime AS DATETIME2, @endtime AS DATETIME2;

CHECKPOINT;

BEGIN TRAN

  ALTER SEQUENCE dbo.Seq1 CACHE 50; -- try with CAHCE 10, 50, 10000, NO CACHE
  IF OBJECT_ID(N'dbo.T', N'U') IS NOT NULL DROP TABLE dbo.T;
  
  -- Stats before
  SELECT @numrecords = COUNT(*), @sizemb = SUM(CAST([Log Record Length] AS BIGINT)) / 1048576.,
    @logflushes = (SELECT cntr_value FROM sys.dm_os_performance_counters
                   WHERE counter_name = 'Log Flushes/sec'
                         AND instance_name = 'testdb' -- to test in testdb
--                         AND instance_name = 'tempdb' -- to test in tempdb
                  )
  FROM sys.fn_dblog(null, null);
 
  SET @starttime = SYSDATETIME();

  -- Actual work
  SELECT
    n -- to test without seq or identity
--    NEXT VALUE FOR dbo.Seq1 AS n -- to test sequence
--    IDENTITY(INT, 1, 1) AS n -- to test identity
  INTO dbo.T
  FROM PerformanceV3.dbo.GetNums(1, 10000000) AS N
  OPTION(MAXDOP 1);

  -- Stats after
  SET @endtime = SYSDATETIME();
 
  SELECT
    COUNT(*) - @numrecords AS numrecords,
    SUM(CAST([Log Record Length] AS BIGINT)) / 1048576. - @sizemb AS sizemb,
    (SELECT cntr_value FROM sys.dm_os_performance_counters
     WHERE counter_name = 'Log Flushes/sec'
       AND instance_name = 'testdb' -- to test in testdb
--       AND instance_name = 'tempdb' -- to test in tempdb
       ) - @logflushes AS logflushes,
    DATEDIFF(ms, @starttime, @endtime) AS durationms 
  FROM sys.fn_dblog(null, null);
 
COMMIT TRAN
 
CHECKPOINT;

---------------------------------------------------------------------
-- ROW_NUMBER
---------------------------------------------------------------------

-- Row numbers with arbitrary order
SELECT
  ROW_NUMBER() OVER(ORDER BY (SELECT NULL)) AS rownum,
  object_id, schema_id, name
FROM sys.objects;

-- GetNums function
IF OBJECT_ID(N'dbo.GetNums', N'IF') IS NOT NULL DROP FUNCTION dbo.GetNums;
GO
CREATE FUNCTION dbo.GetNums(@low AS BIGINT, @high AS BIGINT) RETURNS TABLE
AS
RETURN
  WITH
    L0   AS (SELECT c FROM (SELECT 1 UNION ALL SELECT 1) AS D(c)),
    L1   AS (SELECT 1 AS c FROM L0 AS A CROSS JOIN L0 AS B),
    L2   AS (SELECT 1 AS c FROM L1 AS A CROSS JOIN L1 AS B),
    L3   AS (SELECT 1 AS c FROM L2 AS A CROSS JOIN L2 AS B),
    L4   AS (SELECT 1 AS c FROM L3 AS A CROSS JOIN L3 AS B),
    L5   AS (SELECT 1 AS c FROM L4 AS A CROSS JOIN L4 AS B),
    Nums AS (SELECT ROW_NUMBER() OVER(ORDER BY (SELECT NULL)) AS rownum
             FROM L5)
  SELECT TOP(@high - @low + 1) @low + rownum - 1 AS n
  FROM Nums
  ORDER BY rownum;
GO