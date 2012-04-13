-- ##################################################
--
--	Bazy danych 
-- 	2011 Copyright (c) Artur Trzop 12K2
--	Script v. 6.0.0
--
-- ##################################################

-- włączamy opcje wyświetlania komunikatów przy pomocy DBMS_OUTPUT.PUT_LINE();
set serveroutput on;
--set feedback on;
-- włącz wyświetlanie czasu wykonania zapytania
set timing off; 

-- wyk.3, str.46 ustawianie domyslnego sposobu wyswietlania daty
--ALTER SESSION SET NLS_DATE_FORMAT = 'yyyy/mm/dd';
ALTER SESSION SET NLS_DATE_FORMAT = 'yyyy/mm/dd hh24:mi:ss';


CLEAR SCREEN;
PROMPT ----------------------------------------------;
PROMPT Czyszczenie ekranu;
PROMPT ----------------------------------------------;
PROMPT ;


-- ####################################################################################################

-- Domyślne wartosci parametrów. Ustawiamy je za każdym razem ponieważ chceby by przy kolejnych wywołaniach tego pliku .sql 
-- były początkowo używane domyslne parametry dla sesji
ALTER SESSION SET OPTIMIZER_INDEX_COST_ADJ=100;
ALTER SESSION SET OPTIMIZER_INDEX_CACHING=0;
/*
	CHOOSE - jeśli brak statystyk dla tabeli to RBO
	FIRST_ROWS - preferencja nested-loops
	ALL_ROWS - preferencja sort-merge lub hash-join
*/
ALTER SESSION SET OPTIMIZER_MODE=ALL_ROWS;
-- wyłączamy uzycie scenariuszy
ALTER SESSION SET use_stored_outlines=FALSE;


-- Kasujemy poprzednie plany wykonania
DELETE FROM PLAN_TABLE;



PROMPT ######################################################
PROMPT ###
PROMPT ### Dla zapytania: Pobierz kobiety o imieniu na litere S i urodzone po roku 1980 wlacznie
PROMPT ###
PROMPT ######################################################

PROMPT
PROMPT 
PROMPT
PROMPT 

EXPLAIN PLAN SET statement_id = 'PLAN_1_A' FOR
SELECT count(*) FROM OSOBY WHERE OSO_PLEC = 'k' AND OSO_IMIE LIKE 'S%' AND OSO_DATA_URODZENIA >= '1980/01/01';

-- Wyświetla rozbudowany plan
SELECT plan_table_output FROM table(dbms_xplan.display(NULL,'PLAN_1_A','TYPICAL'));
/*
	### Zostanie uzyty index IX_OSO_PLECIMIEDATAURODZ nałożony na trzy kolumny występujące w where

	PLAN_TABLE_OUTPUT
	--------------------------------------------------------------------------------------------------------------

	Plan hash value: 565578088

	----------------------------------------------------------------------------------------------
	| Id  | Operation         | Name                     | Rows  | Bytes | Cost (%CPU)| Time     |
	----------------------------------------------------------------------------------------------
	|   0 | SELECT STATEMENT  |                          |     1 |    18 |   118   (1)| 00:00:02 |
	|   1 |  SORT AGGREGATE   |                          |     1 |    18 |            |          |
	|*  2 |   INDEX RANGE SCAN| IX_OSO_PLECIMIEDATAURODZ |  4679 | 84222 |   118   (1)| 00:00:02 |
	----------------------------------------------------------------------------------------------

	Predicate Information (identified by operation id):

	PLAN_TABLE_OUTPUT
	--------------------------------------------------------------------------------------------------------------

	---------------------------------------------------

	   2 - access("OSO_PLEC"='k' AND "OSO_IMIE" LIKE 'S%' AND
				  "OSO_DATA_URODZENIA">='1980/01/01')
		   filter("OSO_IMIE" LIKE 'S%' AND "OSO_DATA_URODZENIA">='1980/01/01')
*/


PROMPT
PROMPT
PROMPT ##################################################################
PROMPT ### Plan wykonania po uzyciu wskazowki uzycia indexu IX_OSO_IMIE
PROMPT

--### Stosujemy wskazowke
EXPLAIN PLAN SET statement_id = 'PLAN_1_B' FOR
SELECT /*+ INDEX(OSOBY IX_OSO_IMIE) */ count(*) 
FROM OSOBY WHERE OSO_PLEC = 'k' AND OSO_IMIE LIKE 'S%' AND OSO_DATA_URODZENIA >= '1980/01/01';

-- Wyświetla rozbudowany plan
SELECT plan_table_output FROM table(dbms_xplan.display(NULL,'PLAN_1_B','TYPICAL'));
/*
	PLAN_TABLE_OUTPUT
	--------------------------------------------------------------------------------------------------------------

	Plan hash value: 3411768040

	--------------------------------------------------------------------------------------------
	| Id  | Operation                    | Name        | Rows  | Bytes | Cost (%CPU)| Time     |
	--------------------------------------------------------------------------------------------
	|   0 | SELECT STATEMENT             |             |     1 |    18 | 49231   (1)| 00:09:51 |
	|   1 |  SORT AGGREGATE              |             |     1 |    18 |            |          |
	|*  2 |   TABLE ACCESS BY INDEX ROWID| OSOBY       |  4679 | 84222 | 49231   (1)| 00:09:51 |
	|*  3 |    INDEX RANGE SCAN          | IX_OSO_IMIE | 55211 |       |   147   (3)| 00:00:02 |
	--------------------------------------------------------------------------------------------


	PLAN_TABLE_OUTPUT
	--------------------------------------------------------------------------------------------------------------

	Predicate Information (identified by operation id):
	---------------------------------------------------

	   2 - filter("OSO_DATA_URODZENIA">='1980/01/01' AND "OSO_PLEC"='k')
	   3 - access("OSO_IMIE" LIKE 'S%')
		   filter("OSO_IMIE" LIKE 'S%')
*/


PROMPT
PROMPT
PROMPT ##################################################################
PROMPT ### Plan wykonania po uzyciu wskazowki uzycia kazdego indexu z osobna IX_OSO_IMIE, IX_OSO_PLEC, IX_OSO_DATA_URODZENIA
PROMPT
/*
	Zostaje wybrany jeden z indexow: IX_OSO_PLEC (najszybszy czas wykonania zapytania)
*/

--### Stosujemy wskazowke
EXPLAIN PLAN SET statement_id = 'PLAN_1_C' FOR
SELECT /*+ INDEX(OSOBY IX_OSO_IMIE) INDEX(OSOBY IX_OSO_PLEC) INDEX(OSOBY IX_OSO_DATA_URODZENIA) */ count(*) 
FROM OSOBY WHERE OSO_PLEC = 'k' AND OSO_IMIE LIKE 'S%' AND OSO_DATA_URODZENIA >= '1980/01/01';

-- Wyświetla rozbudowany plan
SELECT plan_table_output FROM table(dbms_xplan.display(NULL,'PLAN_1_C','TYPICAL'));
/*
	PLAN_TABLE_OUTPUT
	--------------------------------------------------------------------------------------------------------------

	Plan hash value: 4080236739

	--------------------------------------------------------------------------------------------
	| Id  | Operation                    | Name        | Rows  | Bytes | Cost (%CPU)| Time     |
	--------------------------------------------------------------------------------------------
	|   0 | SELECT STATEMENT             |             |     1 |    18 | 10601   (1)| 00:02:08 |
	|   1 |  SORT AGGREGATE              |             |     1 |    18 |            |          |
	|*  2 |   TABLE ACCESS BY INDEX ROWID| OSOBY       |  4679 | 84222 | 10601   (1)| 00:02:08 |
	|*  3 |    INDEX RANGE SCAN          | IX_OSO_PLEC |   540K|       |  1005   (3)| 00:00:13 |
	--------------------------------------------------------------------------------------------


	PLAN_TABLE_OUTPUT
	--------------------------------------------------------------------------------------------------------------

	Predicate Information (identified by operation id):
	---------------------------------------------------

	   2 - filter("OSO_IMIE" LIKE 'S%' AND "OSO_DATA_URODZENIA">='1980/01/01')
	   3 - access("OSO_PLEC"='k')
*/



-- ####################################################################################################



PROMPT ######################################################
PROMPT ###
PROMPT ### Dla zapytania: Pobierz ilosc mezczyzn z Krakowa
PROMPT ###
PROMPT ######################################################

PROMPT
PROMPT 
PROMPT
PROMPT 

EXPLAIN PLAN SET statement_id = 'PLAN_2_A' FOR
SELECT count(*) FROM OSOBY O LEFT JOIN ADRES_POCZTY A ON O.ADR_ID = A.ADRK_1_ID WHERE O.OSO_PLEC = 'm' AND A.ADR_MIASTO = 'Kraków';

-- Wyświetla rozbudowany plan
SELECT plan_table_output FROM table(dbms_xplan.display(NULL,'PLAN_2_A','TYPICAL'));
/*
	PLAN_TABLE_OUTPUT
	--------------------------------------------------------------------------------------------------------------

	Plan hash value: 3001107673

	------------------------------------------------------------------------------------
	| Id  | Operation           | Name         | Rows  | Bytes | Cost (%CPU)| Time     |
	------------------------------------------------------------------------------------
	|   0 | SELECT STATEMENT    |              |     1 |    22 |  2790   (6)| 00:00:34 |
	|   1 |  SORT AGGREGATE     |              |     1 |    22 |            |          |
	|*  2 |   HASH JOIN         |              |  3633 | 79926 |  2790   (6)| 00:00:34 |			<<<<################### Uzyto
	|*  3 |    TABLE ACCESS FULL| ADRES_POCZTY |    16 |   256 |     5   (0)| 00:00:01 |
	|*  4 |    TABLE ACCESS FULL| OSOBY        |   461K|  2703K|  2775   (6)| 00:00:34 |
	------------------------------------------------------------------------------------

	PLAN_TABLE_OUTPUT
	--------------------------------------------------------------------------------------------------------------


	Predicate Information (identified by operation id):
	---------------------------------------------------

	   2 - access("O"."ADR_ID"="A"."ADRK_1_ID")
	   3 - filter("A"."ADR_MIASTO"='Krak?w')
	   4 - filter("O"."OSO_PLEC"='m')
*/


PROMPT
PROMPT
PROMPT ##################################################################
PROMPT ### Plan wykonania po uzyciu wskazowki USE_MERGE
PROMPT

EXPLAIN PLAN SET statement_id = 'PLAN_2_B' FOR
SELECT /*+ USE_MERGE(O A) */ count(*) FROM OSOBY O LEFT JOIN ADRES_POCZTY A ON O.ADR_ID = A.ADRK_1_ID WHERE O.OSO_PLEC = 'm' AND A.ADR_MIASTO = 'Kraków';

-- Wyświetla rozbudowany plan
SELECT plan_table_output FROM table(dbms_xplan.display(NULL,'PLAN_2_B','TYPICAL'));
/*
	PLAN_TABLE_OUTPUT
	--------------------------------------------------------------------------------------------------------------

	Plan hash value: 1463370643

	---------------------------------------------------------------------------------------------
	| Id  | Operation            | Name         | Rows  | Bytes |TempSpc| Cost (%CPU)| Time     |
	---------------------------------------------------------------------------------------------
	|   0 | SELECT STATEMENT     |              |     1 |    22 |       |  4355   (6)| 00:00:53 |
	|   1 |  SORT AGGREGATE      |              |     1 |    22 |       |            |          |
	|   2 |   MERGE JOIN         |              |  3633 | 79926 |       |  4355   (6)| 00:00:53 |		<<<<################### Uzyto MERGE JOIN         
	|   3 |    SORT JOIN         |              |    16 |   256 |       |     6  (17)| 00:00:01 |
	|*  4 |     TABLE ACCESS FULL| ADRES_POCZTY |    16 |   256 |       |     5   (0)| 00:00:01 |
	|*  5 |    SORT JOIN         |              |   461K|  2703K|    14M|  4349   (6)| 00:00:53 |
	|*  6 |     TABLE ACCESS FULL| OSOBY        |   461K|  2703K|       |  2775   (6)| 00:00:34 |
	---------------------------------------------------------------------------------------------

	Predicate Information (identified by operation id):
	---------------------------------------------------

	   4 - filter("A"."ADR_MIASTO"='Krak?w')
	   5 - access("O"."ADR_ID"="A"."ADRK_1_ID")
		   filter("O"."ADR_ID"="A"."ADRK_1_ID")
	   6 - filter("O"."OSO_PLEC"='m')
*/


PROMPT
PROMPT
PROMPT ##################################################################
PROMPT ### Plan wykonania po uzyciu wskazowki USE_NL
PROMPT

EXPLAIN PLAN SET statement_id = 'PLAN_2_C' FOR
SELECT /*+ USE_NL(O A) */ count(*) FROM OSOBY O LEFT JOIN ADRES_POCZTY A ON O.ADR_ID = A.ADRK_1_ID WHERE O.OSO_PLEC = 'm' AND A.ADR_MIASTO = 'Kraków';

-- Wyświetla rozbudowany plan
SELECT plan_table_output FROM table(dbms_xplan.display(NULL,'PLAN_2_C','TYPICAL'));
/*
	PLAN_TABLE_OUTPUT
	--------------------------------------------------------------------------------------------------------------

	Plan hash value: 151643436

	-----------------------------------------------------------------------------------------------------
	| Id  | Operation                     | Name                | Rows  | Bytes | Cost (%CPU)| Time     |
	-----------------------------------------------------------------------------------------------------
	|   0 | SELECT STATEMENT              |                     |     1 |    22 |  3718  (29)| 00:00:45 |
	|   1 |  SORT AGGREGATE               |                     |     1 |    22 |            |          |
	|   2 |   NESTED LOOPS                |                     |  3633 | 79926 |  3718  (29)| 00:00:45 |		<<<<################### Uzyto
	|*  3 |    TABLE ACCESS FULL          | OSOBY               |   461K|  2703K|  2775   (6)| 00:00:34 |
	|*  4 |    TABLE ACCESS BY INDEX ROWID| ADRES_POCZTY        |     1 |    16 |     1   (0)| 00:00:01 |
	|*  5 |     INDEX UNIQUE SCAN         | CSR_PK_ADRES_POCZTY |     1 |       |     0   (0)| 00:00:01 |


	Predicate Information (identified by operation id):
	---------------------------------------------------

	   3 - filter("O"."OSO_PLEC"='m')
	   4 - filter("A"."ADR_MIASTO"='Krak?w')
	   5 - access("O"."ADR_ID"="A"."ADRK_1_ID")
*/



-- ####################################################################################################


--### Podzapytania
-- ### Zapytanie pobiera osoby ktore urodzily sie w latach +/- 5 lat od średniej daty urodzenia wszystkich osob

PROMPT ######################################################
PROMPT ###
PROMPT ### Podzapytania: Zapytanie pobiera osoby ktore urodzily sie w latach +/- 5 lat od sredniej daty urodzenia wszystkich osob
PROMPT ###
PROMPT ######################################################

PROMPT
PROMPT 
PROMPT
PROMPT 


-- Aktualne parametry sesji sa takie aby wymusic nested-loops
ALTER SESSION SET OPTIMIZER_INDEX_COST_ADJ=50; 
ALTER SESSION SET OPTIMIZER_INDEX_CACHING=50;
ALTER SESSION SET OPTIMIZER_MODE=FIRST_ROWS;


EXPLAIN PLAN SET statement_id = 'PLAN_3_A' FOR
SELECT O.OSO_IMIE, O.OSO_NAZWISKO, A.ADR_MIASTO, A.ADR_KOD_POCZTOWY 
FROM OSOBY O LEFT JOIN ADRES_POCZTY A ON O.ADR_ID = A.ADRK_1_ID
WHERE 
	O.OSO_DATA_URODZENIA 
	BETWEEN 
		(SELECT TRUNC(AVG(extract(YEAR FROM O.OSO_DATA_URODZENIA)))-5||'/01/01 00:00:00' FROM OSOBY O)  
	AND 
		(SELECT TRUNC(AVG(extract(YEAR FROM O.OSO_DATA_URODZENIA)))+5||'/01/01 00:00:00' FROM OSOBY O);

-- Wyświetla rozbudowany plan
SELECT plan_table_output FROM table(dbms_xplan.display(NULL,'PLAN_3_A','TYPICAL'));
/*
	PLAN_TABLE_OUTPUT
	--------------------------------------------------------------------------------------------------------------

	Plan hash value: 1168666564

	------------------------------------------------------------------------------------------------------
	| Id  | Operation                    | Name                  | Rows  | Bytes | Cost (%CPU)| Time     |
	------------------------------------------------------------------------------------------------------
	|   0 | SELECT STATEMENT             |                       |  2504 |   127K|  4987   (2)| 00:01:00 |
	|   1 |  NESTED LOOPS OUTER          |                       |  2504 |   127K|  3499   (1)| 00:00:42 |			<<<<################### Uzyto
	|   2 |   TABLE ACCESS BY INDEX ROWID| OSOBY                 |  2504 | 72616 |  2244   (1)| 00:00:27 |
	|*  3 |    INDEX RANGE SCAN          | IX_OSO_DATA_URODZENIA |  4507 |       |     7   (0)| 00:00:01 |
	|   4 |     SORT AGGREGATE           |                       |     1 |     8 |            |          |
	|   5 |      INDEX FAST FULL SCAN    | IX_OSO_DATA_URODZENIA |  1001K|  7825K|   744   (5)| 00:00:09 |
	|   6 |     SORT AGGREGATE           |                       |     1 |     8 |            |          |
	|   7 |      INDEX FAST FULL SCAN    | IX_OSO_DATA_URODZENIA |  1001K|  7825K|   744   (5)| 00:00:09 |
	|   8 |   TABLE ACCESS BY INDEX ROWID| ADRES_POCZTY          |     1 |    23 |     1   (0)| 00:00:01 |
	|*  9 |    INDEX UNIQUE SCAN         | CSR_PK_ADRES_POCZTY   |     1 |       |     1   (0)| 00:00:01 |
	------------------------------------------------------------------------------------------------------

	Predicate Information (identified by operation id):
	---------------------------------------------------

	   3 - access("O"."OSO_DATA_URODZENIA">= (SELECT TO_CHAR(TRUNC(AVG(EXTRACT(YEAR FROM
				  INTERNAL_FUNCTION("O"."OSO_DATA_URODZENIA"))))-5)||'/01/01 00:00:00' FROM "OSOBY" "O") AND

				  "O"."OSO_DATA_URODZENIA"<= (SELECT TO_CHAR(TRUNC(AVG(EXTRACT(YEAR FROM
				  INTERNAL_FUNCTION("O"."OSO_DATA_URODZENIA"))))+5)||'/01/01 00:00:00' FROM "OSOBY" "O"))
	   9 - access("O"."ADR_ID"="A"."ADRK_1_ID"(+))
*/


PROMPT
PROMPT
PROMPT ##################################################################
PROMPT ### Plan wykonania po uzyciu wskazowki ALL_ROWS ORDERED 
PROMPT

/*
	### ALL_ROWS - wymusi uzycie hash-join/sort-merge lub w ostatecznosci nested-loops
	### ORDERED - wymusi złączenie tabel wg. kolejnosci wystąpienia po FROM. Tabele zostaną połączone wg. kolejnosci OSOBY do ADRES_POCZTY
				Gdy tą opcje wyłączymy to łączona jest ADRES_POCZTY do OSOBY poniewaz tabela ADRES_POCZTY ma mniej wierszy
*/
EXPLAIN PLAN SET statement_id = 'PLAN_3_B' FOR
SELECT /*+ ALL_ROWS ORDERED */ O.OSO_IMIE, O.OSO_NAZWISKO, A.ADR_MIASTO, A.ADR_KOD_POCZTOWY 
FROM OSOBY O LEFT JOIN ADRES_POCZTY A ON O.ADR_ID = A.ADRK_1_ID
WHERE 
	O.OSO_DATA_URODZENIA 
	BETWEEN 
		(SELECT TRUNC(AVG(extract(YEAR FROM O.OSO_DATA_URODZENIA)))-5||'/01/01 00:00:00' FROM OSOBY O)  
	AND 
		(SELECT TRUNC(AVG(extract(YEAR FROM O.OSO_DATA_URODZENIA)))+5||'/01/01 00:00:00' FROM OSOBY O);

-- Wyświetla rozbudowany plan
SELECT plan_table_output FROM table(dbms_xplan.display(NULL,'PLAN_3_B','TYPICAL'));
/*	
	PLAN_TABLE_OUTPUT
	--------------------------------------------------------------------------------------------------------------

	Plan hash value: 2737590507

	------------------------------------------------------------------------------------------------------
	| Id  | Operation                    | Name                  | Rows  | Bytes | Cost (%CPU)| Time     |
	------------------------------------------------------------------------------------------------------
	|   0 | SELECT STATEMENT             |                       |  2504 |   127K|  3738   (2)| 00:00:45 |
	|*  1 |  HASH JOIN OUTER             |                       |  2504 |   127K|  2250   (1)| 00:00:27 |		<<<<################### Uzyto
	|   2 |   TABLE ACCESS BY INDEX ROWID| OSOBY                 |  2504 | 72616 |  2244   (1)| 00:00:27 |		<<<<################### OSOBY
	|*  3 |    INDEX RANGE SCAN          | IX_OSO_DATA_URODZENIA |  4507 |       |     7   (0)| 00:00:01 |
	|   4 |     SORT AGGREGATE           |                       |     1 |     8 |            |          |
	|   5 |      INDEX FAST FULL SCAN    | IX_OSO_DATA_URODZENIA |  1001K|  7825K|   744   (5)| 00:00:09 |

	PLAN_TABLE_OUTPUT
	--------------------------------------------------------------------------------------------------------------

	|   6 |     SORT AGGREGATE           |                       |     1 |     8 |            |          |
	|   7 |      INDEX FAST FULL SCAN    | IX_OSO_DATA_URODZENIA |  1001K|  7825K|   744   (5)| 00:00:09 |
	|   8 |   TABLE ACCESS FULL          | ADRES_POCZTY          |  2000 | 46000 |     5   (0)| 00:00:01 |		<<<<################### ADRES_POCZTY
	------------------------------------------------------------------------------------------------------

	Predicate Information (identified by operation id):
	---------------------------------------------------

	   1 - access("O"."ADR_ID"="A"."ADRK_1_ID"(+))
	   3 - access("O"."OSO_DATA_URODZENIA">= (SELECT TO_CHAR(TRUNC(AVG(EXTRACT(YEAR FROM
				  INTERNAL_FUNCTION("O"."OSO_DATA_URODZENIA"))))-5)||'/01/01 00:00:00' FROM "OSOBY" "O") AND

	PLAN_TABLE_OUTPUT
	--------------------------------------------------------------------------------------------------------------

				  "O"."OSO_DATA_URODZENIA"<= (SELECT TO_CHAR(TRUNC(AVG(EXTRACT(YEAR FROM
				  INTERNAL_FUNCTION("O"."OSO_DATA_URODZENIA"))))+5)||'/01/01 00:00:00' FROM "OSOBY" "O"))

*/



PROMPT
PROMPT
PROMPT ##################################################################
PROMPT ### Plan wykonania po uzyciu wskazowki USE_HASH NO_INDEX
PROMPT

/*
	Wymuszamy hash-join oraz brak uzycia indexu IX_OSO_DATA_URODZENIA. (Wykona sie FAST FULL SCAN zamiast RANGE SCAN)
*/
EXPLAIN PLAN SET statement_id = 'PLAN_3_C' FOR
SELECT /*+ USE_HASH(A O) NO_INDEX(O IX_OSO_DATA_URODZENIA) */ O.OSO_IMIE, O.OSO_NAZWISKO, A.ADR_MIASTO, A.ADR_KOD_POCZTOWY 
FROM OSOBY O LEFT JOIN ADRES_POCZTY A ON O.ADR_ID = A.ADRK_1_ID
WHERE 
	O.OSO_DATA_URODZENIA 
	BETWEEN 
		(SELECT TRUNC(AVG(extract(YEAR FROM O.OSO_DATA_URODZENIA)))-5||'/01/01 00:00:00' FROM OSOBY O)  
	AND 
		(SELECT TRUNC(AVG(extract(YEAR FROM O.OSO_DATA_URODZENIA)))+5||'/01/01 00:00:00' FROM OSOBY O);

-- Wyświetla rozbudowany plan
SELECT plan_table_output FROM table(dbms_xplan.display(NULL,'PLAN_3_C','TYPICAL'));
/*
	PLAN_TABLE_OUTPUT
	--------------------------------------------------------------------------------------------------------------

	Plan hash value: 1066550627

	---------------------------------------------------------------------------------------------------
	| Id  | Operation                 | Name                  | Rows  | Bytes | Cost (%CPU)| Time     |
	---------------------------------------------------------------------------------------------------
	|   0 | SELECT STATEMENT          |                       |  2504 |   127K|  4283   (6)| 00:00:52 |
	|*  1 |  HASH JOIN RIGHT OUTER    |                       |  2504 |   127K|  2795   (6)| 00:00:34 |		<<<<################### hash-join
	|   2 |   TABLE ACCESS FULL       | ADRES_POCZTY          |  2000 | 46000 |     5   (0)| 00:00:01 |
	|*  3 |   TABLE ACCESS FULL       | OSOBY                 |  2504 | 72616 |  2789   (6)| 00:00:34 |
	|   4 |    SORT AGGREGATE         |                       |     1 |     8 |            |          |
	|   5 |     INDEX FAST FULL SCAN  | IX_OSO_DATA_URODZENIA |  1001K|  7825K|   744   (5)| 00:00:09 |		<<<<################### full scan
	|   6 |      SORT AGGREGATE       |                       |     1 |     8 |            |          |
	|   7 |       INDEX FAST FULL SCAN| IX_OSO_DATA_URODZENIA |  1001K|  7825K|   744   (5)| 00:00:09 |		<<<<################### full scan
	---------------------------------------------------------------------------------------------------

	Predicate Information (identified by operation id):
	---------------------------------------------------

	   1 - access("O"."ADR_ID"="A"."ADRK_1_ID"(+))
	   3 - filter("O"."OSO_DATA_URODZENIA">= (SELECT TO_CHAR(TRUNC(AVG(EXTRACT(YEAR FROM
				  INTERNAL_FUNCTION("O"."OSO_DATA_URODZENIA"))))-5)||'/01/01 00:00:00' FROM "OSOBY" "O") AND
				  "O"."OSO_DATA_URODZENIA"<= (SELECT TO_CHAR(TRUNC(AVG(EXTRACT(YEAR FROM

	PLAN_TABLE_OUTPUT
	--------------------------------------------------------------------------------------------------------------

				  INTERNAL_FUNCTION("O"."OSO_DATA_URODZENIA"))))+5)||'/01/01 00:00:00' FROM "OSOBY" "O"))
*/



-- ####################################################################################################


/*
	MERGE <hint> INTO <table_name>
	USING <table_view_or_query>
	ON (<condition>)
	WHEN MATCHED THEN <update_clause>
	DELETE <where_clause>
	WHEN NOT MATCHED THEN <insert_clause>
	[LOG ERRORS <log_errors_clause> <reject limit <integer | unlimited>];
*/

-- http://psoug.org/reference/merge.html
-- http://www.dba-oracle.com/oracle_tips_rittman_merge.htm
-- http://www.oracle-base.com/articles/10g/MergeEnhancements10g.php
-- http://www.gmmobile.pl/index.php?option=com_content&view=article&id=16:oracle-merge&catid=3:oracle&Itemid=12

-- Za pomocą jednego polecenia dokonujemy aktualizacji lub dodania wartości w tabeli
PROMPT ######################################################
PROMPT ###
PROMPT ### Polecenie MERGE
PROMPT ###
PROMPT ######################################################

PROMPT
PROMPT 
PROMPT
PROMPT 

-- gdy brak statystyk to RBO
ALTER SESSION SET OPTIMIZER_MODE=CHOOSE;


SAVEPOINT S1;



EXPLAIN PLAN SET statement_id = 'PLAN_4_A' FOR
MERGE INTO OSOBY O
USING (SELECT ADRK_1_ID FROM ADRES_POCZTY WHERE ADR_MIASTO = 'Kraków' AND ADRK_1_ID = 1) A
ON (O.ADR_ID = A.ADRK_1_ID)
WHEN MATCHED THEN
	UPDATE SET O.OSO_IMIE = UPPER(O.OSO_IMIE)	
WHEN NOT MATCHED THEN
	INSERT (O.OSO_IMIE, O.OSO_NAZWISKO, O.OSO_PLEC, O.OSO_DATA_URODZENIA, O.OSO_PESEL, O.OSO_NIP, O.OSO_ULICA, O.OSO_NR_LOKALU, O.ADR_ID)
	VALUES ('Jan', 'Kowalski', 'm', '1990/01/01', '44051401458', '', 'Długa', '11/45', A.ADRK_1_ID);
	
-- Wyświetla rozbudowany plan
SELECT plan_table_output FROM table(dbms_xplan.display(NULL,'PLAN_4_A','TYPICAL'));
/*
	PLAN_TABLE_OUTPUT
	--------------------------------------------------------------------------------------------------------------

	Plan hash value: 2057788309

	------------------------------------------------------------------------------------------------------
	| Id  | Operation                      | Name                | Rows  | Bytes | Cost (%CPU)| Time     |
	------------------------------------------------------------------------------------------------------
	|   0 | MERGE STATEMENT                |                     |   501 | 51603 |   247   (0)| 00:00:03 |
	|   1 |  MERGE                         | OSOBY               |       |       |            |          |
	|   2 |   VIEW                         |                     |       |       |            |          |
	|   3 |    NESTED LOOPS OUTER          |                     |   501 | 39579 |   247   (0)| 00:00:03 |		<<<<################### nested-loops
	|*  4 |     TABLE ACCESS BY INDEX ROWID| ADRES_POCZTY        |     1 |    16 |     1   (0)| 00:00:01 |
	|*  5 |      INDEX UNIQUE SCAN         | CSR_PK_ADRES_POCZTY |     1 |       |     1   (0)| 00:00:01 |
	|   6 |     TABLE ACCESS BY INDEX ROWID| OSOBY               |   501 | 31563 |   246   (0)| 00:00:03 |
	|*  7 |      INDEX RANGE SCAN          | IX_CSR_FK_OSO_ADR   |   501 |       |     1   (0)| 00:00:01 |
	------------------------------------------------------------------------------------------------------

	Predicate Information (identified by operation id):
	---------------------------------------------------

	   4 - filter("ADR_MIASTO"='Krak?w')
	   5 - access("ADRK_1_ID"=1)
	   7 - access("O"."ADR_ID"(+)=1)
*/



PROMPT
PROMPT
PROMPT ##################################################################
PROMPT ### Plan wykonania po uzyciu wskazowki USE_HASH
PROMPT

EXPLAIN PLAN SET statement_id = 'PLAN_4_B' FOR
MERGE /*+ USE_HASH(A O) */ INTO OSOBY O
USING (SELECT ADRK_1_ID FROM ADRES_POCZTY WHERE ADR_MIASTO = 'Kraków' AND ADRK_1_ID = 1) A
ON (O.ADR_ID = A.ADRK_1_ID)
WHEN MATCHED THEN
	UPDATE SET O.OSO_IMIE = UPPER(O.OSO_IMIE)	
WHEN NOT MATCHED THEN
	INSERT (O.OSO_IMIE, O.OSO_NAZWISKO, O.OSO_PLEC, O.OSO_DATA_URODZENIA, O.OSO_PESEL, O.OSO_NIP, O.OSO_ULICA, O.OSO_NR_LOKALU, O.ADR_ID)
	VALUES ('Jan', 'Kowalski', 'm', '1990/01/01', '44051401458', '', 'Długa', '11/45', A.ADRK_1_ID);
	
-- Wyświetla rozbudowany plan
SELECT plan_table_output FROM table(dbms_xplan.display(NULL,'PLAN_4_B','TYPICAL'));
/*
	PLAN_TABLE_OUTPUT
	--------------------------------------------------------------------------------------------------------------

	Plan hash value: 244553309

	------------------------------------------------------------------------------------------------------
	| Id  | Operation                      | Name                | Rows  | Bytes | Cost (%CPU)| Time     |
	------------------------------------------------------------------------------------------------------
	|   0 | MERGE STATEMENT                |                     |   501 | 51603 |   250   (1)| 00:00:03 |
	|   1 |  MERGE                         | OSOBY               |       |       |            |          |
	|   2 |   VIEW                         |                     |       |       |            |          |
	|*  3 |    HASH JOIN OUTER             |                     |   501 | 39579 |   250   (1)| 00:00:03 |		<<<<################### hash-join
	|*  4 |     TABLE ACCESS BY INDEX ROWID| ADRES_POCZTY        |     1 |    16 |     1   (0)| 00:00:01 |
	|*  5 |      INDEX UNIQUE SCAN         | CSR_PK_ADRES_POCZTY |     1 |       |     1   (0)| 00:00:01 |
	|   6 |     TABLE ACCESS BY INDEX ROWID| OSOBY               |   501 | 31563 |   248   (0)| 00:00:03 |
	|*  7 |      INDEX RANGE SCAN          | IX_CSR_FK_OSO_ADR   |   501 |       |     2   (0)| 00:00:01 |
	------------------------------------------------------------------------------------------------------

	Predicate Information (identified by operation id):
	---------------------------------------------------

	   3 - access("O"."ADR_ID"(+)="ADRK_1_ID")
	   4 - filter("ADR_MIASTO"='Krak?w')
	   5 - access("ADRK_1_ID"=1)
	   7 - access("O"."ADR_ID"(+)=1)
*/





ROLLBACK TO SAVEPOINT S1;



-- ####################################################################################################


-- # -------------------------------------------------

show error;

COMMIT;