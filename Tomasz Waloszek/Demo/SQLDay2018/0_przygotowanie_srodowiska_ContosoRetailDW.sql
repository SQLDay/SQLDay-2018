--odtworzenie baz danych: 

USE [master]
ALTER DATABASE [ContosoRetailDW] SET SINGLE_USER WITH ROLLBACK IMMEDIATE
RESTORE DATABASE [ContosoRetailDW] FROM  DISK = N'F:\SQL_Database\MSSQL14.MSSQLSERVER\MSSQL\Backup\ContosoRetail_SQLDayDemo' WITH  FILE = 1,  NOUNLOAD,  REPLACE,  STATS = 5
ALTER DATABASE [ContosoRetailDW] SET MULTI_USER

GO

ALTER DATABASE [ContosoRetailDW] SET COMPATIBILITY_LEVEL = 130
GO

USE [ContosoRetailDW]
GO 
ALTER TABLE [dbo].[FactOnlineSales] DROP CONSTRAINT [PK_FactOnlineSales_SalesKey]
GO 

Select * INTO dbo.FactOnlineSales_copy from  [dbo].[FactOnlineSales]

SELECT * 
	into dbo.FactOnlineSalesRowstore 
	FROM dbo.FactOnlineSales WITH (TABLOCK);	

SELECT * 
	into dbo.FactOnlineSalesPrimary 
	FROM dbo.FactOnlineSales WITH (TABLOCK);	



--*****************************************************************************************************************************************

ALTER DATABASE [ContosoRetailDW_2014] SET COMPATIBILITY_LEVEL = 120
GO
ALTER DATABASE [ContosoRetailDW_2014] MODIFY FILE ( NAME = N'ContosoRetailDW2.0', SIZE = 2000000KB , FILEGROWTH = 128000KB )
GO
ALTER DATABASE [ContosoRetailDW_2014] MODIFY FILE ( NAME = N'ContosoRetailDW2.0_log', SIZE = 400000KB , FILEGROWTH = 256000KB )
GO

ALTER DATABASE [ContosoRetailDW_2016] SET COMPATIBILITY_LEVEL = 120
GO
ALTER DATABASE [ContosoRetailDW_2016] MODIFY FILE ( NAME = N'ContosoRetailDW2.0', SIZE = 2000000KB , FILEGROWTH = 128000KB )
GO
ALTER DATABASE [ContosoRetailDW_2016] MODIFY FILE ( NAME = N'ContosoRetailDW2.0_log', SIZE = 400000KB , FILEGROWTH = 256000KB )
GO

---- Drop our existing PK (ok.2 min)
USE ContosoRetailDW_2016
GO 

create partition function pfSalesDate (datetime)
AS RANGE RIGHT FOR VALUES ('2014-01-01', '2015-01-01', '2016-01-01', '2017-01-01', '2018-01-01');


create partition scheme PartitioningSalesScheme 
	AS PARTITION pfSalesDate
		ALL TO ([PRIMARY]);

DROP TABLE IF EXISTS [ContosoRetailDW_2016].dbo.FactSales_
DROP TABLE IF EXISTS [ContosoRetailDW_2016].dbo.FactSales_Part

Select * INTO [ContosoRetailDW_2016].dbo.FactSales_ from [ContosoRetailDW].dbo.FactOnlineSales
Select * INTO [ContosoRetailDW_2016].dbo.FactSales_Part from [ContosoRetailDW].dbo.FactOnlineSales


CREATE CLUSTERED INDEX idx_FactSales
ON [dbo].[FactSales_] (DateKey) ON [primary]
GO

CREATE CLUSTERED INDEX idx_FactSales_Part
ON [dbo].[FactSales_Part] (DateKey) ON PartitioningSalesScheme (DateKey)
GO



