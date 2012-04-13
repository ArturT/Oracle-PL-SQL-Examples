-- ##################################################
--
--	Baza danych dla portalu spo³ecznoœciowego o ksi¹¿kach
-- 	2010/2011 Copyright (c) Artur Trzop 12K2
--	Script v. 8.0.0
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
PROMPT Kolekcje;
PROMPT ----------------------------------------------;
PROMPT ;

-- w³¹czamy opcje wyœwietlania komunikatów przy pomocy DBMS_OUTPUT.PUT_LINE();
set serveroutput on;

-- zmiana formatu wyswietlania daty aby mozna bylo poprawnie porownac daty
-- http://www.dba-oracle.com/sf_ora_01830_date_format_picture_ends_before_converting_entire_input_string.htm
alter session set nls_date_format='YYYY/MM/DD';






-- ##################################################
-- ### Pakiet zawierajacy rekordy i tablice VARRAY do przechowywania informacji o ksiazce i jej autorach.
-- 	   Rekrod RECORD_KSIAZKA uzywa typu V_AUTORZY który z kolei przechowuje 50 elementów typu rekord RECORD_AUTOR

CREATE OR REPLACE PACKAGE PACKAGE_ULU_KSI
IS
	-- rekord z informacja o autorze
	TYPE RECORD_AUTOR IS RECORD (
		imie AUTORZY.AUT_IMIE%TYPE,
		nazwisko AUTORZY.AUT_NAZWISKO%TYPE
	);
	
	
	--### VARRAY przechowuje max 50 rekordów z imieniem i nazwiskiem autora
	TYPE V_AUTORZY IS VARRAY(50) OF RECORD_AUTOR;
	
	
	-- rekord zawierajacy informacje o ksiazce
	--### zagnie¿dzone rekordy uzywajacy jako pola autorzy V_AUTORZY <===============================@@@
	TYPE RECORD_KSIAZKA IS RECORD (
		tytul KSIAZKI.KSI_TYTUL%TYPE,
		autorzy V_AUTORZY		
	);	
	
END;
/	
show error;





-- <===============================@@@
-- ##################################################
-- ###1 (V) Pobieranie ksiazek ktore lubi dany uzytkownik. Lista ksiazek jest ladowana do kolekcji zagnie¿d¿onej w rekordzie. 
--      Sama kolekcja jest typu rekordowego.
/* Zwracany wynik:
	# 1 #-------- Ulubione ksiazki uzytkownika: Artur ---------------
	/-------------------------------------\
	| Ksiazka: Pan Tadeusz
	| Autorzy ksiazki:
	|--> Adam Mickiewicz
	|--> Marek Nowak
	|--> John Gates
	\-------------------------------------/

	/-------------------------------------\
	| Ksiazka: Programowanie w C++
	| Autorzy ksiazki:
	|--> Jan Poeta
	|--> John Gates
	\-------------------------------------/

	/-------------------------------------\
	| Ksiazka: Dziady
	| Autorzy ksiazki:
	|--> Adam Mickiewicz
	\-------------------------------------/

	/-------------------------------------\
	| Ksiazka: Wielka wyprawa w kosmos
	| Autorzy ksiazki:
	|--> Adam Mickiewicz
	|--> Marek Nowak
	\-------------------------------------/

*/

CREATE OR REPLACE PROCEDURE P_ULUBIONE_KSI_UZYTKOWNIKA2
	(login IN VARCHAR2)
IS	
	--### zmienna ksiazka bedzie typu RECORD_KSIAZKA pochodz¹cego z naszego pakietu
	ksiazka PACKAGE_ULU_KSI.RECORD_KSIAZKA;
	licznik_autorow NUMBER DEFAULT 1; 
	
BEGIN
		
	DBMS_OUTPUT.PUT_LINE('# 1 #-------- Ulubione ksiazki uzytkownika: '||login||' ---------------');
	
	--### Musimy zainicjalizowac pole autorzy w rekordzie ksiazka aby moglo przechowywac dane typu VARRAY
	ksiazka.autorzy := PACKAGE_ULU_KSI.V_AUTORZY(); -- wywo³anie konstruktora
	
	--### uzytko kursor niejawny do wybrania ulubionych ksiazek uzytkownika
	FOR dane IN (
		SELECT KSIK_1_ID, KSI_TYTUL FROM KSIAZKI WHERE KSIK_1_ID IN (	
			SELECT KSI_ID FROM ULUBIONE_KSIAZKI WHERE UZY_ID = (
				SELECT UZYK_1_ID FROM UZYTKOWNICY WHERE UZY_LOGIN = login
			)
		)
	) LOOP 
		
		-- przypisanie tytulu ksiazki
		ksiazka.tytul := dane.KSI_TYTUL;
		
		-- przed przypisaniem nowych autorów do VARRAY czyscimy jej zawartosc z danych z poprzedniego pobierania autorow
		ksiazka.autorzy.DELETE;
		
		
		-- reset licznika. Ten licznik uzyjemy do wstawiania nazw autorow pod odpowiednie indexy w VARRAY
		licznik_autorow:=1; 
		FOR autor IN (
			SELECT AUT_IMIE, AUT_NAZWISKO FROM AUTORZY WHERE AUTK_1_ID IN (
				SELECT AUT_ID FROM AUK_AUTORZY_KSIAZKI WHERE KSI_ID = dane.KSIK_1_ID
			) 
		) LOOP
			
			-- ³adujemy do poszczególnych zagnie¿dzonych rekordów autorow danej ksiazki
			ksiazka.autorzy.EXTEND;
			ksiazka.autorzy(licznik_autorow).imie := autor.AUT_IMIE;
			ksiazka.autorzy(licznik_autorow).nazwisko := autor.AUT_NAZWISKO;
									
			licznik_autorow:=licznik_autorow+1;
		END LOOP;
		

		
		--### wyœwietlenie ulubionych ksiazek uzytkownika
		DBMS_OUTPUT.PUT_LINE('/-------------------------------------\');
		DBMS_OUTPUT.PUT_LINE('| Ksiazka: '||ksiazka.tytul);
		DBMS_OUTPUT.PUT_LINE('| Autorzy ksiazki: ');
		
		IF ksiazka.autorzy.COUNT > 0 THEN

			-- jeœli s¹ autorzy przypisani do ksiazki to wyswietlamy ich kolejno
			licznik_autorow:=1;
			WHILE licznik_autorow <= ksiazka.autorzy.LAST LOOP
				
				-- wyœwietlamy danego autora
				DBMS_OUTPUT.PUT_LINE('|--> '||ksiazka.autorzy(licznik_autorow).imie||' '||ksiazka.autorzy(licznik_autorow).nazwisko);
				
				--### Przeskakujemy na nastêpny element tablicy
				licznik_autorow := ksiazka.autorzy.NEXT(licznik_autorow);
			END LOOP;
			
			DBMS_OUTPUT.PUT_LINE('\-------------------------------------/'||CHR(10));
			
		ELSE
			DBMS_OUTPUT.PUT_LINE('Brak autorów przypisanych do tej ksiazki.');		
		END IF;
		
				
	END LOOP;
	
	
END;
/	
show error;

BEGIN	
	P_ULUBIONE_KSI_UZYTKOWNIKA2('Artur');
	P_ULUBIONE_KSI_UZYTKOWNIKA2('Micha87');
END;
/












-- ##################################################
-- ###2 (TI) Wyœwietlamy ile ksiazek przeczytal dany uzytkownik. Dane zapisujemy do kolekcji bêd¹cej tablic¹ asocjacyjn¹ czyli par¹ klucz-wartosc.
-- 			Kluczem bêdzie login uzytkownika, a wartoscia ile ksiazek przeczytal. 
/*
	Zwracany wynik:
	
	# 2 #-------- Przeczytane ksiazki uzytkownikow ---------------
	Artur przeczytal ksiazek: 3
	Micha87 przeczytal ksiazek: 3
*/
CREATE OR REPLACE PROCEDURE P_KSIAZKI_PRZECZYTANE
IS	
	--### Deklarujemy nasz¹ kolekcjê index-by
	--### indexy kolekcji bêd¹ typu varchar2
	TYPE TI_PRZECZYTANE_KSI IS TABLE OF NUMBER INDEX BY VARCHAR2(20);
	
	kolekcja TI_PRZECZYTANE_KSI;
	
	-- Deklaracja zmiennej przechowujacej nasz tymczasowy klucz kolekcji
	klucz VARCHAR2(20);
	
BEGIN
		
	--### Pobieramy kursorem niejawnym login uzytkownika i liczbe ksiazek ktore oceni³ (jesli oceni³ ksi¹¿kê to znaczy ¿e j¹ czyta³.)
	FOR dane IN (
		SELECT U.UZY_LOGIN, COUNT(*) ILE
		FROM UZYTKOWNICY U RIGHT JOIN OCENY_KSIAZEK O ON U.UZYK_1_ID = O.UZY_ID		
		GROUP BY U.UZY_LOGIN
	) LOOP
		
		--### zapisanie do ablicy asocjacyjnej jako klucz unikatowy login, a jako wartosc liczbe przeczytanych ksiazek
		kolekcja(dane.UZY_LOGIN) := dane.ILE;
		
	END LOOP;
	
	
	DBMS_OUTPUT.PUT_LINE('# 2 #-------- Przeczytane ksiazki uzytkownikow ---------------');
	
	--### Wyœwietlamy dane z kolekcji
	klucz := kolekcja.FIRST;
	LOOP
		
		-- klucz przechowuje nasz login uzytkownika
		DBMS_OUTPUT.PUT_LINE(klucz||' przeczytal ksiazek: '||kolekcja(klucz));
			
		--### wychodzimy z petli gdy wyswietlimy ostatni klucz
		EXIT WHEN klucz = kolekcja.LAST;
		
		--### ustawiamy jako klucz nastêpny klucz po tym ktory teraz uzywalismy
		-- ustawienie to musi znajdowaæ siê po warunku wyjœcia z pêtli
		klucz := kolekcja.NEXT(klucz);
		
	END LOOP;

END;
/


BEGIN
	P_KSIAZKI_PRZECZYTANE();
END;
/






	
	
	
	
	
-- ##################################################
-- ###3 (T)	Procedura tworzy kolekcjê TABLE index-by (dla ka¿dego autora. Klucz to ID autora),
--		    która to wskazuje na kolekcjê TABLE przechowuj¹c¹ nazwy ksi¹¿ek przypisanych do danego autora.
/*
	Wynik zwracany:
	
	# 3 #-------- Ksiazki autorow ---------------
	====-> Adam Mickiewicz <-====
	-> Pan Tadeusz
	-> Dziady
	-> Konrad Wallenrod
	-> Wielka wyprawa w kosmos
	====-> Jan Poeta <-====
	-> Powiesc prawdziwa
	-> Programowanie w C++
	====-> Marek Nowak <-====
	-> Pan Tadeusz
	-> Wielka wyprawa w kosmos
	-> Super ksiazka 2
	====-> John Gates <-====
	-> Pan Tadeusz
	-> Programowanie w C++
*/	
CREATE OR REPLACE PROCEDURE P_KSIAZKI_AUTOROW
IS		
	-- kolekcja T przechowuje tytuly ksiazek
	TYPE T_KSIAZKI IS TABLE OF VARCHAR2(254);
	
	-- kolekcja TI przechowuje ksiazki przypisane do danego autora. Numer klucza dla tej kolekcji bedzie IDentyfikatorem autora (dlatego uzylismy TI)
	-- PLS_INTEGER http://www2.error-code.org.uk/view.asp?e=ORACLE-PLS-00315
	TYPE TI_AUTORZY IS TABLE OF T_KSIAZKI INDEX BY PLS_INTEGER;
	
	kolekcja_autorzy TI_AUTORZY;
	kolekcja_ksiazki T_KSIAZKI;
	
	-- potrzebny przy tworzeniu kolekcji ksiazek dla danego autora
	licznik INTEGER DEFAULT 1;
	
	-- klucz bêdzie zawieral ID danego autora dla ktorego bedziemy odczytywac ksiazki ktore napisa³
	klucz INTEGER; 
	
	-- zmienne do przechowywania tymczasowo odczytywanego autora z bazy
	imie VARCHAR2(100);
	nazwisko VARCHAR2(150);
	
BEGIN
	
	-- wywo³anie konstruktora dla zwyklej kolekcji jest niezbêdne!	
	kolekcja_ksiazki := T_KSIAZKI();
	-- kolekcja_autorzy := TI_AUTORZY(); -- To Ÿle!! bo to kolekcja index-by
	
	
	DBMS_OUTPUT.PUT_LINE('# 3 #-------- Ksiazki autorow ---------------');
	
	--### Pobieramy ID autorow
	FOR dane IN (
		SELECT AUTK_1_ID FROM AUTORZY ORDER BY AUTK_1_ID ASC
	) LOOP
			
		-- przed odczytaniem ksiazek danego autora kasujemy kolekcja_ksiazki z zawartoœci¹ pochodz¹c¹ z poprzedniej iteracji
		kolekcja_ksiazki.DELETE;
		
		-- resetujemy licznik
		licznik := 1;
		
		-- Pobieramy ksiazki napisane przez autora o danym ID dla tej iteracji dane.AUTK_1_ID	
		FOR dane2 IN (
			SELECT K.KSI_TYTUL
			FROM KSIAZKI K RIGHT JOIN AUK_AUTORZY_KSIAZKI A ON (K.KSIK_1_ID = A.KSI_ID)
			WHERE A.AUT_ID = dane.AUTK_1_ID		
		) LOOP
			
			-- Rozszerzamy nasz¹ kolekcjê o nowy element
			kolekcja_ksiazki.EXTEND;
			kolekcja_ksiazki(licznik) := dane2.KSI_TYTUL;
			
			licznik := licznik+1;
			
		END LOOP;
		
		-- Gdy ju¿ utworzylismy kolekcje ksiazek to mozemy ja przypisac do kolekcji autorow dla autora o danym ID jako klucz kolekcji
		kolekcja_autorzy(dane.AUTK_1_ID) := kolekcja_ksiazki;
		
	END LOOP;
	
	
	
	
	--### Wyœwietlenie dla kazdego autora ksiazek ktore napisal
	klucz := kolekcja_autorzy.FIRST; -- klucz to ID autora
	LOOP
		
		--### Pobranie nazwy autora dla ktorego wyswietlimy ksiazki z kolekcji
		SELECT AUT_IMIE, AUT_NAZWISKO INTO imie, nazwisko FROM AUTORZY WHERE AUTK_1_ID = klucz;
		DBMS_OUTPUT.PUT_LINE('====-> '||imie||' '||nazwisko||' <-====');
		
		--### wyœwietlamy ksiazki danego autora z kolekcji 
		FOR i IN 1..kolekcja_autorzy(klucz).COUNT 
		LOOP
						
			DBMS_OUTPUT.PUT_LINE('-> '||kolekcja_autorzy(klucz)(i));
			
		END LOOP;
		
		
		-- warunek stopu
		EXIT WHEN klucz=kolekcja_autorzy.LAST;
		
		-- przypisujemy nastepny klucz
		klucz := kolekcja_autorzy.NEXT(klucz);	
	
	END LOOP;
	

END;
/

	
BEGIN
	P_KSIAZKI_AUTOROW();
END;
/	
	
	
	
	
	



-- ##################################################
-- ###4 Tabela GATUNKI_ULUBIONE bêdzie przechowywa³a ulubione gatunki ksi¹¿ek u¿ytkowników. 
-- 		Ka¿dy gatunek bêdzie zapisany w kolekcji która jest atrybutem tabeli GATUNKI_ULUBIONE.
/* Zwracane wyniki:

	# 4 #-------- Ulubione gatunki ksiazek uzytkownikow ---------------
	Uzytkownik: Artur lubi gatunki:
	-> Krymina³y
	-> Science fiction
	Uzytkownik: Micha87 lubi gatunki:
	-> Romanse
	-> Thriller
	-> Krymina³y
*/
-- Kasowanie tabeli. Odkomentowaæ aby skasowaæ tabelê
--/* -- Wskazówka: Dodaj¹c znaki -- przed komentarz blokowy mo¿emy wy³aczyæ go.
DELETE FROM GATUNKI_ULUBIONE;
ALTER TABLE GATUNKI_ULUBIONE DROP COLUMN GAT_GATUNKI;
ALTER TABLE GATUNKI_ULUBIONE DROP CONSTRAINT CSR_PK_GATUNKI_ULUBIONE;
DROP TABLE GATUNKI_ULUBIONE CASCADE CONSTRAINTS;
COMMIT;
--*/


--### Tworzymy typ kolekcji która bêdzie zagnie¿dzonym atrybutem encji: GATUNKI_ULUBIONE
DROP TYPE T_GATUNKI;
CREATE OR REPLACE TYPE T_GATUNKI IS TABLE OF VARCHAR2(50); 
/ 
--### WAZNE!!! Pamiêtaæ o powy¿szym znaku / przy tworzeniu typu!!!!!!!!!!!!



-- Tworzymy tabele
CREATE TABLE GATUNKI_ULUBIONE (
  UZY_ID INT NOT NULL
, GAT_GATUNKI T_GATUNKI
) NESTED TABLE GAT_GATUNKI STORE AS TAB_GATUNKI;

-- Dodajemy klucz g³owny
ALTER TABLE GATUNKI_ULUBIONE ADD CONSTRAINT CSR_PK_GATUNKI_ULUBIONE PRIMARY KEY (UZY_ID);



---### Dodajemy przyk³adowe rekordy do tabeli 
INSERT INTO GATUNKI_ULUBIONE (UZY_ID, GAT_GATUNKI) VALUES (1, T_GATUNKI('Krymina³y', 'Science fiction'));
INSERT INTO GATUNKI_ULUBIONE (UZY_ID, GAT_GATUNKI) VALUES (2, T_GATUNKI('Romanse', 'Thriller', 'Krymina³y'));

--### Procedura pobiera ulubione gatunki ksi¹¿ek danego u¿ytkownika.
CREATE OR REPLACE PROCEDURE P_ULUBIONE_GATUNKI_KSIAZEK 
IS	
	kolekcja_gatunki T_GATUNKI;
	klucz NUMBER;
	
BEGIN 
	
	DBMS_OUTPUT.PUT_LINE('# 4 #-------- Ulubione gatunki ksiazek uzytkownikow ---------------');
				
		
	--### Pobieramy uzytkownikow ktorzy okreœlili swoje ulubione gatunki ksiazek
	FOR dane IN (
		SELECT G.UZY_ID, G.GAT_GATUNKI, U.UZY_LOGIN 
		FROM GATUNKI_ULUBIONE G LEFT JOIN UZYTKOWNICY U ON G.UZY_ID = U.UZYK_1_ID
	) LOOP	
	
		-- pobieramy kolekcjê z gatunkami
		DBMS_OUTPUT.PUT_LINE('Uzytkownik: '||dane.UZY_LOGIN||' lubi gatunki: ');
		
		--### Iterujemy po kolekcji z bazy danych
		klucz := dane.GAT_GATUNKI.FIRST;
		LOOP
			
			DBMS_OUTPUT.PUT_LINE('-> '||dane.GAT_GATUNKI(klucz));
			
			-- Warunek stopu
			EXIT WHEN klucz = dane.GAT_GATUNKI.LAST;
			
			klucz := dane.GAT_GATUNKI.NEXT(klucz);
		END LOOP;
	
	END LOOP;
	
		

END;
/


BEGIN
	-- Wywo³ujemy procedure sprawdzaj¹c¹ ulubione gatunki poszczegolnych uzytkownikow
	P_ULUBIONE_GATUNKI_KSIAZEK();
END;
/	
	
	


	
	
-- ##################################################
-- ###5 Przyk³ad wyszukiwania uzytkownikow ktorzy lubia dane gatunki
DECLARE
	klucz NUMBER;
BEGIN

	DBMS_OUTPUT.PUT_LINE('# 5 #---- Uzytkownicy ktorzy lubia kryminaly, romanse, thriller ---');
	--/*
	--### Pobieramy u¿ytkowników którzy lubi¹ ksi¹¿ki z gatunku: Romanse, Krymina³y, Thriller
	--### Kolejnoœæ wyst¹pieñ nazw gatunków w kolekcji w klauzuli where nie ma znaczenia.  <===============================@@@
	--### Liczy siê to aby kolekcja zawiera³a dok³adnie te 3 gatunki!!! 
	FOR dane2 IN (
		SELECT UZY_ID, GAT_GATUNKI, UZY_LOGIN 
		FROM GATUNKI_ULUBIONE LEFT JOIN UZYTKOWNICY ON UZY_ID = UZYK_1_ID
		WHERE GAT_GATUNKI = T_GATUNKI('Krymina³y', 'Romanse', 'Thriller')
		
	) LOOP	
	
		-- pobieramy kolekcjê z gatunkami
		DBMS_OUTPUT.PUT_LINE('Uzytkownik: '||dane2.UZY_LOGIN||' lubi gatunki: ');
		DBMS_OUTPUT.PUT_LINE('Sprawdzamy czy faktycznie lubi te gatunki jak w zapytaniu:');
		
		--### Iterujemy po kolekcji z bazy danych
		klucz := dane2.GAT_GATUNKI.FIRST;
		LOOP
			
			DBMS_OUTPUT.PUT_LINE('-> '||dane2.GAT_GATUNKI(klucz));
			
			-- Warunek stopu
			EXIT WHEN klucz = dane2.GAT_GATUNKI.LAST;
			
			klucz := dane2.GAT_GATUNKI.NEXT(klucz);
		END LOOP;
	
	END LOOP;	
	--*/
	
END;
/





-- ##################################################
-- ### Funkcja sprawdzajaca czy w danej kolekcji istnieje dana wartosc. Zwraca prawa/falsz
CREATE OR REPLACE FUNCTION P_CHECK_VALUE_IN_T_GATUNKI
	(kolekcja IN T_GATUNKI, wartosc IN VARCHAR2)
	RETURN BOOLEAN		
IS
	czy_znaleziono BOOLEAN DEFAULT FALSE;
	klucz NUMBER;
BEGIN
	klucz := kolekcja.FIRST;
	LOOP		
		-- Jeœli w kolekcji istnieje dana wartosc to zapisujemy to do zmiennej czy_znaleziono i wychodzimy z petli
		IF kolekcja(klucz) = wartosc THEN
			czy_znaleziono := TRUE;
			EXIT;
		END IF;
			
		-- Warunek stopu
		EXIT WHEN klucz = kolekcja.LAST;
		
		klucz := kolekcja.NEXT(klucz);
	END LOOP;
	
	RETURN czy_znaleziono;
END;
/



-- ##################################################
-- ###6 Procedura aktualizujaca ulubione gatunki ksiazek danego u¿ytkownika. Mo¿na okreœliæ parametr czy nadpisaæ gatunki ju¿ znajduj¹ce siê w bazie
--		o te ktore podano jako argument, czy moze po prostu dopisac do kolekcji nowe gatunki sprawdzaj¹c aby siê nie dublowa³y.
/* Zwracane wyniki:

	# 6 #---- Aktualizacja kolekcji ulubionych gatunkow ---
	Dopisano gatunki do kolekcji!
	Nadpisano gatunki w kolekcji!
	# 4 #-------- Ulubione gatunki ksiazek uzytkownikow ---------------
	Uzytkownik: Artur lubi gatunki:
	-> Krymina³y 															(Krymina³ siê nie powtórzy³)
	-> Science fiction														
	-> Horrory																(Dopisano horrory i historyczne)
	-> Historyczne
	Uzytkownik: Micha87 lubi gatunki:
	-> Biografie															(Nowe gatunki nadpisa³y poprzednie: Romanse, Thriller, Krymina³y)
	-> Romanse
*/
CREATE OR REPLACE PROCEDURE P_UPDATE_ULUBIONE_GATUNKI
	(login IN VARCHAR2, kolekcja_arg IN T_GATUNKI, parametr IN VARCHAR2)
IS	
	id_uzytkownika INTEGER;
	kolekcja_z_bazy T_GATUNKI;
	kolekcja_nowa T_GATUNKI;
	klucz NUMBER;
	klucz_nowy NUMBER;
BEGIN
	
	-- pobieramy id uzytkownika na podstawie jego loginu
	SELECT UZYK_1_ID INTO id_uzytkownika FROM UZYTKOWNICY WHERE UZY_LOGIN = login;
		
	
	IF parametr = '_DOPISZ_' THEN
		
		-- pobieramy zawartosc kolekcji uzytkownika
		SELECT GAT_GATUNKI INTO kolekcja_z_bazy FROM GATUNKI_ULUBIONE WHERE UZY_ID = id_uzytkownika; 
		
		-- Jeœli coœ znajduje siê w kolekcji zapisanej w bazie to trzeba sprawdziæ jakie s¹ w niej wartoœci i czy dopisywane wartoœci siê nie powtarzaja
		IF kolekcja_z_bazy.COUNT > 0 THEN
			
			-- nowa kolekcja zawiera dane z kolekcji z bazy danych. Do nowej kolekcji bedziemy dopisywac kolejne wartosci
			kolekcja_nowa := kolekcja_z_bazy;
			
			--### iterujemy po kolekcji przeslanej jako argument procedury. Ka¿d¹ wartosc z kolekcji sprawdzimy funkcj¹ P_CHECK_VALUE_IN_T_GATUNKI
			--### czy wystêpuje w kolekcji z bazy danych
			klucz := kolekcja_arg.FIRST;
			LOOP		
				
				--### Jeœli wartoœæ która mamy dopisaæ do bazy nie istnieje w kolekcji z bazy to mo¿emy j¹ dodaæ na koñcu tej kolekcji
				IF P_CHECK_VALUE_IN_T_GATUNKI(kolekcja_z_bazy, kolekcja_arg(klucz)) = FALSE THEN 
					-- ustalamy numer klucza nowego dodanego
					klucz_nowy := kolekcja_nowa.COUNT+1;
					-- rozszerzamy now¹ kolekcjê o nowy element
					kolekcja_nowa.EXTEND;
					-- zapisujemy wartosc do nowej kolekcji
					kolekcja_nowa(klucz_nowy) := kolekcja_arg(klucz);
				END IF;	
					
				-- Warunek stopu
				EXIT WHEN klucz = kolekcja_arg.LAST;
				
				klucz := kolekcja_arg.NEXT(klucz);
			END LOOP;
			
			
		ELSE
			--kolekcja jest pusta wiec po prostu dopiszemy do bazy nasz¹ kolekcje podana jako argument
			kolekcja_nowa := kolekcja_arg;
		END IF;
		
		
		-- ustawienie nowej kolekcji
		UPDATE GATUNKI_ULUBIONE SET GAT_GATUNKI = kolekcja_nowa WHERE UZY_ID = id_uzytkownika;
		DBMS_OUTPUT.PUT_LINE('Dopisano gatunki do kolekcji!');
		
		
		
		
	ELSIF parametr = '_NADPISZ_' THEN
		
		kolekcja_nowa := kolekcja_arg;
		UPDATE GATUNKI_ULUBIONE SET GAT_GATUNKI = kolekcja_nowa WHERE UZY_ID = id_uzytkownika;
		DBMS_OUTPUT.PUT_LINE('Nadpisano gatunki w kolekcji!');
		
	ELSE
		DBMS_OUTPUT.PUT_LINE('Nie okreœlono parametru procedury!');
	END IF;
	
	
END;
/


BEGIN
	DBMS_OUTPUT.PUT_LINE('# 6 #---- Aktualizacja kolekcji ulubionych gatunkow ---');

	--### Ustawiamy ze uzytkownik Artur lubi ksiazki Horrory, Historyczne, Krymina³y. Gatunki te zostan¹ dopisane do tych które teraz lubi
	--### Gatunek Krymina³y ju¿ wystêpuje jako ulubiony uzytkownika wiêc on nie zostanie dopisany do kolekcji <=#####
	P_UPDATE_ULUBIONE_GATUNKI('Artur', T_GATUNKI('Horrory', 'Historyczne', 'Krymina³y'), '_DOPISZ_');
	
	--### Nadpisujemy ulubione gatunki uzytkownika Micha87
	P_UPDATE_ULUBIONE_GATUNKI('Micha87', T_GATUNKI('Biografie', 'Romanse'), '_NADPISZ_');
	
	
	-- Wywo³ujemy procedure wyœwietlaj¹c¹ ulubione gatunki ksiazek uzytkownikow aby sprawdzic czy faktycznie zapisano w tabeli zmiany 	
	P_ULUBIONE_GATUNKI_KSIAZEK();
END;
/




	
	
	
	
	


COMMIT;

-- wyœwietlamy b³êdy jeœli jakieœ wyst¹pi³y
show error;