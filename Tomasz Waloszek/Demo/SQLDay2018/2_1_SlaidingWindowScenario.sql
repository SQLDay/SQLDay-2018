 USE ContosoRetailDW
 GO 
 
 DECLARE @Day datetime

 SET @Day = cast((select top 1 [value] from sys.partition_range_values
        where function_id = (select function_id
                from sys.partition_functions
                where name = 'pfOnlineSalesDate_copy')
       order by boundary_id desc) as datetime)
--SELECT @Day

 WHILE @Day < DATEADD(MONTH, 1, GETDATE())
 BEGIN
                 SET @Day = DATEADD(MONTH, 1, @Day)

                 ALTER PARTITION SCHEME PartitioningScheme
                 NEXT USED [PRIMARY];

                 ALTER PARTITION FUNCTION pfOnlineSalesDate_copy()
                 SPLIT RANGE (@Day);
 END
 GO


 --STEP2 > Truncate old partition

 DECLARE @Day datetime

 SET @Day = cast((select top 1 [value] from sys.partition_range_values
        where function_id = (select function_id
                from sys.partition_functions
                where name = 'pfOnlineSalesDate')
       order by boundary_id asc) as datetime)
 select @day


 WHILE DATEDIFF(dd, @Day, GETDATE()) > 180
 BEGIN

	 TRUNCATE TABLE dbo.FactOnlineSales_copy
		WITH (PARTITIONS (2))

	 --in SQL Server <2014
	 --ALTER TABLE dbo.FactOnlineSales_copy SWITCH PARTITION 2 TO dbo.FactOnlineSales_copy_Archive;
	 --TRUNCATE TABLE dbo.FactOnlineSales_copy_Archive;


	 --and remove the first one:
	 ALTER PARTITION FUNCTION pfOnlineSalesDate_copy()
	 MERGE RANGE (@Day);

	  SET @Day = cast((select top 1 [value] from sys.partition_range_values
           where function_id = (select function_id
                   from sys.partition_functions
                   where name = 'pfOnlineSalesDate')
          order by boundary_id asc) as datetime)


 END



 ---------------------------------
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
from sys.partition_range_values
where 
function_id = (Select function_id from sys.partition_functions
				where name = 'pfOnlineSalesDate_copy')