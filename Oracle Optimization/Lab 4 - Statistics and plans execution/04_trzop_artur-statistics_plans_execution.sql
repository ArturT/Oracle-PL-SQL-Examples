-- ##################################################
--
--	Bazy danych 
-- 	2011 Copyright (c) Artur Trzop 12K2
--	Script v. 4.0.0
--
-- ##################################################

-- w³¹czamy opcje wyœwietlania komunikatów przy pomocy DBMS_OUTPUT.PUT_LINE();
set serveroutput on;
--set feedback on;
-- w³¹cz wyœwietlanie czasu wykonania zapytania
set timing off; 

-- wyk.3, str.46 ustawianie domyslnego sposobu wyswietlania daty
--ALTER SESSION SET NLS_DATE_FORMAT = 'yyyy/mm/dd';
ALTER SESSION SET NLS_DATE_FORMAT = 'yyyy/mm/dd hh24:mi:ss';

--# W³¹czamy polskie znaki w konsoli
--set NLS_LANG=POLISH_POLAND.EE8PC852;

CLEAR SCREEN;
PROMPT ----------------------------------------------;
PROMPT Czyszczenie ekranu;
PROMPT ----------------------------------------------;
PROMPT ;


-- ####################################################################################################

--/*
--### Analiza tabel ###------------------------------------------------------------------------------
ANALYZE TABLE ADRES_POCZTY 
compute statistics
FOR ALL INDEXED COLUMNS;

ANALYZE TABLE OSOBY 
estimate statistics sample 10 percent 
FOR ALL INDEXED COLUMNS;



--### Analiza indexów ###------------------------------------------------------------------------------
ANALYZE INDEX IX_OSO_IMIE_OSO_PLEC 
estimate statistics sample 10 percent;

ANALYZE INDEX IX_OSO_IMIE 
estimate statistics sample 10 percent;

-- Dla p³ci mozemy wszystkie dane przeanalizowac poniewaz plec ma nisk¹ kardynalnosc
ANALYZE INDEX IX_OSO_PLEC 
compute statistics; 

ANALYZE INDEX IX_OSO_DATA_URODZENIA 
estimate statistics sample 10 percent;

ANALYZE INDEX IX_OSO_PLECIMIEDATAURODZ 
estimate statistics sample 10 percent;

--# Analizujemy ca³y index poniewaz tabela ADRES_POCZTY jest mniejsza
ANALYZE INDEX IX_ADR_MIASTO 
compute statistics; 



-- ####################################################################################################

--### Zebranie statystyk przy pomocy DBMS_STATS
DECLARE 
	l_cnt PLS_INTEGER;
BEGIN
	
	DBMS_OUTPUT.PUT_LINE('# 1 #---- Zebranie statystyk przy pomocy DBMS_STATS ---');
	
	--# Jesli tabela statystyk nie istnieje to zostanie utworzona
	SELECT COUNT(*) INTO l_cnt FROM dba_tables WHERE owner = 'TRZOP_ARTUR' AND table_name = 'STATS_TABLE';
	 
	IF l_cnt > 0 THEN
		DBMS_OUTPUT.PUT_LINE('Tabela statystyk juz istnieje.');
	ELSE
		DBMS_OUTPUT.PUT_LINE('Tabela statystyk nie istnieje, wiec ja tworzymy.');
		-- Tworzymy tabele statystyk
		DBMS_STATS.CREATE_STAT_TABLE('Trzop_Artur', 'STATS_TABLE');
	END IF;

	
	--### Analiza tabel ###------------------------------------
	DBMS_STATS.GATHER_TABLE_STATS(
		ownname => 'Trzop_Artur', 
		tabname => 'ADRES_POCZTY', 
		estimate_percent => NULL,
		method_opt => 'FOR ALL COLUMNS SIZE AUTO'
	);
	
	-- mo¿na te¿ u¿yæ estimate_percent=>DBMS_STATS.AUTO_SAMPLE_SIZE
	DBMS_STATS.GATHER_TABLE_STATS(
		ownname => 'Trzop_Artur', 
		tabname => 'OSOBY', 
		estimate_percent => 10,
		method_opt => 'FOR ALL COLUMNS SIZE AUTO'
	);
	
	
	
	--### Analiza indexów ###------------------------------------
	DBMS_STATS.GATHER_INDEX_STATS(
		ownname => 'Trzop_Artur',
		indname => 'IX_OSO_IMIE_OSO_PLEC',
		estimate_percent => 10
	);
	DBMS_STATS.GATHER_INDEX_STATS(
		ownname => 'Trzop_Artur',
		indname => 'IX_OSO_IMIE',
		estimate_percent => 10
	);
	DBMS_STATS.GATHER_INDEX_STATS(
		ownname => 'Trzop_Artur',
		indname => 'IX_OSO_PLEC',
		estimate_percent => DBMS_STATS.AUTO_SAMPLE_SIZE
	);
	DBMS_STATS.GATHER_INDEX_STATS(
		ownname => 'Trzop_Artur',
		indname => 'IX_OSO_DATA_URODZENIA',
		estimate_percent => 10
	);
	DBMS_STATS.GATHER_INDEX_STATS(
		ownname => 'Trzop_Artur',
		indname => 'IX_OSO_PLECIMIEDATAURODZ',
		estimate_percent => 10
	);
	DBMS_STATS.GATHER_INDEX_STATS(
		ownname => 'Trzop_Artur',
		indname => 'IX_ADR_MIASTO',
		estimate_percent => null
	);
	
	
END;
/
--*/



-- ####################################################################################################


--### Wyœwietlenie informacji o zebranych statystykach

/*
	Wynik analizy:
	
	### Pobranie czasu ostatniej analizy tabel i innych informacji #########

	TABLE_NAME     NUM_ROWS     BLOCKS LAST_ANALYZED       SAMPLE_SIZE
	------------ ---------- ---------- ------------------- -----------
	ADRES_POCZTY       2000         13 2011/04/02 17:07:32        2000			<=========== COMPUTE
	OSOBY            997360       9714 2011/04/02 17:07:35       99736 			<=========== ESTIMATE

	2 wierszy zosta³o wybranych.



	### Pobranie analizy kolumn dla tabel ##################################

	TABLE_NAME   COLUMN_NAME          NUM_DISTINCT NUM_BUCKETS HISTOGRAM
	------------ -------------------- ------------ ----------- ---------------
	ADRES_POCZTY ADRK_1_ID                    2000           1 NONE
	ADRES_POCZTY ADR_MIASTO                   1943         254 HEIGHT BALANCED	<=========== Histogram o zrównowa¿onej wysokoœci (Dzieli ca³y zbiór wartoœci kolumny na przedzia³y o tej samej liczbie rekordów.)
	ADRES_POCZTY ADR_KOD_POCZTOWY             2000           1 NONE
	ADRES_POCZTY ADR_ULICA                    1933           1 NONE
	ADRES_POCZTY ADR_NR_LOKALU                1817           1 NONE

	5 wierszy zosta-o wybranych.




	TABLE_NAME   COLUMN_NAME          NUM_DISTINCT NUM_BUCKETS HISTOGRAM
	------------ -------------------- ------------ ----------- ---------------
	OSOBY        OSOK_1_ID                  997360           1 NONE
	OSOBY        OSO_IMIE                      594         254 HEIGHT BALANCED 	<=========== Histogram o zrównowa¿onej wysokoœci
	OSOBY        OSO_NAZWISKO                19877           1 NONE
	OSOBY        OSO_PLEC                        2           2 FREQUENCY		<=========== Histogram czêstotliwoœci (Ka¿da unikatowa wartoœæ kolumny tworzy jeden przedzia³, który zawiera liczbê wyst¹pieñ tej wartoœci)
	OSOBY        OSO_DATA_URODZENIA          30493           1 NONE
	OSOBY        OSO_PESEL                       0           0 NONE
	OSOBY        OSO_NIP                    997360           1 NONE
	OSOBY        OSO_ULICA                   29647           1 NONE
	OSOBY        OSO_NR_LOKALU                9605           1 NONE
	OSOBY        ADR_ID                       2000           1 NONE

	10 wierszy zosta-o wybranych.
	
*/

PROMPT
PROMPT 

-- Ustawiamy szerokosc kolumn
COLUMN TABLE_NAME FORMAT A12;
COLUMN COLUMN_NAME FORMAT A20;

--###@@@
PROMPT ### Pobranie czasu ostatniej analizy tabel i innych informacji #########

SELECT TABLE_NAME, NUM_ROWS, BLOCKS, LAST_ANALYZED, SAMPLE_SIZE FROM USER_TAB_STATISTICS
WHERE TABLE_NAME='ADRES_POCZTY' OR TABLE_NAME='OSOBY';

PROMPT
PROMPT 

--###@@@
PROMPT ### Pobranie analizy kolumn dla tabel ##################################

SELECT TABLE_NAME, COLUMN_NAME, NUM_DISTINCT, NUM_BUCKETS, HISTOGRAM FROM USER_TAB_COL_STATISTICS
WHERE TABLE_NAME='ADRES_POCZTY';

PROMPT
PROMPT 

SELECT TABLE_NAME, COLUMN_NAME, NUM_DISTINCT, NUM_BUCKETS, HISTOGRAM FROM USER_TAB_COL_STATISTICS
WHERE TABLE_NAME='OSOBY';


PROMPT
PROMPT
PROMPT
PROMPT



-- ####################################################################################################


--### Plan wykonania (EXPLAIN PLAN)


COLUMN PLAN FORMAT A60;

--###<<< Dla zapytania: Pobierz kobiety o imieniu na litere S i urodzone po roku 1980 w³¹cznie >>>
PROMPT #####################################################################
PROMPT ### 1. Dla zapytania: Pobierz kobiety o imieniu na litere S i urodzone po roku 1980 w³¹cznie
DELETE FROM PLAN_TABLE;

EXPLAIN PLAN SET statement_id = 'PLAN_1' FOR
SELECT count(*) FROM OSOBY WHERE OSO_PLEC = 'k' AND OSO_IMIE LIKE 'S%' AND OSO_DATA_URODZENIA >= '1980/01/01';

-- Wyœwietl plan
SELECT 
	LPAD(' ',2*(LEVEL-1))||OPERATION||' '||OPTIONS||' '||DECODE(OBJECT_INSTANCE,NULL,OBJECT_NAME,TO_CHAR(OBJECT_INSTANCE)||'*'||OBJECT_NAME) PLAN
FROM PLAN_TABLE
START WITH ID = 0
CONNECT BY PRIOR ID = PARENT_ID AND statement_id = 'PLAN_1'
ORDER BY ID;

--### Podstawowy plan z informacjami o uzytych indexach
SELECT plan_table_output FROM table(dbms_xplan.display(NULL,'PLAN_1','Basic'));
--### Plan typowy - wyswietli to samo co przy uzyciu autotrace traceonly EXPLAIN
SELECT plan_table_output FROM table(dbms_xplan.display(NULL,'PLAN_1','TYPICAL'));

/*
-- Wyœwietlenie planu inn¹ metod¹
SET autotrace traceonly EXPLAIN 
	SELECT count(*) FROM OSOBY WHERE OSO_PLEC = 'k' AND OSO_IMIE LIKE 'S%' AND OSO_DATA_URODZENIA >= '1980/01/01';
SET autotrace off
*/

PROMPT
PROMPT
PROMPT
PROMPT


--###<<< Dla zapytania: Pobierz osoby o imieniu Marek pochodzace z Krakowa. (Zlaczenie tabel) >>>   [@@@@@@ JOIN @@@@@@]
PROMPT #####################################################################
PROMPT ### 2. Dla zapytania: Pobierz osoby o imieniu Marek pochodzace z Krakowa. (Zlaczenie tabel)
DELETE FROM PLAN_TABLE;

EXPLAIN PLAN SET statement_id = 'PLAN_2' FOR
SELECT count(*) FROM OSOBY O LEFT JOIN ADRES_POCZTY A ON O.ADR_ID = A.ADRK_1_ID WHERE O.OSO_IMIE = 'Marek' AND A.ADR_MIASTO = 'Kraków';

-- Wyœwietl plan
SELECT 
	LPAD(' ',2*(LEVEL-1))||OPERATION||' '||OPTIONS||' '||DECODE(OBJECT_INSTANCE,NULL,OBJECT_NAME,TO_CHAR(OBJECT_INSTANCE)||'*'||OBJECT_NAME) PLAN
FROM PLAN_TABLE
START WITH ID = 0
CONNECT BY PRIOR ID = PARENT_ID AND statement_id = 'PLAN_2'
ORDER BY ID;

--### Podstawowy plan z informacjami o uzytych indexach
SELECT plan_table_output FROM table(dbms_xplan.display(NULL,'PLAN_2','Basic'));
--### Plan typowy - wyswietli to samo co przy uzyciu autotrace traceonly EXPLAIN
SELECT plan_table_output FROM table(dbms_xplan.display(NULL,'PLAN_2','TYPICAL'));

/*
-- Wyœwietlenie planu inn¹ metod¹
SET autotrace traceonly EXPLAIN 
	SELECT count(*) FROM OSOBY O LEFT JOIN ADRES_POCZTY A ON O.ADR_ID = A.ADRK_1_ID WHERE O.OSO_IMIE = 'Marek' AND A.ADR_MIASTO = 'Kraków';
SET autotrace off
*/

PROMPT
PROMPT
PROMPT
PROMPT


--###<<< Dla zapytania: Pobierz mezczyzn[!] o imieniu[!] Mateusz >>>
/*
	--------------------------------------------------
	| Id  | Operation         | Name                 |
	--------------------------------------------------
	|   0 | SELECT STATEMENT  |                      |
	|   1 |  SORT AGGREGATE   |                      |
	|   2 |   INDEX RANGE SCAN| IX_OSO_IMIE_OSO_PLEC |
	--------------------------------------------------
*/
PROMPT #####################################################################
PROMPT ### 3. Dla zapytania: Pobierz mezczyzn[!] o imieniu[!] Mateusz
DELETE FROM PLAN_TABLE;

EXPLAIN PLAN SET statement_id = 'PLAN_3' FOR
SELECT count(*) FROM OSOBY WHERE OSO_IMIE = 'Mateusz' AND OSO_PLEC = 'm';

-- Wyœwietl plan
SELECT 
	LPAD(' ',2*(LEVEL-1))||OPERATION||' '||OPTIONS||' '||DECODE(OBJECT_INSTANCE,NULL,OBJECT_NAME,TO_CHAR(OBJECT_INSTANCE)||'*'||OBJECT_NAME) PLAN
FROM PLAN_TABLE
START WITH ID = 0
CONNECT BY PRIOR ID = PARENT_ID AND statement_id = 'PLAN_3'
ORDER BY ID;

--### Podstawowy plan z informacjami o uzytych indexach
SELECT plan_table_output FROM table(dbms_xplan.display(NULL,'PLAN_3','Basic'));
--### Plan typowy - wyswietli to samo co przy uzyciu autotrace traceonly EXPLAIN
SELECT plan_table_output FROM table(dbms_xplan.display(NULL,'PLAN_3','TYPICAL'));

/*
-- Wyœwietlenie planu inn¹ metod¹
SET autotrace traceonly EXPLAIN 
	SELECT count(*) FROM OSOBY WHERE OSO_IMIE = 'Mateusz' AND OSO_PLEC = 'm';
SET autotrace off
*/

PROMPT
PROMPT
PROMPT
PROMPT


--###<<< Dla zapytania: Pobierz kobiety[!] z Krakowa[!] (Zlaczenie tabel) >>>     [@@@@@@ JOIN @@@@@@]
PROMPT #####################################################################
PROMPT ### 4. Dla zapytania: Pobierz kobiety[!] z Krakowa[!] (Zlaczenie tabel)
DELETE FROM PLAN_TABLE;

EXPLAIN PLAN SET statement_id = 'PLAN_4' FOR
SELECT count(*) FROM OSOBY O LEFT JOIN ADRES_POCZTY A ON O.ADR_ID = A.ADRK_1_ID WHERE O.OSO_PLEC = 'k' AND A.ADR_MIASTO = 'Kraków';

-- Wyœwietl plan
SELECT 
	LPAD(' ',2*(LEVEL-1))||OPERATION||' '||OPTIONS||' '||DECODE(OBJECT_INSTANCE,NULL,OBJECT_NAME,TO_CHAR(OBJECT_INSTANCE)||'*'||OBJECT_NAME) PLAN
FROM PLAN_TABLE
START WITH ID = 0
CONNECT BY PRIOR ID = PARENT_ID AND statement_id = 'PLAN_4'
ORDER BY ID;

--### Podstawowy plan z informacjami o uzytych indexach
SELECT plan_table_output FROM table(dbms_xplan.display(NULL,'PLAN_4','Basic'));
--### Plan typowy - wyswietli to samo co przy uzyciu autotrace traceonly EXPLAIN
SELECT plan_table_output FROM table(dbms_xplan.display(NULL,'PLAN_4','TYPICAL'));

/*
-- Wyœwietlenie planu inn¹ metod¹
SET autotrace traceonly EXPLAIN 
	SELECT count(*) FROM OSOBY O LEFT JOIN ADRES_POCZTY A ON O.ADR_ID = A.ADRK_1_ID WHERE O.OSO_PLEC = 'k' AND A.ADR_MIASTO = 'Kraków';
SET autotrace off
*/

PROMPT
PROMPT
PROMPT
PROMPT
PROMPT
PROMPT
PROMPT
PROMPT



-- ####################################################################################################


--### Histogramy

PROMPT #####################################################################
PROMPT ### Pobieramy informacje o naszych tabelach


COLUMN COLUMN_NAME FORMAT A15
COLUMN TABLE_NAME FORMAT A10
--COLUMN ENDPOINT_VALUE FORMAT 999999999.99999999
COLUMN ENDPOINT_VALUE FORMAT A20

-- Pobieramy informacje o naszych tabelach
PROMPT ### Tabela: ADRES_POCZTY
SELECT COLUMN_NAME, NUM_DISTINCT, DENSITY, NUM_BUCKETS, HISTOGRAM
FROM USER_TAB_COLUMNS
WHERE TABLE_NAME = 'ADRES_POCZTY';

PROMPT
PROMPT
PROMPT ### Tabela: OSOBY #########################################
SELECT COLUMN_NAME, NUM_DISTINCT, DENSITY, NUM_BUCKETS, HISTOGRAM
FROM USER_TAB_COLUMNS
WHERE TABLE_NAME = 'OSOBY'; 

/*
	Zwrócone wyniki (na podstawie kodu wyzej):
	
	#####################################################################
	### Pobieramy informacje o naszych tabelach
	### Tabela: ADRES_POCZTY

	COLUMN_NAME     NUM_DISTINCT    DENSITY NUM_BUCKETS HISTOGRAM
	--------------- ------------ ---------- ----------- ---------------
	ADRK_1_ID               2000      .0005           1 NONE
	ADR_MIASTO              1943 .000520202         254 HEIGHT BALANCED
	ADR_KOD_POCZTOWY        2000      .0005           1 NONE
	ADR_ULICA               1933 .000517331           1 NONE
	ADR_NR_LOKALU           1817 .000550358           1 NONE

	5 rows selected.



	### Tabela: OSOBY #########################################

	COLUMN_NAME     NUM_DISTINCT    DENSITY NUM_BUCKETS HISTOGRAM
	--------------- ------------ ---------- ----------- ---------------
	OSOK_1_ID             999640 1.0004E-06           1 NONE
	OSO_IMIE                 594 .001751313         254 HEIGHT BALANCED
	OSO_NAZWISKO           19872 .000050322           1 NONE
	OSO_PLEC                   2 5.0018E-07           2 FREQUENCY
	OSO_DATA_URODZENIA     30453 .000032837           1 NONE
	OSO_PESEL                  0          0           0 NONE
	OSO_NIP               999640 1.0004E-06           1 NONE
	OSO_ULICA              29626 .000033754           1 NONE
	OSO_NR_LOKALU           9605 .000104112           1 NONE	
	ADR_ID                  2000      .0005           1 NONE

	10 rows selected.
*/




--### Wyœwietlamy dostêpne histogramy
PROMPT
PROMPT
PROMPT #####################################################################
PROMPT ### Wyswietlamy histogramy
PROMPT ### Histogramy z tabeli: ADRES_POCZTY #########################################

--### HEIGHT BALANCED
SELECT COLUMN_NAME, NUM_DISTINCT, NUM_BUCKETS, HISTOGRAM 
FROM USER_TAB_COL_STATISTICS
WHERE TABLE_NAME = 'ADRES_POCZTY' AND COLUMN_NAME = 'ADR_MIASTO';
/* 
SELECT TABLE_NAME, COLUMN_NAME, ENDPOINT_NUMBER, ENDPOINT_VALUE
FROM USER_HISTOGRAMS
WHERE TABLE_NAME = 'ADRES_POCZTY' AND COLUMN_NAME='ADR_MIASTO' ORDER BY ENDPOINT_NUMBER;
*/


/*
--### Inna metoda wyœwietlania w konsoli histogramu
--### http://www.orafaq.com/wiki/Histogram
COLUMN COL1 FORMAT A15
COLUMN COL2 FORMAT A15
SELECT d.ADR_MIASTO COL1,
             LPAD('+', COUNT(*), '+') COL2
FROM ADRES_POCZTY d GROUP BY d.ADR_MIASTO ORDER BY LENGTH(COL2) DESC;
*/
 

PROMPT
PROMPT
PROMPT ### Histogramy z tabeli: OSOBY #########################################

--### HEIGHT BALANCED
SELECT COLUMN_NAME, NUM_DISTINCT, NUM_BUCKETS, HISTOGRAM 
FROM USER_TAB_COL_STATISTICS
WHERE TABLE_NAME = 'OSOBY' AND COLUMN_NAME = 'OSO_IMIE';
--/*
-- http://oracleabc.com/oracledocs/11gDict/USER_HISTOGRAMS.htm
-- ENDPOINT_ACTUAL_VALUE Wyœwietli koñce przedzia³ów
SELECT TABLE_NAME, COLUMN_NAME, ENDPOINT_NUMBER, ENDPOINT_VALUE, ENDPOINT_ACTUAL_VALUE
FROM USER_HISTOGRAMS
WHERE TABLE_NAME = 'OSOBY' AND COLUMN_NAME='OSO_IMIE'
ORDER BY ENDPOINT_NUMBER;
--*/

/*
	
	TABLE_NAME COLUMN_NAME     ENDPOINT_NUMBER ENDPOINT_VALUE
	---------- --------------- --------------- --------------
	ENDPOINT_ACTUAL_VALUE
	--------------------------------------------------------------------------------

	OSOBY      OSO_IMIE                     57     ##########
	R??a

	OSOBY      OSO_IMIE                     58     ##########
	Raisa

	OSOBY      OSO_IMIE                     59     ##########
	Robert
*/


/* ############# Wy³¹czone bo zajmuje du¿¹ czêœæ ekranu <------------------<<<<<<<<<<<<================
PROMPT @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
PROMPT @@@ Wyswietlamy histogram imion
--### Inna metoda wyœwietlania w konsoli histogramu
--### http://www.orafaq.com/wiki/Histogram
COLUMN COL1 FORMAT A15
COLUMN COL2 FORMAT A50
-- Mo¿na te¿ uzyc wyswietlania +++ zamiast liczby 3 itd, ale w konsoli jest to nieczytelne
-- SELECT d.OSO_IMIE COL1, LPAD('+', COUNT(*), '+') COL2

SELECT d.OSO_IMIE COL1, COUNT(*) COL2
FROM OSOBY d GROUP BY d.OSO_IMIE ORDER BY LENGTH(COL2) DESC;
*/



--### FREQUENCY
SELECT COLUMN_NAME, NUM_DISTINCT, NUM_BUCKETS, HISTOGRAM 
FROM USER_TAB_COL_STATISTICS
WHERE TABLE_NAME = 'OSOBY' AND COLUMN_NAME = 'OSO_PLEC';
/* 
SELECT TABLE_NAME, COLUMN_NAME, ENDPOINT_NUMBER, ENDPOINT_VALUE
FROM USER_HISTOGRAMS
WHERE TABLE_NAME = 'OSOBY' AND COLUMN_NAME='OSO_PLEC' ORDER BY ENDPOINT_NUMBER;
*/


/*
	Zwrócone wyniki:
	
	#####################################################################
	### Wyswietlamy histogramy
	### Histogramy z tabeli: ADRES_POCZTY #########################################

	COLUMN_NAME     NUM_DISTINCT NUM_BUCKETS HISTOGRAM
	--------------- ------------ ----------- ---------------
	ADR_MIASTO              1943         254 HEIGHT BALANCED

	1 row selected.



	### Histogramy z tabeli: OSOBY #########################################

	COLUMN_NAME     NUM_DISTINCT NUM_BUCKETS HISTOGRAM
	--------------- ------------ ----------- ---------------
	OSO_IMIE                 594         254 HEIGHT BALANCED

	1 row selected.


	COLUMN_NAME     NUM_DISTINCT NUM_BUCKETS HISTOGRAM
	--------------- ------------ ----------- ---------------
	OSO_PLEC                   2           2 FREQUENCY

	1 row selected.
*/

PROMPT
PROMPT
PROMPT
PROMPT
	

-- ####################################################################################################

--### Analiza statystyk dla wybranej tabeli
PROMPT
PROMPT
PROMPT #####################################################################
PROMPT ### Analiza statystyk

/*
	Wskazówka: Na serwerze PK nie ma dostêpu do tabel: DBA_TAB_STATISTICS, DBA_IND_STATISTICS
*/

--## Pobranie informacji o ilosci wierszy w tabeli oraz iloœci przeanalizowanych wierszy a takze czasie ostatniej analizy 
SELECT TABLE_NAME, NUM_ROWS, SAMPLE_SIZE, LAST_ANALYZED 
FROM DBA_TAB_STATISTICS 
WHERE TABLE_NAME = 'OSOBY';


--## Informacje na temat indexow w tabeli
COLUMN INDEX_NAME FORMAT A10

SELECT INDEX_NAME, BLEVEL, DISTINCT_KEYS, NUM_ROWS, AVG_CACHED_BLOCKS, SAMPLE_SIZE, LAST_ANALYZED 
FROM DBA_IND_STATISTICS
WHERE INDEX_NAME='IX_OSO_IMIE';	

SELECT INDEX_NAME, BLEVEL, DISTINCT_KEYS, NUM_ROWS, AVG_CACHED_BLOCKS, SAMPLE_SIZE, LAST_ANALYZED 
FROM DBA_IND_STATISTICS
WHERE INDEX_NAME='IX_OSO_PLEC';	

SELECT INDEX_NAME, BLEVEL, DISTINCT_KEYS, NUM_ROWS, AVG_CACHED_BLOCKS, SAMPLE_SIZE, LAST_ANALYZED 
FROM DBA_IND_STATISTICS
WHERE INDEX_NAME='IX_OSO_DATA_URODZENIA';	

-- Index zlozony z 2 kolumn
SELECT INDEX_NAME, BLEVEL, DISTINCT_KEYS, NUM_ROWS, AVG_CACHED_BLOCKS, SAMPLE_SIZE, LAST_ANALYZED 
FROM DBA_IND_STATISTICS
WHERE INDEX_NAME='IX_OSO_IMIE_OSO_PLEC';	

-- Index zlozony z 3 kolumn
SELECT INDEX_NAME, BLEVEL, DISTINCT_KEYS, NUM_ROWS, AVG_CACHED_BLOCKS, SAMPLE_SIZE, LAST_ANALYZED 
FROM DBA_IND_STATISTICS
WHERE INDEX_NAME='IX_OSO_PLECIMIEDATAURODZ';	

/*
	Zwrócone wyniki:
	
	#####################################################################
	### Analiza statystyk

	TABLE_NAME   NUM_ROWS SAMPLE_SIZE LAST_ANALYZED
	---------- ---------- ----------- -------------------
	OSOBY         1003080      100308 2011/04/02 21:40:32

	1 row selected.


	INDEX_NAME     BLEVEL DISTINCT_KEYS   NUM_ROWS AVG_CACHED_BLOCKS SAMPLE_SIZE
	---------- ---------- ------------- ---------- ----------------- -----------
	LAST_ANALYZED
	-------------------
	IX_OSO_IMI          2           562    1029333                        442698
	E
	2011/04/02 21:41:00


	1 row selected.


	INDEX_NAME     BLEVEL DISTINCT_KEYS   NUM_ROWS AVG_CACHED_BLOCKS SAMPLE_SIZE
	---------- ---------- ------------- ---------- ----------------- -----------
	LAST_ANALYZED
	-------------------
	IX_OSO_PLE          2             2    1000000                       1000000
	C
	2011/04/02 21:41:05


	1 row selected.


	INDEX_NAME     BLEVEL DISTINCT_KEYS   NUM_ROWS AVG_CACHED_BLOCKS SAMPLE_SIZE
	---------- ---------- ------------- ---------- ----------------- -----------
	LAST_ANALYZED
	-------------------
	IX_OSO_DAT          2         30607     997347                        423550
	A_URODZENI
	A
	2011/04/02 21:41:07


	1 row selected.


	INDEX_NAME     BLEVEL DISTINCT_KEYS   NUM_ROWS AVG_CACHED_BLOCKS SAMPLE_SIZE
	---------- ---------- ------------- ---------- ----------------- -----------
	LAST_ANALYZED
	-------------------
	IX_OSO_IMI          2           543     945288                        367230
	E_OSO_PLEC
	2011/04/02 21:40:58


	1 row selected.


	INDEX_NAME     BLEVEL DISTINCT_KEYS   NUM_ROWS AVG_CACHED_BLOCKS SAMPLE_SIZE
	---------- ---------- ------------- ---------- ----------------- -----------
	LAST_ANALYZED
	-------------------
	IX_OSO_PLE          2        945701     972825                        272835
	CIMIEDATAU
	RODZ
	2011/04/02 21:41:11

*/	
	
	

-- ####################################################################################################



--### Pomocne opcje
--DBMS_STATS.DROP_STAT_TABLE('Trzop_Artur', 'STATS_TABLE');



-- # -------------------------------------------------

show error;

COMMIT;