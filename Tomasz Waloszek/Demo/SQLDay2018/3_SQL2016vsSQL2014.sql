/*
-- poni¿szy kod zosta³ wykonany na obydwu bazach w ramach przygotowania œrodowiska

-- Create table
CREATE TABLE [dbo].[lineitem_cci_part](
	[l_shipdate] [date] NULL,
	[l_orderkey] [bigint] NOT NULL,
	[l_discount] [money] NOT NULL,
	[l_extendedprice] [money] NOT NULL,
	[l_suppkey] [int] NOT NULL,
	[l_quantity] [bigint] NOT NULL,
	[l_returnflag] [char](1) NULL,
	[l_partkey] [bigint] NOT NULL,
	[l_linestatus] [char](1) NULL,
	[l_tax] [money] NOT NULL,
	[l_commitdate] [date] NULL,
	[l_receiptdate] [date] NULL,
	[l_shipmode] [char](10) NULL,
	[l_linenumber] [bigint] NOT NULL,
	[l_shipinstruct] [char](25) NULL,
	[l_comment] [varchar](44) NULL
)

GO

-- Create Clustered  Index
create clustered index cci_lineitem_cci_part
	on dbo.lineitem_cci_part ( [l_shipdate] )
		WITH (DATA_COMPRESSION = PAGE)
			ON ps_DailyPartScheme( [l_shipdate] ); 

-- Create Clustered Columnstore Index
create clustered columnstore index cci_lineitem_cci_part
	on dbo.lineitem_cci_part
		WITH (DROP_EXISTING = ON)
			ON ps_DailyPartScheme( [l_shipdate] );

-- Load the Data
insert into dbo.lineitem_cci_part (l_shipdate, l_orderkey, l_discount, l_extendedprice, l_suppkey, l_quantity, l_returnflag, l_partkey, l_linestatus, l_tax, l_commitdate, l_receiptdate, l_shipmode, l_linenumber, l_shipinstruct, l_comment)
SELECT [l_shipdate]
      ,[l_orderkey]
      ,[l_discount]
      ,[l_extendedprice]
      ,[l_suppkey]
      ,[l_quantity]
      ,[l_returnflag]
      ,[l_partkey]
      ,[l_linestatus]
      ,[l_tax]
      ,[l_commitdate]
      ,[l_receiptdate]
      ,[l_shipmode]
      ,[l_linenumber]
      ,[l_shipinstruct]
      ,[l_comment]
  FROM [dbo].[lineitem_cci]


alter index cci_lineitem_cci_part
	on dbo.lineitem_cci_part
	reorganize with (COMPRESS_ALL_ROW_GROUPS = ON);
*/

EXEC TPCH2016.dbo.cstore_GetRowGroups @tableName = 'lineitem_cci_part';
EXEC TPCH2014.dbo.cstore_GetRowGroups @tableName = 'lineitem_cci_part';


SET STATISTICS TIME ON; 
-- Enable Execution Plan


--SQL 2014
 select TOP 10 l_discount, SUM(l_discount * 1.123) as TotalDiscount
	from TPCH2014.dbo.lineitem_cci
	where l_shipdate <= '1998-01-01'
	group by l_discount
	order by TotalDiscount desc

--SQL 2016
 select TOP 10 l_discount, SUM(l_discount * 1.123) as TotalDiscount
	from TPCH2016.dbo.lineitem_cci
	where l_shipdate <= '1998-01-01'
	group by l_discount
	order by TotalDiscount desc




--************************

--SQL2014
 select TOP 10 l_discount, SUM(l_discount * 1.123) as TotalDiscount
	from TPCH2014.dbo.lineitem_cci_part
	where l_shipdate <= '1998-01-01'
	group by l_discount
	order by TotalDiscount desc

--SQL2016
 select TOP 10 l_discount, SUM(l_discount * 1.123) as TotalDiscount
	from TPCH2016.dbo.lineitem_cci_part
	where l_shipdate <= '1998-01-01'
	group by l_discount
	order by TotalDiscount desc