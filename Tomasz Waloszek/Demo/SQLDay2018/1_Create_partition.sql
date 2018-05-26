USE ContosoRetailDW
GO 


-- check persisted_sku_features


select *
from sys.dm_db_persisted_sku_features




-- Add  new filegroups to our database
alter database ContosoRetailDW
	add filegroup OldColumnstoreData_;
GO
alter database ContosoRetailDW
	add filegroup Columnstore2014_;
GO
alter database ContosoRetailDW
	add filegroup Columnstore2015_;
GO
alter database ContosoRetailDW
	add filegroup Columnstore2016_;
GO
alter database ContosoRetailDW
	add filegroup Columnstore2017_;
GO
alter database ContosoRetailDW
	add filegroup Columnstore2018;
GO

-- Add 1 datafile to each of the respective filegroups
alter database ContosoRetailDW 
add file 
(
    NAME = 'old_data_',
    FILENAME = 'F:\SQL_Database\MSSQL14.MSSQLSERVER\MSSQL\DATA\old_data_.ndf',
    SIZE = 10MB,
    FILEGROWTH = 125MB
) to Filegroup [OldColumnstoreData_];
GO

alter database ContosoRetailDW 
add file 
(
    NAME = '2014_data_',
    FILENAME = 'F:\SQL_Database\MSSQL14.MSSQLSERVER\MSSQL\DATA\2014_data_.ndf',
    SIZE = 500MB,
    FILEGROWTH = 125MB
) TO Filegroup Columnstore2014_;
GO

alter database ContosoRetailDW 
add file 
(
    NAME = '2015_data_',
    FILENAME = 'F:\SQL_Database\MSSQL14.MSSQLSERVER\MSSQL\DATA\2015_data_.ndf',
    SIZE = 500MB,
    FILEGROWTH = 125MB
) to Filegroup Columnstore2015_;
GO

alter database ContosoRetailDW 
add file 
(
    NAME = '2016_data_',
    FILENAME = 'F:\SQL_Database\MSSQL14.MSSQLSERVER\MSSQL\DATA\2016_data_.ndf',
    SIZE = 500MB,
    FILEGROWTH = 125MB
) TO Filegroup Columnstore2016_;
GO

alter database ContosoRetailDW 
add file 
(
    NAME = '2017_data_',
    FILENAME = 'F:\SQL_Database\MSSQL14.MSSQLSERVER\MSSQL\DATA\2017_data_.ndf',
    SIZE = 500MB,
    FILEGROWTH = 125MB
) TO Filegroup Columnstore2017_;
GO
alter database ContosoRetailDW 
add file 
(
    NAME = '2018_data',
    FILENAME = 'F:\SQL_Database\MSSQL14.MSSQLSERVER\MSSQL\DATA\2018_data.ndf',
    SIZE = 500MB,
    FILEGROWTH = 125MB
) TO Filegroup Columnstore2018;
GO

-------------------------------------------------------------
-- Define the partitioning function for it, which will be mapping data to each of the corresponding filegroups

create partition function pfOnlineSalesDate_copy (datetime)
AS RANGE RIGHT FOR VALUES ('2014-01-01', '2015-01-01', '2016-01-01', '2017-01-01');



select *
from sys.partition_range_values
where 
function_id = (Select function_id from sys.partition_functions
				where name = 'pfOnlineSalesDate_copy')
 
 

 -- Create the Partitioning scheme

create partition scheme PartitioningScheme 
	AS PARTITION pfOnlineSalesDate_Copy
		TO ( OldColumnstoreData_, Columnstore2014_, Columnstore2015_, Columnstore2016_, Columnstore2017_ );

-------------------------------------------------------------

-- Check the Partitioning Information

select * 
from sys.partitions
where object_id = OBJECT_ID('dbo.FactOnlineSales_copy')

select *
from sys.dm_db_partition_stats
where object_id = OBJECT_ID('dbo.FactOnlineSales_copy')





-- Creation of a traditional Clustered Index (~ 90sek)

Create Clustered Index CCI_FactOnlineSales
	on dbo.FactOnlineSales_copy (DateKey)
		ON ColumstorePartitioning (DateKey)

	
-- Check the Partitioning Information

SELECT $PARTITION.pfOnlineSalesDate(DateKey) AS Partition,  COUNT(*) AS [Rows Count]
	, Min(Year(DateKey)) as [MinYear],  Max(Year(DateKey)) as [MaxYear] 
	FROM dbo.FactOnlineSales_copy
GROUP BY $PARTITION.pfOnlineSalesDate(DateKey)
ORDER BY Partition ; 




select * 
from sys.partitions
where object_id = OBJECT_ID('dbo.FactOnlineSales_copy')

select *
from sys.dm_db_partition_stats
where object_id = OBJECT_ID('dbo.FactOnlineSales_copy')


select *
from sys.dm_db_persisted_sku_features
