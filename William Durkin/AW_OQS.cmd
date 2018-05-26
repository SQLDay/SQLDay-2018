@echo off

:loop

sqlcmd.exe -S.\SQL2014 -dAdventureWorks -E -iC:\Users\Administrator\Desktop\DEMO\AW_Workload_random_waits.sql

goto loop