-- ##################################################
--
--	Bazy danych 
-- 	2011 Copyright (c) Artur Trzop 12K2
--	Script v. 2.1.0
--
-- ##################################################

-- włączamy opcje wyświetlania komunikatów przy pomocy DBMS_OUTPUT.PUT_LINE();
set serveroutput on;
set feedback on;

-- wyk.3, str.46 ustawianie domyslnego sposobu wyswietlania daty
ALTER SESSION SET NLS_DATE_FORMAT = 'yyyy/mm/dd';
--ALTER SESSION SET NLS_DATE_FORMAT = 'yyyy/mm/dd hh24:mi:ss';

CLEAR SCREEN;
PROMPT ----------------------------------------------;
PROMPT Czyszczenie ekranu;
PROMPT ----------------------------------------------;
PROMPT ;


-- ##################################################


/*
	Zwracane dane:
	
	# 1 #---- Dodawanie urzedu pocztowego ---
	+ Dodano rekord!
	.
	# 2 #---- Dodawanie osoby --------
	.
	#>>--------------- OSOBA -----------------------<<#
	Imie: Jan
	Nazwisko: Kowalski
	Ulica zamieszkania: Kolorowa
	Nr lokalu: 12/2
	Miasto: Podolszyny
	Kod pocztowy: 10-823
	.
	#>>--------------- OSOBA -----------------------<<#
	Imie: Adam
	Nazwisko: Nowak
	Ulica zamieszkania: Dluga
	Nr lokalu: 23/65
	Miasto: Jeziorka
	Kod pocztowy: 16-140

*/




-- ####################################################################################################




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







-- ####################################################################################################

-- 
/*
	Zwracany wynik:
	
*/
-- Deklaracja Pakietu
CREATE OR REPLACE PACKAGE PACKAGE_OSO_ADR
IS
	
	--### Procedury i funkcje przeładowane
	PROCEDURE P_NEW_ADRES_POCZTY (Miasto IN VARCHAR2, KodPocztowy IN VARCHAR2, Ulica IN VARCHAR2, NrLokalu IN VARCHAR2);
	
	FUNCTION F_NEW_OSOBY (
		Imie IN VARCHAR2, Nazwisko IN VARCHAR2, Plec IN CHAR, DataUrodzenia IN DATE, Pesel IN VARCHAR2, 
		Nip IN VARCHAR2, Ulica IN VARCHAR2, NrLokalu IN VARCHAR2, AdresPocztyId IN INTEGER
	) RETURN INTEGER;
	--### Funkcja przeładowana. Jako ostatni argument zamiast ID urzędu pocztowego możemy podać kod pocztowy i na jego podstawie zostanie
	--### pobrany odpowiedni ID
	FUNCTION F_NEW_OSOBY (
		Imie IN VARCHAR2, Nazwisko IN VARCHAR2, Plec IN CHAR, DataUrodzenia IN DATE, Pesel IN VARCHAR2, 
		Nip IN VARCHAR2, Ulica IN VARCHAR2, NrLokalu IN VARCHAR2, KodPocztowy IN VARCHAR2, Text IN VARCHAR2
	) RETURN INTEGER;
	
	PROCEDURE P_WYSWIETL_OSOBA(Id IN INTEGER);
	
	
	--### Typ rekordowy	
	TYPE RECORD_OSOBA IS RECORD (
		imie OSOBY.OSO_IMIE%TYPE NOT NULL DEFAULT 'Brak', 
		nazwisko OSOBY.OSO_NAZWISKO%TYPE NOT NULL DEFAULT 'Brak',
		ulica OSOBY.OSO_ULICA%TYPE NOT NULL DEFAULT 'Brak',
		nr_lokalu OSOBY.OSO_NR_LOKALU%TYPE NOT NULL DEFAULT 'Brak',
		miasto ADRES_POCZTY.ADR_MIASTO%TYPE NOT NULL DEFAULT 'Brak',
		kod_pocztowy ADRES_POCZTY.ADR_KOD_POCZTOWY%TYPE NOT NULL DEFAULT 'Brak'
	);
		
	
	-- kursor pobierajacy osobe o danym ID 
	--### Zwracany jest rekord RECORD_OSOBA
	CURSOR CURSOR_OSOBA (id IN INTEGER)
		RETURN RECORD_OSOBA
	IS
		SELECT O.OSO_IMIE, O.OSO_NAZWISKO, O.OSO_ULICA, O.OSO_NR_LOKALU, A.ADR_MIASTO, A.ADR_KOD_POCZTOWY 
		FROM OSOBY O LEFT JOIN ADRES_POCZTY A ON O.ADR_ID = A.ADRK_1_ID
		WHERE O.OSOK_1_ID = id;	
	
END;
/	



-- Definicja pakietu
CREATE OR REPLACE PACKAGE BODY PACKAGE_OSO_ADR
IS
	
	
	-- +++<<<### START ###>>>+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
	-- Procedura dodawania nowego urzędu pocztowego	
	-- Nie będziemy sprawdzać czy podane miasto się powtarza w tabeli ponieważ w danym mieście może być kilka urzędów pocztowych
	PROCEDURE P_NEW_ADRES_POCZTY 
		(Miasto IN VARCHAR2, KodPocztowy IN VARCHAR2, Ulica IN VARCHAR2, NrLokalu IN VARCHAR2)	
	IS
		-- zmienne
		licznik INT;
		int_max INT;
			
	BEGIN
		
		-- Sprawdzenie czy podany kod pocztowy juz istnieje w bazie. Jesli tak to rzucamy wyjatek
		-- Jest on sprawdzany w pierwszej kolejnosci poniewaz na pole kodu pocztowego nalozony jest index
		SELECT COUNT(*) INTO licznik FROM ADRES_POCZTY WHERE ADR_KOD_POCZTOWY = KodPocztowy;
		IF licznik > 0 THEN
			RAISE_APPLICATION_ERROR(-20001,'Kod pocztowy: "'||KodPocztowy||'" juz istnieje w bazie danych.');
		END IF;
		
		-- pobieramy ile znakow moze przechowywac maksymalnie pole w danej tabeli
		int_max := F_GET_MAX_SIZE_OF_FIELD('ADRES_POCZTY', 'ADR_KOD_POCZTOWY');		
		IF LENGTH(KodPocztowy) != 6 THEN						
			--### Rzucanie wyjątku 
			RAISE_APPLICATION_ERROR(-20002,'Kod pocztowy: "'||KodPocztowy||'" jest niepoprawny! Prosze podac go w formacie: 00-000');
		END IF;
		
		
		-- Sprawdzamy czy podane miasto ma odpowiednia ilosc znakow
		int_max := F_GET_MAX_SIZE_OF_FIELD('ADRES_POCZTY', 'ADR_MIASTO');		
		licznik := LENGTH(Miasto);
		IF licznik > int_max OR licznik < 3 THEN						
			--### Rzucanie wyjątku 
			RAISE_APPLICATION_ERROR(-20003,'Podane miasto: "'||Miasto||'" jest niepoprawne! Musi skladac sie z minimum 3 znakow i nie wiecej niz '||int_max); 
		END IF;
		
		
		-- Sprawdzamy czy podana ulica ma odpowiednia ilosc znakow
		int_max := F_GET_MAX_SIZE_OF_FIELD('ADRES_POCZTY', 'ADR_ULICA');		
		licznik := LENGTH(Ulica);
		IF licznik > int_max OR licznik < 3 THEN						
			--### Rzucanie wyjątku 
			RAISE_APPLICATION_ERROR(-20004,'Podana ulica: "'||Ulica||'" jest niepoprawna! Musi skladac sie z minimum 3 znakow i nie wiecej niz '||int_max); 
		END IF;
		
				
		-- Sprawdzamy czy podany nr lokalu ma odpowiednia ilosc znakow
		int_max := F_GET_MAX_SIZE_OF_FIELD('ADRES_POCZTY', 'ADR_NR_LOKALU');		
		licznik := LENGTH(NrLokalu);
		IF licznik > int_max OR licznik < 1 OR NrLokalu IS NULL THEN						
			--### Rzucanie wyjątku 
			RAISE_APPLICATION_ERROR(-20005,'Podany nr lokalu: "'||NrLokalu||'" jest niepoprawny! Musi skladac sie z minimum 1 znaku i nie wiecej niz '||int_max||'. Mozna stosowac zapis 00/00 czyli numer bloku/mieszkania.'); 
		END IF;
		
		
		-- ############### Uzycie wyrazen regularnych do sprawdzenia poprawnosci kodu pocztowego
		select REGEXP_INSTR(to_char(KodPocztowy), '^[0-9]{2}-[0-9]{3}$') into licznik from dual;
		IF licznik = 0 THEN						
			--### Rzucanie wyjątku 
			RAISE_APPLICATION_ERROR(-20006,'Podany kod pocztowy ma zly format. Wymagany: 00-000'); 
		END IF;
		
		
		
		-- dodawanie do bazy nowego rekordu
		INSERT INTO ADRES_POCZTY (ADR_MIASTO, ADR_KOD_POCZTOWY, ADR_ULICA, ADR_NR_LOKALU)
		VALUES (Miasto, KodPocztowy, Ulica, NrLokalu);
		DBMS_OUTPUT.PUT_LINE('+ Dodano rekord!');
	
	EXCEPTION				
		WHEN OTHERS THEN	
			DBMS_OUTPUT.PUT_LINE('### Moj Wyjatek: (code: '||SQLCODE||') '||SQLERRM);
	
	END P_NEW_ADRES_POCZTY;
	-- +++<<<### END ###>>>+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
	
	
	
	
	-- +++<<<### START ###>>>+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
	FUNCTION F_NEW_OSOBY (
		Imie IN VARCHAR2, Nazwisko IN VARCHAR2, Plec IN CHAR, DataUrodzenia IN DATE, Pesel IN VARCHAR2, 
		Nip IN VARCHAR2, Ulica IN VARCHAR2, NrLokalu IN VARCHAR2, AdresPocztyId IN INTEGER
	) RETURN INTEGER
	IS
		id INTEGER;
		licznik INTEGER;
		int_max INTEGER;
		
	BEGIN
		
		-- Sprawdzamy czy podane imie ma odpowiednia ilosc znakow
		int_max := F_GET_MAX_SIZE_OF_FIELD('OSOBY', 'OSO_IMIE');		
		licznik := LENGTH(Imie);
		IF licznik > int_max OR licznik < 3 THEN						
			--### Rzucanie wyjątku 
			RAISE_APPLICATION_ERROR(-20001,'Podane imie: "'||Imie||'" jest niepoprawne! Musi skladac sie z minimum 3 znakow i nie wiecej niz '||int_max);
		END IF;
		
		
		-- Sprawdzamy czy podane Nazwisko ma odpowiednia ilosc znakow
		int_max := F_GET_MAX_SIZE_OF_FIELD('OSOBY', 'OSO_NAZWISKO');		
		licznik := LENGTH(Nazwisko);
		IF licznik > int_max OR licznik < 3 THEN						
			--### Rzucanie wyjątku 
			RAISE_APPLICATION_ERROR(-20002,'Podane nazwisko: "'||Nazwisko||'" jest niepoprawne! Musi skladac sie z minimum 3 znakow i nie wiecej niz '||int_max);
		END IF;
		
		
		-- Sprawdzamy czy plec jest podana poprawnie		
		IF Plec != 'm' AND Plec != 'k' THEN						
			--### Rzucanie wyjątku 
			RAISE_APPLICATION_ERROR(-20003,'Podana plec: "'||Plec||'" jest niepoprawna! Nalezy podac: k-kobieta, m-mezczyzna');
		END IF;
		
		
		
		IF NOT(F_CHECK_BIRTHDAY_DATE(DataUrodzenia)) THEN						
			--### Rzucanie wyjątku 
			RAISE_APPLICATION_ERROR(-20004,'Data urodzenia: "'||DataUrodzenia||'" ma niepoprawny format.');
		END IF;
		
		
		select REGEXP_INSTR(to_char(Pesel), '^[0-9]{11}$') into licznik from dual;
		IF licznik = 0 THEN							
			--### Rzucanie wyjątku 
			RAISE_APPLICATION_ERROR(-20005,'Pesel ma niepoprawny format.');
		END IF;
		
		
		select REGEXP_INSTR(to_char(Nip), '^[0-9]{10}$') into licznik from dual;
		IF licznik = 0 THEN							
			--### Rzucanie wyjątku 
			RAISE_APPLICATION_ERROR(-20006,'NIP ma niepoprawny format.');
		END IF;
		
		
		-- Sprawdzamy czy podana Ulica ma odpowiednia ilosc znakow
		int_max := F_GET_MAX_SIZE_OF_FIELD('OSOBY', 'OSO_ULICA');		
		licznik := LENGTH(Ulica);
		IF licznik > int_max OR licznik < 3 THEN						
			--### Rzucanie wyjątku 
			RAISE_APPLICATION_ERROR(-20007,'Podana ulica: "'||Ulica||'" jest niepoprawna! Musi skladac sie z minimum 3 znakow i nie wiecej niz '||int_max);
		END IF;
		
		
		-- Sprawdzamy czy podany nr lokalu ma odpowiednia ilosc znakow
		int_max := F_GET_MAX_SIZE_OF_FIELD('ADRES_POCZTY', 'ADR_NR_LOKALU');		
		licznik := LENGTH(NrLokalu);
		IF licznik > int_max OR licznik < 1 OR NrLokalu IS NULL THEN						
			--### Rzucanie wyjątku 
			RAISE_APPLICATION_ERROR(-20008,'Podany nr lokalu: "'||NrLokalu||'" jest niepoprawny! Musi skladac sie z minimum 1 znaku i nie wiecej niz '||int_max||'. Mozna stosowac zapis 00/00 czyli numer bloku/mieszkania.'); 
		END IF;
				
		
		--### Sprawdzamy czy pod podanym ID urzedu pocztowego istnieje rekord
		SELECT COUNT(*) INTO licznik FROM ADRES_POCZTY WHERE ADRK_1_ID = AdresPocztyId;		
		IF licznik = 0 THEN							
			--### Rzucanie wyjątku 
			RAISE_APPLICATION_ERROR(-20009,'Urzad pocztowy o ID='||AdresPocztyId||' nie istnieje!');
		END IF;
		
		
		
		INSERT INTO OSOBY (OSO_IMIE, OSO_NAZWISKO, OSO_PLEC, OSO_DATA_URODZENIA, OSO_PESEL, OSO_NIP, OSO_ULICA, OSO_NR_LOKALU, ADR_ID) 
		VALUES (Imie, Nazwisko, Plec, DataUrodzenia, Pesel, Nip, Ulica, NrLokalu, AdresPocztyId);
		
		
		-- pobieramy ID osoby ktora dodalismy do bazy
		SELECT SEQ_OSOBY.CURRVAL INTO id FROM dual;	
		---DBMS_OUTPUT.PUT_LINE('id dodanego wiersza: '||id);		
		-- zwracamy jej ID		
		RETURN id;
		
	EXCEPTION				
		WHEN OTHERS THEN	
			DBMS_OUTPUT.PUT_LINE('### Moj Wyjatek: (code: '||SQLCODE||') '||SQLERRM);
			RETURN 0;
	END F_NEW_OSOBY;
	-- +++<<<### END ###>>>+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
	
	
	
	-- +++<<<### START ###>>>+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
	-- Funkcja przeładowana. Ostatni argument to kod pocztowy
	FUNCTION F_NEW_OSOBY (
		Imie IN VARCHAR2, Nazwisko IN VARCHAR2, Plec IN CHAR, DataUrodzenia IN DATE, Pesel IN VARCHAR2, 
		Nip IN VARCHAR2, Ulica IN VARCHAR2, NrLokalu IN VARCHAR2, KodPocztowy IN VARCHAR2, Text IN VARCHAR2
	) RETURN INTEGER
	IS
		id INTEGER;
		id_urzedu INTEGER;
	
	BEGIN
		
		-- Pobieramy id urzędu pocztowego na podstawie kodu
		SELECT ADRK_1_ID INTO id_urzedu FROM ADRES_POCZTY WHERE ADR_KOD_POCZTOWY = KodPocztowy;
		-- jeśli nie znaleziono id_urzedu to rzucamy wyjatek
		IF SQL%NOTFOUND THEN
			--### Rzucanie wyjątku 
			RAISE_APPLICATION_ERROR(-20001,'Probujesz przypisac osobe do urzedu, ktory nie istnieje!');
		END IF;
		
		-- wywołujemy tą samą funkcję z pakietu tylko ze z argumentem id_urzedu
		id := PACKAGE_OSO_ADR.F_NEW_OSOBY(Imie, Nazwisko, Plec, DataUrodzenia, Pesel, Nip, Ulica, NrLokalu, id_urzedu);
					
		-- zwracamy ID dodanej osoby		
		RETURN id;
		
	EXCEPTION				
		WHEN OTHERS THEN	
			DBMS_OUTPUT.PUT_LINE('### Moj Wyjatek: (code: '||SQLCODE||') '||SQLERRM);
			RETURN 0;
	END F_NEW_OSOBY;
	-- +++<<<### END ###>>>+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
	
	
	
	-- +++<<<### START ###>>>+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
	-- Procedura wyswietlajaca dana osobe wraz z danymi o miescie z ktorego pochodzodzi i adresie pocztowym
	-- Uzywamy tutaj CURSOR oraz RECORD
	PROCEDURE P_WYSWIETL_OSOBA 
		(Id IN INTEGER)	
	IS
		rekord PACKAGE_OSO_ADR.RECORD_OSOBA;
	BEGIN
		DBMS_OUTPUT.PUT_LINE('.');
		DBMS_OUTPUT.PUT_LINE('#>>--------------- OSOBA -----------------------<<#');	
		--### Otwieramy kursor z parametrem
		OPEN PACKAGE_OSO_ADR.CURSOR_OSOBA(Id);	
		LOOP		
			FETCH PACKAGE_OSO_ADR.CURSOR_OSOBA INTO rekord;		
			EXIT WHEN PACKAGE_OSO_ADR.CURSOR_OSOBA%NOTFOUND;
			
			DBMS_OUTPUT.PUT_LINE('Imie: '||rekord.imie);		
			DBMS_OUTPUT.PUT_LINE('Nazwisko: '||rekord.nazwisko);
			DBMS_OUTPUT.PUT_LINE('Ulica zamieszkania: '||rekord.ulica);
			DBMS_OUTPUT.PUT_LINE('Nr lokalu: '||rekord.nr_lokalu);
			DBMS_OUTPUT.PUT_LINE('Miasto: '||rekord.miasto);
			DBMS_OUTPUT.PUT_LINE('Kod pocztowy: '||rekord.kod_pocztowy);
			
		END LOOP;	
		
		-- jeśli nie pobrano żadnych danych to wyświetlamy stosowny komunikat
		IF PACKAGE_OSO_ADR.CURSOR_OSOBA%ROWCOUNT=0 THEN
			DBMS_OUTPUT.PUT_LINE('Nie znaleziono osoby o ID='||Id||'. Nie zostala dodana nowa osoba!');
		END IF;
		
		CLOSE PACKAGE_OSO_ADR.CURSOR_OSOBA;
	END P_WYSWIETL_OSOBA;
	-- +++<<<### END ###>>>+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
	
	
	
		
END;
/	






-- ####################################################################################################


CREATE OR REPLACE PACKAGE PACKAGE_MY_CRYPTO
IS
	FUNCTION MD5(string IN VARCHAR2) RETURN VARCHAR2;
	FUNCTION MD5(string IN VARCHAR2, salt IN VARCHAR2) RETURN VARCHAR2;
	FUNCTION MD4(string IN VARCHAR2) RETURN VARCHAR2;
	FUNCTION MD4(string IN VARCHAR2, salt IN VARCHAR2) RETURN VARCHAR2;
	FUNCTION SH1(string IN VARCHAR2) RETURN VARCHAR2;
	FUNCTION SH1(string IN VARCHAR2, salt IN VARCHAR2) RETURN VARCHAR2;
END;
/



-- Definicja pakietu
CREATE OR REPLACE PACKAGE BODY PACKAGE_MY_CRYPTO
IS

	FUNCTION MD5(string IN VARCHAR2) RETURN VARCHAR2	
	IS 
		wej RAW(128) := UTL_RAW.CAST_TO_RAW(string);
		wyj VARCHAR2(200);		
	BEGIN
		wyj := DBMS_CRYPTO.HASH(wej,1); -- 1 - md5
		RETURN wyj;
	END;
	
	FUNCTION MD5(string IN VARCHAR2, salt IN VARCHAR2) RETURN VARCHAR2	
	IS 
		wej RAW(128) := UTL_RAW.CAST_TO_RAW(string);
		wej_salt RAW(128) := UTL_RAW.CAST_TO_RAW(salt);
		wyj VARCHAR2(200);		
	BEGIN
		wyj := DBMS_CRYPTO.HASH(wej||wej_salt,1); -- 1 - md5
		RETURN wyj;
	END;
	
	
	FUNCTION MD4(string IN VARCHAR2) RETURN VARCHAR2	
	IS 
		wej RAW(128) := UTL_RAW.CAST_TO_RAW(string);
		wyj VARCHAR2(200);		
	BEGIN
		wyj := DBMS_CRYPTO.HASH(wej,2); -- 2 - md4
		RETURN wyj;
	END;
	
	FUNCTION MD4(string IN VARCHAR2, salt IN VARCHAR2) RETURN VARCHAR2	
	IS 
		wej RAW(128) := UTL_RAW.CAST_TO_RAW(string);
		wej_salt RAW(128) := UTL_RAW.CAST_TO_RAW(salt);
		wyj VARCHAR2(200);		
	BEGIN
		wyj := DBMS_CRYPTO.HASH(wej||wej_salt,2); -- 2 - md4
		RETURN wyj;
	END;
	

	FUNCTION SH1(string IN VARCHAR2) RETURN VARCHAR2	
	IS 
		wej RAW(128) := UTL_RAW.CAST_TO_RAW(string);
		wyj VARCHAR2(200);		
	BEGIN
		wyj := DBMS_CRYPTO.HASH(wej,3); -- 3 - sh1
		RETURN wyj;
	END;
	
	FUNCTION SH1(string IN VARCHAR2, salt IN VARCHAR2) RETURN VARCHAR2	
	IS 
		wej RAW(128) := UTL_RAW.CAST_TO_RAW(string);
		wej_salt RAW(128) := UTL_RAW.CAST_TO_RAW(salt);
		wyj VARCHAR2(200);		
	BEGIN
		wyj := DBMS_CRYPTO.HASH(wej||wej_salt,3); -- 3 - sh1
		RETURN wyj;
	END;
		
END;
/







-- ####################################################################################################







-- wywołanie w bloku anonimowym	
DECLARE
	liczba INTEGER;
		
BEGIN
	SAVEPOINT SAVE_1;
	
	/*
		-- Kasowanie nadmiarowych rekordow niz te ktore na poczatku wygenerowalismy
		delete from osoby where osok_1_id > 1000000;
		delete from ADRES_POCZTY where adrk_1_id > 2000;
	*/
	
	
	DBMS_OUTPUT.PUT_LINE('# 1 #---- Dodawanie urzedu pocztowego ---');
	
	-- dodanie nowego urzedu pocztowego
	--PACKAGE_OSO_ADR.P_NEW_ADRES_POCZTY('Nowy Jork', '12-3453', 'Niepodległości', '12/34');
	PACKAGE_OSO_ADR.P_NEW_ADRES_POCZTY('Now', '10-347', 'Niepodległości', '12/4');
		
	
	DBMS_OUTPUT.PUT_LINE('.');
	DBMS_OUTPUT.PUT_LINE('# 2 #---- Dodawanie osoby --------');	
	liczba := PACKAGE_OSO_ADR.F_NEW_OSOBY('Jan', 'Kowalski', 'm', '1990/05/09', '90050912345', '1234567890', 'Kolorowa', '12/2', 1);
	
	-- wyświetlenie danych o użytkowniku z użyciem kursora
	PACKAGE_OSO_ADR.P_WYSWIETL_OSOBA(liczba);
	
	
	
	-- wywołanie tej samej funkcji tylko z przeciążonym argumentem
	liczba := PACKAGE_OSO_ADR.F_NEW_OSOBY('Adam', 'Nowak', 'm', '1976/02/24', '76022412342', '4232567891', 'Dluga', '23/65', '16-140', 'KodPocztowy');
		
	-- wyświetlenie danych o użytkowniku z użyciem kursora
	PACKAGE_OSO_ADR.P_WYSWIETL_OSOBA(liczba);
	
	
	
	
	ROLLBACK TO SAVEPOINT SAVE_1;
END;
/












-- # -------------------------------------------------

show error;

COMMIT;