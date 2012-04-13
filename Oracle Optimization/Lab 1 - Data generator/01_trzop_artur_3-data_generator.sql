-- ##################################################
--
--	Bazy danych 
-- 	2011 Copyright (c) Artur Trzop 12K2
--	Script v. 1.2.0
--
-- ##################################################

-- włączamy opcje wyświetlania komunikatów przy pomocy DBMS_OUTPUT.PUT_LINE();
set serveroutput on;
set feedback on;

-- wyk.3, str.46 ustawianie domyslnego sposobu wyswietlania daty
ALTER SESSION SET NLS_DATE_FORMAT = 'yyyy/mm/dd hh24:mi:ss';

CLEAR SCREEN;
PROMPT ----------------------------------------------;
PROMPT Czyszczenie ekranu;
PROMPT ----------------------------------------------;
PROMPT ;


-- ##################################################
PROMPT ;
PROMPT ----------------------------------------------;
PROMPT Generowanie danych w tabelach;
PROMPT ----------------------------------------------;
PROMPT ;



-- przed wygenerowaniem danych kasujemy poprzednio wygenerowane dane
DELETE FROM OSOBY;
DELETE FROM ADRES_POCZTY;

-- ustawiamy na nowo sekwencje
DROP SEQUENCE SEQ_ADRES_POCZTY;
CREATE SEQUENCE SEQ_ADRES_POCZTY INCREMENT BY 1 START WITH 1
MAXVALUE 9999999999 MINVALUE 1; 

DROP SEQUENCE SEQ_OSOBY;
CREATE SEQUENCE SEQ_OSOBY INCREMENT BY 1 START WITH 1
MAXVALUE 9999999999 MINVALUE 1; 




-- ####################################################################################################

-- Tabela 1 to: ADRES_POCZTY - przechowuje mniej rekordow
-- Tabela 2 to: OSOBY - przechowuje dużo rekordow od 1 do 2 mln
-- Argumenty procedury określają ile nalezy wygenerowac rekordow w danej tabeli
/*
	Zwracany wynik:
	# 1 #-- Tworzymy kolekcje z ktorych bedziemy generowac dane --
	+ Kolekcje zostaly utworzone
	+ Wygenerowano adresy urzedow pocztowych: 10
	+ Wygenerowano osob: 100
	--- Statystyki wykonania skryptu ----
	Interval: +00 00:00:01.116000
	Seconds: 1.116
*/
CREATE OR REPLACE PROCEDURE P_GENERUJ_DANE
	(IleTab1 IN INT, IleTab2 IN INT)
IS
	-- tworzymy kolekcje typu takiego jak pole HEL_FIELD w tabeli HELP_TABLE przechowującej losowe dane,
	-- z których będziemy generować dane do dwoch tabel
	TYPE T_FIELD IS TABLE OF HELP_TABLE.HEL_FIELD%TYPE;
	
	-- kolekcja w ktorej generujemuy poszczegolne numery do NIPu
	TYPE T_NIP IS TABLE OF NUMBER;
	
	kolekcja_nip T_NIP;
	
	-- tworzymy zmienne kolekcji ktore beda przechowywac odpowiednie dane ktore uzyjemy do losowania informacji
	kolekcja_imie_mezczyzna T_FIELD;
	kolekcja_imie_kobieta T_FIELD;
	kolekcja_nazwisko T_FIELD;
	kolekcja_ulica T_FIELD;
	kolekcja_miasto T_FIELD;
	kolekcja_kod_pocztowy T_FIELD;
	kolekcja_nip_wylosowane T_FIELD;
	
	-- licznik wykorzystamy jako klucz podczas zapisu danych do kolekcji
	-- zaczynamy od 0 bo przy pierwszej inkrementacji zwiekszymy licznik o jeden dzieki czemu indexy kolekcji będą
	-- zaczynać się od 1. A co za tym idzie licznik pod koniec wszystkich iteracji bedzie zawieral liczbe elementów 
	-- w danej kolekcji
	licznik0 INTEGER DEFAULT 0; -- imiona meskie
	licznik1 INTEGER DEFAULT 0; -- imiona zenskie
	licznik2 INTEGER DEFAULT 0; -- nazwisko
	licznik3 INTEGER DEFAULT 0; -- ulica
	licznik4 INTEGER DEFAULT 0; -- miasto
	licznik5 INTEGER DEFAULT 0; -- kod pocztowy
	licznik_dodanych_urzedow INTEGER DEFAULT 0;
	licznik_dodanych_osob INTEGER DEFAULT 0;
	
	-- zmienna potrzebna przy weryfikowaniu czy dany numer kodu pocztowego widnieje juz w bazie
	zm_kod_pocztowy ADRES_POCZTY.ADR_KOD_POCZTOWY%TYPE;
	-- pomocnicze zmienne do przechowywania liczb
	zm_liczba INT DEFAULT 0;
	zm_liczba2 INT DEFAULT 0;
	zm_real NUMBER;
	zm_moja_losowa INTEGER DEFAULT 0;
	zm_oso_plec OSOBY.OSO_PLEC%TYPE;
	zm_oso_imie OSOBY.OSO_IMIE%TYPE;
	zm_oso_data_urodzenia VARCHAR2(10); -- format: 1957/02/22
	zm_oso_nip VARCHAR2(10) DEFAULT '';
	
	zm_IleTab1 INT DEFAULT 0;
		
	v_begin TIMESTAMP(9);
    v_end TIMESTAMP(9);
    v_interval INTERVAL DAY TO SECOND;
	
	c_liczba INT DEFAULT 999999; -- domyślna liczba losowych danych pobieranych z bazy do kolekcji
	
BEGIN

	zm_IleTab1 := IleTab1;
	
	v_begin := SYSTIMESTAMP;
	
	-- wywołanie konstruktora dla zwyklej kolekcji jest niezbędne!	
	kolekcja_imie_mezczyzna := T_FIELD();
	kolekcja_imie_kobieta := T_FIELD();
	kolekcja_nazwisko := T_FIELD();
	kolekcja_ulica := T_FIELD();
	kolekcja_miasto := T_FIELD();
	kolekcja_kod_pocztowy := T_FIELD();
	
	-- kolekcja ta bedzioe zawierac uzyte juz NIPy aby ich nie dublowac
	kolekcja_nip_wylosowane := T_FIELD();
	
	-- tworzymy kolekcje ktora bedzie zawierac NIP
	-- rozszerzamy ja do 10 elementów
	kolekcja_nip := T_NIP();
	FOR i IN 1..10 LOOP
		kolekcja_nip.EXTEND;
	END LOOP;
	

	DBMS_OUTPUT.PUT_LINE('# 1 #-- Tworzymy kolekcje z ktorych bedziemy generowac dane --');
		
	
	FOR dane IN (
		SELECT HEL_FIELD, HEL_TYPE FROM HELP_TABLE ORDER BY HELK_1_ID ASC
	) LOOP	
	
		-- dodajemy imiona meskie do wlasciwej kolekcji
		IF dane.HEL_TYPE = 0 THEN
			
			IF licznik0 < c_liczba THEN
			
			licznik0 := licznik0+1;
			-- Rozszerzamy naszą kolekcję o nowy element
			kolekcja_imie_mezczyzna.EXTEND;
			kolekcja_imie_mezczyzna(licznik0) := dane.HEL_FIELD;
			--DBMS_OUTPUT.PUT_LINE(kolekcja_imie_mezczyzna(licznik0)); -- podgląd zapisanych imion
			END IF;
						
		ELSIF dane.HEL_TYPE = 1 THEN
			
			IF licznik1 < c_liczba THEN
			licznik1 := licznik1+1;
			kolekcja_imie_kobieta.EXTEND;
			kolekcja_imie_kobieta(licznik1) := dane.HEL_FIELD;
			END IF;
					
		ELSIF dane.HEL_TYPE = 2 THEN
			
			IF licznik2 < c_liczba THEN
			licznik2 := licznik2+1;
			kolekcja_nazwisko.EXTEND;
			kolekcja_nazwisko(licznik2) := dane.HEL_FIELD;
			END IF;
		
		ELSIF dane.HEL_TYPE = 3 THEN
			
			IF licznik3 < c_liczba THEN
			licznik3 := licznik3+1;
			kolekcja_ulica.EXTEND;
			kolekcja_ulica(licznik3) := dane.HEL_FIELD;	
			END IF;			
		
		ELSIF dane.HEL_TYPE = 4 THEN
			
			IF licznik4 < c_liczba THEN
			licznik4 := licznik4+1;
			kolekcja_miasto.EXTEND;
			kolekcja_miasto(licznik4) := dane.HEL_FIELD;
			END IF;
				
		ELSIF dane.HEL_TYPE = 5 THEN
			
			IF licznik5 < c_liczba THEN
			licznik5 := licznik5+1;
			kolekcja_kod_pocztowy.EXTEND;
			kolekcja_kod_pocztowy(licznik5) := dane.HEL_FIELD;			
			END IF;
			
		END IF;
	
	END LOOP;
	
	--DBMS_OUTPUT.PUT_LINE('bbb'||licznik0);
	--kolekcja_kod_pocztowy.EXTEND;
	--kolekcja_kod_pocztowy(1) := 'aaa'; 
	--#DBMS_OUTPUT.PUT_LINE('test: '||kolekcja_kod_pocztowy.count);
	--kolekcja_kod_pocztowy(1)
	--#DBMS_OUTPUT.PUT_LINE('+ Kolekcje zostaly utworzone');
	
	
	
	
	-- # -------------------------------------------------
	
	
	--## Przed wygenerowaniem rekordow dla tabeli 1 sprawdzamy czy dysponujemy odpowiednia liczba unikatowych kodow pocztowych aby
	-- mozna bylo stworzyc odpowiednia liczbe rekordow
	-- jeśli mamy za malo kodow pocztowych to ograniczamy liczbe rekordow dla tabeli1
	--/*
	SELECT count(*) INTO zm_liczba FROM HELP_TABLE WHERE HEL_TYPE=5;
	IF zm_IleTab1 > zm_liczba THEN
		zm_IleTab1 := floor(zm_liczba/2);
	END IF;
	--DBMS_OUTPUT.PUT_LINE('l: '||zm_IleTab1);
	--zm_IleTab1:=0;
	--*/
	
	--### Generowanie danych dla tabeli 1: ADRES_POCZTY
		--@@@@@@ Aby sprawdzić czy w bazie występują np. dwa takie same miasta mozna uzyc zapytania:
		-- select adr_miasto, count(adr_miasto) from adres_poczty group by adr_miasto having count(adr_miasto)>1;
	FOR i IN 1..zm_IleTab1 
	LOOP
		
		
		--### Sprawdzamy czy dany kod pocztowy juz wystepuje w bazie 
		--####### WAZNE, chroni nas przed naruszeniem unikatowego klucza nałożonego na pole kod pocztowy @@@@@@@@@@@@		
		
		--### Mniej wydajne sprawdzenie poniewaz wykonuje zapytanie do bazy za kazdym razem!
			-- zm_kod_pocztowy := kolekcja_kod_pocztowy(TRUNC(dbms_random.value(1,licznik5)));
			-- SELECT count(*) INTO zm_liczba FROM ADRES_POCZTY WHERE ADR_KOD_POCZTOWY = zm_kod_pocztowy;
			-- -- Jeśli już w bazie jest adres z takim kodem pocztowym to ponawiamy losowanie kodu pocztowego
			-- WHILE zm_liczba > 0
			-- LOOP
				-- zm_kod_pocztowy := kolekcja_kod_pocztowy(TRUNC(dbms_random.value(1,licznik5)));
				-- SELECT count(*) INTO zm_liczba FROM ADRES_POCZTY WHERE ADR_KOD_POCZTOWY = zm_kod_pocztowy;
			-- END LOOP;
				
		--### Bardziej wydajne sprawdzenie. Sprawdza czy dany kod pocztowy zostal usuniety z kolekcji, jesli 
		-- tak to znaczy ze juz go przydzielono i nie moze byc uzyty drugi raz
		zm_liczba := to_number(TRUNC(dbms_random.value(1,licznik5)));
		
		zm_kod_pocztowy := kolekcja_kod_pocztowy(zm_liczba);
				
		WHILE zm_kod_pocztowy IS NULL 
		LOOP
			
			-- jeśli pod danym indexem w kolekcji jest NULL, a nie kod pocztowy to znaczy ze juz ten kod został uzyty.
			-- losujemy więc nowy kod pocztowy i ponawiamy sprawdzenie w pętli
			zm_liczba := to_number(TRUNC(dbms_random.value(1,licznik5)));
			zm_kod_pocztowy := kolekcja_kod_pocztowy(zm_liczba);
		END LOOP;
		
		--### możemy już nadpisać użyty kod pocztowy w kolekcji NULLem aby więcej nie był używany
		kolekcja_kod_pocztowy(zm_liczba) := NULL;
		
		
		--DBMS_OUTPUT.PUT_LINE('test: '||TRUNC(dbms_random.value(1,101)));
		-- funkcja TRUNC odcina wartosci po przecinku
		INSERT INTO ADRES_POCZTY (ADR_MIASTO, ADR_KOD_POCZTOWY, ADR_ULICA, ADR_NR_LOKALU)
		VALUES (
			kolekcja_miasto(TRUNC(dbms_random.value(1,licznik4)))
		,	zm_kod_pocztowy
		,	kolekcja_ulica(TRUNC(dbms_random.value(1,licznik3)))
		,	to_char(TRUNC(dbms_random.value(1,99))||'/'||TRUNC(dbms_random.value(1,99)))
		);
		
		/*
		licznik_dodanych_urzedow := licznik_dodanych_urzedow+1;
		-- wyświetlamy potwierdzenie dodania osob co 1000 rekordow
		IF mod(licznik_dodanych_urzedow,10)=0 THEN
			DBMS_OUTPUT.PUT_LINE('- Dodano do tej pory urzedow: '||licznik_dodanych_urzedow);
		END IF;
		*/
		
	END LOOP;
	DBMS_OUTPUT.PUT_LINE('+ Wygenerowano adresy urzedow pocztowych: '||zm_IleTab1);
	
	
	
	
	-- # -------------------------------------------------
	
	
	
	--### Generowanie osób ######################################################################
	FOR i IN 1..IleTab2 
	LOOP
		
		--### Losujemy płeć. 0-mezczyzna, 1-kobieta
		--### Od płci zależy jakie imie wylosujemy
		-- potrzebny jest duzy zakres a nie tylko od 0 do 1 poniewaz generowane sa liczby zmienno przecinkowe! 
		-- przez co obciecie koncowki powoduje ze trafiamy praktycznie caly czas na tą samą liczbę. 
		-- Stąd też użycie duzego zakresu 1 - 9999		
		zm_liczba := TRUNC(dbms_random.value(1,9999)); -- losowanie płci random'em // aktualnie nie używane bo wykorzystalem własne generowanie losowej liczby
		
		
		
		
		---### Przykład mojego własnego generatora liczb pseudolosowych ###############################################################
		zm_real := extract(second from SYSTIMESTAMP);		
		/*
			Jeśli długość jest równa 6 czyli np. wylosowano liczbe: 43.523 to wycinamy z niej kropke i powstaje liczna 43523
			Z takiej liczby liczymy odpowiednio moduł aby uzyskać losową liczbę.
			
			W przypadku gdy wylosowana liczba nie będzie dłgości 6 znaków to moduł obliczamy bezpośrednio z całej liczby  
			ale wynik zostaje obcięty trunc więc otrzymujemy wynik jak przy modulo z liczby przed kropką.
			
			Liczb z zakresu 0-9 jest 10. A więc prawdopodobienstwo 10/60
			Liczb z zakresu 0-99 jest 100. A więc prawdopodobienstwo 100/1000
			
			Prawdopodobieństwo, że liczba nie będzie miała 6 znaków to: (10/60)*(100/1000)=(1/6)*(1/10)=1/60=1,6%
			Daje nam to dodatkowe zakłocenia w psudolosowości.
		*/
		IF length(zm_real) = 6 THEN
			-- wycinamy sekundy, a pozniej milisekundy
			zm_real := substr(zm_real,1,2)||substr(zm_real,4,3);	
		END IF;
		--DBMS_OUTPUT.PUT_LINE('Losowa liczba: '||zm_real||', mod 2: '||mod(zm_real,2)||', int: '||trunc(mod(zm_real,2)));
		-- moja zmienna losowa jest obliczana jako moduł 20 z liczby zm_real, a następnie jako moduł 2, co daje lepszy rozrzut wynikow
		zm_moja_losowa := trunc(mod(mod(zm_real,20),2));
		--### KONIEC losowania mojej zmiennej pseudolosowej
		
	
	
		IF zm_moja_losowa = 0 THEN --mod(zm_liczba,2) = 0 <== jeżeli używamy losowania z random (linia 254) to taki powinien byc warunek
			-- mezczyzna
			zm_oso_plec := 'm';
			-- losujemy imie meskie
			zm_oso_imie := kolekcja_imie_mezczyzna(TRUNC(dbms_random.value(1,licznik0)));
		ELSE
			-- kobieta
			zm_oso_plec := 'k';
			-- losujemy imie zenskie
			zm_oso_imie := kolekcja_imie_kobieta(TRUNC(dbms_random.value(1,licznik1)));
		END IF;
		
		
		
		--### Generowanie daty urodzenia w formacie: 1957/02/22 ############################################################
		/*
			Przykład wygenerowanych dat:
			1912/10/22
			1933/04/01
			1917/03/22
			1974/05/02
			1922/07/01
			1980/07/25
		*/
		zm_oso_data_urodzenia := TRUNC(dbms_random.value(1900,1995))||'/';		
		-- losujemy miesiac
		zm_liczba := TRUNC(dbms_random.value(1,12)); 
		-- jeśli miesiąc zajmuje tylko jeden znak to trzeba dokleic zero do napisu reprezentujacego miesiac
		IF zm_liczba < 10 THEN
			zm_oso_data_urodzenia := zm_oso_data_urodzenia||'0'||zm_liczba||'/';
		ELSE
			zm_oso_data_urodzenia := zm_oso_data_urodzenia||zm_liczba||'/';
		END IF;
		
		-- W zależnosci od tego jaki to miesiac to moze miec rozna liczbe dni
		-- jeśli miesiac to luty
		IF zm_liczba = 2 THEN
			zm_liczba2 := TRUNC(dbms_random.value(1,28));
		-- jeśli miesiące stycz, marzec, maj itd to maja liczbe dni 31 
		ELSIF zm_liczba = 1 OR zm_liczba = 3 OR  zm_liczba = 5 OR  zm_liczba = 7 OR  zm_liczba = 8 OR  zm_liczba = 10 OR  zm_liczba = 12 THEN
			zm_liczba2 := TRUNC(dbms_random.value(1,31));
		-- pozostałe miesiące mają 30 dni
		ELSE			
			zm_liczba2 := TRUNC(dbms_random.value(1,30));
		END IF;
		
		-- jeśli dzień miesiąca zajmuje tylko jeden znak to trzeba dokleic zero do napisu reprezentujacego dzień
		IF zm_liczba2 < 10 THEN
			zm_oso_data_urodzenia := zm_oso_data_urodzenia||'0'||zm_liczba2;
		ELSE
			zm_oso_data_urodzenia := zm_oso_data_urodzenia||zm_liczba2;
		END IF;		
		-- Podgląd wylosowanej daty
		-- DBMS_OUTPUT.PUT_LINE(zm_oso_data_urodzenia);
		
		
		
		
		
		--### Generowanie NIPu ############################################################
		-- Teoria: http://www.algorytm.org/numery-identyfikacyjne/nip.html
		--# losujemy 9 cyfr
		/*
			Przykładowo wygenerowane numery:
			NIP: 8506725473
			NIP: 4131146574
			NIP: 4761074505
			NIP: 6460655734
			NIP: 8114684466
			NIP: 4443708562
			NIP: 2751673516
			NIP: 6235706042			
			NIP: 6605385789
			NIP: 8582028206
			NIP: 4743540084
			NIP: 6355202255
			NIP: 5715681212
			NIP: 7888650117
		*/		
		-- zm_liczba2 bedzie przechowywac sume kontrolną NIPu
		-- jeśli suma kontrolna wyniesie 10 to nalezy powtorzyc operacje losowania NIPu poniewaz jest wtedy niepoprawny
		zm_liczba2 := 10; 
		WHILE zm_liczba2 = 10 LOOP
			zm_oso_nip := ''; -- ustawiamy zmienna na pustą poniewaz dla kazdej nowej osoby generujemy nowy NIP
			FOR i IN 1..9 LOOP
				kolekcja_nip(i) := TRUNC(dbms_random.value(0,9));
				zm_oso_nip := zm_oso_nip||kolekcja_nip(i);
			END LOOP;
			
			--# obliczamy sume kontrolną i zapisujemy ją jako 10 liczbę
			--# Każdą pozycję numeru identyfikacji podatkowej mnoży się przez odpowiednią wagę, 
			--# są to kolejno: 6 5 7 2 3 4 5 6 7. Następnie utworzone iloczyny dodaje się i wynik dzieli się modulo 11
			zm_liczba := 6*kolekcja_nip(1) + 5*kolekcja_nip(2) + 7*kolekcja_nip(3) + 2*kolekcja_nip(4) + 3*kolekcja_nip(5) + 4*kolekcja_nip(6) + 5*kolekcja_nip(7) + 6*kolekcja_nip(8) + 7*kolekcja_nip(9);
			zm_liczba2 := mod(zm_liczba,11); -- suma kontrolna
			
			-- jeśli wygenerowalismy poprawny NIP to sprawdzimy czy juz wczesniej wygenerowano taki nip
			-- jesli tak to aby wygenerowac inny ustawimy na sztywno zm_liczba2:=10 aby wymuśić ponową iterację w WHILE
			IF zm_liczba2 != 10 THEN
				/* -- nie używany kod
				FOR i IN 1..kolekcja_nip_wylosowane.count LOOP
					IF kolekcja_nip_wylosowane(i) = zm_oso_nip||zm_liczba2 THEN
						zm_liczba2 := 10;
					--ELSE	
						--kolekcja_nip_wylosowane.EXTEND;
						--kolekcja_nip_wylosowane(kolekcja_nip_wylosowane.LAST) := zm_oso_nip||zm_liczba2;
					END IF;
				END LOOP;								
				
				IF zm_liczba2 != 10 THEN
				kolekcja_nip_wylosowane.EXTEND;
				kolekcja_nip_wylosowane(kolekcja_nip_wylosowane.LAST) := zm_oso_nip||zm_liczba2;
				END IF;
				*/
				
				SELECT count(*) INTO zm_liczba FROM OSOBY WHERE OSO_NIP = zm_oso_nip||zm_liczba2;
				IF zm_liczba > 0 THEN 
					zm_liczba2 := 10; -- ustawiamy na 10 bo sie w bazie dubluje NIP
				END IF;
				
			END IF;
			
		END LOOP;
		
		kolekcja_nip(10) := zm_liczba2; -- można zapisac do 10 pozycji sume kontrlną ponieważ jest mniejsza niz 10
		zm_oso_nip := zm_oso_nip||kolekcja_nip(10);
		--DBMS_OUTPUT.PUT_LINE('NIP: '||zm_oso_nip); -- podgląd NIPu
		
		
		
		
		
		--### Wykonujemy wstawienie rekordu #############################################################
		--### ADR_ID generowany jest z przedzialu od 1 do liczby rekordow dodanych do tabeli ADRES_POCZTY, czyli wartosc zmiennej IleTab1
		
		INSERT INTO OSOBY (OSO_IMIE, OSO_NAZWISKO, OSO_PLEC, OSO_DATA_URODZENIA, OSO_PESEL, OSO_NIP, OSO_ULICA, OSO_NR_LOKALU, ADR_ID)
		VALUES (
			zm_oso_imie		
		,	kolekcja_nazwisko(TRUNC(dbms_random.value(1,licznik2)))
		,	zm_oso_plec
		,	zm_oso_data_urodzenia
		,	NULL
		,	zm_oso_nip
		,	kolekcja_ulica(TRUNC(dbms_random.value(1,licznik3)))
		,	to_char(TRUNC(dbms_random.value(1,99))||'/'||TRUNC(dbms_random.value(1,99)))
		,	TRUNC(dbms_random.value(1,zm_IleTab1))		
		);
		
		/*
		licznik_dodanych_osob := licznik_dodanych_osob+1;
		-- wyświetlamy potwierdzenie dodania osob co 1000 rekordow
		IF mod(licznik_dodanych_osob,1000)=0 THEN
			DBMS_OUTPUT.PUT_LINE('- Dodano do tej pory osob: '||licznik_dodanych_osob);
		END IF;
		*/
		
		
	END LOOP;
	DBMS_OUTPUT.PUT_LINE('+ Wygenerowano osob: '||IleTab2);
	
		
	
	
	
	
	
	
	-- wyświetlamy czas wykonania skryptu
	v_end := SYSTIMESTAMP;    
    v_interval := v_end - v_begin;
    DBMS_OUTPUT.PUT_LINE('--- Statystyki wykonania skryptu ----');
	DBMS_OUTPUT.PUT_LINE( 'Interval: ' || to_char(v_interval) );
    DBMS_OUTPUT.PUT_LINE( 'Seconds: ' || extract(second from v_interval) );

END P_GENERUJ_DANE;
/



-- wywołanie procedury w bloku anonimowym	
BEGIN
	-- arg1: ilosc danych w tabeli ADRES_POCZTY
	-- arg2: ilosc danych w tabeli OSOBY (tutaj powinno byc duzo danych 1-2mln)
	--P_GENERUJ_DANE(2000,10000);	-- dodaje się 10 sekund, 
	P_GENERUJ_DANE(2000,1000000); -- szacuje ze 1mln rekordow doda sie w okolo 16min
	--P_GENERUJ_DANE(100,1000);
END;
/












-- # -------------------------------------------------

show error;

COMMIT;