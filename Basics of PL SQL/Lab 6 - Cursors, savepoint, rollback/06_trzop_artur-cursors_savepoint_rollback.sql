-- ##################################################
--
--	Baza danych dla portalu spo³ecznoœciowego o ksi¹¿kach
-- 	2010/2011 Copyright (c) Artur Trzop 12K2
--	Script v. 6.0.0
--
-- ##################################################

CLEAR SCREEN;
PROMPT ----------------------------------------------;
PROMPT Czyszczenie ekranu;
PROMPT ----------------------------------------------;
PROMPT ;


-- ##################################################
PROMPT ;
PROMPT ----------------------------------------------;
PROMPT 1. PL/SQL;
PROMPT Cursor;
PROMPT ----------------------------------------------;
PROMPT ;

-- w³¹czamy opcje wyœwietlania komunikatów przy pomocy DBMS_OUTPUT.PUT_LINE();
set serveroutput on;

-- zmiana formatu wyswietlania daty aby mozna bylo poprawnie porownac daty
-- http://www.dba-oracle.com/sf_ora_01830_date_format_picture_ends_before_converting_entire_input_string.htm
alter session set nls_date_format='YYYY/MM/DD';




-- ##################################################
-- ###1 Pobranie ksiazki i jej kategorii po podaniu tytulu do kursora 
CREATE OR REPLACE PROCEDURE P_SZUKAJ_KSIAZEK
	(tytul IN KSIAZKI.KSI_TYTUL%TYPE)
IS
	--### Rekord zwracany przez kursor
	TYPE RECORD_WYNIKI_SZUKANIA_KSIAZEK IS RECORD (
		tytul KSIAZKI.KSI_TYTUL%TYPE NOT NULL DEFAULT 'Brak', 
		kategoria KATEGORIE_KSIAZEK.KAT_NAZWA%TYPE NOT NULL DEFAULT 'Brak'
	);
	
	rekord RECORD_WYNIKI_SZUKANIA_KSIAZEK;
	
	-- kursor pobierajacy ksiazki o podanym tytule 
	--### Zwracany jest rekord zawieraj¹cy dwa pola
	CURSOR CURSOR_SZUKAJ_KSIAZEK (szukaj_tytul IN KSIAZKI.KSI_TYTUL%TYPE)
		RETURN RECORD_WYNIKI_SZUKANIA_KSIAZEK
	IS
		SELECT K.KSI_TYTUL, KK.KAT_NAZWA 
		FROM KSIAZKI K LEFT JOIN KATEGORIE_KSIAZEK KK ON (K.KAT_ID = KK.KATK_1_ID)
		WHERE LOWER(KSI_TYTUL) LIKE LOWER('%'||szukaj_tytul||'%'); 
	
BEGIN
	
	DBMS_OUTPUT.PUT_LINE('# 1 #--------------- Wyniki Szukania ------------------------------');	
	--### Otwieramy kursor z parametrem
	OPEN CURSOR_SZUKAJ_KSIAZEK(tytul);	
	LOOP		
		FETCH CURSOR_SZUKAJ_KSIAZEK INTO rekord.tytul, rekord.kategoria;		
		EXIT WHEN CURSOR_SZUKAJ_KSIAZEK%NOTFOUND;
		--### U¿ytko %ROWCOUNT do wyœwietlenia liczby pobranych dotychczas rekordów
		DBMS_OUTPUT.PUT_LINE(CURSOR_SZUKAJ_KSIAZEK%ROWCOUNT||'. Znaleziono ksiazke: '||rekord.tytul||' z kategorii: '||rekord.kategoria);		
	END LOOP;	
	
	-- jeœli nie pobrano ¿adnych danych to wyœwietlamy stosowny komunikat
	IF CURSOR_SZUKAJ_KSIAZEK%ROWCOUNT=0 THEN
		DBMS_OUTPUT.PUT_LINE('Nie znaleziono zadnych wynikow!');
	END IF;
	
	CLOSE CURSOR_SZUKAJ_KSIAZEK;
		
END P_SZUKAJ_KSIAZEK;
/	


-- Uruchomienie procedury
BEGIN
	P_SZUKAJ_KSIAZEK('aw');
END;
/



	
	










-- ##################################################
-- ###2 Procedura szukaj¹ca uzytkownikow ktorzy urodzili sie w danych latach np. od 1980 do 2000 roku.
CREATE OR REPLACE PROCEDURE P_UZY_URODZENI_W_LATACH
	(od_roku IN INT, do_roku IN INT)
IS
	--### Kursor przyjmuj¹cy dwa argumenty podane jako rok. Mamy odpowiedni¹ konkatenacje roku do postaci yyyy/mm/dd
	CURSOR CURSOR_UZY_URODZENI 
		(od_r IN INT, do_r IN INT)
	IS	
		SELECT UZY_IMIE, UZY_DATA_URODZENIA FROM UZYTKOWNICY 
		WHERE UZY_DATA_URODZENIA >= TO_DATE(od_r||'/01/01','YYYY/MM/DD') AND UZY_DATA_URODZENIA <= TO_DATE(do_r||'/12/31','YYYY/MM/DD');
		
	licznik INT DEFAULT 0;
	wiek INT;
BEGIN	
	DBMS_OUTPUT.PUT_LINE('# 2 #--- Wyniki szukania uzytkownikow w danym przedziale urodzenia ----');

	-- Nie trzeba otwierac kursora poniewaz FOR automatycznie to robi
	--OPEN CURSOR_UZY_URODZENI(od_roku, do_roku);
		
	FOR dane IN CURSOR_UZY_URODZENI(od_roku, do_roku)
	LOOP
		licznik:=licznik+1;
		
		--### Obliczamy wiek odejmuj¹c rok obecny od roku urodzenia uzytkownika
		wiek := substr(to_date(sysdate,'yyyy/mm/dd'),1,4)-substr(dane.UZY_DATA_URODZENIA,1,4);
		DBMS_OUTPUT.PUT_LINE(licznik||'. Imie: '||dane.UZY_IMIE||', Wiek: '||wiek||', Rok urodzenia: '||dane.UZY_DATA_URODZENIA);
		
	END LOOP;
	--Zamkniêcie kursora nast¹pi³o automatycznie przez pêtle FOR
	
	IF licznik=0 THEN
		DBMS_OUTPUT.PUT_LINE('Nie znaleziono zadnych wynikow!');
	ELSE
		DBMS_OUTPUT.PUT_LINE('Wszystkich wynikow: '||licznik);
	END IF;	
	
END P_UZY_URODZENI_W_LATACH;
/
	
	
BEGIN
	P_UZY_URODZENI_W_LATACH(1980,2000);
END;
/	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
-- ##################################################
-- ###3 Procedura ktora przegl¹da liste autorów i poprawia imiona i nazwiska tak aby zaczyna³y siê od du¿ej litery	
-- u¿ytko wlasny typ rekordu
-- zastosowano FOR UPDATE, WHERE CURRENT OF
CREATE OR REPLACE PROCEDURE P_AUTORZY_POPRAW_NAZWISKA
IS
	CURSOR CURSOR_AUTORZY_POPRAW 
	IS
		--### FOR UPDATE
		SELECT AUTK_1_ID, AUT_IMIE, AUT_NAZWISKO FROM AUTORZY FOR UPDATE;
		
	--### W³asny rekord
	TYPE RECORD_AUTOR IS RECORD (
		id AUTORZY.AUTK_1_ID%TYPE, 
		imie AUTORZY.AUT_IMIE%TYPE,
		nazwisko AUTORZY.AUT_NAZWISKO%TYPE
	);
	
	rekord RECORD_AUTOR;
	
BEGIN
	DBMS_OUTPUT.PUT_LINE('# 3 #-- Poprawa imion i nazwisk autorow na zaczynajace sie od duzej litery --');
	
	OPEN CURSOR_AUTORZY_POPRAW;
	
	FETCH CURSOR_AUTORZY_POPRAW INTO rekord;	
	WHILE CURSOR_AUTORZY_POPRAW%FOUND
	LOOP
		
		-- INITCAP(str) - Zamienia pierwsze litery wyrazów wystêpuj¹cych w ³añcuchu str na wielkie litery, a pozosta³e na ma³e.
		--### WHERE CURRENT OF
		UPDATE AUTORZY SET AUT_IMIE=INITCAP(AUT_IMIE), AUT_NAZWISKO=INITCAP(AUT_NAZWISKO) 
		WHERE CURRENT OF CURSOR_AUTORZY_POPRAW;
		
		DBMS_OUTPUT.PUT_LINE('Poprawiono autora o ID='||rekord.id||' - '||rekord.imie||' '||rekord.nazwisko);
		
		-- kolejny przeskok kursora
		FETCH CURSOR_AUTORZY_POPRAW INTO rekord;
	END LOOP;
	
	CLOSE CURSOR_AUTORZY_POPRAW;

END P_AUTORZY_POPRAW_NAZWISKA;
/	
	
	
BEGIN
	P_AUTORZY_POPRAW_NAZWISKA();
END;
/	
	
	
	
	
	
	
	
	
	
	
	
	




-- ##################################################
-- ###4 Procedura wyswietla drzewo kategorii ksiazek!!
/*
	# 4 #-- Lista kategorii ksiazek --
	- Literatura
	--- Powieœæ
	--- Historyczne
	--- Popularnonaukowe
	- Edukacja
	- Informatyka
	--- Bazy danych
	--- Programowanie
	----- Programowanie obiektowe
	----- Programowanie proceduralne
	--- Hacking
	- Biznes
	- Zdrowie
	- Podrêczniki
*/
--### U¿ytko kursor niejawny
--### Rekurencyjne wywo³anie procedury
CREATE OR REPLACE PROCEDURE P_WYSWIETL_KATEGORIE_KSIAZEK
	(id_rodzica IN INT, prefix_kat IN VARCHAR2)
IS	
BEGIN
	
	-- Jeœli id_rodzica jest pusty to znaczy ze mamy doczynienia z g³ówn¹ kategori¹. 
	-- Zapytanie niejawnego kursora musi zatem wygl¹daæ inaczej. Zawiera warunek IS NULL
	IF id_rodzica IS NULL THEN
		--### U¿ytko kursor niejawny
		FOR dane IN (SELECT KATK_1_ID, KAT_NAZWA FROM KATEGORIE_KSIAZEK WHERE KAT_RODZIC_KATEGORII IS NULL)
		LOOP
			DBMS_OUTPUT.PUT_LINE(prefix_kat||' '||dane.KAT_NAZWA);
			--### Rekurencyjne wywo³anie procedury
			P_WYSWIETL_KATEGORIE_KSIAZEK(dane.KATK_1_ID, prefix_kat||'--');
		END LOOP;
	ELSE
		FOR dane IN (SELECT KATK_1_ID, KAT_NAZWA FROM KATEGORIE_KSIAZEK WHERE KAT_RODZIC_KATEGORII=id_rodzica)
		LOOP
			DBMS_OUTPUT.PUT_LINE(prefix_kat||' '||dane.KAT_NAZWA);
			P_WYSWIETL_KATEGORIE_KSIAZEK(dane.KATK_1_ID, prefix_kat||'--');
		END LOOP;
	END IF;
	
END P_WYSWIETL_KATEGORIE_KSIAZEK;
/


BEGIN
	DBMS_OUTPUT.PUT_LINE('# 4 #-- Lista kategorii ksiazek --');
	-- Zaczynamy od wyœwietlenia g³ównych kategorii które nie maj¹ przypisanej kategorii rodzica, st¹d te¿ NULL jako argument procedury	
	P_WYSWIETL_KATEGORIE_KSIAZEK(NULL, '-');
END;
/

	
	
	
	
	
	
	
	
	
	
	
-- ##################################################
-- ###5 Kasowanie rekordow z wybranej tabeli pod podanym warunkiem 
-- # Wykorzystano dbms_sql (http://download.oracle.com/docs/cd/B19306_01/appdev.102/b14258/d_sql.htm)
-- # rzucanie wyj¹tku gdy brakuje podanego warunku.
-- # kasowanie wszystkich rekordow z tabeli gdy podano jako warunek 1=1

CREATE OR REPLACE PROCEDURE P_KASUJ_REKORDY_Z_TABELI
	(tabela IN VARCHAR2, warunek IN VARCHAR2)	
IS
	cursor_ NUMBER;
	--# Obowi¹zkowo nale¿y okreœli iloœæ znaków jak¹ mo¿e przechowywac zmienna dla zapytania
	query_ VARCHAR2(254);
	liczba_wynikow NUMBER;
	
	-- deklaracja moich wlasnych wyjatkow
	my_exception_warunek EXCEPTION;
	
BEGIN
	
	IF length(warunek)=0 THEN
		RAISE my_exception_warunek;
	END IF;
	
	-- otwarcie kursora
	cursor_ := dbms_sql.open_cursor;
	-- tworzymy wzór zapytania na podstawie argumentow przekazanych do procedury
	query_ := 'DELETE FROM '||tabela||' WHERE '||warunek;
	-- parsowanie zapytania
	dbms_sql.parse(cursor_, query_, dbms_sql.native);
	-- wykonanie kursora
	liczba_wynikow := dbms_sql.EXECUTE(cursor_);
	
	IF liczba_wynikow > 0 THEN
		DBMS_OUTPUT.PUT_LINE('Usunieto rekordow: '||liczba_wynikow||' z tabeli: '||tabela);
	ELSE
		DBMS_OUTPUT.PUT_LINE('Nie usunieto zadnych danych z tabeli: '||tabela);
	END IF;
	
	-- zamkniêcie kursora
	dbms_sql.close_cursor(cursor_);
	
EXCEPTION
	WHEN my_exception_warunek THEN
		DBMS_OUTPUT.PUT_LINE('### Nie podales warunku. Jesli chcesz skasowac wszystkie rekordy z danej tabeli jako warunek podaj 1=1');
		dbms_sql.close_cursor(cursor_);
	WHEN OTHERS THEN	
		DBMS_OUTPUT.PUT_LINE('### Wystapil nieoczekiwany blad!');
		dbms_sql.close_cursor(cursor_);
	
END P_KASUJ_REKORDY_Z_TABELI;
/


BEGIN
	SAVEPOINT PRZED_KASOWANIEM_1;
	
	DBMS_OUTPUT.PUT_LINE('# 5 #-- Kasowanie danych z wybranych tabel -------------------------');
	
	-- Kasowanie ocen nalezacych do uzytkownika id=1 gdzie oceny sa nizsze niz 4.0
	P_KASUJ_REKORDY_Z_TABELI('OCENY_KSIAZEK', 'UZY_ID = 1 AND OCE_OCENA <= 4.0');
	
	-- Kasowanie ocen nie istniejacego uzytkownika
	P_KASUJ_REKORDY_Z_TABELI('OCENY_KSIAZEK', 'UZY_ID = 99999');
	
	-- Brak podanego warunku. Zostanie rzucony wyj¹tek
	P_KASUJ_REKORDY_Z_TABELI('OCENY_KSIAZEK', '');
	
	-- Kasowanie wszystkich rekordow gdy jako warunek podamy 1=1
	P_KASUJ_REKORDY_Z_TABELI('OCENY_KSIAZEK', '1=1');
	
	ROLLBACK TO SAVEPOINT PRZED_KASOWANIEM_1;
END;
/
	
	
	
	
	
	
	
	
	
	
	
-- ##################################################
-- ###6 Procedura pobierajaca wydawnictwa z danego miasta z uzyciem DBMS_SQL
-- Wyœwietlanie wybranych wydawnictw. Poni¿ej przyk³ad wyniku dzia³ania:	
/*
	# 6 #-- Pobieranie wydawnictw z danego miasta -------------------------
	Znalezione wydawnictwo: KrakMedia (ID: 2)
	-# Brak ksiazek z tego wydawnictwa.
	Znalezione wydawnictwo: PWN (ID: 1)
	-> Ksiazka: Pan Tadeusz (kategoria: Powieœæ)
*/

CREATE OR REPLACE PROCEDURE P_WYDAWNICTWA_Z_MIASTA
        (miasto IN VARCHAR2)
IS
    kursor INTEGER;
    liczba_wierszy INTEGER;
    wydawnictwo VARCHAR2(254); --WYDAWNICTWO.WYD_NAZWA_WYDAWNICTWA%TYPE; #to nie u¿ywaæ
	id_wyd INTEGER;
	licznik INTEGER DEFAULT 0;
BEGIN
        
    kursor := DBMS_SQL.OPEN_CURSOR;
    DBMS_SQL.PARSE(kursor, 'SELECT w.WYD_NAZWA_WYDAWNICTWA, w.WYDK_1_ID 
							FROM WYDAWNICTWO w LEFT JOIN MIASTO m ON w.MIA_ID = m.MIAK_1_ID 
                            WHERE m.MIA_MIASTO = :x',
                   DBMS_SQL.NATIVE);
    DBMS_SQL.BIND_VARIABLE(kursor, ':x', miasto);
	DBMS_SQL.DEFINE_COLUMN(kursor, 1, wydawnictwo, 254);
	DBMS_SQL.DEFINE_COLUMN(kursor, 2, id_wyd);
    -- wykonanie zapytania kursora
	liczba_wierszy := DBMS_SQL.EXECUTE(kursor);
               
    WHILE DBMS_SQL.FETCH_ROWS(kursor) != 0
    LOOP
		/* Mo¿na te¿ zamiast WHILE u¿yæ tego
        IF DBMS_SQL.FETCH_ROWS(kursor) = 0 THEN
            EXIT;
        END IF;
        --*/
		DBMS_SQL.COLUMN_VALUE(kursor, 1, wydawnictwo);
		DBMS_SQL.COLUMN_VALUE(kursor, 2, id_wyd);
		DBMS_OUTPUT.PUT_LINE('Znalezione wydawnictwo: '||wydawnictwo||' (ID: '||id_wyd||')');
		
		--		
		FOR dane IN (
			SELECT K.KSI_TYTUL, KK.KAT_NAZWA 
			FROM (KSIAZKI K 
				LEFT JOIN (WERSJE_WYDANIA_KSIAZEK WWK 
					LEFT JOIN WERSJA_WYDANIA WER ON (WWK.WER_ID = WER.WERK_1_ID)) ON K.KSIK_1_ID = WWK.KSI_ID) 
						LEFT JOIN KATEGORIE_KSIAZEK KK ON (K.KAT_ID = KK.KATK_1_ID)
			WHERE WER.WERK_1_ID = id_wyd
			ORDER BY K.KSI_TYTUL ASC			
		)
		LOOP
			 DBMS_OUTPUT.PUT_LINE('-> Ksiazka: '||dane.KSI_TYTUL||' (kategoria: '||dane.KAT_NAZWA||')');
			 licznik:=licznik+1;
		END LOOP;
		
		-- Jeœli nie wyœwietlono ¿adnej ksi¹¿ki z danego wydawnictwa to pokazujemy komunikat
		IF licznik=0 THEN
			DBMS_OUTPUT.PUT_LINE('-# Brak ksiazek z tego wydawnictwa.');
		END IF;
		
		licznik:=0; -- Resetowanie licznika który przyda siê do kolejnej iteracji (nastêpnego wydawnictwa)
	END LOOP;
        
    DBMS_SQL.CLOSE_CURSOR(kursor);
        
EXCEPTION
WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('### Wystapil blad!');
    DBMS_SQL.CLOSE_CURSOR(kursor);
        
END P_WYDAWNICTWA_Z_MIASTA;
/


BEGIN
	DBMS_OUTPUT.PUT_LINE('# 6 #-- Pobieranie wydawnictw z danego miasta -------------------------');
	P_WYDAWNICTWA_Z_MIASTA('Kraków');
	P_WYDAWNICTWA_Z_MIASTA('Warszawa');	
END;
/




	
	
	
	
	


COMMIT;

-- wyœwietlamy b³êdy jeœli jakieœ wyst¹pi³y
show error;