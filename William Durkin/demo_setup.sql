-- start OQS collection

exec oqs.start_scheduler



-- check activity log
select * from oqs.activity_log









-- check the settings
select * from oqs.collection_metadata









-- activate collection and change interval to 15 seconds for demo purposes
update oqs.collection_metadata set collection_active = 1, collection_interval = 15

waitfor delay '00:00:15'
select * from oqs.activity_log






-- register AdventureWorks for collection

insert into oqs.monitored_databases
select 'AdventureWorks'

waitfor delay '00:00:15'
select * from oqs.activity_log










-- Hide those "noisy" queries
declare @queryid int = 28
exec oqs.exclude_query_from_dashboard @queryid