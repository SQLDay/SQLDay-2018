@echo off

:loop

sqlcmd.exe -S.\SQL2017 -dAdventureWorks -E -iC:\Users\Administrator\Desktop\DEMO\AW_Workload_random_waits.sql

goto loop