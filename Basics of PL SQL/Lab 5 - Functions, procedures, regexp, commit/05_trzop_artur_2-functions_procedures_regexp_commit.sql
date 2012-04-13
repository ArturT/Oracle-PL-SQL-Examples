-- ##################################################
--
--	Baza danych dla portalu społecznościowego o książkach
-- 	2010 Copyright (c) Artur Trzop 12K2
--	Script v. 5.0.0
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
PROMPT Procedura do generowania uzytkownikow w bazie;
PROMPT ----------------------------------------------;
PROMPT ;

-- włączamy opcje wyświetlania komunikatów przy pomocy DBMS_OUTPUT.PUT_LINE();
set serveroutput on;

-- zmiana formatu wyswietlania daty aby mozna bylo poprawnie porownac daty
-- http://www.dba-oracle.com/sf_ora_01830_date_format_picture_ends_before_converting_entire_input_string.htm
alter session set nls_date_format='YYYY/MM/DD';





-- Funkcja zwraca liczbe znaków jaką maksymalnie można przetrzymywac w polu danej tabeli
CREATE OR REPLACE FUNCTION F_GET_MAX_SIZE_OF_FIELD
	(Tabela IN VARCHAR2, Atrybut IN VARCHAR2)
	RETURN INT
IS
	int_max INT;
BEGIN
	select max(data_length) into int_max from user_tab_cols where table_name = Tabela and column_name = Atrybut;
	RETURN int_max;
END F_GET_MAX_SIZE_OF_FIELD;
/



-- Funkcja sprawdzajaca czy podana data urodzenia jest poprawna
CREATE OR REPLACE FUNCTION F_CHECK_BIRTHDAY_DATE
	(Birthday IN DATE)
	RETURN BOOLEAN
IS
	int_check INT;
	return_value BOOLEAN;
	-- przechowuje biezaca date
	-- date_curr DATE;
BEGIN
	select REGEXP_INSTR(to_char(Birthday), '^[[:digit:]]{4}/[01][[:digit:]]/[0123][[:digit:]]$') into int_check from dual;

	-- Inna metoda pobierania aktualnej daty
	-- pobieramy obecna date i ladujemy do zmiennej date_curr
	-- select to_date(current_date,'yyyy/mm/dd') into date_curr from dual; 
	
	-- sprawdzamy czy podana data urodzenia jest mniejsza od obecnej
	-- jesli jest mniejsza od obecnej i int_check=1 z poprzedniego zapytania to znaczy ze data jest poprawna
	IF int_check = 1 THEN
		IF to_date(Birthday) < to_date(sysdate,'yyyy/mm/dd') THEN		
			return_value := true;
		ELSE
			return_value := false;
		END IF;
	ELSE
		return_value := false;
	END IF;

	
	return return_value;
END F_CHECK_BIRTHDAY_DATE;
/	
--show error;







-- Funkcja zwracajaca ID danego miasta, lub gdy ono nie istnieje to go doda do bazy i pobierze jego ID
CREATE OR REPLACE FUNCTION F_GET_MIASTO_ID
	(Miasto IN VARCHAR2)
	RETURN INT
IS
	-- bedzie przechowywac wartosc ID aktualnie wstawionego nowego miasta jesli sie okaze ze dane miasto nie istnieje
	mia_id_curr INT DEFAULT 0;
	-- przechowuje liczbe znalezionych miast o tej samej nazwie
	i INT; 
BEGIN
	select count(MIAK_1_ID) into i from MIASTO where MIA_MIASTO = Miasto;
	IF i > 0 THEN
		select MIAK_1_ID into mia_id_curr from MIASTO where MIA_MIASTO = Miasto;
	END IF;
	
	-- jesli nie zaladowano do zmiennej mia_id_curr wartosc miasta to znaczy ze ono nie istnieje w bazie
	-- w takim wypadku musimy sami dodac do bazy nowe miasto i pobrac wtedy jego ID
	IF mia_id_curr = 0 THEN
		insert into MIASTO (MIA_MIASTO) values(Miasto);
		select SEQ_MIASTO.currval into mia_id_curr from dual;		
	END IF;
	
	RETURN mia_id_curr;	
END F_GET_MIASTO_ID;
/
--show error;
	


	
-- Funkcja sprawdzajaca czy podany adres email jest poprawny
-- zwraca true jesli format poprawny
CREATE OR REPLACE FUNCTION F_CHECK_EMAIL_FORMAT
	(Email IN VARCHAR2)
	RETURN BOOLEAN
IS
	int_check INT;
	return_value BOOLEAN;	
BEGIN
	select REGEXP_INSTR(to_char(Email), '^.+@.+\..{2,4}$') into int_check from dual;
	
	IF int_check = 1 THEN
		return_value := true;
	ELSE
		return_value := false;
	END IF;
	
	return return_value;
END F_CHECK_EMAIL_FORMAT;
/	
--show error;	
	
	
	



-- ### Wazniejsze funkcje procedury ######################################################################
-- sprawdzanie poprawnosci argumentow
-- pobieranie wartosci maksymalnej dla pol z tabeli user_tab_cols
-- rzucanie wyjatkow
-- savepoint
-- drukowanie znakow nowej linii
-- automatyczne tworzenie nowego miasta jesli go nie ma i pobieranie wartosci kursora
-- funkcje sprawdzajace dlugosc pola w tabeli, czy poprawna data urodzenia
-- wyrazenia regularne
-- weryfikacja emaila

-- dodawanie nowego uzytkownika, podanie nazwy miasta (sprawdzenie czy miasto istnieje, jesli nie to wycofuje transakcje)
-- dodawanie miast
-- weryfikowac login, status(0,1),admin, email, dlugosc loginu, date urodzenia, plec (m,k)
-- podane haslo szyfrowac do sh1

-- Konwencja: 
-- P_ - prefix w nazwie oznacza ze jest to procedura
-- Nazwy argumentow procedury zaczynaja sie duza litera i stosuje sie nazewnictwo Camel
-- nazwy zmiennych w procedurze malymi literami z uzyciem _
CREATE OR REPLACE PROCEDURE P_DODAJ_UZYTKOWNIKA	
	-- Licznik informuje ile wygenerowac wierszy w bazie
	(Licznik IN INT, Login IN VARCHAR2, Haslo IN VARCHAR2, Status IN NUMBER, CzyAdmin IN NUMBER, Imie IN VARCHAR2, Plec IN CHAR, Email IN VARCHAR2, DataUrodzenia IN DATE, MiastoUzytkownika IN VARCHAR2)
IS
	-- bedzie przechowywac wartosc ID aktualnie wstawionego nowego miasta jesli sie okaze ze dane miasto nie istnieje
	mia_id_curr MIASTO.MIAK_1_ID%TYPE;	
	-- przechowuje liczbe, bedziemy uzywac tej zmiennej do ladowania dlugosci poszczegolnych maksymalnych wartosci 
	-- dla pol tabel i uzywac jej przy sprawdzaniu czy podane argumenty zmieszcza sie w tabeli	
	int_max INT;
	hash_haslo UZYTKOWNICY.UZY_HASLO_HASH%TYPE;
	uzy_id_befor UZYTKOWNICY.UZYK_1_ID%TYPE;
	uzy_id_after uzy_id_befor%TYPE;
	int_check_login_exist INT;
	int_check_email_exist INT;
	--przechowuje wartosc i z petli for
	Iterator INT;
	
	-- deklaracja moich wlasnych wyjatkow
	my_exception_Licznik EXCEPTION;
	my_exception_Login EXCEPTION;
	my_exception_LoginExist EXCEPTION;
	my_exception_Status EXCEPTION;
	my_exception_CzyAdmin EXCEPTION;
	my_exception_Imie EXCEPTION;
	my_exception_Plec EXCEPTION;
	my_exception_Email EXCEPTION;
	my_exception_EmailFormat EXCEPTION;
	my_exception_EmailExist EXCEPTION;
	my_exception_DataUrodzenia EXCEPTION;
	my_exception_MiastoUzytkownika EXCEPTION;
	
BEGIN
	-- Przed wykonaniem kodu robimy SAVEPOINT
	SAVEPOINT P_DODAJ_UZY__BEFORE_START;
	-- ||CHR(13)||CHR(10) to znaki nowej linii \r\n
	DBMS_OUTPUT.PUT_LINE('--- Tworzymy savepoint ------------------'||CHR(13)||CHR(10));
	
	
	--DBMS_OUTPUT.PUT_LINE('Test text');
	
	-- Sprawdzamy czy licznik dodawanych rekordów jest większy od zera
	IF Licznik > 0 THEN	
		
		-- Sprawdzamy długość podanego Loginu połączonego z masymalną wartością licznika.
		-- Np. Uzytkownik20. Sprawdzamy dzieki temu czy w polu tabeli zmiesci sie tak długi login
		-- Pobieramy maksymalna wartosc jaką może przechowywać pole UZY_LOGIN i ładujemy ją do zmiennej int_max
		int_max := F_GET_MAX_SIZE_OF_FIELD('UZYTKOWNICY', 'UZY_LOGIN');		
		IF NOT(LENGTH(Login||Licznik) <= int_max) THEN			
			RAISE my_exception_Login;
		END IF;
		
		
		-- Sprawdzamy czy status aktywnosci konta przyjmuje wartosc 0 lub 1
		IF NOT(Status = 0 OR Status = 1) THEN
			RAISE my_exception_Status;			
		END IF;
		
		
		-- Sprawdzamy czy uzytkownik ma status admina. CzyAdmin przyjmuje wartosc 0 lub 1
		IF NOT(CzyAdmin = 0 OR CzyAdmin = 1) THEN
			RAISE my_exception_CzyAdmin;			
		END IF;
		
		
		-- Pobieramy maksymalna wartosc jaką może przechowywać pole UZY_IMIE i ładujemy ją do zmiennej int_max
		int_max := F_GET_MAX_SIZE_OF_FIELD('UZYTKOWNICY', 'UZY_IMIE');		
		IF NOT(LENGTH(Imie||Licznik) <= int_max) THEN			
			RAISE my_exception_Imie;
		END IF;
		
		
		-- Sprawdzamy czy uzytkownik ma poprawna plec. Plec przyjmuje wartosc k-kobieta lub m-mezczyzna
		IF NOT(Plec = 'k' OR Plec = 'm') THEN
			RAISE my_exception_Plec;			
		END IF;
		
		
		--### Pobieramy maksymalna wartosc jaką może przechowywać pole UZY_EMAIL i ładujemy ją do zmiennej int_max
		int_max := F_GET_MAX_SIZE_OF_FIELD('UZYTKOWNICY', 'UZY_EMAIL');		
		IF NOT(LENGTH(Licznik||Email) <= int_max) THEN			
			RAISE my_exception_Email;
		END IF;
		
		
		--### Sprawdzamy czy format email jest poprawny, czy zawiera znak @ i koncowke domeny
		IF NOT(F_CHECK_EMAIL_FORMAT(Email)) THEN
			RAISE my_exception_EmailFormat;
		END IF;
		
		
		--### Sprawdzamy czy podana data jest poprawna (uzywamy do tego funkcji)
		IF F_CHECK_BIRTHDAY_DATE(DataUrodzenia) = false THEN
			RAISE my_exception_DataUrodzenia;
		END IF;
		
		
		-- Pobieramy maksymalna wartosc jaką może przechowywać pole MIA_MIASTO i ładujemy ją do zmiennej int_max
		int_max := F_GET_MAX_SIZE_OF_FIELD('MIASTO', 'MIA_MIASTO');		
		IF NOT(LENGTH(MiastoUzytkownika) <= int_max) THEN			
			RAISE my_exception_MiastoUzytkownika;
		END IF;
		
		--### Pobieramy id miasta, funkcja stworzy nowe miasto w bazie jesli go nie ma
		mia_id_curr := F_GET_MIASTO_ID(MiastoUzytkownika);
		
		-- DBMS_OUTPUT.PUT_LINE('id miasta: '||mia_id_curr);
		
		
		
		
		/*
		 *	Dodawanie rekordu do bazy
		 */	
		
		-- Pobieramy wartosc ostatnio dodanego rekordu
		select SEQ_UZYTKOWNICY.currval into uzy_id_befor from dual;

		 
		 
		FOR i IN 1..Licznik
		LOOP
			Iterator := i;
			-- Sprawdzamy czy uzytkownik o danym loginie juz istnieje w bazie. Jesli tak to rzucamy wyjatek
			select count(UZYK_1_ID) into int_check_login_exist from UZYTKOWNICY where UZY_LOGIN = (Login||i);
			
			IF int_check_login_exist = 1 THEN
				RAISE my_exception_LoginExist;
			END IF;
			
			-- Sprawdzamy czy email juz istnieje w bazie
			select count(UZYK_1_ID) into int_check_email_exist from UZYTKOWNICY where UZY_EMAIL = (i||Email);
			IF int_check_email_exist = 1 THEN
				RAISE my_exception_EmailExist;
			END IF;
		
			-- 3 oznacza szyfrowanie sh1 (funkcji tej nie mozna uzyc bo nie ma odpowiednich uprawien na serwerze)
			-- hash_haslo := dbms_crypto.hash(Haslo||i,3);
			-- DBMS_OUTPUT.PUT_LINE('haslo: '||hash_haslo);
			
			-- zastępcze haslo bez szyfrowania
			hash_haslo := Haslo||i;		
			
			insert into UZYTKOWNICY (UZY_LOGIN, UZY_HASLO_HASH, UZY_STATUS, UZY_CZY_ADMIN, UZY_IMIE, UZY_PLEC, UZY_DATA_URODZENIA, UZY_EMAIL, MIA_ID) 
			values (
				Login||i
			,	hash_haslo
			,	Status
			,	CzyAdmin
			,	Imie||i
			,	Plec
			,	DataUrodzenia
			,	i||Email		
			,	mia_id_curr
			);
		END LOOP;
		
		
		-- Pobieramy wartosc ostatnio dodanego rekordu
		select SEQ_UZYTKOWNICY.currval into uzy_id_after from dual;
		
		-- Jesli liczba dodanych rekordow sie nie zmienila lub dodano mniej rekordow niz zadeklarowano w liczniku to wycofujemy transakcje
		IF uzy_id_befor = uzy_id_after OR (uzy_id_befor+Licznik)>uzy_id_after THEN
			DBMS_OUTPUT.PUT_LINE('--- Wycofano transakcje z powodu nie dodania wystarczajacej liczby wierszy'||CHR(13)||CHR(10));
			ROLLBACK TO SAVEPOINT P_DODAJ_UZY__BEFORE_START;
		ELSE
			-- pomyślnie dodano rekordy wiec zatwierdzamy transakcje
			DBMS_OUTPUT.PUT_LINE('--- Pomyslnie zakonczono transakcje -------'||CHR(13)||CHR(10));
			DBMS_OUTPUT.PUT_LINE('Dodano wierszy: '||Licznik);
			COMMIT;
		END IF;
		
	ELSE 
		RAISE my_exception_Licznik;
	END IF;

EXCEPTION
	WHEN my_exception_Licznik THEN
		DBMS_OUTPUT.PUT_LINE('### Wyjatek: Licznik dodawanych rekordow musi byc wiekszy od zera!');
	WHEN my_exception_Login THEN
		DBMS_OUTPUT.PUT_LINE('### Wyjatek: Login jest zbyt dlugi! Nie moze przekraczac '||int_max||' znakow.');
	WHEN my_exception_LoginExist THEN
		DBMS_OUTPUT.PUT_LINE('### Wyjatek: Login '||Login||Iterator||' juz istnieje w bazie!');
	WHEN my_exception_Status THEN
		DBMS_OUTPUT.PUT_LINE('### Wyjatek: Status uzytkownika moze przyjac wartosc tylko 0 lub 1. Gdzie 0-nieaktywne konto, 1-aktywne');
	WHEN my_exception_CzyAdmin THEN
		DBMS_OUTPUT.PUT_LINE('### Wyjatek: Argument CzyAdmin moze przyjac wartosc tylko 0 lub 1. Gdzie 0-zwykly uzytkownik, 1-administrator');
	WHEN my_exception_Imie THEN
		DBMS_OUTPUT.PUT_LINE('### Wyjatek: Imie jest zbyt dlugie! Nie moze przekraczac '||int_max||' znakow.');
	WHEN my_exception_Plec THEN
		DBMS_OUTPUT.PUT_LINE('### Wyjatek: Uzytkownik moze przyjac plec tylko k lub m. Gdzie k-kobieta, m-mezczyzna');
	WHEN my_exception_Email THEN
		DBMS_OUTPUT.PUT_LINE('### Wyjatek: Email jest zbyt dlugi! Nie moze przekraczac '||int_max||' znakow.');
	WHEN my_exception_EmailFormat THEN
		DBMS_OUTPUT.PUT_LINE('### Wyjatek: Email ma nie poprawny format! Musi zawiera prefix, znak @ i domene wraz z koncowka .com, .pl itp');
	WHEN my_exception_EmailExist THEN
		DBMS_OUTPUT.PUT_LINE('### Wyjatek: Email '||Iterator||Email||' juz istnieje w bazie!');
	WHEN my_exception_DataUrodzenia THEN
		DBMS_OUTPUT.PUT_LINE('### Wyjatek: Data urodzenia jest niepoprawna lub podales date wieksza od dzisiejszej.');
	WHEN my_exception_MiastoUzytkownika THEN
		DBMS_OUTPUT.PUT_LINE('### Wyjatek: Podane miasto ma za dluga nazwe! Nie moze przekraczac '||int_max||' znakow.');
	
END P_DODAJ_UZYTKOWNIKA;
/		
	


	
-- wywołanie procedury w bloku anonimowym	
BEGIN
	P_DODAJ_UZYTKOWNIKA(3, 'User', 'tajnehaslo', 1, 0, 'Imie', 'm', 'user@domena.pl', '1957/02/22', 'Warszawa2');	
END;
/












COMMIT;

-- wyświetlamy błędy jeśli jakieś wystąpiły
show error;