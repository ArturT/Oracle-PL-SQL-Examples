-- ##################################################
--
--	Bazy danych 
-- 	2011 Copyright (c) Artur Trzop 12K2
--	Script v. 3.0.0
--
-- ##################################################

-- w³¹czamy opcje wyœwietlania komunikatów przy pomocy DBMS_OUTPUT.PUT_LINE();
set serveroutput on;
set feedback on;
set timing on; -- w³¹cz wyœwietlanie czasu wykonania zapytania

-- wyk.3, str.46 ustawianie domyslnego sposobu wyswietlania daty
ALTER SESSION SET NLS_DATE_FORMAT = 'yyyy/mm/dd';
--ALTER SESSION SET NLS_DATE_FORMAT = 'yyyy/mm/dd hh24:mi:ss';

CLEAR SCREEN;
PROMPT ----------------------------------------------;
PROMPT Czyszczenie ekranu;
PROMPT ----------------------------------------------;
PROMPT ;



/*
	########## Przed dodaniem indexow

	# 1 #---- Rozne metody obliczania selektywnosci dla zapytan ---
	# Zapytanie 1 - Duza selektywnosc
	+ Pobranych mezczyzn[!] o imieniu[!] Mateusz: 1491 trwalo: +00 00:00:00.108016
	- Selektywnosc jako stosunek wystapien danej wartosci do ilosci wszystkich
	wierszy w tabeli:  000,149100%
	- Selektywnosc unikatowych imion w tabeli:  000,168350%. Jest to
	prawdopodobienstwo wystapienie danego imienia ale tylko przy zalozeniu ze
	wystepuja rownomiernie.
	- Selektywnosc calkowita imion:  000,171597622600%
	.
	.
	# Zapytanie 2 - Bardzo duza selektywnosc
	+ Pobranych osob o imieniu Marek[!] z Krakowa[!]: 73 trwalo: +00 00:00:00.070625
	Selektywnosc dla JOIN:  000,0514668000%
	.
	._______.
	.
	# Zapytanie 3 - Mala selektywnosc
	+ Pobranych kobiet[!] z Krakowa[!]: 9862 trwalo: +00 00:00:00.066636
	Selektywnosc dla JOIN:  000,0514668000%
	.
	.
	# Zapytanie 4 - Bardzo mala selektywnosc
	+ Pobranych mezczyzn: 503310 trwalo: +00 00:00:00.165410
	- Selektywnosc jako stosunek wystapien danej wartosci do ilosci wszystkich
	wierszy w tabeli:  050,331000%
	.
	.
	# Zapytanie 5 - Bardzo duza selektywnosc
	+ Kobiety o imieniu na litere S i urodzone po roku 1980 wlacznie: 4893 trwalo:
	+00 00:00:00.151754
	- Selektywnosc jako stosunek wystapien danej wartosci do ilosci wszystkich
	wierszy w tabeli:  000,489300%
	
	
	
	########## Po dodaniu indexow
	# 2 #---- Czas wykonania zapytan po dodaniu indexow ---
	# Zapytanie 1 - Duza selektywnosc
	+ Pobranych mezczyzn[!] o imieniu[!] Mateusz: 1491 trwalo: +00 00:00:00.014680			(wzrost szybkosci o 7 razy)
	- Selektywnosc jako stosunek wystapien danej wartosci do ilosci wszystkich
	wierszy w tabeli:  000,149100%
	- Selektywnosc unikatowych imion w tabeli:  000,168350%. Jest to
	prawdopodobienstwo wystapienie danego imienia ale tylko przy zalozeniu ze
	wystepuja rownomiernie.
	- Selektywnosc calkowita imion:  000,171597622600%
	.
	.
	# Zapytanie 2 - Bardzo duza selektywnosc
	+ Pobranych osob o imieniu Marek[!] z Krakowa[!]: 73 trwalo: +00 00:00:00.067955
	Selektywnosc dla JOIN:  000,0514668000%
	.
	._______.
	.
	# Zapytanie 3 - Mala selektywnosc
	+ Pobranych kobiet[!] z Krakowa[!]: 9862 trwalo: +00 00:00:00.066660
	Selektywnosc dla JOIN:  000,0514668000%
	.
	.
	# Zapytanie 4 - Bardzo mala selektywnosc
	+ Pobranych mezczyzn: 503310 trwalo: +00 00:00:00.115086
	- Selektywnosc jako stosunek wystapien danej wartosci do ilosci wszystkich
	wierszy w tabeli:  050,331000%
	.
	.
	# Zapytanie 5 - Bardzo duza selektywnosc
	+ Kobiety o imieniu na litere S i urodzone po roku 1980 wlacznie: 4893 trwalo: 	+00 00:00:00.037043   		(wzrost szybkosci o 4 razy)
	- Selektywnosc jako stosunek wystapien danej wartosci do ilosci wszystkich
	wierszy w tabeli:  000,489300%
	
*/







-- ##################################################

-- Kasujemy indexy
DROP INDEX IX_OSO_IMIE_OSO_PLEC;
DROP INDEX IX_OSO_IMIE;
DROP INDEX IX_OSO_PLEC;
DROP INDEX IX_OSO_DATA_URODZENIA;
DROP INDEX IX_OSO_PLECIMIEDATAURODZ;
DROP INDEX IX_ADR_MIASTO;


-- ##################################################

-- Ustawiamy 20 urzedow pocztowych z Krakowa
DECLARE
	int1 INTEGER DEFAULT 0;
	licznik INTEGER DEFAULT 20; -- okresla ile urzedow pocztowych bedzie w Krakowie do ktorych beda przypisane osoby
	liczba INTEGER DEFAULT 0;
	los_liczba INTEGER DEFAULT 0;
BEGIN
	
	SAVEPOINT S1;
	
	-- generowanie mieszkañców Krakowa odbêdzie siê tylko gdy jeszcze tego wczeœniej nie robiono
	SELECT count(*) INTO int1 FROM ADRES_POCZTY WHERE ADRK_1_ID <= licznik AND ADR_MIASTO = 'Kraków';
	IF int1 != 20 THEN
	
		-- ustawiamy aby pierwsze 20 rekordow to byly urzedy pocztowe z krakowa
		FOR i IN 1..licznik LOOP
			UPDATE ADRES_POCZTY SET ADR_MIASTO = 'Kraków' WHERE ADRK_1_ID = i;
		END LOOP;
		
		-- ustawiamy aby 10 000 osob bylo mieszkancami Krakowa
		FOR i IN 1..10000 LOOP
			liczba := to_number(TRUNC(dbms_random.value(1,1000000))); -- losujemy jedn¹ z 1mln osob ktora bedzie przypisana do ktoregos urzedu pocztowego w krakowie
			int1 := to_number(TRUNC(dbms_random.value(1,licznik))); -- losujemy id urzedu pocztowego
			UPDATE OSOBY SET ADR_ID = int1 WHERE OSOK_1_ID = liczba;
			
			-- jednej na 100 osob ustawiamy imie na Marek pod warunkiem ze jest mezczyznom
			los_liczba := to_number(TRUNC(dbms_random.value(1,100))); 
			IF los_liczba = 1 THEN		
				UPDATE OSOBY SET OSO_IMIE = 'Marek' WHERE OSOK_1_ID = liczba AND OSO_PLEC = 'm';
			END IF;
			
		END LOOP;
		
		SELECT count(*) INTO int1 FROM OSOBY O LEFT JOIN ADRES_POCZTY A ON O.ADR_ID = A.ADRK_1_ID WHERE O.OSO_IMIE = 'Marek' AND A.ADR_MIASTO = 'Kraków';
		DBMS_OUTPUT.PUT_LINE('Markow z Krakowa: '||int1);
		
	END IF;
		
		
	--ROLLBACK TO SAVEPOINT S1;
	
END;
/

/*
	### str.19	
	SQL> show parameter compatible;
	NAME                                 TYPE        VALUE
	------------------------------------ ----------- ------------------------------
	compatible                           string      10.2.0.1.0
		
	
	### (str.20/wyklad Optymalizacja_cz_I_v1.5) 
	###	ALL_ROWS - z preferencj¹ sort-merge lub hash-join. Jeœli nie ma statystyk dla tabeli to u¿ycie RBO
	SQL> show parameter OPTIMIZER_MODE;	
	NAME                                 TYPE        VALUE
	------------------------------------ ----------- ------------------------------
	optimizer_mode                       string      ALL_ROWS
	
	show parameter OPTIMIZER_MODE;
	ALTER SESSION SET OPTIMIZER_MODE = RULE;
	ALTER SESSION SET OPTIMIZER_MODE = ALL_ROWS;
	
	
	
		
	### str.21. Im wyzsza wartosc tym wzrasta preferencja dla nested-loops	
	SQL> show parameter OPTIMIZER_INDEX_CACHING;
	NAME                                 TYPE        VALUE
	------------------------------------ ----------- ------------------------------
	optimizer_index_caching              integer     0
	
	
	### str.22. Zmniejszenie wartosci powoduje spadek uzycia indexow. Wartosc powyzej 100 wymusza uzycie sort-merge, hash-join	
	SQL> show parameter OPTIMIZER_INDEX_COST_ADJ;
	NAME                                 TYPE        VALUE
	------------------------------------ ----------- ------------------------------
	optimizer_index_cost_adj             integer     100
	SQL>
	
	
	### str.23. Okreœla liczbê bajtów przydzielon¹ dla obszaru sortowania w ramach jednej sesji u¿ytkownika.
	SQL> show parameter SORT_AREA_SIZE;
	NAME                                 TYPE        VALUE
	------------------------------------ ----------- ------------------------------
	sort_area_size                       integer     65536
	SQL>

*/




-- ####################################################################################################

-- Deklaracja Pakietu
CREATE OR REPLACE PACKAGE PACKAGE_SELEKTYWNOSC
IS
	--### Funkcja do pomiaru czasu wykonania zapytania	
	FUNCTION P_LICZ_CZAS_START(StartTime IN TIMESTAMP) RETURN TIMESTAMP;
	FUNCTION P_LICZ_CZAS_END(StartTime IN TIMESTAMP) RETURN VARCHAR2;
	-- Funkcja zwracajaca procentowa selektywnosc dla zlaczonych tabel
	FUNCTION P_SELEKTYWNOSC_DLA_JOIN(Tabela1 IN VARCHAR2, Kolumna1 IN VARCHAR2, Tabela2 IN VARCHAR2, Kolumna2 IN VARCHAR2) RETURN VARCHAR2;
	
	--### Procedury 
	PROCEDURE P_SELEKTYWNOSC_ROZNE_METODY(N IN VARCHAR2);

END;
/	



-- Definicja pakietu
CREATE OR REPLACE PACKAGE BODY PACKAGE_SELEKTYWNOSC
IS
		
	-- +++<<<### START (2 Funkcje) ###>>>++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
	FUNCTION P_LICZ_CZAS_START(StartTime IN TIMESTAMP) RETURN TIMESTAMP
	IS	
		v_return TIMESTAMP(9);
		
	BEGIN
		
		v_return := SYSTIMESTAMP;	
		RETURN v_return;
				
	END P_LICZ_CZAS_START;
		
	FUNCTION P_LICZ_CZAS_END(StartTime IN TIMESTAMP) RETURN VARCHAR2
	IS			
		v_end TIMESTAMP(9);
		v_interval INTERVAL DAY TO SECOND;
	BEGIN				
		
		v_end := SYSTIMESTAMP;    
		v_interval := v_end - StartTime;			
				
		RETURN to_char(v_interval);
				
	END P_LICZ_CZAS_END;
	
	-- +++<<<### END ###>>>+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
	
	
	
	
	-- +++<<<### START ###>>>+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++	
	FUNCTION P_SELEKTYWNOSC_DLA_JOIN(Tabela1 IN VARCHAR2, Kolumna1 IN VARCHAR2, Tabela2 IN VARCHAR2, Kolumna2 IN VARCHAR2) RETURN VARCHAR2
	IS			
		liczba_wierszy_tab1 number(20) DEFAULT 0;
		liczba_null_tab1 number(20) DEFAULT 0;
		liczba_wierszy_tab2 number(20) DEFAULT 0;
		liczba_null_tab2 number(20) DEFAULT 0;
		liczba_unikat_wierszy_tab1 number(20) DEFAULT 0;
		liczba_unikat_wierszy_tab2 number(20) DEFAULT 0;
		wynik number(30,10) DEFAULT 0;
		v_return VARCHAR2(100);
		zapytanie VARCHAR2(300);
				
	BEGIN				
				
		SELECT num_rows INTO liczba_wierszy_tab1 FROM user_tables WHERE table_name = Tabela1;
		
		--SELECT count(*) INTO liczba_null_tab1 FROM Tabela1 WHERE Kolumna1 IS NULL;
		zapytanie := 'SELECT count(*) FROM '||Tabela1||' WHERE '||Kolumna1||' IS NULL';
		EXECUTE IMMEDIATE zapytanie INTO liczba_null_tab1;
								
		--SELECT count(DISTINCT(Kolumna1)) INTO liczba_unikat_wierszy_tab1 FROM Tabela1;
		zapytanie := 'SELECT count(DISTINCT('||Kolumna1||')) FROM '||Tabela1;
		EXECUTE IMMEDIATE zapytanie INTO liczba_unikat_wierszy_tab1;
		
		
		
		SELECT num_rows INTO liczba_wierszy_tab2 FROM user_tables WHERE table_name = Tabela2;	
		
		--SELECT count(*) INTO liczba_null_tab2 FROM Tabela2 WHERE Kolumna2 IS NULL;
		zapytanie := 'SELECT count(*) FROM '||Tabela2||' WHERE '||Kolumna2||' IS NULL';
		EXECUTE IMMEDIATE zapytanie INTO liczba_null_tab2;
				
		--SELECT count(DISTINCT(Kolumna2)) INTO liczba_unikat_wierszy_tab2 FROM Tabela2;
		zapytanie := 'SELECT count(DISTINCT('||Kolumna2||')) FROM '||Tabela2;
		EXECUTE IMMEDIATE zapytanie INTO liczba_unikat_wierszy_tab2;	
				
			
				
		wynik:=((liczba_wierszy_tab1 - liczba_null_tab1)/liczba_wierszy_tab1)*((liczba_wierszy_tab2 - liczba_null_tab2)/liczba_wierszy_tab2)/greatest(liczba_unikat_wierszy_tab1, liczba_unikat_wierszy_tab2);           
		v_return := 'Selektywnosc dla JOIN: '||to_char(wynik*100,'099D9999999999')||'%';		
				
		RETURN v_return;
				
	END P_SELEKTYWNOSC_DLA_JOIN;
	-- +++<<<### END ###>>>+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
	
	
	
	
	-- +++<<<### START ###>>>+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
	PROCEDURE P_SELEKTYWNOSC_ROZNE_METODY(N IN VARCHAR2)
	IS	
		czas TIMESTAMP;
		czas_interval VARCHAR2(19);
		int1 INTEGER;
		int2 INTEGER;
		real1 NUMBER;
	BEGIN
		
		--### Du¿a selektywnosc - 0.1417% ###################################
		--### Pobranych mezczyzn[!] o imieniu[!] Mateusz
		DBMS_OUTPUT.PUT_LINE('# Zapytanie 1 - Duza selektywnosc');
		
		czas := PACKAGE_SELEKTYWNOSC.P_LICZ_CZAS_START(NULL); -- startujemy licznik czasu
		--### Wystêpuj¹ dwa warunki na imie i plec!!
		SELECT count(*) INTO int1 FROM OSOBY WHERE OSO_IMIE = 'Mateusz' AND OSO_PLEC = 'm';
		czas_interval := PACKAGE_SELEKTYWNOSC.P_LICZ_CZAS_END(czas); -- konczymy liczenie czasu
		DBMS_OUTPUT.PUT_LINE('+ Pobranych mezczyzn[!] o imieniu[!] Mateusz: '||int1||' trwalo: '||to_char(czas_interval));
		
		SELECT count(*) INTO int2 FROM OSOBY;
		
		DBMS_OUTPUT.PUT_LINE('- Selektywnosc jako stosunek wystapien danej wartosci do ilosci wszystkich wierszy w tabeli: '||to_char(int1/int2*100,'099D999999')||'%');
		
		
		--### Sprawdzamy ile wystepuje unikatowych imion w tabeli
		SELECT count(distinct(OSO_IMIE)) INTO int1 FROM OSOBY;
		DBMS_OUTPUT.PUT_LINE('- Selektywnosc unikatowych imion w tabeli: '||to_char(1/int1*100,'099D999999')||'%. Jest to prawdopodobienstwo wystapienie danego imienia ale tylko przy zalozeniu ze wystepuja rownomiernie.');
		
		
		--### Selektywnoœc ca³kowita powinna byæ sum¹ selektywnoœci cz¹stkowych dla ka¿dej unikatowej wartoœci kolumny.
		--### Poniewaz duzo osob moze nosic imie Jan a malo osob nosi imie Fabian
		SELECT sum(count(OSO_IMIE)*count(OSO_IMIE))/(sum(count(OSO_IMIE))*sum(count(*))) INTO real1 FROM OSOBY GROUP BY OSO_IMIE;
		DBMS_OUTPUT.PUT_LINE('- Selektywnosc calkowita imion: '||to_char(real1*100,'099D999999999999')||'%');
		
				
		
		DBMS_OUTPUT.PUT_LINE('.'); DBMS_OUTPUT.PUT_LINE('.');
		
		
	
		--### Bardzo du¿a selektywnosc 0.0067% ###################################	
		--### Pobranie osob o imieniu Marek z Krakowa
		DBMS_OUTPUT.PUT_LINE('# Zapytanie 2 - Bardzo duza selektywnosc');
		
		czas := PACKAGE_SELEKTYWNOSC.P_LICZ_CZAS_START(NULL); -- startujemy licznik czasu
		--### Wystêpuj¹ dwa warunki na imie i plec!!
		SELECT count(*) INTO int1 FROM OSOBY O LEFT JOIN ADRES_POCZTY A ON O.ADR_ID = A.ADRK_1_ID WHERE O.OSO_IMIE = 'Marek' AND A.ADR_MIASTO = 'Kraków';
		czas_interval := PACKAGE_SELEKTYWNOSC.P_LICZ_CZAS_END(czas); -- konczymy liczenie czasu
		DBMS_OUTPUT.PUT_LINE('+ Pobranych osob o imieniu Marek[!] z Krakowa[!]: '||int1||' trwalo: '||to_char(czas_interval));
			
		--### Obliczamy selektywnosc dla z³¹czonych tabel
		DBMS_OUTPUT.PUT_LINE(P_SELEKTYWNOSC_DLA_JOIN('OSOBY', 'OSO_IMIE', 'ADRES_POCZTY', 'ADR_MIASTO'));
		
		
		
		DBMS_OUTPUT.PUT_LINE('.'); DBMS_OUTPUT.PUT_LINE('._______.'); DBMS_OUTPUT.PUT_LINE('.'); -- ===============================================
		
		
		
		--### Ma³a selektywnosc na poziomie 1% ###################################	
		--### Pobrac wszystkie kobiety z Krakowa
		DBMS_OUTPUT.PUT_LINE('# Zapytanie 3 - Mala selektywnosc');
		
		czas := PACKAGE_SELEKTYWNOSC.P_LICZ_CZAS_START(NULL); -- startujemy licznik czasu
		--### Wystêpuj¹ dwa warunki na plec i miasto!!
		SELECT count(*) INTO int1 FROM OSOBY O LEFT JOIN ADRES_POCZTY A ON O.ADR_ID = A.ADRK_1_ID WHERE O.OSO_PLEC = 'k' AND A.ADR_MIASTO = 'Kraków';
		czas_interval := PACKAGE_SELEKTYWNOSC.P_LICZ_CZAS_END(czas); -- konczymy liczenie czasu
		DBMS_OUTPUT.PUT_LINE('+ Pobranych kobiet[!] z Krakowa[!]: '||int1||' trwalo: '||to_char(czas_interval));
		
		--### Obliczamy selektywnosc dla z³¹czonych tabel
		DBMS_OUTPUT.PUT_LINE(P_SELEKTYWNOSC_DLA_JOIN('OSOBY', 'OSO_PLEC', 'ADRES_POCZTY', 'ADR_MIASTO'));
		
		
		
		
		DBMS_OUTPUT.PUT_LINE('.'); DBMS_OUTPUT.PUT_LINE('.');
		
	
	
		--### Bardzo ma³a selektywnosc na poziomie 50% ###################################	
		--### Pobrac wszystkie kobiety z Krakowa
		DBMS_OUTPUT.PUT_LINE('# Zapytanie 4 - Bardzo mala selektywnosc');
		
		czas := PACKAGE_SELEKTYWNOSC.P_LICZ_CZAS_START(NULL); -- startujemy licznik czasu
		--### warunek plec=mezczyzna
		SELECT count(*) INTO int1 FROM OSOBY WHERE OSO_PLEC = 'm';
		czas_interval := PACKAGE_SELEKTYWNOSC.P_LICZ_CZAS_END(czas); -- konczymy liczenie czasu
		DBMS_OUTPUT.PUT_LINE('+ Pobranych mezczyzn: '||int1||' trwalo: '||to_char(czas_interval));
		
		SELECT count(*) INTO int2 FROM OSOBY;
		
		DBMS_OUTPUT.PUT_LINE('- Selektywnosc jako stosunek wystapien danej wartosci do ilosci wszystkich wierszy w tabeli: '||to_char(int1/int2*100,'099D999999')||'%');
		
		
		
		DBMS_OUTPUT.PUT_LINE('.'); DBMS_OUTPUT.PUT_LINE('.');
		
		
		
		--### Bardzo duza selektywnosc ###################################	
		--### 
		DBMS_OUTPUT.PUT_LINE('# Zapytanie 5 - Bardzo duza selektywnosc');
		
		czas := PACKAGE_SELEKTYWNOSC.P_LICZ_CZAS_START(NULL); -- startujemy licznik czasu
		--### warunek: Pobierz kobiety o imieniu na litere S i urodzone po roku 1980 w³¹cznie
		SELECT count(*) INTO int1 FROM OSOBY WHERE OSO_PLEC = 'k' AND OSO_IMIE LIKE 'S%' AND OSO_DATA_URODZENIA >= '1980/01/01';
		czas_interval := PACKAGE_SELEKTYWNOSC.P_LICZ_CZAS_END(czas); -- konczymy liczenie czasu
		DBMS_OUTPUT.PUT_LINE('+ Kobiety o imieniu na litere S i urodzone po roku 1980 wlacznie: '||int1||' trwalo: '||to_char(czas_interval));
		
		SELECT count(*) INTO int2 FROM OSOBY;
		
		DBMS_OUTPUT.PUT_LINE('- Selektywnosc jako stosunek wystapien danej wartosci do ilosci wszystkich wierszy w tabeli: '||to_char(int1/int2*100,'099D999999')||'%');
		
	
	
		
	END P_SELEKTYWNOSC_ROZNE_METODY;
	-- +++<<<### END ###>>>+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

END;
/	



-- ####################################################################################################





CLEAR SCREEN;
-- wywo³anie w bloku anonimowym	
BEGIN
	
	DBMS_OUTPUT.PUT_LINE('# 1 #---- Rozne metody obliczania selektywnosci dla zapytan ---');
	
	PACKAGE_SELEKTYWNOSC.P_SELEKTYWNOSC_ROZNE_METODY(NULL);
	
END;
/



--### Tworzymy indexy na odpowiednie kolumny
CREATE INDEX IX_OSO_IMIE_OSO_PLEC
ON OSOBY (OSO_IMIE, OSO_PLEC)
STORAGE (INITIAL 150k NEXT 150k)
TABLESPACE STUDENT_INDEX;

CREATE INDEX IX_OSO_IMIE
ON OSOBY (OSO_IMIE)
STORAGE (INITIAL 150k NEXT 150k)
TABLESPACE STUDENT_INDEX;

--### Na kolumne p³eæ powinien byc na³o¿ony index bitmapowy poniewa¿ ma ona nisk¹ kardynalnosc
-- indexy BITMAP nie dzia³aj¹ w wersji darmowej bazy (ORA-00439: feature not enabled: Bit-mapped indexes)
/*
CREATE BITMAP INDEX IX_OSO_PLEC
ON OSOBY (OSO_PLEC);
*/
CREATE INDEX IX_OSO_PLEC
ON OSOBY (OSO_PLEC)
STORAGE (INITIAL 150k NEXT 150k)
TABLESPACE STUDENT_INDEX;

CREATE INDEX IX_OSO_DATA_URODZENIA
ON OSOBY (OSO_DATA_URODZENIA)
STORAGE (INITIAL 150k NEXT 150k)
TABLESPACE STUDENT_INDEX;

CREATE INDEX IX_OSO_PLECIMIEDATAURODZ
ON OSOBY (OSO_PLEC, OSO_IMIE, OSO_DATA_URODZENIA)
STORAGE (INITIAL 150k NEXT 150k)
TABLESPACE STUDENT_INDEX;

CREATE INDEX IX_ADR_MIASTO
ON ADRES_POCZTY (ADR_MIASTO)
STORAGE (INITIAL 150k NEXT 150k)
TABLESPACE STUDENT_INDEX;




-- Analiza danych dla indexów
analyze INDEX IX_OSO_IMIE_OSO_PLEC estimate statistics sample 5 percent;
analyze INDEX IX_OSO_IMIE estimate statistics sample 5 percent;
-- Dla p³ci mozemy wszystkie dane przeanalizowac poniewaz plec ma nisk¹ kardynalnosc
analyze INDEX IX_OSO_PLEC compute statistics; 
analyze INDEX IX_OSO_DATA_URODZENIA estimate statistics sample 5 percent;
-- 20% poniewaz tabela jest mniejsza
analyze INDEX IX_ADR_MIASTO estimate statistics sample 20 percent;





-- wywo³anie w bloku anonimowym	
BEGIN
	DBMS_OUTPUT.PUT_LINE('#########################################################');
	DBMS_OUTPUT.PUT_LINE('#########################################################');
	DBMS_OUTPUT.PUT_LINE('# 2 #---- Czas wykonania zapytan po dodaniu indexow ---');
	
	PACKAGE_SELEKTYWNOSC.P_SELEKTYWNOSC_ROZNE_METODY(NULL);
	
END;
/


prompt
prompt


--### Analiza zapytania zlozonego z 3 kolumn
/*

Execution Plan
----------------------------------------------------------
Plan hash value: 2557933524

---------------------------------------------------------------------------------------------

| Id  | Operation           | Name                  | Rows  | Bytes | Cost (%CPU)| Time     |

---------------------------------------------------------------------------------------------

|   0 | SELECT STATEMENT    |                       |     1 |    18 |   475   (4)| 00:00:06 |

|   1 |  SORT AGGREGATE     |                       |     1 |    18 | 			 |          |

|*  2 |   VIEW              | index$_join$_001      |   756 | 13608 |   475   (4)| 00:00:06 |

|*  3 |    HASH JOIN        |                       |       |       | 			 |          |

|*  4 |     INDEX RANGE SCAN| IX_OSO_IMIE_OSO_PLEC  |   756 | 13608 |    33   (7)| 00:00:01 |

|*  5 |     INDEX RANGE SCAN| IX_OSO_DATA_URODZENIA |   756 | 13608 |  1453   (4)| 00:00:18 |

---------------------------------------------------------------------------------------------


Predicate Information (identified by operation id):
---------------------------------------------------

   2 - filter("OSO_DATA_URODZENIA">=TO_DATE('1980-01-01 00:00:00', 'yyyy-mm-dd
              hh24:mi:ss') AND "OSO_IMIE" LIKE 'S%' AND "OSO_PLEC"='k')
   3 - access(ROWID=ROWID)
   4 - access("OSO_IMIE" LIKE 'S%' AND "OSO_PLEC"='k')
   5 - access("OSO_DATA_URODZENIA">=TO_DATE('1980-01-01 00:00:00', 'yyyy-mm-dd
              hh24:mi:ss'))
			  
			  
			  
			  
			  
			  
			  
			  
-- ###############################################################################

-- Po dodaniu indexu na 3 kolumny zostanie on uzyty

Plan wykonywania
----------------------------------------------------------
Plan hash value: 565578088

----------------------------------------------------------------------------------------------

| Id  | Operation         | Name                     | Rows  | Bytes | Cost (%CPU)| Time     |

----------------------------------------------------------------------------------------------

|   0 | SELECT STATEMENT  |                          |     1 |    18 |    81   (2)| 00:00:01 |

|   1 |  SORT AGGREGATE   |                          |     1 |    18 |  	  |          |

|*  2 |   INDEX RANGE SCAN| IX_OSO_PLECIMIEDATAURODZ |  3030 | 54540 |    81   (2)| 00:00:01 |

----------------------------------------------------------------------------------------------


Predicate Information (identified by operation id):
---------------------------------------------------

   2 - access("OSO_PLEC"='k' AND "OSO_IMIE" LIKE 'S%' AND
              "OSO_DATA_URODZENIA">=TO_DATE('1980-01-01 00:00:00', 'yyyy-mm-dd h
h24:mi:ss'))

       filter("OSO_DATA_URODZENIA">=TO_DATE('1980-01-01 00:00:00', 'yyyy-mm-dd
              hh24:mi:ss') AND "OSO_IMIE" LIKE 'S%')			  
			  
					  

*/
SET autotrace traceonly EXPLAIN
        SELECT count(*) FROM OSOBY WHERE OSO_PLEC = 'k' AND OSO_IMIE LIKE 'S%' AND OSO_DATA_URODZENIA >= '1980/01/01';
SET autotrace off





-- # -------------------------------------------------

show error;

COMMIT;