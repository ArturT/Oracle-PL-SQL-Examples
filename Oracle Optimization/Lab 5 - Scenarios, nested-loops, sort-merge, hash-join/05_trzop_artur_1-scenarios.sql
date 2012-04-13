-- ##################################################
--
--	Bazy danych 
-- 	2011 Copyright (c) Artur Trzop 12K2
--	Script v. 5.0.0
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

-- Polecenie do kasowania scenariuszy
-- DROP OUTLINE nazwa_scenariusza;


-- Nie rejestrujemy scenariuszy
ALTER SESSION SET CREATE_STORED_OUTLINES = FALSE;



-- ####################################################################################################




PROMPT ######################################################
PROMPT ###
PROMPT ### SCENARIUSZ_1:
PROMPT ###
PROMPT ######################################################


-- Zapytanie liczy osoby z Krakowa
CREATE OR REPLACE OUTLINE SCENARIUSZ_1
FOR CATEGORY MOJE_SCENARIUSZE ON
SELECT count(*) 
FROM OSOBY O LEFT JOIN ADRES_POCZTY A ON O.ADR_ID = A.ADRK_1_ID 
WHERE A.ADR_MIASTO = 'Kraków';
  
  
-- sprawdzamy liste scenariuszy. (Można też pobrać pole: sql_text)
SELECT name, category FROM user_outlines;
/*
	NAME                 CATEGORY
	-------------------- --------------------
	SCENARIUSZ_1         MOJE_SCENARIUSZE
*/


-- Sprawdzamy aktualny plan wykonania
/*
	Uzyty zostanie nested-loops.
*/
set timing on;
set autotrace traceonly explain
	SELECT count(*) 
	FROM OSOBY O LEFT JOIN ADRES_POCZTY A ON O.ADR_ID = A.ADRK_1_ID 
	WHERE A.ADR_MIASTO = 'Kraków';
set autotrace off
set timing off;


-- Zmieniamy parametry sesji tak aby wymusic hash-join
ALTER SESSION SET OPTIMIZER_INDEX_COST_ADJ=10000; 
ALTER SESSION SET OPTIMIZER_INDEX_CACHING=1;
ALTER SESSION SET OPTIMIZER_MODE=ALL_ROWS;


-- Sprawdzamy czy faktycznie zostanie uzyty hash-join
/*
	Zgadza się plan przewiduje uzycie hash-join
*/
set timing on;
set autotrace traceonly explain
	SELECT count(*) 
	FROM OSOBY O LEFT JOIN ADRES_POCZTY A ON O.ADR_ID = A.ADRK_1_ID 
	WHERE A.ADR_MIASTO = 'Kraków';
set autotrace off
set timing off;



-- Włączamy użycie scenariuszy MOJE_SCENARIUSZE
ALTER SESSION SET use_stored_outlines=MOJE_SCENARIUSZE;


-- Pobieramy informacje o uzyciu scenariuszy
SELECT name, category, used FROM user_outlines;
/*
	Aktualnie scenariusz nie był uzywany.

	NAME                 CATEGORY             USED
	-------------------- -------------------- ----------
	SCENARIUSZ_1         MOJE_SCENARIUSZE     UNUSED
*/


-- Wykonujemy zapytanie co spowoduje uzycie scenariusza pasujacego do niego
set timing on;
set autotrace traceonly explain
	SELECT count(*) 
	FROM OSOBY O LEFT JOIN ADRES_POCZTY A ON O.ADR_ID = A.ADRK_1_ID 
	WHERE A.ADR_MIASTO = 'Kraków';
set autotrace off
set timing off;
/*
	Użyto nested-loops mimo że parametry sesji podpowiadały użycie hash-join.
	Został użyty scenariusz

	|   2 |   NESTED LOOPS      |                   |  7887 |   154K|  3245   (2)| 0


	Note
	-----
	   - outline "SCENARIUSZ_1" used for this statement
*/


-- Pobieramy informacje o uzyciu scenariuszy aby sie dodatkowo upewnic czy zostal uzyty nasz scenariusz
SELECT name, category, used FROM user_outlines;
/*	
	NAME                 CATEGORY             USED
	-------------------- -------------------- ----------
	SCENARIUSZ_1         MOJE_SCENARIUSZE     USED
*/

-- wyłączamy uzycie scenariuszy
ALTER SESSION SET use_stored_outlines=FALSE;





-- ####################################################################################################



PROMPT ######################################################
PROMPT ###
PROMPT ### SCENARIUSZ_2:
PROMPT ###
PROMPT ######################################################

-- Aktualnie parametry sesji sa takie aby wymusic hash-join
ALTER SESSION SET OPTIMIZER_INDEX_COST_ADJ=10000; 
ALTER SESSION SET OPTIMIZER_INDEX_CACHING=1;
ALTER SESSION SET OPTIMIZER_MODE=ALL_ROWS;


/*
	Zapytanie pobiera kobiety z Krakowa o imieniu na literę S i urodzone po roku '80
*/
CREATE OR REPLACE OUTLINE SCENARIUSZ_2
FOR CATEGORY MOJE_SCENARIUSZE ON
SELECT count(*) 
FROM OSOBY O LEFT JOIN ADRES_POCZTY A ON O.ADR_ID = A.ADRK_1_ID
WHERE O.OSO_PLEC = 'k' AND O.OSO_IMIE LIKE 'S%' AND O.OSO_DATA_URODZENIA >= '1980/01/01' AND A.ADR_MIASTO = 'Kraków';


-- Sprawdzamy aktualny plan wykonania
/*
	Uzyty zostanie hash-join.
*/
set timing on;
set autotrace traceonly explain
	SELECT count(*) 
	FROM OSOBY O LEFT JOIN ADRES_POCZTY A ON O.ADR_ID = A.ADRK_1_ID
	WHERE O.OSO_PLEC = 'k' AND O.OSO_IMIE LIKE 'S%' AND O.OSO_DATA_URODZENIA >= '1980/01/01' AND A.ADR_MIASTO = 'Kraków';
set autotrace off
set timing off;
/*
	### Zostanie uzyty hash-join. Nie wykorzystano indexow! Czas zapytania ~4s

	Execution Plan
	----------------------------------------------------------
	Plan hash value: 3001107673

	------------------------------------------------------------------------------------
	| Id  | Operation           | Name         | Rows  | Bytes | Cost (%CPU)| Time     |
	------------------------------------------------------------------------------------
	|   0 | SELECT STATEMENT    |              |     1 |    38 |  2752   (5)| 00:00:34 |
	|   1 |  SORT AGGREGATE     |              |     1 |    38 |            |          |
	|*  2 |   HASH JOIN         |              |    41 |  1558 |  2752   (5)| 00:00:34 |
	|*  3 |    TABLE ACCESS FULL| ADRES_POCZTY |    16 |   256 |     5   (0)| 00:00:01 |
	|*  4 |    TABLE ACCESS FULL| OSOBY        |  4679 |   100K|  2746   (5)| 00:00:33 |
	------------------------------------------------------------------------------------

	Predicate Information (identified by operation id):
	---------------------------------------------------

	   2 - access("O"."ADR_ID"="A"."ADRK_1_ID")
	   3 - filter("A"."ADR_MIASTO"='Krak?w')
	   4 - filter("O"."OSO_IMIE" LIKE 'S%' AND
				  "O"."OSO_DATA_URODZENIA">='1980/01/01' AND "O"."OSO_PLEC"='k')
*/




-- Zmieniamy parametry sesji tak aby wymusic nested-loops
ALTER SESSION SET OPTIMIZER_INDEX_COST_ADJ=50; 
ALTER SESSION SET OPTIMIZER_INDEX_CACHING=50;
ALTER SESSION SET OPTIMIZER_MODE=FIRST_ROWS;



-- Sprawdzamy czy faktycznie zostanie uzyty nested-loops
/*
	Plan nie przewiduje uzycie nested-loops ale za to wykorzysta indexy i kilka hash-join
*/
set timing on;
set autotrace traceonly explain
	SELECT count(*) 
	FROM OSOBY O LEFT JOIN ADRES_POCZTY A ON O.ADR_ID = A.ADRK_1_ID
	WHERE O.OSO_PLEC = 'k' AND O.OSO_IMIE LIKE 'S%' AND O.OSO_DATA_URODZENIA >= '1980/01/01' AND A.ADR_MIASTO = 'Kraków';
set autotrace off
set timing off;
/*
	### Zapytanie wykona sie wolniej. ~19s

	Execution Plan
	----------------------------------------------------------
	Plan hash value: 1569249447

	--------------------------------------------------------------------------------------------------
	| Id  | Operation                | Name                  | Rows  | Bytes | Cost (%CPU)| Time     |
	--------------------------------------------------------------------------------------------------
	|   0 | SELECT STATEMENT         |                       |     1 |    38 |  1974   (4)| 00:00:24 |
	|   1 |  SORT AGGREGATE          |                       |     1 |    38 |            |          |
	|*  2 |   HASH JOIN              |                       |    41 |  1558 |  1974   (4)| 00:00:24 |
	|*  3 |    VIEW                  | index$_join$_002      |    16 |   256 |     5  (20)| 00:00:01 |
	|*  4 |     HASH JOIN            |                       |       |       |            |          |
	|*  5 |      INDEX RANGE SCAN    | IX_ADR_MIASTO         |    16 |   256 |     1   (0)| 00:00:01 |
	|   6 |      INDEX FAST FULL SCAN| CSR_PK_ADRES_POCZTY   |    16 |   256 |     3   (0)| 00:00:01 |
	|*  7 |    VIEW                  | index$_join$_001      |  4679 |   100K|  1969   (4)| 00:00:24 |
	|*  8 |     HASH JOIN            |                       |       |       |            |          |
	|*  9 |      HASH JOIN           |                       |       |       |            |          |
	|* 10 |       INDEX RANGE SCAN   | IX_OSO_IMIE_OSO_PLEC  |  4679 |   100K|   211   (4)| 00:00:03 |
	|* 11 |       INDEX RANGE SCAN   | IX_OSO_DATA_URODZENIA |  4679 |   100K|   958   (5)| 00:00:12 |
	|  12 |      INDEX FAST FULL SCAN| IX_CSR_FK_OSO_ADR     |  4679 |   100K|  1557   (2)| 00:00:19 |
	--------------------------------------------------------------------------------------------------

	Predicate Information (identified by operation id):
	---------------------------------------------------

	   2 - access("O"."ADR_ID"="A"."ADRK_1_ID")
	   3 - filter("A"."ADR_MIASTO"='Krak?w')
	   4 - access(ROWID=ROWID)
	   5 - access("A"."ADR_MIASTO"='Krak?w')
	   7 - filter("O"."OSO_IMIE" LIKE 'S%' AND "O"."OSO_DATA_URODZENIA">='1980/01/01' AND
				  "O"."OSO_PLEC"='k')
	   8 - access(ROWID=ROWID)
	   9 - access(ROWID=ROWID)
	  10 - access("O"."OSO_IMIE" LIKE 'S%' AND "O"."OSO_PLEC"='k')
	  11 - access("O"."OSO_DATA_URODZENIA">='1980/01/01')
*/






-- Włączamy użycie scenariuszy MOJE_SCENARIUSZE
ALTER SESSION SET use_stored_outlines=MOJE_SCENARIUSZE;


-- Pobieramy informacje o uzyciu scenariuszy
SELECT name, category, used FROM user_outlines;
/*
	Aktualnie SCENARIUSZ_2 nie był uzywany.

	NAME                 CATEGORY             USED
	-------------------- -------------------- ----------
	SCENARIUSZ_1         MOJE_SCENARIUSZE     USED
	SCENARIUSZ_2         MOJE_SCENARIUSZE     UNUSED
*/


-- Wykonujemy zapytanie co spowoduje uzycie scenariusza pasujacego do niego
set timing on;
set autotrace traceonly explain
	SELECT count(*) 
	FROM OSOBY O LEFT JOIN ADRES_POCZTY A ON O.ADR_ID = A.ADRK_1_ID
	WHERE O.OSO_PLEC = 'k' AND O.OSO_IMIE LIKE 'S%' AND O.OSO_DATA_URODZENIA >= '1980/01/01' AND A.ADR_MIASTO = 'Kraków';
set autotrace off
set timing off;
/*
	### Został użyty SCENARIUSZ_2
		
	Execution Plan
	----------------------------------------------------------
	Plan hash value: 3001107673

	------------------------------------------------------------------------------------
	| Id  | Operation           | Name         | Rows  | Bytes | Cost (%CPU)| Time     |
	------------------------------------------------------------------------------------
	|   0 | SELECT STATEMENT    |              |     1 |    38 |  2752   (5)| 00:00:34 |
	|   1 |  SORT AGGREGATE     |              |     1 |    38 |            |          |
	|*  2 |   HASH JOIN         |              |    41 |  1558 |  2752   (5)| 00:00:34 |
	|*  3 |    TABLE ACCESS FULL| ADRES_POCZTY |    16 |   256 |     5   (0)| 00:00:01 |
	|*  4 |    TABLE ACCESS FULL| OSOBY        |  4679 |   100K|  2746   (5)| 00:00:33 |
	------------------------------------------------------------------------------------

	Predicate Information (identified by operation id):
	---------------------------------------------------

	   2 - access("O"."ADR_ID"="A"."ADRK_1_ID")
	   3 - filter("A"."ADR_MIASTO"='Krak?w')
	   4 - filter("O"."OSO_IMIE" LIKE 'S%' AND
				  "O"."OSO_DATA_URODZENIA">='1980/01/01' AND "O"."OSO_PLEC"='k')

	Note
	-----
	   - outline "SCENARIUSZ_2" used for this statement
*/




-- Pobieramy informacje o uzyciu scenariuszy aby sie dodatkowo upewnic czy zostal uzyty nasz scenariusz
SELECT name, category, used FROM user_outlines;
/*	
	NAME                 CATEGORY             USED
	-------------------- -------------------- ----------
	SCENARIUSZ_2         MOJE_SCENARIUSZE     USED
	SCENARIUSZ_1         MOJE_SCENARIUSZE     USED
*/

-- wyłączamy uzycie scenariuszy
ALTER SESSION SET use_stored_outlines=FALSE;



-- ####################################################################################################



--### Zapytania z podzapytaniami
PROMPT ######################################################
PROMPT ###
PROMPT ### Zapytania z podzapytaniami
PROMPT ### SCENARIUSZ_3:
PROMPT ###
PROMPT ######################################################


-- Aktualne parametry sesji sa takie aby wymusic nested-loops
ALTER SESSION SET OPTIMIZER_INDEX_COST_ADJ=50; 
ALTER SESSION SET OPTIMIZER_INDEX_CACHING=50;
ALTER SESSION SET OPTIMIZER_MODE=FIRST_ROWS;


/*
	### Pobieramy ilosc kobiet przypisanych do trzech najwiekszych urzędów pocztowych w Polsce 
	(najwiekszych tzn tych do ktorych jest najwiecej osob zapisanych)
*/
CREATE OR REPLACE OUTLINE SCENARIUSZ_3
FOR CATEGORY MOJE_SCENARIUSZE ON
SELECT COUNT(*) FROM OSOBY WHERE OSO_PLEC = 'k' AND ADR_ID IN (
	SELECT * FROM (
		SELECT AA.ADR_ID FROM (
			SELECT O.ADR_ID, COUNT(O.ADR_ID) ILOSC_MIESZKANCOW 
			FROM OSOBY O LEFT JOIN ADRES_POCZTY A ON O.ADR_ID = A.ADRK_1_ID 
			GROUP BY O.ADR_ID 
			ORDER BY COUNT(O.ADR_ID) DESC 
		) AA 
		WHERE ROWNUM<=3 ORDER BY AA.ILOSC_MIESZKANCOW DESC
	)
);

/*
-- proste sprawdzenie ile kobiet miesza w tych urzedach
SELECT COUNT(*) FROM OSOBY WHERE OSO_PLEC = 'k' AND ADR_ID IN (7, 18, 3);

-- pobranie miast w ktorych sa te urzedy oraz ich kodow pocztowych
SELECT ADR_MIASTO, ADR_KOD_POCZTOWY	FROM ADRES_POCZTY WHERE ADRK_1_ID IN (7, 18, 3);
*/


-- Sprawdzamy aktualny plan wykonania
/*
	Uzyty zostanie nested-loops.
*/
set timing on;
set autotrace traceonly explain
	SELECT COUNT(*) FROM OSOBY WHERE OSO_PLEC = 'k' AND ADR_ID IN (
		SELECT * FROM (
			SELECT AA.ADR_ID FROM (
				SELECT O.ADR_ID, COUNT(O.ADR_ID) ILOSC_MIESZKANCOW 
				FROM OSOBY O LEFT JOIN ADRES_POCZTY A ON O.ADR_ID = A.ADRK_1_ID 
				GROUP BY O.ADR_ID 
				ORDER BY COUNT(O.ADR_ID) DESC 
			) AA 
			WHERE ROWNUM<=3 ORDER BY AA.ILOSC_MIESZKANCOW DESC
		)
	);
set autotrace off
set timing off;
/*
	Execution Plan
	----------------------------------------------------------
	Plan hash value: 4127924172

	------------------------------------------------------------------------------------------------------
	| Id  | Operation                      | Name                | Rows  | Bytes | Cost (%CPU)| Time     |
	------------------------------------------------------------------------------------------------------
	|   0 | SELECT STATEMENT               |                     |     1 |    19 |  1655  (16)| 00:00:20 |
	|   1 |  SORT AGGREGATE                |                     |     1 |    19 |            |          |
	|*  2 |   TABLE ACCESS BY INDEX ROWID  | OSOBY               |   270 |  1620 |   246   (0)| 00:00:03 |
	|   3 |    NESTED LOOPS                |                     |   810 | 15390 |  1655  (16)| 00:00:20 |
	|   4 |     VIEW                       |                     |     3 |    39 |   915  (28)| 00:00:11 |
	|   5 |      SORT ORDER BY             |                     |     3 |    78 |   915  (28)| 00:00:11 |
	|*  6 |       COUNT STOPKEY            |                     |       |       |            |          |
	|   7 |        VIEW                    |                     |  2000 | 52000 |   915  (28)| 00:00:11 |
	|*  8 |         SORT ORDER BY STOPKEY  |                     |  2000 | 16000 |   915  (28)| 00:00:11 |
	|   9 |          HASH GROUP BY         |                     |  2000 | 16000 |   915  (28)| 00:00:11 |
	|* 10 |           HASH JOIN RIGHT OUTER|                     |  1001K|  7825K|   718   (8)| 00:00:09 |
	|  11 |            INDEX FULL SCAN     | CSR_PK_ADRES_POCZTY |  2000 |  8000 |     3   (0)| 00:00:01 |
	|  12 |            INDEX FAST FULL SCAN| IX_CSR_FK_OSO_ADR   |  1001K|  3912K|   693   (5)| 00:00:09 |
	|* 13 |     INDEX RANGE SCAN           | IX_CSR_FK_OSO_ADR   |   501 |       |     1   (0)| 00:00:01 |
	------------------------------------------------------------------------------------------------------

	Predicate Information (identified by operation id):
	---------------------------------------------------

	   2 - filter("OSO_PLEC"='k')
	   6 - filter(ROWNUM<=3)
	   8 - filter(ROWNUM<=3)
	  10 - access("O"."ADR_ID"="A"."ADRK_1_ID"(+))
	  13 - access("ADR_ID"="from$_subquery$_002"."ADR_ID")
*/



-- Zmieniamy parametry sesji tak aby wymusic hash-join
ALTER SESSION SET OPTIMIZER_INDEX_COST_ADJ=10000; 
ALTER SESSION SET OPTIMIZER_INDEX_CACHING=1;
ALTER SESSION SET OPTIMIZER_MODE=ALL_ROWS;


-- Sprawdzamy czy faktycznie zostanie uzyty hash-join
/*
	Zgadza się plan przewiduje uzycie hash-join
*/
set timing on;
set autotrace traceonly explain
	SELECT COUNT(*) FROM OSOBY WHERE OSO_PLEC = 'k' AND ADR_ID IN (
		SELECT * FROM (
			SELECT AA.ADR_ID FROM (
				SELECT O.ADR_ID, COUNT(O.ADR_ID) ILOSC_MIESZKANCOW 
				FROM OSOBY O LEFT JOIN ADRES_POCZTY A ON O.ADR_ID = A.ADRK_1_ID 
				GROUP BY O.ADR_ID 
				ORDER BY COUNT(O.ADR_ID) DESC 
			) AA 
			WHERE ROWNUM<=3 ORDER BY AA.ILOSC_MIESZKANCOW DESC
		)
	);
set autotrace off
set timing off;
/*
	Execution Plan
	----------------------------------------------------------
	Plan hash value: 3751798329

	-----------------------------------------------------------------------------------------------------
	| Id  | Operation                     | Name                | Rows  | Bytes | Cost (%CPU)| Time     |
	-----------------------------------------------------------------------------------------------------
	|   0 | SELECT STATEMENT              |                     |     1 |    19 |  3703  (11)| 00:00:45 |
	|   1 |  SORT AGGREGATE               |                     |     1 |    19 |            |          |
	|*  2 |   HASH JOIN                   |                     |   810 | 15390 |  3703  (11)| 00:00:45 |
	|   3 |    VIEW                       |                     |     3 |    39 |   916  (28)| 00:00:11 |
	|   4 |     SORT ORDER BY             |                     |     3 |    78 |   916  (28)| 00:00:11 |
	|*  5 |      COUNT STOPKEY            |                     |       |       |            |          |
	|   6 |       VIEW                    |                     |  2000 | 52000 |   916  (28)| 00:00:11 |
	|*  7 |        SORT ORDER BY STOPKEY  |                     |  2000 | 16000 |   916  (28)| 00:00:11 |
	|   8 |         HASH GROUP BY         |                     |  2000 | 16000 |   916  (28)| 00:00:11 |
	|*  9 |          HASH JOIN RIGHT OUTER|                     |  1001K|  7825K|   719   (8)| 00:00:09 |
	|  10 |           INDEX FAST FULL SCAN| CSR_PK_ADRES_POCZTY |  2000 |  8000 |     3   (0)| 00:00:01 |
	|  11 |           INDEX FAST FULL SCAN| IX_CSR_FK_OSO_ADR   |  1001K|  3912K|   693   (5)| 00:00:09 |
	|* 12 |    TABLE ACCESS FULL          | OSOBY               |   540K|  3165K|  2775   (6)| 00:00:34 |
	-----------------------------------------------------------------------------------------------------

	Predicate Information (identified by operation id):
	---------------------------------------------------

	   2 - access("ADR_ID"="from$_subquery$_002"."ADR_ID")
	   5 - filter(ROWNUM<=3)
	   7 - filter(ROWNUM<=3)
	   9 - access("O"."ADR_ID"="A"."ADRK_1_ID"(+))
	  12 - filter("OSO_PLEC"='k')
*/


-- Włączamy użycie scenariuszy MOJE_SCENARIUSZE
ALTER SESSION SET use_stored_outlines=MOJE_SCENARIUSZE;


-- Pobieramy informacje o uzyciu scenariuszy
SELECT name, category, used FROM user_outlines;
/*
	Aktualnie scenariusz nie był uzywany.

	NAME                 CATEGORY             USED
	-------------------- -------------------- ----------
	SCENARIUSZ_3         MOJE_SCENARIUSZE     UNUSED
	SCENARIUSZ_1         MOJE_SCENARIUSZE     USED
	SCENARIUSZ_2         MOJE_SCENARIUSZE     USED
*/


-- Wykonujemy zapytanie co spowoduje uzycie scenariusza pasujacego do niego
set timing on;
set autotrace traceonly explain
	SELECT COUNT(*) FROM OSOBY WHERE OSO_PLEC = 'k' AND ADR_ID IN (
		SELECT * FROM (
			SELECT AA.ADR_ID FROM (
				SELECT O.ADR_ID, COUNT(O.ADR_ID) ILOSC_MIESZKANCOW 
				FROM OSOBY O LEFT JOIN ADRES_POCZTY A ON O.ADR_ID = A.ADRK_1_ID 
				GROUP BY O.ADR_ID 
				ORDER BY COUNT(O.ADR_ID) DESC 
			) AA 
			WHERE ROWNUM<=3 ORDER BY AA.ILOSC_MIESZKANCOW DESC
		)
	);
set autotrace off
set timing off;
/*
	Użyto nested-loops mimo że parametry sesji podpowiadały użycie hash-join.
	Został użyty scenariusz

	Execution Plan
	----------------------------------------------------------
	Plan hash value: 4127924172

	------------------------------------------------------------------------------------------------------
	| Id  | Operation                      | Name                | Rows  | Bytes | Cost (%CPU)| Time     |
	------------------------------------------------------------------------------------------------------
	|   0 | SELECT STATEMENT               |                     |     1 |    19 |  1655  (16)| 00:00:20 |
	|   1 |  SORT AGGREGATE                |                     |     1 |    19 |            |          |
	|*  2 |   TABLE ACCESS BY INDEX ROWID  | OSOBY               |   270 |  1620 |   246   (0)| 00:00:03 |
	|   3 |    NESTED LOOPS                |                     |   810 | 15390 |  1655  (16)| 00:00:20 |
	|   4 |     VIEW                       |                     |     3 |    39 |   915  (28)| 00:00:11 |
	|   5 |      SORT ORDER BY             |                     |     3 |    78 |   915  (28)| 00:00:11 |
	|*  6 |       COUNT STOPKEY            |                     |       |       |            |          |
	|   7 |        VIEW                    |                     |  2000 | 52000 |   915  (28)| 00:00:11 |
	|*  8 |         SORT ORDER BY STOPKEY  |                     |  2000 | 16000 |   915  (28)| 00:00:11 |
	|   9 |          HASH GROUP BY         |                     |  2000 | 16000 |   915  (28)| 00:00:11 |
	|* 10 |           HASH JOIN RIGHT OUTER|                     |  1001K|  7825K|   718   (8)| 00:00:09 |
	|  11 |            INDEX FULL SCAN     | CSR_PK_ADRES_POCZTY |  2000 |  8000 |     3   (0)| 00:00:01 |
	|  12 |            INDEX FAST FULL SCAN| IX_CSR_FK_OSO_ADR   |  1001K|  3912K|   693   (5)| 00:00:09 |
	|* 13 |     INDEX RANGE SCAN           | IX_CSR_FK_OSO_ADR   |   501 |       |     1   (0)| 00:00:01 |
	------------------------------------------------------------------------------------------------------

	Predicate Information (identified by operation id):
	---------------------------------------------------

	   2 - filter("OSO_PLEC"='k')
	   6 - filter(ROWNUM<=3)
	   8 - filter(ROWNUM<=3)
	  10 - access("O"."ADR_ID"="A"."ADRK_1_ID"(+))
	  13 - access("ADR_ID"="from$_subquery$_002"."ADR_ID")

	Note
	-----
	   - outline "SCENARIUSZ_3" used for this statement	
*/	


-- Pobieramy informacje o uzyciu scenariuszy aby sie dodatkowo upewnic czy zostal uzyty nasz scenariusz
SELECT name, category, used FROM user_outlines;
/*	
	NAME                 CATEGORY             USED
	-------------------- -------------------- ----------
	SCENARIUSZ_3         MOJE_SCENARIUSZE     USED
	SCENARIUSZ_1         MOJE_SCENARIUSZE     USED
	SCENARIUSZ_2         MOJE_SCENARIUSZE     USED
*/


-- wyłączamy uzycie scenariuszy
ALTER SESSION SET use_stored_outlines=FALSE;



-- ####################################################################################################



--### http://www.stanford.edu/dept/itss/docs/oracle/10g/appdev.101/b10802/d_outled.htm
PROMPT ######################################################
PROMPT ###
PROMPT ### DBMS.OUTLN_EDIT (Scenariusze prywatne)
PROMPT ###
PROMPT ######################################################


-- Aktualnie parametry sesji sa takie aby wymusic hash-join
ALTER SESSION SET OPTIMIZER_INDEX_COST_ADJ=10000; 
ALTER SESSION SET OPTIMIZER_INDEX_CACHING=1;
ALTER SESSION SET OPTIMIZER_MODE=ALL_ROWS;

-- This procedure creates outline editing tables in calling a user's schema.
EXEC DBMS_OUTLN_EDIT.CREATE_EDIT_TABLES;


-- Tworzymy prywatny scenariusz na podstawie scenariusza 1
CREATE OR REPLACE PRIVATE OUTLINE SCENARIUSZ_PRYWATNY_1 FROM SCENARIUSZ_1;


-- Sprawdzamy plan wykonania przed włączeniem prywatnych scenariuszy
/*
	Uzyty zostanie hash-join.
*/
set timing on;
set autotrace traceonly explain
	SELECT count(*) 
	FROM OSOBY O LEFT JOIN ADRES_POCZTY A ON O.ADR_ID = A.ADRK_1_ID 
	WHERE A.ADR_MIASTO = 'Kraków';
set autotrace off
set timing off;
/*
	Execution Plan
	----------------------------------------------------------
	Plan hash value: 389548803

	--------------------------------------------------------------------------------------------
	| Id  | Operation              | Name              | Rows  | Bytes | Cost (%CPU)| Time     |
	--------------------------------------------------------------------------------------------
	|   0 | SELECT STATEMENT       |                   |     1 |    20 |   721   (8)| 00:00:09 |
	|   1 |  SORT AGGREGATE        |                   |     1 |    20 |            |          |
	|*  2 |   HASH JOIN            |                   |  7887 |   154K|   721   (8)| 00:00:09 |
	|*  3 |    TABLE ACCESS FULL   | ADRES_POCZTY      |    16 |   256 |     5   (0)| 00:00:01 |
	|   4 |    INDEX FAST FULL SCAN| IX_CSR_FK_OSO_ADR |  1001K|  3912K|   693   (5)| 00:00:09 |
	--------------------------------------------------------------------------------------------

	Predicate Information (identified by operation id):
	---------------------------------------------------

	   2 - access("O"."ADR_ID"="A"."ADRK_1_ID")
	   3 - filter("A"."ADR_MIASTO"='Krak?w')
*/



-- Włączamy prywatne scenariusze
ALTER SESSION SET use_private_outlines=TRUE;


-- Sprawdzamy aktualny plan wykonania
/*
	Uzyty zostanie nested-loops zgodnie ze scenariuszem prywatnym
*/
set timing on;
set autotrace traceonly explain
	SELECT count(*) 
	FROM OSOBY O LEFT JOIN ADRES_POCZTY A ON O.ADR_ID = A.ADRK_1_ID 
	WHERE A.ADR_MIASTO = 'Kraków';
set autotrace off
set timing off;
/*
	Execution Plan
	----------------------------------------------------------
	Plan hash value: 1904654162

	-----------------------------------------------------------------------------------------
	| Id  | Operation           | Name              | Rows  | Bytes | Cost (%CPU)| Time     |
	-----------------------------------------------------------------------------------------
	|   0 | SELECT STATEMENT    |                   |     1 |    20 |  3245   (2)| 00:00:39 |
	|   1 |  SORT AGGREGATE     |                   |     1 |    20 |            |          |
	|   2 |   NESTED LOOPS      |                   |  7887 |   154K|  3245   (2)| 00:00:39 |
	|*  3 |    TABLE ACCESS FULL| ADRES_POCZTY      |    16 |   256 |     5   (0)| 00:00:01 |
	|*  4 |    INDEX RANGE SCAN | IX_CSR_FK_OSO_ADR |   501 |  2004 |   203   (2)| 00:00:03 |
	-----------------------------------------------------------------------------------------

	Predicate Information (identified by operation id):
	---------------------------------------------------

	   3 - filter("A"."ADR_MIASTO"='Krak?w')
	   4 - access("O"."ADR_ID"="A"."ADRK_1_ID")

	Note
	-----
	   - outline "SCENARIUSZ_PRYWATNY_1" used for this statement
*/



-- Pobranie informacji o wskazówkach ktore mogą byc uzyte
COLUMN hint_text FORMAT A55;
COLUMN OL_NAME FORMAT A20;
SELECT OL_NAME, HINT#, hint_text FROM ol$hints 
WHERE OL_NAME LIKE '%SCENARIUSZ_PRYWATNY_1%';
/*
	SQL> SELECT OL_NAME, HINT#, hint_text FROM ol$hints
		2  WHERE OL_NAME LIKE '%SCENARIUSZ_PRYWATNY_1%';

	OL_NAME                   HINT# HINT_TEXT
	-------------------- ---------- -------------------------------------------------------
	SCENARIUSZ_PRYWATNY_          1 LEADING(@"SEL$3BAA97A7" "A"@"SEL$1" "O"@"SEL$2")
	1

	SCENARIUSZ_PRYWATNY_          2 OUTLINE(@"SEL$1")
	1

	SCENARIUSZ_PRYWATNY_          3 OUTLINE(@"SEL$2")
	1

	SCENARIUSZ_PRYWATNY_          4 OUTLINE(@"SEL$3")
	1

	OL_NAME                   HINT# HINT_TEXT
	-------------------- ---------- -------------------------------------------------------

	SCENARIUSZ_PRYWATNY_          5 OUTLINE(@"SEL$58A6D7F6")
	1

	SCENARIUSZ_PRYWATNY_          6 OUTLINE(@"SEL$23D58506")
	1

	SCENARIUSZ_PRYWATNY_          7 OUTLINE_LEAF(@"SEL$3BAA97A7")
	1

	SCENARIUSZ_PRYWATNY_          8 OPTIMIZER_FEATURES_ENABLE('10.2.0.1')

	OL_NAME                   HINT# HINT_TEXT
	-------------------- ---------- -------------------------------------------------------
	1

	SCENARIUSZ_PRYWATNY_          9 USE_NL(@"SEL$3BAA97A7" "O"@"SEL$2")
	1

	SCENARIUSZ_PRYWATNY_         10 IGNORE_OPTIM_EMBEDDED_HINTS
	1

	SCENARIUSZ_PRYWATNY_         11 ALL_ROWS
	1


	OL_NAME                   HINT# HINT_TEXT
	-------------------- ---------- -------------------------------------------------------
	SCENARIUSZ_PRYWATNY_         12 MERGE(@"SEL$58A6D7F6")
	1

	SCENARIUSZ_PRYWATNY_         13 ELIMINATE_OUTER_JOIN(@"SEL$3")
	1

	SCENARIUSZ_PRYWATNY_         14 MERGE(@"SEL$1")
	1

	SCENARIUSZ_PRYWATNY_         15 FULL(@"SEL$3BAA97A7" "A"@"SEL$1")
	1

	OL_NAME                   HINT# HINT_TEXT
	-------------------- ---------- -------------------------------------------------------

	SCENARIUSZ_PRYWATNY_         16 INDEX(@"SEL$3BAA97A7" "O"@"SEL$2" ("OSOBY"."ADR_ID"))
	1
*/





ALTER SESSION SET use_private_outlines=FALSE;


-- This procedure drops outline editing tables in calling the user's schema.
EXEC DBMS_OUTLN_EDIT.DROP_EDIT_TABLES;



-- ####################################################################################################


-- # -------------------------------------------------

show error;

COMMIT;