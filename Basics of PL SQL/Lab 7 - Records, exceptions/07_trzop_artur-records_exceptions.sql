-- ##################################################
--
--	Baza danych dla portalu społecznościowego o książkach
-- 	2010/2011 Copyright (c) Artur Trzop 12K2
--	Script v. 7.0.0
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
PROMPT Rekordy i wyjatki;
PROMPT ----------------------------------------------;
PROMPT ;

-- włączamy opcje wyświetlania komunikatów przy pomocy DBMS_OUTPUT.PUT_LINE();
set serveroutput on;

-- zmiana formatu wyswietlania daty aby mozna bylo poprawnie porownac daty
-- http://www.dba-oracle.com/sf_ora_01830_date_format_picture_ends_before_converting_entire_input_string.htm
alter session set nls_date_format='YYYY/MM/DD';




--- ###########################################################################################################
-- Rekordy ####################################################################################################
--- ###########################################################################################################


-- ##################################################
-- ###1 Pobranie ksiazki i jej kategorii po podaniu tytulu do kursora. 
-- Użyto rekord jako typ zwracany przez kursor. Wyświetlanie danych z pól rekordu. <===============================@@@
CREATE OR REPLACE PROCEDURE P_SZUKAJ_KSIAZEK
	(tytul IN KSIAZKI.KSI_TYTUL%TYPE)
IS
	--### Rekord zwracany przez kursor  <===============================@@@
	TYPE RECORD_WYNIKI_SZUKANIA_KSIAZEK IS RECORD (
		tytul KSIAZKI.KSI_TYTUL%TYPE NOT NULL DEFAULT 'Brak', --### typ jak pole tabeli <===============================@@@ 
		kategoria KATEGORIE_KSIAZEK.KAT_NAZWA%TYPE NOT NULL DEFAULT 'Brak'
	);
	
	-- definujemy zmienną typu powyzszego rekordu
	rekord RECORD_WYNIKI_SZUKANIA_KSIAZEK;
	
	-- kursor pobierajacy ksiazki o podanym tytule 
	--### Zwracany jest rekord zawierający dwa pola
	CURSOR CURSOR_SZUKAJ_KSIAZEK (szukaj_tytul IN KSIAZKI.KSI_TYTUL%TYPE)
		RETURN RECORD_WYNIKI_SZUKANIA_KSIAZEK
	IS
		SELECT K.KSI_TYTUL, KK.KAT_NAZWA 
		FROM KSIAZKI K LEFT JOIN KATEGORIE_KSIAZEK KK ON (K.KAT_ID = KK.KATK_1_ID)
		WHERE LOWER(KSI_TYTUL) LIKE LOWER('%'||szukaj_tytul||'%'); 
	
BEGIN
	
	DBMS_OUTPUT.PUT_LINE('# 1 #--------------- Record: Wyniki szukania ksiazek -------------------------');	
	--### Otwieramy kursor z parametrem
	OPEN CURSOR_SZUKAJ_KSIAZEK(tytul);	
	LOOP		
		FETCH CURSOR_SZUKAJ_KSIAZEK INTO rekord.tytul, rekord.kategoria; --### Ładowanie danych do pól rekordu <===============================@@@		
		EXIT WHEN CURSOR_SZUKAJ_KSIAZEK%NOTFOUND;
		--### Użytko %ROWCOUNT do wyświetlenia liczby pobranych dotychczas rekordów
		DBMS_OUTPUT.PUT_LINE(CURSOR_SZUKAJ_KSIAZEK%ROWCOUNT||'. Znaleziono ksiazke: '||rekord.tytul||' z kategorii: '||rekord.kategoria);		
	END LOOP;	
	
	-- jeśli nie pobrano żadnych danych to wyświetlamy stosowny komunikat
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
-- ###2 Procedura pobiera pisarzy i wyświetla o nich informacje. Użyto rekord o typie takim jak tabela AUTORZY
/* Wynik działania:
	# 1 #--------------- Record: Lista autorów -------------------------
	Gates John (ur. 1959/06/20) Napisal ksiazek: 1
	- Informatyk i autor wielu książek dla inżynierów.
	Mickiewicz Adam (ur. 1798/12/24 zm. 1855/11/26) Napisal ksiazek: 3
	- Polski poeta, działacz i publicysta polityczny.
	Nowak Marek (ur. 1968/07/30) Napisal ksiazek: 2
	- Współczesny pisarz i zarazem pasjonat żeglarstwa.
	Poeta Jan (ur. 1898/02/12 zm.
*/	
CREATE OR REPLACE PROCEDURE P_POBIERZ_AUTOROW
IS
	--### Rekord oparty na tabeli <===============================@@@
	rekord AUTORZY%ROWTYPE;
	
	--### kursor pobierajacy autorow
	CURSOR CURSOR_AUTORZY
	IS
		SELECT * FROM AUTORZY ORDER BY AUT_NAZWISKO ASC;
		
	data_smierci VARCHAR2(20);	
		
BEGIN
	DBMS_OUTPUT.PUT_LINE('# 2 #--------------- Record: Lista autorów -------------------------');
	
	OPEN CURSOR_AUTORZY;
	
	LOOP
		FETCH CURSOR_AUTORZY INTO rekord;
		EXIT WHEN CURSOR_AUTORZY%NOTFOUND;
		
		--### jeśli autor już nie żyje to wyświetlimy datę śmierci
		IF rekord.AUT_ROK_SMIERCI IS NULL THEN
			data_smierci := '';
		ELSE
			data_smierci := ' zm. '||rekord.AUT_ROK_SMIERCI;
		END IF;
		
		-- Wyświetlamy informacje o danym autorze
		DBMS_OUTPUT.PUT_LINE(rekord.AUT_NAZWISKO||' '||rekord.AUT_IMIE||' (ur. '||rekord.AUT_ROK_URODZENIA||data_smierci||') Napisal ksiazek: '||rekord.AUT_LICZBA_KSIAZEK);
		DBMS_OUTPUT.PUT_LINE('- '||rekord.AUT_BIOGRAFIA);
		
	END LOOP;
	
	CLOSE CURSOR_AUTORZY;
	
END;
/
--show error;

BEGIN
	P_POBIERZ_AUTOROW();
END;
/
	
	
	
	
	




-- ##################################################
-- ###3	Pobieranie listy użytkowników którze ostatnio się zarejestrowali w portalu. Użyto rekord oparty na kursorze
/* Wynik zwracany:
	# 3 #--------------- Record: Lista uzytkownikow -------------------------
	Login: Tomek3, Imie: Imie3, Plec: Mezczyzna, Status: Zwykly uzytkownik, Miasto: Kraków
	Login: Tomek2, Imie: Imie2, Plec: Mezczyzna, Status: Zwykly uzytkownik, Miasto: Kraków
	Login: Tomek1, Imie: Imie1, Plec: Mezczyzna, Status: Zwykly uzytkownik, Miasto: Kraków
	Login: User3, Imie: Imie3, Plec: Mezczyzna, Status: Zwykly uzytkownik, Miasto: Warszawa2
	Login: User2, Imie: Imie2, Plec: Mezczyzna, Status: Zwykly uzytkownik, Miasto: Warszawa2
	Login: User1, Imie: Imie1, Plec: Mezczyzna, Status: Zwykly uzytkownik, Miasto: Warszawa2
	Login: Micha87, Imie: Michał, Plec: Mezczyzna, Status: Zwykly uzytkownik, Miasto: Warszawa
	Login: Artur, Imie: Artur, Plec: Mezczyzna, Status: Administrator, Miasto: Kraków
*/
CREATE OR REPLACE PROCEDURE P_POBIERZ_UZYTKOWNIKOW
IS		
	--### kursor pobierajacy ostatnio zarejestrowanych uzytkownikow.
	CURSOR CURSOR_UZYTKOWNICY
	IS
		SELECT UZY_LOGIN, UZY_CZY_ADMIN, UZY_IMIE, UZY_PLEC, MIA_MIASTO 
		FROM UZYTKOWNICY LEFT JOIN MIASTO ON (MIA_ID = MIAK_1_ID)
		ORDER BY UZYK_1_ID DESC;
		
	--### Rekord oparty na kursorze <===============================@@@
	rekord CURSOR_UZYTKOWNICY%ROWTYPE;
	
	plec VARCHAR2(10);
	admin_status VARCHAR2(20);
		
BEGIN
	DBMS_OUTPUT.PUT_LINE('# 3 #--------------- Record: Lista uzytkownikow -------------------------');
	
	OPEN CURSOR_UZYTKOWNICY;
	
	FETCH CURSOR_UZYTKOWNICY INTO rekord;
	WHILE CURSOR_UZYTKOWNICY%FOUND LOOP
		
		-- Sprawdzamy czy uzytkownik jest administratorem portalu
		IF rekord.UZY_CZY_ADMIN=1 THEN 
			admin_status := 'Administrator';		
		ELSE
			admin_status := 'Zwykly uzytkownik';
		END IF;
		
		-- Sprawdzamy plec uzytkownika
		IF rekord.UZY_PLEC='m' THEN
			plec := 'Mezczyzna';		
		ELSE
			plec := 'Kobieta';
		END IF;
				
		DBMS_OUTPUT.PUT_LINE('Login: '||rekord.UZY_LOGIN||', Imie: '||rekord.UZY_IMIE||', Plec: '||plec||', Status: '||admin_status||', Miasto: '||rekord.MIA_MIASTO);
		
		FETCH CURSOR_UZYTKOWNICY INTO rekord;
	END LOOP;
	
END;
/


BEGIN
	P_POBIERZ_UZYTKOWNIKOW();
END;
/








-- ##################################################
-- ###4 Pobieranie ksiazek ktore lubi dany uzytkownik. Użyto rekordu zagnieżdzonego!
/* Wynik zwracany:
	# 4 #-------- Record: Ulubione ksiazki uzytkownika: Artur ---------------
	Pan Tadeusz, Autorzy:
		-> Adam Mickiewicz
		-> Marek Nowak
		-> John Gates
	Programowanie w C++, Autorzy:
		-> Jan Poeta
		-> John Gates	
	Dziady, Autorzy:
		-> Adam Mickiewicz	
	Wielka wyprawa w kosmos, Autorzy:
		-> Adam Mickiewicz
		-> Marek Nowak	
*/

CREATE OR REPLACE PROCEDURE P_ULUBIONE_KSI_UZYTKOWNIKA
	(login IN VARCHAR2)
IS
	-- rekord z informacja o autorze
	TYPE RECORD_AUTOR IS RECORD (
		imie AUTORZY.AUT_IMIE%TYPE,
		nazwisko AUTORZY.AUT_NAZWISKO%TYPE
	);
	
	-- rekord zawierajacy informacje o ksiazce
	--### zagnieżdzone rekordy <===============================@@@
	TYPE RECORD_KSIAZKA IS RECORD (
		tytul KSIAZKI.KSI_TYTUL%TYPE,
		autor1 RECORD_AUTOR,
		autor2 RECORD_AUTOR,
		autor3 RECORD_AUTOR
	);

	ksiazka RECORD_KSIAZKA;
	licznik_autorow NUMBER DEFAULT 1; 
	
BEGIN
		
	DBMS_OUTPUT.PUT_LINE('# 4 #-------- Record: Ulubione ksiazki uzytkownika: '||login||' ---------------');
	
	
	--### uzyto kursor niejawny do wybrania ulubionych ksiazek uzytkownika
	FOR dane IN (
		SELECT KSIK_1_ID, KSI_TYTUL FROM KSIAZKI WHERE KSIK_1_ID IN (	
			SELECT KSI_ID FROM ULUBIONE_KSIAZKI WHERE UZY_ID = (
				SELECT UZYK_1_ID FROM UZYTKOWNICY WHERE UZY_LOGIN = login
			)
		)
	) LOOP 
		
		ksiazka.tytul := dane.KSI_TYTUL;
		
		--### pobranie autorow danej ksiazki do rekordow zagnieżdzonych.
		licznik_autorow:=1; -- reset licznika
		-- rest zmiennych aby nie wyswietlic danych z poprzedneigo pobrania jesli w obecnym pobraniu bedzie mniej autorow
		ksiazka.autor1.imie := NULL;		
		ksiazka.autor1.nazwisko := NULL;	
		ksiazka.autor2.imie := NULL;
		ksiazka.autor2.nazwisko := NULL;
		ksiazka.autor3.imie := NULL;
		ksiazka.autor3.nazwisko := NULL;
		FOR autor IN (
			SELECT AUT_IMIE, AUT_NAZWISKO FROM AUTORZY WHERE AUTK_1_ID IN (
				SELECT AUT_ID FROM AUK_AUTORZY_KSIAZKI WHERE KSI_ID = dane.KSIK_1_ID
			) 
		) LOOP
			
			-- ładujemy do poszczególnych zagnieżdzonych rekordów autorow danej ksiazki
			IF licznik_autorow=1 THEN
				ksiazka.autor1.imie := autor.AUT_IMIE;
				ksiazka.autor1.nazwisko := autor.AUT_NAZWISKO;				
			ELSIF licznik_autorow=2 THEN
				ksiazka.autor2.imie := autor.AUT_IMIE;
				ksiazka.autor2.nazwisko := autor.AUT_NAZWISKO;	
			ELSIF licznik_autorow=3 THEN			
				ksiazka.autor3.imie := autor.AUT_IMIE;
				ksiazka.autor3.nazwisko := autor.AUT_NAZWISKO;	
			END IF;
						
			licznik_autorow:=licznik_autorow+1;
		END LOOP;
				
		--### wyświetlenie ulubionych ksiazek uzytkownika z rekordu ktory zawiera rekord zagnieżdzony
		DBMS_OUTPUT.PUT_LINE(ksiazka.tytul||', Autorzy: ');
		IF NOT(ksiazka.autor1.imie IS NULL) THEN
			DBMS_OUTPUT.PUT_LINE('-> '||ksiazka.autor1.imie||' '||ksiazka.autor1.nazwisko);
		END IF;
		IF NOT(ksiazka.autor2.imie IS NULL) THEN
			DBMS_OUTPUT.PUT_LINE('-> '||ksiazka.autor2.imie||' '||ksiazka.autor2.nazwisko);
		END IF;
		IF NOT(ksiazka.autor3.imie IS NULL) THEN
			DBMS_OUTPUT.PUT_LINE('-> '||ksiazka.autor3.imie||' '||ksiazka.autor3.nazwisko);
		END IF;
		DBMS_OUTPUT.PUT_LINE('');
		
	END LOOP;
	
	
END;
/	
show error;

BEGIN	
	P_ULUBIONE_KSI_UZYTKOWNIKA('Artur');
	P_ULUBIONE_KSI_UZYTKOWNIKA('Micha87');
END;
/
	









	
	




--- ###########################################################################################################
-- Wyjątki ####################################################################################################
--- ###########################################################################################################

-- ##################################################
-- ###5 Procedura generująca użytkowników. 
--     Użytko wyjątki do rzucania błędów w przypadku gdy podano nie poprawne wartości dla pól login, email, imie itd.
/*
	Przykłady zwracanych wyjatkow:
		### Wyjatek: (code: -20003) ORA-20003: Login Tomek juz istnieje w bazie.
		
		ORA-20002: Login a3 jest za krotki! Wymagane sa conajmniej 3 znaki.
		ORA-20005: Email ma nie poprawny format! Musi zawiera prefix, znak @ i domene wraz z koncowka .com, .pl itp
*/
CREATE OR REPLACE PROCEDURE P_DODAJ_UZYTKOWNIKA2	
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
	
	--### deklaracja moich wlasnych wyjatkow <===============================@@@
	my_exception_Licznik EXCEPTION;
	
	--### Uzycie PRAGMA EXCEPTION_INIT <===============================@@@
	my_exception_Login EXCEPTION; 			
	/*
		http://download.oracle.com/docs/cd/B19306_01/appdev.102/b14261/errors.htm#BABGIIBI
		zakres nr bledow -20000 - -20999
	*/
	PRAGMA EXCEPTION_INIT(my_exception_Login,-20001); --### Login jest za długi 
	PRAGMA EXCEPTION_INIT(my_exception_Login,-20002); --### Login jest za krotki
	PRAGMA EXCEPTION_INIT(my_exception_Login,-20003); --### Login juz istnieje w bazie danych
	
	my_exception_Status EXCEPTION;
	my_exception_CzyAdmin EXCEPTION;
	my_exception_Imie EXCEPTION;
	my_exception_Plec EXCEPTION;
	
	my_exception_Email EXCEPTION;
	PRAGMA EXCEPTION_INIT(my_exception_Email,-20004); --### Email jest zbyt dlugi! 
	PRAGMA EXCEPTION_INIT(my_exception_Email,-20005); --### Email ma nie poprawny format!
	PRAGMA EXCEPTION_INIT(my_exception_Email,-20006); --### Email juz istnieje w bazie!
		
	my_exception_DataUrodzenia EXCEPTION;
	my_exception_MiastoUzytkownika EXCEPTION;
	
BEGIN
	-- Przed wykonaniem kodu robimy SAVEPOINT
	SAVEPOINT P_DODAJ_UZY__BEFORE_START;
	-- ||CHR(13)||CHR(10) to znaki nowej linii \r\n
	--DBMS_OUTPUT.PUT_LINE('--- Tworzymy savepoint ------------------'||CHR(13)||CHR(10));
	
	
	--DBMS_OUTPUT.PUT_LINE('Test text');
	
	-- Sprawdzamy czy licznik dodawanych rekordów jest większy od zera
	IF Licznik > 0 THEN	
		
		-- Sprawdzamy długość podanego Loginu połączonego z masymalną wartością licznika.
		-- Np. Uzytkownik20. Sprawdzamy dzieki temu czy w polu tabeli zmiesci sie tak długi login
		-- Pobieramy maksymalna wartosc jaką może przechowywać pole UZY_LOGIN i ładujemy ją do zmiennej int_max
		int_max := F_GET_MAX_SIZE_OF_FIELD('UZYTKOWNICY', 'UZY_LOGIN');		
		IF NOT(LENGTH(Login||Licznik) <= int_max) THEN						
			--### Rzucanie wyjątku 
			RAISE_APPLICATION_ERROR(-20001,'Login jest za dlugi! Maksylanie moze miec '||int_max||' znakow.'); -- <===============================@@@
		END IF;
		
		-- Login musi mieć conajmniej 3 znaki
		IF LENGTH(Login||Licznik) < 3 THEN						
			--### Rzucanie wyjątku 
			RAISE_APPLICATION_ERROR(-20002,'Login '||Login||Licznik||' jest za krotki! Wymagane sa conajmniej 3 znaki.'); -- <===============================@@@
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
			--### Rzucanie wyjątku 
			RAISE_APPLICATION_ERROR(-20004,'Email jest zbyt dlugi! Nie moze przekraczac '||int_max||' znakow.'); -- <===============================@@@
		END IF;
		
		
		--### Sprawdzamy czy format email jest poprawny, czy zawiera znak @ i koncowke domeny
		IF NOT(F_CHECK_EMAIL_FORMAT(Email)) THEN
			--### Rzucanie wyjątku 
			RAISE_APPLICATION_ERROR(-20005,'Email ma nie poprawny format! Musi zawiera prefix, znak @ i domene wraz z koncowka .com, .pl itp'); -- <===============================@@@
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
				--### Rzucanie wyjątku
				RAISE_APPLICATION_ERROR(-20003,'Login '||Login||' juz istnieje w bazie.'); -- <===============================@@@
			END IF;
			
			-- Sprawdzamy czy email juz istnieje w bazie
			select count(UZYK_1_ID) into int_check_email_exist from UZYTKOWNICY where UZY_EMAIL = (i||Email);
			IF int_check_email_exist = 1 THEN
				--### Rzucanie wyjątku 
				RAISE_APPLICATION_ERROR(-20006,'Email '||Iterator||Email||' juz istnieje w bazie!'); -- <===============================@@@
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
	--### Przechwytywanie poszczególnych wyjątków. <===============================@@@
	WHEN my_exception_Licznik THEN
		DBMS_OUTPUT.PUT_LINE('### Wyjatek: Licznik dodawanych rekordow musi byc wiekszy od zera!');
	
	WHEN my_exception_Login THEN --### Obsługą wyjątku z różnymi numerami błędu (wykład 7, str.32) <===============================@@@
		DBMS_OUTPUT.PUT_LINE('### Wyjatek: (code: '||SQLCODE||') '||SQLERRM);
		
	WHEN my_exception_Status THEN
		DBMS_OUTPUT.PUT_LINE('### Wyjatek: Status uzytkownika moze przyjac wartosc tylko 0 lub 1. Gdzie 0-nieaktywne konto, 1-aktywne');
	WHEN my_exception_CzyAdmin THEN
		DBMS_OUTPUT.PUT_LINE('### Wyjatek: Argument CzyAdmin moze przyjac wartosc tylko 0 lub 1. Gdzie 0-zwykly uzytkownik, 1-administrator');
	WHEN my_exception_Imie THEN
		DBMS_OUTPUT.PUT_LINE('### Wyjatek: Imie jest zbyt dlugie! Nie moze przekraczac '||int_max||' znakow.');
	WHEN my_exception_Plec THEN
		DBMS_OUTPUT.PUT_LINE('### Wyjatek: Uzytkownik moze przyjac plec tylko k lub m. Gdzie k-kobieta, m-mezczyzna');
	
	WHEN my_exception_Email THEN --### Obsługą wyjątku z różnymi numerami błędu <===============================@@@
		DBMS_OUTPUT.PUT_LINE('### Wyjatek: (code: '||SQLCODE||') '||SQLERRM);
	
	WHEN my_exception_DataUrodzenia THEN
		DBMS_OUTPUT.PUT_LINE('### Wyjatek: Data urodzenia jest niepoprawna lub podales date wieksza od dzisiejszej.');
	WHEN my_exception_MiastoUzytkownika THEN
		DBMS_OUTPUT.PUT_LINE('### Wyjatek: Podane miasto ma za dluga nazwe! Nie moze przekraczac '||int_max||' znakow.');
	
END;
/		

	
-- wywołanie procedury w bloku anonimowym	
BEGIN
	DBMS_OUTPUT.PUT_LINE('# 5 #--------------- Wyjatki: Generowanie uzytkownikow -------------------------');
	--savepoint art_1;
	P_DODAJ_UZYTKOWNIKA2(3, 'Tomek', 'pass', 1, 0, 'Imie', 'm', 'tomek@domena.pl', '1988/08/12', 'Kraków');	-- powtarzajacy sie login
	P_DODAJ_UZYTKOWNIKA2(3, 'A', 'pass', 1, 0, 'Imie', 'm', 'a@domena.pl', '1977/02/17', 'Kraków'); -- za krótki login
	P_DODAJ_UZYTKOWNIKA2(3, 'Adam', 'pass', 1, 0, 'Imie', 'm', 'adamATdomena.pl', '1988/08/12', 'Kraków'); -- nie poprawnie podany email	
	--rollback to savepoint art_1;
	
END;
/







-- ##################################################
-- ###6 Przechwytywanie wyjatkow. Uzyto FORMAT_CALL_STACK i FORMAT_ERROR_STACK
/*
	Wynik zwracany:
	
	# 6 #--------------- Wyjatki: Przechwytywanie bledu -------------------------
	Wykryto error:
	ORA-20002: Login A3 jest za krotki! Wymagane sa conajmniej 3 znaki.

	Problem wystapil wewnatrz: "TRZOP_ARTUR.P_ERROR"

	Podglad calego stosu:
	----- PL/SQL Call Stack -----
	  object      line
	object
	  handle    number  name
	388AF1CC        14  procedure
	TRZOP_ARTUR.P_ERROR
	388ACBBC         3  anonymous block
*/
CREATE OR REPLACE PROCEDURE P_ERROR 
AS
	zrodlo_bledu VARCHAR2(999);
	stos VARCHAR2(999);
	i INTEGER;
BEGIN
	--### wywołujemy procedure ze zbyt krotki loginem	
	P_DODAJ_UZYTKOWNIKA2(3, 'A', 'pass', 1, 0, 'Imie', 'm', 'a@domena.pl', '1977/02/17', 'Kraków');
EXCEPTION
	WHEN OTHERS THEN
		DBMS_OUTPUT.PUT_LINE('Wykryto error: ');
		DBMS_OUTPUT.PUT_LINE(DBMS_UTILITY.FORMAT_ERROR_STACK); 
		
		-- zapisujemy stos wywołania do zmiennej
		stos := DBMS_UTILITY.FORMAT_CALL_STACK;
		
		-- instr opis funkcji: http://www.techonthenet.com/oracle/functions/instr.php
		-- char(10) to Line feed (LF) "znak sterujący powodujący wysunięcie papieru o jeden wiersz"
		
		-- obliczamy dlugosc wiersza w stosie gdzie zapisana jest nazwa procedury w ktorej wystapil błąd
		i := length(substr(stos,instr(stos, chr(10),1,3)))-length(substr(stos,instr(stos, chr(10),1,4)));
		
		-- wycinamy ten wiersz
		zrodlo_bledu := substr(stos,instr(stos, chr(10),1,3),i);
		
		-- możemy obciac puste znaki na krancach stringu
		zrodlo_bledu := trim(zrodlo_bledu);
		
		-- Wycinamy string od ostatniej spacji. +1 aby bez tej spacji wyciąć
		zrodlo_bledu := substr(zrodlo_bledu,instr(zrodlo_bledu,' ',-1)+1);
				
		DBMS_OUTPUT.PUT_LINE('Problem wystapil wewnatrz: "'||zrodlo_bledu||'"');
		DBMS_OUTPUT.PUT_LINE(chr(10)||'Podglad calego stosu: '||chr(10)||stos);
		
END;
/


BEGIN
	DBMS_OUTPUT.PUT_LINE('# 6 #--------------- Wyjatki: Przechwytywanie bledu -------------------------');
	P_ERROR();
END;
/




	
	
	
	
	


COMMIT;

-- wyświetlamy błędy jeśli jakieś wystąpiły
show error;