-- ##################################################
--
--	Bazy danych 
-- 	2011 Copyright (c) Artur Trzop 12K2
--	Script v. 5.0.0 DBMS_OUTLN
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






-- Sprawdzamy czy juz istnieja jakies scenariusze (wyklad3, str.13)
-- ### user_outlines - perspektywa słownika /w.3,s15
PROMPT ######################################################
PROMPT ###
PROMPT ### Pobieramy dostepne scenariusze:
PROMPT ###
PROMPT ######################################################
COLUMN name FORMAT A20
COLUMN category FORMAT A20
COLUMN used FORMAT A10
SELECT name, category FROM user_outlines;


PROMPT
PROMPT 
PROMPT
PROMPT 


-- Nie rejestrujemy scenariuszy
ALTER SESSION SET CREATE_STORED_OUTLINES = FALSE;



-- ####################################################################################################




--### http://download.oracle.com/docs/cd/B19306_01/appdev.102/b14258/d_outln.htm
PROMPT ######################################################
PROMPT ###
PROMPT ### DBMS.OUTLN
PROMPT ###
PROMPT ######################################################


-- Aktualnie parametry sesji sa takie aby wymusic hash-join
ALTER SESSION SET OPTIMIZER_INDEX_COST_ADJ=10000; 
ALTER SESSION SET OPTIMIZER_INDEX_CACHING=1;
ALTER SESSION SET OPTIMIZER_MODE=ALL_ROWS;


--### Wykonujemy zapytanie liczace ilosc osob z urzedow pocztowych o ID <= 100
SELECT count(*) FROM OSOBY O LEFT JOIN ADRES_POCZTY A ON O.ADR_ID = A.ADRK_1_ID WHERE A.ADRK_1_ID <= 100;


DECLARE 
	my_hash INT;
	my_child_number INT;
		
BEGIN
	
	--### Pobieramy informacje o hashu i numerze potomka dla wykonanego zapytania
	SELECT hash_value, child_number INTO my_hash, my_child_number  
	FROM v$sql 
	WHERE sql_text LIKE 'SELECT count(*) FROM OSOBY O LEFT JOIN ADRES_POCZTY A ON O.ADR_ID = A.ADRK_1_ID WHERE A.ADRK_1_ID <= 100' AND ROWNUM=1;

	DBMS_OUTPUT.PUT_LINE('my_hash: '||my_hash||', my_child_number: '||my_child_number);
	
	--### Tworzymy scenariusz
	DBMS_OUTLN.CREATE_OUTLINE(
		hash_value => my_hash,
		child_number => my_child_number,
		category => 'MOJE_SCENARIUSZE_DBMS_OUTLN'
	);
	
	
END;
/


-- Pobieramy informacje o uzyciu scenariuszy
COLUMN name FORMAT A30
COLUMN category FORMAT A30
SELECT name, category, used FROM user_outlines;
/*
	Sprawdzamy czy zostal utworzony scenariusz:
	NAME                           CATEGORY                       USED
	------------------------------ ------------------------------ ----------
	SCENARIUSZ_1                   MOJE_SCENARIUSZE               USED
	SCENARIUSZ_2                   MOJE_SCENARIUSZE               USED
	SYS_OUTLINE_11040920355037212  MOJE_SCENARIUSZE_DBMS_OUTLN    UNUSED			<===== Został stworzony
	SCENARIUSZ_3                   MOJE_SCENARIUSZE               USED
*/



/*
	Pomocne polecenia:
	-- Kasuje scenariusze z danej kategorii
	EXEC DBMS_OUTLN.DROP_BY_CAT('S_OUTLN');
	-- Kasuje dany scenariusz
	DROP OUTLINE SYS_OUTLINE_11040919;
*/


-- Sprawdzamy aktualny plan wykonania
/*
	Uzyty zostanie hash-join.
*/
set timing on;
set autotrace traceonly explain
	SELECT count(*) FROM OSOBY O LEFT JOIN ADRES_POCZTY A ON O.ADR_ID = A.ADRK_1_ID WHERE A.ADRK_1_ID <= 100;
set autotrace off
set timing off;
/*
	Execution Plan
	----------------------------------------------------------
	Plan hash value: 3818240244

	----------------------------------------------------------------------------------------------
	| Id  | Operation              | Name                | Rows  | Bytes | Cost (%CPU)| Time     |
	----------------------------------------------------------------------------------------------
	|   0 | SELECT STATEMENT       |                     |     1 |     8 |   709   (7)| 00:00:09 |
	|   1 |  SORT AGGREGATE        |                     |     1 |     8 |            |          |
	|*  2 |   HASH JOIN            |                     |  2508 | 20064 |   709   (7)| 00:00:09 |
	|*  3 |    INDEX FAST FULL SCAN| CSR_PK_ADRES_POCZTY |   100 |   400 |     3   (0)| 00:00:01 |
	|*  4 |    INDEX FAST FULL SCAN| IX_CSR_FK_OSO_ADR   | 50130 |   195K|   704   (6)| 00:00:09 |
	----------------------------------------------------------------------------------------------

	Predicate Information (identified by operation id):
	---------------------------------------------------

	   2 - access("O"."ADR_ID"="A"."ADRK_1_ID")
	   3 - filter("A"."ADRK_1_ID"<=100)
	   4 - filter("O"."ADR_ID"<=100)
*/


-- Zmieniamy parametry sesji aby wymusic nested-loops
ALTER SESSION SET OPTIMIZER_INDEX_COST_ADJ=50; 
ALTER SESSION SET OPTIMIZER_INDEX_CACHING=50;
ALTER SESSION SET OPTIMIZER_MODE=FIRST_ROWS;


-- Sprawdzamy plan wykonania po zmianie parametrow sesji. Zostanie uzyty nested-loops
set timing on;
set autotrace traceonly explain
	SELECT count(*) FROM OSOBY O LEFT JOIN ADRES_POCZTY A ON O.ADR_ID = A.ADRK_1_ID WHERE A.ADRK_1_ID <= 100;
set autotrace off
set timing off;
/*
	Execution Plan
	----------------------------------------------------------
	Plan hash value: 3947245571

	------------------------------------------------------------------------------------------
	| Id  | Operation          | Name                | Rows  | Bytes | Cost (%CPU)| Time     |
	------------------------------------------------------------------------------------------
	|   0 | SELECT STATEMENT   |                     |     1 |     8 |     3  (34)| 00:00:01 |
	|   1 |  SORT AGGREGATE    |                     |     1 |     8 |            |          |
	|   2 |   NESTED LOOPS     |                     |  2508 | 20064 |     3  (34)| 00:00:01 |
	|*  3 |    INDEX RANGE SCAN| CSR_PK_ADRES_POCZTY |   100 |   400 |     1   (0)| 00:00:01 |
	|*  4 |    INDEX RANGE SCAN| IX_CSR_FK_OSO_ADR   |    25 |   100 |     1   (0)| 00:00:01 |
	------------------------------------------------------------------------------------------

	Predicate Information (identified by operation id):
	---------------------------------------------------

	   3 - access("A"."ADRK_1_ID"<=100)
	   4 - access("O"."ADR_ID"="A"."ADRK_1_ID")
		   filter("O"."ADR_ID"<=100)
*/


-- Włączamy użycie scenariuszy MOJE_SCENARIUSZE
ALTER SESSION SET use_stored_outlines=MOJE_SCENARIUSZE_DBMS_OUTLN;


-- Sprawdzamy plan po włączeniu scenariuszy. Okazuje sie ze zostanie uzyty hash-join zgodnie ze scenariuszem
set timing on;
set autotrace traceonly explain
	SELECT count(*) FROM OSOBY O LEFT JOIN ADRES_POCZTY A ON O.ADR_ID = A.ADRK_1_ID WHERE A.ADRK_1_ID <= 100;
set autotrace off
set timing off;
/*	
	Execution Plan
	----------------------------------------------------------
	Plan hash value: 3818240244

	----------------------------------------------------------------------------------------------
	| Id  | Operation              | Name                | Rows  | Bytes | Cost (%CPU)| Time     |
	----------------------------------------------------------------------------------------------
	|   0 | SELECT STATEMENT       |                     |     1 |     8 |   709   (7)| 00:00:09 |
	|   1 |  SORT AGGREGATE        |                     |     1 |     8 |            |          |
	|*  2 |   HASH JOIN            |                     |  2508 | 20064 |   709   (7)| 00:00:09 |
	|*  3 |    INDEX FAST FULL SCAN| CSR_PK_ADRES_POCZTY |   100 |   400 |     3   (0)| 00:00:01 |
	|*  4 |    INDEX FAST FULL SCAN| IX_CSR_FK_OSO_ADR   | 50130 |   195K|   704   (6)| 00:00:09 |
	----------------------------------------------------------------------------------------------

	Predicate Information (identified by operation id):
	---------------------------------------------------

	   2 - access("O"."ADR_ID"="A"."ADRK_1_ID")
	   3 - filter("A"."ADRK_1_ID"<=100)
	   4 - filter("O"."ADR_ID"<=100)

	Note
	-----
	   - outline "SYS_OUTLINE_11040920355037212" used for this statement
*/



-- Pobieramy informacje o uzyciu scenariuszy aby sie dodatkowo upewnic czy zostal uzyty nasz scenariusz
SELECT name, category, used FROM user_outlines;
/*	
	NAME                           CATEGORY                       USED
	------------------------------ ------------------------------ ----------
	SCENARIUSZ_2                   MOJE_SCENARIUSZE               USED
	SCENARIUSZ_3                   MOJE_SCENARIUSZE               USED
	SYS_OUTLINE_11040920355037212  MOJE_SCENARIUSZE_DBMS_OUTLN    USED
	SCENARIUSZ_1                   MOJE_SCENARIUSZE               USED
*/


-- wyłączamy uzycie scenariuszy
ALTER SESSION SET use_stored_outlines=FALSE;


-- Kasuje scenariusze z danej kategorii
EXEC DBMS_OUTLN.DROP_BY_CAT('MOJE_SCENARIUSZE_DBMS_OUTLN');






-- ####################################################################################################


-- # -------------------------------------------------

show error;

COMMIT;