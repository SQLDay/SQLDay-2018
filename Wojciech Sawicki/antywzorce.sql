/*
Opis:
Przyk³ady przygotowane na sesjê SQLDay2018
Antywzorce czyli ciemna strona mocy.
Autor:
Wojciech Sawicki

Wszelkie uwagi mile widziane.
Zw³aszcza krytyczne.
*/

--ZAPYTANIA SQL
--Postanowi³em skorzystaæ ze znanego przyk³adu.

--DOMYŒL SIÊ - W literaturze znane jako IMPLICIT
--U¿ycie domyœlnych wartoœci lub zachowania MSSQL.


--Podzbiór: Semantyka oparta na aktualnym projekcie tabeli.

--1. Zobacz co masz i daj wszystko
SELECT *
FROM tabela;

--Ten sam mechanizm

INSERT INTO tabela VALUES (1,2,3);

--Ca³kiem dopuszczalne jako wyra¿enie ad hoc.














 






































--Nadal DOMYŒL SIÊ, problem pojawi siê gdy dodamy drug¹ tabelê
SELECT col1
	,col2
	,co3
FROM tabela;






--Nadal DOMYŒL SIÊ, czego on musi siê tu domyœlaæ?
SELECT t.col1
	,t.col2
	,t.col3
FROM tabela t;






















































--Jak w selekcie nie ma to trudno, ale jak nie ma przy zak³adaniu, to gorzej.
SELECT t.col1
	,t.col2
	,t.col3
FROM schema_tabeli.tabela t;




--Mój ulubiony przyk³ad tego typu
--Tu ju¿ nie jest takie oczywiste, ale ci¹gle jest to przyk³ad IMPLICIT
DECLARE @a TABLE (
	wartosc MONEY
	,kiedy DATE
	,inna_kolumna_opisowa VARCHAR(255)
	,suma_narastajaco MONEY
	);

INSERT INTO @a (
	wartosc
	,kiedy
	,inna_kolumna_opisowa
	)
VALUES 
     (	1	,'20000101'	,'raz'	)
	,(	3	,'20010101'	,'dwa'	)
	,(	17	,'20180101'	,'siedem'	)
	,(	100	,'20181001'	,'osiem'	)
	,(	5	,'20100101'	,'trzy'	)
	,(	7	,'20110101'	,'cztery'	)
	,(	11	,'20150101'	,'piêæ'	)
	,(	13	,'20170101'	,'szeœæ'		);



SELECT a.wartosc
	,a.kiedy
	,a.inna_kolumna_opisowa
FROM @a a;

DECLARE @s MONEY;


SET @s = 0;

WITH cte
AS (
	SELECT TOP 9223372036854775807 a.suma_narastajaco  --Proszê zwróciæ uwagê NIE TOP 100 PERCENT bo zignoruje
		,a.wartosc
	FROM @a a
	ORDER BY a.kiedy ASC
	)
UPDATE cte
SET @s = suma_narastajaco = wartosc + @s;

/*
Tu jest niejawne za³o¿enie, ¿e update jest w tej samej kolejnoœci co 
select. 
Ale
https://blogs.msdn.microsoft.com/sqltips/2005/07/20/ordering-guarantees-in-sql-server/
*/




SELECT a.wartosc
	,a.kiedy
	,a.inna_kolumna_opisowa
	,suma_narastajaco
FROM @a a
ORDER BY a.kiedy ASC;
GO










/*
Te¿ siê domyœlamy.
*/

CREATE TABLE #temp
(
kwota money,
typ nvarchar(15)
)

select * from [WideWorldImporters].[Application].[People] People
inner join #temp t on t.typ=People.LogonName


/*
Jak nasze domys³y s¹ nies³uszne to co dostajemy?
Msg 468, Level 16, State 9, Line ...
Cannot resolve the collation conflict between....


No jak to, przecie¿ u mnie dzia³a.
*/



/*
Solucja - przepisaæ kod.
Lecz có¿ czyniæ, aby nie wraca³?
*/





-----------------------------------------------------------------------------------------------------------------
--DO DOMU
-----------------------------------------------------------------------------------------------------------------

/*
Inne antywzorce dotycz¹ce zapytañ.
1. Traktowanie NULL jako wartoœci
*/

Declare @a table(id int,
opis varchar(255)
);
insert into @a(id,opis)
values (1,'raz'),(3,'dwa'),
(17,null),(100,'raz'),
(5,'trzy'),(7,'cztery'),
(11,'piêæ'),(13,'szeœæ');

select * from @a where opis='raz';
select * from @a where opis<>'raz';


/*
Solucja:
Gdzie tylko mo¿na okreœlaæ kolumnê jako not null (optymalizator te¿ to zobaczy i mo¿e wykorzysta).
Uzupe³niaæ warunki ... and opis is not null 
NIE! isnull(id,0)<>0 

*/










--3. Goldberg Machine

--Losowa kolejnoœæ - unecessary
select top 1 * from master.dbo.spt_values s where  s.type='P'
order by newid(); 
--Trzeba przeskanowaæ ca³¹ tabelê.
--Takie te¿ lubiê :)



-- https://pl.wikipedia.org/wiki/Maszyna_Rube_Goldberga

/*
Maszyna Rube'a Goldberga – przesadnie rozbudowane urz¹dzenie lub seria mechanizmów
 dzia³aj¹cych na zasadzie domina, które w z³o¿ony sposób wykonuj¹ bardzo proste czynnoœci. 
 Nazwa pochodzi od amerykañskiego rysownika i wynalazcy Rube'a Goldberga, 
 który na swoich ilustracjach przedstawia³ pomys³owo powi¹zane ze sob¹ 
 urz¹dzenia i sprzêty gospodarstwa domowego. 
 Wed³ug niego mia³y one byæ symbolem ludzkiej zdolnoœci do osi¹gania 
 maksymalnego wysi³ku i minimalnego efektu. 
 Uwa¿a³ bowiem, ¿e wiêkszoœæ ludzi woli osi¹gaæ swój cel w trudniejszy sposób, 
 ni¿ d¹¿yæ do niego szybciej i proœciej.
*/
--Najpierw zrób a potem siê pomyœli - niepotrzebne informacje, zbêdne dzia³ania 
-- bardzo wdziêczne do optymalizacji.
declare @a int;
select @a=count() from schema_tabeli.tabela t;
if @a>0
begin
print 'S¹ wiersze trzeba zrobiæ update'
end
else
begin
print 'Nie ma trzeba zrobiæ insert'
end;




--Najpierw zrób a potem siê pomyœli - niepotrzebne dzia³ania
--
IF OBJECT_ID('SortTable_temp') IS NOT NULL
  DROP TABLE SortTable_temp
GO
SELECT  s.name , s.id
into SortTable_temp
  FROM sys.sysobjects s
where id>0
 ORDER BY name;
--Tu akurat m¹dry jest i wie ale my siê zastanawiamy.

















--A mo¿e by tak daæ mu wiêcej bo siê leni
select t.kolumna
from schema.tabela t
where
convert(varchar(4),year(t.kolumna_typu_data_czas))>'2015';












--I wiele wiele innych
--Ale antywzorce dotycz¹ nie tylko pisania zapytañ.


-----------------------------------------------------------------------------------------------------------------
--DO DOMU - KONIEC
-----------------------------------------------------------------------------------------------------------------

--Projekt logiczny
--Lista przecinkowa jako realizacja relacji wiele do wielu.
--Zwykle gdy jest z³a relacja.
CREATE TABLE dbo.towar (
	towar_id INT PRIMARY KEY
	,towar_nazwa VARCHAR(255)
	,dostawca_id INT --klucz obcy do tabeli dostawca
	)

CREATE TABLE dbo.dostawca (
	dostawca_id INT PRIMARY KEY
	,dostawca_nazwa VARCHAR(255)
	)

ALTER TABLE [dbo].[towar]
	WITH CHECK ADD CONSTRAINT [FK_dostawca#towar#dostawca] FOREIGN KEY ([dostawca_id]) REFERENCES [dbo].[dostawca]([dostawca_id]) ON
DELETE CASCADE
GO
--Prawie dobry projekt, towar ma dostawcê, hmm jednego(?)



--Dobrze dzia³a jak s¹ samy monopoliœci ale gdy ju¿ mamy dwóch to....
--Poprawiamy projekt, pozwalamy wpisaæ wiêcej ni¿ jednego do pola dostawca_id



CREATE TABLE dbo.towar (
	towar_id INT PRIMARY KEY
	,towar_nazwa VARCHAR(255)
	,dostawca_id VARCHAR(100) --klucz obcy ? ju¿ nie
	);

UPDATE dbo.towar
SET dostawca_id = '1,3,5,7,11,....'
WHERE towar_id = ?;

/*
Zasada nieco bardziej ogólna.
Do przechowywania z³o¿onych struktur s³u¿¹ xml i jason, ale jeden, w jednym polu.



Solucja:
Klasyczna relacja wiele do wielu i tabela.


*/




/*
https://www.slideshare.net/billkarwin/sql-antipatterns-strike-back/32-Polymorphic_Associations_Of_course_some
*/
--Polimorfia -polymorphic association.

create table dbo.towar(towar_id int primary key,
towar_nazwa varchar(255)
)

create table dbo.usluga(usluga_id int primary key,
usluga_nazwa varchar(255)
)

create table dbo.zakup(zakup_id int primary key,
--... --ró¿ne cechy zakupu
towar_lub_usluga_id int, --O kluczu obcym tak¿e mo¿na zapomnieæ
rodzaj varchar(10) check (rodzaj='towar' or rodzaj='usluga')
)
/*
W polu towar_lub_usluga_id przechowujemy klucz z tabeli towar lub tabeli us³uga.
*/



/*Solucja
1. Dwie kolumny
*/
create table dbo.zakup(zakup_id int primary key,
--... --ró¿ne cechy zakupu
towar_id int,
usluga_id int,
--Tylko jedna nie mo¿e byæ null


/*
2. Odwróciæ relacjê.
*/


create table dbo.zakup_towar(zakup_id int primary key,
towar_id int )

create table dbo.zakup_usluga(zakup_id int primary key,
usluga_id int )



/*
3. Tabela nadrzêdna.
*/

create table dbo.produkt(produkt_id int primary key,
...
)

create table dbo.usluga(usluga_id int primary key,
usluga_nazwa varchar(255),
produkt_id int --Tu ju¿ klucz obcy

)

create table dbo.towar(towar_id int primary key,
towar_nazwa varchar(255),
produkt_id int --Tu ju¿ klucz obcy
)

create table dbo.zakup(zakup_id int primary key,
--... --ró¿ne cechy zakupu
produkt_id int, --Tu te¿ klucz obcy







































/*
Jeden o wielu nazwach.

--God Table(?)
--Gold Hammer
--Swiss Army Knife


Próba rozwi¹zania wszystkich problemów. 
1. Przechowania wszystkich danych w jednej tabeli.
2. Zwrócenia jednym zapytaniem.
3. Oczyszczenia wszystkich danych wejœciowych z wszystkich Ÿróde³ w jednym zapytaniu.



Tu nie ma przyk³adu, by³by nieczytelny.
Jednak zakres tego antywzorca jest bardzo szeroki.



*/








--Fizyczna realizacja

--Z³e typy danych - tutaj z³ym jest zaufanie do ORM 
CREATE TABLE [dbo].[Budzet](
	[discriminator] [varchar](31) NOT NULL,
	[id] [bigint] IDENTITY(1,1) NOT NULL,
	[uuid] [varchar](255) NULL, -- tu jest guid
	[kwota] [float] NULL,
	[oczekujace] [float] NULL,
	[wykorzystano] [float] NULL,
	[zaplanowano] [float] NULL,
	[rok] [int] NULL,
...
) 
/*

VARCHAR (1) lub VARCHAR(2)
Podajê za 
https://blogs.msdn.microsoft.com/arvindsh/2013/04/03/teched-india-2013-t-sql-horrors-slides/
Arvind Shyamsundar T-SQL Horrors: Now not to code


https://msdn.microsoft.com/en-us/library/Dd193263(v=VS.100).aspx




*/
IF EXISTS (
		SELECT *
		FROM sys.objects
		WHERE object_id = OBJECT_ID(N'[dbo].[tabela_varchar]')
			AND type IN (N'U')
		)
	DROP TABLE dbo.tabela_varchar;
GO

IF EXISTS (
		SELECT *
		FROM sys.objects
		WHERE object_id = OBJECT_ID(N'[dbo].[tabela_char]')
			AND type IN (N'U')
		)
	DROP TABLE dbo.tabela_char;
GO

CREATE TABLE dbo.tabela_varchar (Varchar1Col VARCHAR(1));
GO

SET NOCOUNT ON

INSERT INTO tabela_varchar (Varchar1Col)
SELECT TOP 100000 'a'
FROM master.dbo.spt_values a
CROSS JOIN master.dbo.spt_values b;
GO

CREATE TABLE tabela_char (Char1Col CHAR(1));
GO

SET NOCOUNT ON;

INSERT INTO tabela_char (Char1Col)
SELECT TOP 100000 'a'
FROM master.dbo.spt_values a
CROSS JOIN master.dbo.spt_values b;
GO

-- VARCHAR wiêkszy
SELECT avg_record_size_in_bytes
	--,*
FROM sys.dm_db_index_physical_stats(db_id(), object_id('tabela_varchar'), NULL, NULL, 'detailed')

SELECT avg_record_size_in_bytes
	--,*
FROM sys.dm_db_index_physical_stats(db_id(), object_id('tabela_char'), NULL, NULL, 'detailed')
GO






/*Solucja
CHAR(1)
NCHAR(2)
U¿ywaæ zmiennoprzecinkowych jedynie do przechowywania wyników pomiarów w aplikacjach naukowych.
*/

--Ci¹gle nadmierne zaufanie - brak regu³ integralnoœci.
--Tu przyk³ad jest na koñcu.



/*------------------------------------------------------------------------------------------

Jedna klasa, antywzorców bezpieczeñstwa, jest groŸna.
Security Loopholes


*/

--SQL Injection
--https://blogs.msdn.microsoft.com/mike/2008/10/15/how-to-configure-urlscan-3-0-to-mitigate-sql-injection-attacks/
--SQL Injection Attacks and Defense, Second Edition 2nd Edition Justin Clarke ISBN-13: 978-1597499637




--Brak polityki hase³.
--Nadmierne uprawnienia.
--Has³a jawnie w bazie.
 


 /*
 Heurystyka du¿o wierszy i du¿o jedynek.
 */
 
 select loginname
,IS_SRVROLEMEMBER('sysadmin',loginname) sysadmin
,IS_SRVROLEMEMBER('serveradmin',loginname) serveradmin
,IS_SRVROLEMEMBER('dbcreator',loginname) dbcreator
,IS_SRVROLEMEMBER('setupadmin',loginname) setupadmin
,IS_SRVROLEMEMBER('bulkadmin',loginname) bulkadmin
,IS_SRVROLEMEMBER('securityadmin',loginname) securityadmin
--diskadmin	Applies to: SQL Server 2012 (11.x) through SQL Server 2017.
,IS_SRVROLEMEMBER('public',loginname) 'public'
,IS_SRVROLEMEMBER('processadmin',loginname) processadmin
 from sys.syslogins












































-----------------------------------------------------------------------------------------------------------------
--DO DOMU 2
-----------------------------------------------------------------------------------------------------------------



--Czasem jak zapytanie jest bardzo z³o¿one to gdzieœ warunek z³¹czenia daje za du¿o 
--i co wtedy: nie nie poprawiamy zapytania dajemy distinct - te¿ dzia³a
--W skrajnej postaci
--select distinct  from cross join
--Czasem distinct wskazuje na https://pl.wikipedia.org/wiki/Voodoo_programming
select distinct t1.number from master.dbo.spt_values t1
,master.dbo.spt_values t2
where t1.type='P' and t2.type='P';
--W ka¿dym b¹dŸ razie pachnie nie za ³adnie.



--Czemu sortujemy w œrodku widok?
--To jest zadanie zapytania u¿ywj¹cego widoku.
--Proszê zwróciæ uwagê, na to co siê stanie, jak zamienimy 9999999
--na 100 percent
go
create view dbo.sortowany_widok as
select top 9999999 t.name from sys.all_objects t order by t.name desc;


--Wraca zbêdne dzia³anie a mo¿e to jest implicite?
go
declare @kolejny_numerek int;
declare cursor_z_numerkami cursor for select  t1.number from master.dbo.spt_values t1;
--Ok to mo¿e byæ przydatne
OPEN cursor_z_numerkami ; 

FETCH NEXT FROM cursor_z_numerkami
INTO @kolejny_numerek  ;

WHILE @@FETCH_STATUS = 0  
BEGIN  

EXEC dbo.jakas_procedura @arg_numerek=@kolejny_numerek;

FETCH NEXT FROM cursor_z_numerkami
INTO @kolejny_numerek  ;
END;


--Tylko czemu budujemy dwukierunkow¹ listê?

-----------------------------------------------------------------------------------------------------------------
--DO DOMU 2 KONIEC
-----------------------------------------------------------------------------------------------------------------





-----------------------------------------------------------------------------------------------------------------
--Jak wykryæ Antywrzorzec?
--Panowie Khumin Poonyanuch and Twittie Senivongse, “SQL Antipatterns Detection and Database Refactoring Process”,2017 18th IEEE/ACIS
--International Conference on Software Engineering, Artificial Intelligence, Networking, and Parallel/Distributed Computing,
--Ishikawa, Japan,2017
--Zaproponowali poszukiwania heurystyk w bazie. Bardzo dobry pomys³. Oparli siê na definicjach Karwina (Sql Antipattern...)[1]




-----------------------------------------------------------------------------------------------------------------
/*
Clone Table or Columns
CREATE TABLE Bugs_2008 ( . . . );
CREATE TABLE Bugs_2009 ( . . . );
CREATE TABLE Bugs_2010 ( . . . );
*/
/*
Clone Table or Columns PREP -¿eby mieæ muszê za³o¿yæ
*/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

IF NOT EXISTS (
		SELECT *
		FROM sys.objects
		WHERE object_id = OBJECT_ID(N'[dbo].[dane_z_roku_2005]')
			AND type IN (N'U')
		)
BEGIN
	CREATE TABLE [dbo].[dane_z_roku_2005] (
		[id] [int] NOT NULL
		,[nazwa] [varchar](255) NULL
		,col1 INT --Create Multiple Columns
		,col2 INT
		,col3 INT
		,col4 INT
		,PRIMARY KEY CLUSTERED ([id] ASC) WITH (
			PAD_INDEX = OFF
			,STATISTICS_NORECOMPUTE = OFF
			,IGNORE_DUP_KEY = OFF
			,ALLOW_ROW_LOCKS = ON
			,ALLOW_PAGE_LOCKS = ON
			) ON [PRIMARY]
		) ON [PRIMARY]
END;
GO

DECLARE @i INT;
DECLARE @sql NVARCHAR(4000)

SET @i = 10;

WHILE @i > 0
BEGIN
	SET @sql = 'IF NOT EXISTS (
		SELECT *
		FROM sys.objects
		WHERE object_id = OBJECT_ID(N''[dbo].[dane_z_roku_'+ convert(VARCHAR, 2005 + @i) + ']'')
			AND type IN (N''U'')
		)
	SELECT * INTO dane_z_roku_' + convert(VARCHAR, 2005 + @i) + ' from [dbo].[dane_z_roku_2005]'

	EXEC sp_executesql @sql

	SELECT @i = @i - 1
END;
/*
Clone Table or Columns PREP END
*/

SELECT ROW_NUMBER() OVER( ORDER BY COUNT(C.COLUMN_NAME ) ) AS _RK, 
T.TABLE_NAME , COUNT(C.COLUMN_NAME ) AS CNT_COL
FROM INFORMATION_SCHEMA.TABLES T
INNER JOIN INFORMATION_SCHEMA.COLUMNS C
ON ( T.TABLE_NAME = C.TABLE_NAME )
WHERE T.TABLE_TYPE = 'BASE TABLE'
GROUP BY T.TABLE_NAME

--Szukamy tabel o identycznej liczbie kolumn i podobnej nazwie

/*Solucja
Partycjonowanie - porz¹dne, z indeksami odpowiednimi i statystykami filtrowanymi
*/

/*
Create Multiple Columns
create table schema.t (
id int,
kol1 varchar(255),
kol2 varchar(255),
kol3 varchar(255),
..
koln varchar(255)
*/
SELECT a.TABLE_NAME , a.COLUMN_NAME ,a.DATA_TYPE , a.IS_NULLABLE
, a.CHARACTER_MAXIMUM_LENGTH , a.CHARACTER_OCTET_LENGTH,
a.NUMERIC_PRECISION, a.NUMERIC_SCALE
from INFORMATION_SCHEMA.COLUMNS a
INNER JOIN
( SELECT TABLE_NAME , LEFT(COLUMN_NAME,3) AS PREFIX_COL
, DATA_TYPE , IS_NULLABLE
, CHARACTER_MAXIMUM_LENGTH , CHARACTER_OCTET_LENGTH,
NUMERIC_PRECISION, NUMERIC_SCALE
FROM INFORMATION_SCHEMA.COLUMNS
GROUP BY TABLE_NAME , LEFT(COLUMN_NAME,3) , DATA_TYPE ,
IS_NULLABLE
, CHARACTER_MAXIMUM_LENGTH , CHARACTER_OCTET_LENGTH,
NUMERIC_PRECISION, NUMERIC_SCALE
HAVING COUNT(*) > 1 ) c
ON ( a.TABLE_NAME = c.TABLE_NAME
and LEFT(a.COLUMN_NAME,3) = LEFT(c.PREFIX_COL,3) )
WHERE ASCII( RIGHT(COLUMN_NAME,1) ) BETWEEN 48 AND 57

--Szukamy kolumn o nazwie zakoñczonej cyfr¹.

/*Solucja
Wiêcej tabel.
*/

/*
Leave Out the Constraints
Baza bez kluczy obcych jest szybsza i prostsza
*/

SELECT T.TABLE_NAME
	,T.ConstraintType
	,c.ConstraintName
	,CASE 
		WHEN c.ConstraintName IS NOT NULL
			THEN 1
		ELSE 0
		END AS IS_NOT_EXISTS
FROM (
	SELECT T1.TABLE_NAME
		,cons.ConstraintType
	FROM INFORMATION_SCHEMA.TABLES T1
		,(
			SELECT 'DEFAULT_CONSTRAINT' AS ConstraintType
			
			UNION ALL
			
			SELECT 'FOREIGN_KEY_CONSTRAINT' AS ConstraintType
			
			UNION ALL
			
			SELECT 'PRIMARY_KEY_CONSTRAINT' AS ConstraintType
			
			UNION ALL
			
			SELECT 'UNIQUE_CONSTRAINT' AS ConstraintType
			
			UNION ALL
			
			SELECT 'CHECK_CONSTRAINT' AS ConstraintType
			) AS cons
	) T
LEFT OUTER JOIN (
	SELECT OBJECT_NAME(object_id) AS ConstraintName
		,SCHEMA_NAME(schema_id) AS SchemaName
		,OBJECT_NAME(parent_object_id) AS TableName
		,type_desc AS ConstraintType
	FROM sys.objects
	WHERE type_desc LIKE '%CONSTRAINT'
	) c ON (
		T.TABLE_NAME = c.TableName
		AND T.ConstraintType = c.ConstraintType
		)


/*Solucja
Zero zaufania. A baza musi byæ jak ¿ona Cezara.

*/




/*
Always Depend on One’s Parent
Tabela zawiera kolumnê wskazuj¹c¹ na inny wiersz tej tabeli - zwykle parent_id
*/


SELECT P.TABLE_NAME
	,P.COLUMN_NAME AS PARENT_COLUMN_NAME
	,C.COLUMN_NAME AS CHILD_COLUMN_NAME
FROM (
	SELECT T.TABLE_NAME
		,COLUMN_NAME
		,DATA_TYPE
		,CHARACTER_MAXIMUM_LENGTH
		,CHARACTER_OCTET_LENGTH
		,NUMERIC_PRECISION
		,NUMERIC_SCALE
	FROM INFORMATION_SCHEMA.TABLES T
	INNER JOIN INFORMATION_SCHEMA.COLUMNS C ON (T.TABLE_NAME = C.TABLE_NAME)
	WHERE T.TABLE_TYPE = 'BASE TABLE'
	--Tu trzeba do³o¿yæ swojej wyobraŸni
		--AND (
		--	C.COLUMN_NAME LIKE '%PARENT%'			OR C.COLUMN_NAME LIKE '%UPPER%'			OR C.COLUMN_NAME LIKE '%CHILD%'
		--	)
	) P
LEFT OUTER JOIN INFORMATION_SCHEMA.COLUMNS C ON (
		P.TABLE_NAME = C.TABLE_NAME
		AND P.DATA_TYPE = C.DATA_TYPE
		AND ISNULL(P.CHARACTER_MAXIMUM_LENGTH, 0) = ISNULL(C.CHARACTER_MAXIMUM_LENGTH, 0)
		AND ISNULL(P.CHARACTER_OCTET_LENGTH, 0) = ISNULL(C.CHARACTER_OCTET_LENGTH, 0)
		AND ISNULL(P.NUMERIC_PRECISION, 0) = ISNULL(C.NUMERIC_PRECISION, 0)
		AND ISNULL(P.NUMERIC_SCALE, 0) = ISNULL(C.NUMERIC_SCALE, 0)
		)
WHERE P.COLUMN_NAME <> C.COLUMN_NAME
ORDER BY P.TABLE_NAME
	,P.COLUMN_NAME


/*
One Size Fits All
CREATE TABLE BugsProducts
( id BIGINT IDENTITY(1,1) PRIMARY KEY,
bug_id BIGINT,
product_id BIGINT, -- . . .);




Kolumny nie unikalne.

*/

SELECT DISTINCT TCS.SCHEMA_NAME
	,TCS.TABLE_NAME
	,C.COLUMN_NAME
FROM (
	SELECT SCHEMA_NAME(SCHEMA_ID) SCHEMA_NAME
		,OBJECT_NAME(PARENT_OBJECT_ID) AS TABLE_NAME
		,TYPE_DESC AS CONSTRAINT_TYPE
	FROM sys.objects
	WHERE TYPE_DESC IN (
			'PRIMARY_KEY_CONSTRAINT'
			,'UNIQUE_CONSTRAINT'
			)
	) TCS
LEFT OUTER JOIN INFORMATION_SCHEMA.CONSTRAINT_COLUMN_USAGE CS ON (TCS.TABLE_NAME = CS.TABLE_NAME)
LEFT OUTER JOIN INFORMATION_SCHEMA.COLUMNS C ON (TCS.TABLE_NAME = C.TABLE_NAME)
WHERE CS.COLUMN_NAME <> C.COLUMN_NAME
	AND C.COLUMN_NAME NOT IN (
		SELECT COLUMN_NAME
		FROM INFORMATION_SCHEMA.CONSTRAINT_COLUMN_USAGE C2
		WHERE C2.TABLE_NAME = TCS.TABLE_NAME
		)
	AND DATA_TYPE <> 'datetime'
	AND DATA_TYPE <> 'datetime2'



/*God Table
Zafascynowany pomys³em dodam swoje.
Najwiêksze obiekty czyli take co maj¹ najwiêcej kolumn. 
*/
SELECT TOP 10 max(colorder) ilosc_wierszy
	,object_name(id) obiekt
FROM sys.syscolumns c
GROUP BY id
ORDER BY ilosc_wierszy DESC;

/*
Swiss Army Knife
Szukam nawiêkszych procedur.
-- 6212725 tyle widzia³em w polu rozmiar.
*/

SELECT TOP 10
       o.name AS Object_Name,
       o.type_desc,
	   len( m.definition) rozmiar,
	   len(m.definition) - len(replace(m.definition,char(13),'')) wiersze
  FROM sys.sql_modules m
       INNER JOIN
       sys.objects o
         ON m.object_id = o.object_id
 ORDER BY rozmiar DESC;


  /*
  Index Shotgun

  Brak indeksów.
  Za du¿o indeksów - zbêdne lub powtarzaj¹ce siê.
  Zapytania które nie mog¹ skorzystaæ z indeksów - SARG.


  https://www.sqlsaturday.com/SessionDownload.aspx?suid=5445
  
  
  
  Znalaz³em fajny algorytm:

 while(query performance problem){
	    create new index 
  }


  Tu do razu solucja bo trudna.
  Zobacz co wolno dzia³a, jest czêsto u¿ywane lub blokuje.
  Przenalizuj plany czy w zapytaniach pomog³y by indeksy.
  SprawdŸ po do³o¿eniu czy pomog³o i czy nie popsu³o.
  

  Cytat:
  Impress your boss.
  The new index gave a 27% performance improvement.
  https://www.slideshare.net/billkarwin/sql-antipatterns-strike-back/107-Indexes_are_Magical_Solution_MENTOR



  */


  --Brakuj¹ce 
 -- Za http://www.sqlservercentral.com/scripts/Indexes/143678/
 -- Ale wiêcej takich jest

 /*
 use [WideWorldImporters]
 GO
 select t.[ColdRoomTemperatureID],t.[Temperature] from [Warehouse].[ColdRoomTemperatures_Archive] t
where t.Temperature<3;
use [sqlday2018]
GO

*/
SELECT  user_seeks * avg_total_user_cost * ( avg_user_impact * 0.01 ) AS [index_advantage] ,
        migs.last_user_seek ,
        mid.[statement] AS [Database.Schema.Table] ,
        mid.equality_columns ,
        mid.inequality_columns ,
        mid.included_columns ,
        migs.unique_compiles ,
        migs.user_seeks ,
        migs.avg_total_user_cost ,
        migs.avg_user_impact ,
        N'CREATE NONCLUSTERED INDEX [IX_' + SUBSTRING(mid.statement,
                                                      CHARINDEX('.',
                                                              mid.statement,
                                                              CHARINDEX('.',
                                                              mid.statement)
                                                              + 1) + 2,
                                                      LEN(mid.statement) - 3
                                                      - CHARINDEX('.',
                                                              mid.statement,
                                                              CHARINDEX('.',
                                                              mid.statement)
                                                              + 1) + 1) + '_'
        + REPLACE(REPLACE(REPLACE(CASE WHEN mid.equality_columns IS NOT NULL
                                            AND mid.inequality_columns IS NOT NULL
                                            AND mid.included_columns IS NOT NULL
                                       THEN mid.equality_columns + '_'
                                            + mid.inequality_columns
                                            + '_Includes'
                                       WHEN mid.equality_columns IS NOT NULL
                                            AND mid.inequality_columns IS NOT NULL
                                            AND mid.included_columns IS NULL
                                       THEN mid.equality_columns + '_'
                                            + mid.inequality_columns
                                       WHEN mid.equality_columns IS NOT NULL
                                            AND mid.inequality_columns IS NULL
                                            AND mid.included_columns IS NOT NULL
                                       THEN mid.equality_columns + '_Includes'
                                       WHEN mid.equality_columns IS NOT NULL
                                            AND mid.inequality_columns IS NULL
                                            AND mid.included_columns IS NULL
                                       THEN mid.equality_columns
                                       WHEN mid.equality_columns IS NULL
                                            AND mid.inequality_columns IS NOT NULL
                                            AND mid.included_columns IS NOT NULL
                                       THEN mid.inequality_columns
                                            + '_Includes'
                                       WHEN mid.equality_columns IS NULL
                                            AND mid.inequality_columns IS NOT NULL
                                            AND mid.included_columns IS NULL
                                       THEN mid.inequality_columns
                                  END, ', ', '_'), ']', ''), '[', '') + '] '
        + N'ON ' + mid.[statement] + N' (' + ISNULL(mid.equality_columns, N'')
        + CASE WHEN mid.equality_columns IS NULL
               THEN ISNULL(mid.inequality_columns, N'')
               ELSE ISNULL(', ' + mid.inequality_columns, N'')
          END + N') ' + ISNULL(N'INCLUDE (' + mid.included_columns + N');',
                               ';') AS CreateStatement
FROM    sys.dm_db_missing_index_group_stats AS migs WITH ( NOLOCK )
        INNER JOIN sys.dm_db_missing_index_groups AS mig WITH ( NOLOCK ) ON migs.group_handle = mig.index_group_handle
        INNER JOIN sys.dm_db_missing_index_details AS mid WITH ( NOLOCK ) ON mig.index_handle = mid.index_handle
--WHERE   mid.database_id = DB_ID()
ORDER BY index_advantage DESC;




--Kandydaci do skasowania
--https://github.com/MichelleUfford/sql-scripts/blob/master/indexes/unused.sql


SELECT sqlserver_start_time FROM sys.dm_os_sys_info;

DECLARE @dbid INT
    , @dbName VARCHAR(100);

SELECT @dbid = DB_ID()
    , @dbName = DB_NAME();

WITH partitionCTE (object_id, index_id, row_count, partition_count) 
AS
(
    SELECT [object_id]
        , index_id
        , SUM([rows]) AS 'row_count'
        , COUNT(partition_id) AS 'partition_count'
    FROM sys.partitions
    GROUP BY [object_id]
        , index_id
)

SELECT OBJECT_NAME(i.[object_id]) AS objectName
        , i.name
        , CASE 
            WHEN i.is_unique = 1 
                THEN 'UNIQUE ' 
            ELSE '' 
          END + i.type_desc AS 'indexType'
        , ddius.user_seeks
        , ddius.user_scans
        , ddius.user_lookups
        , ddius.user_updates
        , cte.row_count
        , CASE WHEN partition_count > 1 THEN 'yes' 
            ELSE 'no' END AS 'partitioned?'
        , CASE 
            WHEN i.type = 2 AND i.is_unique = 0
                THEN 'Drop Index ' + i.name 
                    + ' On ' + @dbName 
                    + '.dbo.' + OBJECT_NAME(ddius.[object_id]) + ';'
            WHEN i.type = 2 AND i.is_unique = 1
                THEN 'Alter Table ' + @dbName 
                    + '.dbo.' + OBJECT_NAME(ddius.[object_ID]) 
                    + ' Drop Constraint ' + i.name + ';'
            ELSE '' 
          END AS 'SQL_DropStatement'
FROM sys.indexes                                                        AS i
INNER JOIN sys.dm_db_index_usage_stats                                  AS ddius
    ON i.object_id = ddius.object_id
        AND i.index_id = ddius.index_id
INNER JOIN partitionCTE                                                 AS cte
    ON i.object_id = cte.object_id
        AND i.index_id = cte.index_id
WHERE ddius.database_id = @dbid
    AND i.type = 2                                                      ----> retrieve nonclustered indexes only
    AND i.is_unique = 0                                                 ----> ignore unique indexes, we'll assume they're serving a necessary business use
    --AND (ddius.user_seeks + ddius.user_scans + ddius.user_lookups) = 0  ----> starting point, update this value as needed; 0 retrieves completely unused indexes
ORDER BY user_updates DESC;

/*
Powielone to jest trochê wiêcej kodu 
https://www.sqlskills.com/blogs/kimberly/removing-duplicate-indexes/
*/



/*
SQL injection

Szukam w kodzie exec( lub sp_executesql 
te ostatnie to podejrzane s¹ jak nie maj¹ parametrów.
*/



SELECT o.name AS Object_Name,
       o.type_desc,
	   m.definition
  FROM sys.sql_modules m
       INNER JOIN
       sys.objects o
        ON m.object_id = o.object_id
 where replace(m.definition,' ','') like '%exec(%';
 --Tu zak³adam ¿e nie ma innych bia³ych znaków miêdzy exec a (, ale je¿eli mamy podejrzenia to 
 --po prostu dok³adamy replace.

 SELECT o.name AS Object_Name,
       o.type_desc,
	   m.definition
  FROM sys.sql_modules m
       INNER JOIN
       sys.objects o
        ON m.object_id = o.object_id
 where m.definition like '%sp_executesql%';

 --Tu szukaæ nale¿y sp_executesql z jednym parametrem
