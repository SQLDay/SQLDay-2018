USE ContosoRetailDW
GO 


-- Create the Partitioning scheme
create partition function pfOnlineSalesDate_ (datetime)
AS RANGE RIGHT FOR VALUES ('2014-01-01', '2015-01-01', '2016-01-01', '2017-01-01','20180101');
GO
 
-- Define the partitioning function for it, which will be mapping data to each of the corresponding filegroups
create partition scheme ColumstorePartitioning_ 
	AS PARTITION pfOnlineSalesDate_
		TO ( OldColumnstoreData, Columnstore2014, Columnstore2015, Columnstore2016, Columnstore2017, Columnstore2018 );
GO
-------------------------------------------------------------
 
-- Creation of a traditional Clustered Index (~200 s)

Create Clustered Index CI_FactOnlineSales
	on dbo.FactOnlineSales (DateKey)
		ON ColumstorePartitioning (DateKey)
GO	 
 
-- Create Partitioned Clustered Columnstore Index (~ 60s)

Create Clustered Columnstore Index CCI_FactOnlineSales
	on dbo.FactOnlineSales
     with (DROP_EXISTING = ON)
		ON ColumstorePartitioning (DateKey);
GO






-- Check the Partitioning Information

SELECT $PARTITION.pfOnlineSalesDate(DateKey) AS Partition,  COUNT(*) AS [Rows Count]
	, Min(Year(DateKey)) as [MinYear],  Max(Year(DateKey)) as [MaxYear] 
	FROM dbo.FactOnlineSales
GROUP BY $PARTITION.pfOnlineSalesDate(DateKey)
ORDER BY Partition ;
 
SELECT OBJECT_NAME(st.object_id) as TableName, partition_number, row_count
	FROM sys.dm_db_partition_stats st
	WHERE st.object_id = object_id('dbo.FactOnlineSales')
		AND index_id = 1
	ORDER BY partition_number;


--Merging Partitions (fail)

ALTER PARTITION FUNCTION pfOnlineSalesDate ()  
	MERGE RANGE ('2015-01-01'); 

ALTER PARTITION FUNCTION pfOnlineSalesDate ()  
	MERGE RANGE ('2014-01-01'); 

--**********************************************
-- Load Data from the original table (~50 s)
--SELECT * 
--	into dbo.FactOnlineSalesPrimary 
--	FROM dbo.FactOnlineSales WITH (TABLOCK);	
 
 
-- Create the Partitioning scheme
create partition function pfOnlineSalesDatePrimary (datetime)
	AS RANGE RIGHT FOR VALUES ('2014-01-01', '2015-01-01', '2016-01-01', '2017-01-01', '2018-01-01');
 
create partition scheme ColumstorePartitioningPrimary 
	AS PARTITION pfOnlineSalesDatePrimary
		ALL to ([Primary]);
GO
 
-- Create traditional partitioned Clustered Index

Create Clustered Index CCI_FactOnlineSalesPrimary
	on dbo.FactOnlineSalesPrimary (DateKey)
		ON ColumstorePartitioningPrimary (DateKey)
	 
-- Create Partitioned Clustered Columnstore Index

Create Clustered Columnstore Index CCI_FactOnlineSalesPrimary
	on dbo.FactOnlineSalesPrimary
     with (DROP_EXISTING = ON)
		ON ColumstorePartitioningPrimary (DateKey);

-- merge partition part.2

ALTER PARTITION FUNCTION pfOnlineSalesDatePrimary ()  
	MERGE RANGE ('2014-01-01'); 


--Splitting Partitions

 	
	ALTER PARTITION SCHEME ColumstorePartitioning 
		NEXT USED [Columnstore2017]
 
	-- Splitting Partitions
	ALTER PARTITION FUNCTION pfOnlineSalesDate ()  
		SPLIT RANGE ('2017-07-01'); 


-- Load Data from the original table
--SELECT * 
--	into dbo.FactOnlineSalesRowstore 
--	FROM dbo.FactOnlineSales WITH (TABLOCK);	
 
 
-- Create the Partitioning scheme
create partition function pfOnlineSalesDateRowstore (datetime)
	AS RANGE RIGHT FOR VALUES ('2014-01-01', '2015-01-01', '2016-01-01', '2017-01-01', '2018-01-01');
 
create partition scheme ColumstorePartitioningRowstore 
	AS PARTITION pfOnlineSalesDateRowstore
		TO ( OldColumnstoreData, Columnstore2014, Columnstore2015, Columnstore2016, Columnstore2017, Columnstore2017 );
GO
 
-- Creation of a traditional Clustered Index
Create Clustered Index CCI_FactOnlineSalesRowstore
	on dbo.FactOnlineSalesRowstore (DateKey)
		ON ColumstorePartitioningRowstore (DateKey)
	 
 
GO
ALTER PARTITION SCHEME ColumstorePartitioningRowstore
	NEXT USED [Columnstore2017]
GO
 
-- Splitting Partitions
ALTER PARTITION FUNCTION pfOnlineSalesDateRowstore ()  
	SPLIT RANGE ('2017-07-01'); 

