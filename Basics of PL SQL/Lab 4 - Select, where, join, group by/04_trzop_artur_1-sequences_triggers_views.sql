-- ##################################################
--
--	Baza danych dla portalu spo³ecznoœciowego o ksi¹¿kach
-- 	2010 Copyright (c) Artur Trzop 12K2
--	Script v. 3.0.0
--
-- ##################################################

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
PROMPT Tworzenie sekwencji;
PROMPT ----------------------------------------------;
PROMPT ;

DROP SEQUENCE SEQ_MIASTO;
CREATE SEQUENCE SEQ_MIASTO INCREMENT BY 1 START WITH 1
MAXVALUE 9999999999 MINVALUE 1; 

DROP SEQUENCE SEQ_UZYTKOWNICY;
CREATE SEQUENCE SEQ_UZYTKOWNICY INCREMENT BY 1 START WITH 1
MAXVALUE 9999999999 MINVALUE 1; 

DROP SEQUENCE SEQ_SESJE_UZYTKOWNIKOW;
CREATE SEQUENCE SEQ_SESJE_UZYTKOWNIKOW INCREMENT BY 1 START WITH 1
MAXVALUE 9999999999 MINVALUE 1; 

DROP SEQUENCE SEQ_KATEGORIE_KSIAZEK;
CREATE SEQUENCE SEQ_KATEGORIE_KSIAZEK INCREMENT BY 1 START WITH 1
MAXVALUE 9999999999 MINVALUE 1; 

DROP SEQUENCE SEQ_AUTORZY;
CREATE SEQUENCE SEQ_AUTORZY INCREMENT BY 1 START WITH 1
MAXVALUE 9999999999 MINVALUE 1; 

DROP SEQUENCE SEQ_KSIAZKI;
CREATE SEQUENCE SEQ_KSIAZKI INCREMENT BY 1 START WITH 1
MAXVALUE 9999999999 MINVALUE 1; 

DROP SEQUENCE SEQ_CYTATY_Z_KSIAZEK;
CREATE SEQUENCE SEQ_CYTATY_Z_KSIAZEK INCREMENT BY 1 START WITH 1
MAXVALUE 9999999999 MINVALUE 1; 

DROP SEQUENCE SEQ_RECENZJE_KSIAZEK;
CREATE SEQUENCE SEQ_RECENZJE_KSIAZEK INCREMENT BY 1 START WITH 1
MAXVALUE 9999999999 MINVALUE 1; 

DROP SEQUENCE SEQ_KOMENTARZE_DO_RECENZJI;
CREATE SEQUENCE SEQ_KOMENTARZE_DO_RECENZJI INCREMENT BY 1 START WITH 1
MAXVALUE 9999999999 MINVALUE 1; 

DROP SEQUENCE SEQ_OPINIE_DO_KSIAZEK;
CREATE SEQUENCE SEQ_OPINIE_DO_KSIAZEK INCREMENT BY 1 START WITH 1
MAXVALUE 9999999999 MINVALUE 1; 

DROP SEQUENCE SEQ_WYDAWNICTWO;
CREATE SEQUENCE SEQ_WYDAWNICTWO INCREMENT BY 1 START WITH 1
MAXVALUE 9999999999 MINVALUE 1; 

DROP SEQUENCE SEQ_WERSJA_WYDANIA;
CREATE SEQUENCE SEQ_WERSJA_WYDANIA INCREMENT BY 1 START WITH 1
MAXVALUE 9999999999 MINVALUE 1; 




-- ##################################################
PROMPT ;
PROMPT ----------------------------------------------;
PROMPT Tworzenie triggerow;
PROMPT ----------------------------------------------;
PROMPT ;


CREATE OR REPLACE TRIGGER T_BI_MIASTO
BEFORE INSERT ON MIASTO
FOR EACH ROW
BEGIN
	IF :NEW.MIAK_1_ID IS NULL THEN 
		SELECT SEQ_MIASTO.NEXTVAL INTO :NEW.MIAK_1_ID FROM DUAL;
	END IF;
END;
/

-- # -------------------------------------------------

CREATE OR REPLACE TRIGGER T_BI_UZYTKOWNICY
BEFORE INSERT ON UZYTKOWNICY
FOR EACH ROW
BEGIN
	IF :NEW.UZYK_1_ID IS NULL THEN 
		SELECT SEQ_UZYTKOWNICY.NEXTVAL INTO :NEW.UZYK_1_ID FROM DUAL;		
	END IF;
	-- Dodanie rekordu powoduje zapisanie daty dolaczenia uzytkownika do portalu	
	:NEW.UZY_DOLACZYL := to_date(SYSDATE, 'yyyy/mm/dd hh24:mi:ss');		
END;
/

-- # -------------------------------------------------
-- Dla tabeli: SESJE_UZYTKOWNIKOW

CREATE OR REPLACE TRIGGER T_BI_SESJE_UZYTKOWNIKOW
BEFORE INSERT ON SESJE_UZYTKOWNIKOW
FOR EACH ROW
BEGIN
	IF :NEW.SESK_1_ID IS NULL THEN 
		SELECT SEQ_SESJE_UZYTKOWNIKOW.NEXTVAL INTO :NEW.SESK_1_ID FROM DUAL;
	END IF;
	-- Podczas tworzenia nowego rekordu zapisujemy date zalogowania automatycznie jako obecna chwile
	:NEW.SES_ZALOGOWANO := to_date(SYSDATE, 'yyyy/mm/dd hh24:mi:ss');
	-- Waznosc sesji trwa 7 dni
	:NEW.SES_WAZNOSC := to_date(SYSDATE, 'yyyy/mm/dd hh24:mi:ss')+7;
END;
/

CREATE OR REPLACE TRIGGER T_BU_SESJE_UZYTKOWNIKOW
BEFORE UPDATE ON SESJE_UZYTKOWNIKOW
FOR EACH ROW
BEGIN
	-- Podczas aktualizacji rekordu przedluzamy waznosc sesji. Sesja jest wazna przez 7 dni od aktualizacji rekordu
	:NEW.SES_WAZNOSC := to_date(SYSDATE, 'yyyy/mm/dd hh24:mi:ss')+7;
END;
/

-- # -------------------------------------------------

CREATE OR REPLACE TRIGGER T_BI_KATEGORIE_KSIAZEK
BEFORE INSERT ON KATEGORIE_KSIAZEK
FOR EACH ROW
BEGIN
	IF :NEW.KATK_1_ID IS NULL THEN 
		SELECT SEQ_KATEGORIE_KSIAZEK.NEXTVAL INTO :NEW.KATK_1_ID FROM DUAL;
	END IF;
END;
/

-- # -------------------------------------------------

CREATE OR REPLACE TRIGGER T_BI_AUTORZY
BEFORE INSERT ON AUTORZY
FOR EACH ROW
BEGIN
	IF :NEW.AUTK_1_ID IS NULL THEN 
		SELECT SEQ_AUTORZY.NEXTVAL INTO :NEW.AUTK_1_ID FROM DUAL;
	END IF;
END;
/

-- # -------------------------------------------------

CREATE OR REPLACE TRIGGER T_BI_KSIAZKI
BEFORE INSERT ON KSIAZKI
FOR EACH ROW
BEGIN
	IF :NEW.KSIK_1_ID IS NULL THEN 
		SELECT SEQ_KSIAZKI.NEXTVAL INTO :NEW.KSIK_1_ID FROM DUAL;
	END IF;
	-- Dodanie rekordu powoduje zapisanie automatycznie daty dodania	
	:NEW.KSI_DODANO := to_date(SYSDATE, 'yyyy/mm/dd hh24:mi:ss');
END;
/

-- # -------------------------------------------------

CREATE OR REPLACE TRIGGER T_BI_CYTATY_Z_KSIAZEK
BEFORE INSERT ON CYTATY_Z_KSIAZEK
FOR EACH ROW
BEGIN
	IF :NEW.CYTK_1_ID IS NULL THEN 
		SELECT SEQ_CYTATY_Z_KSIAZEK.NEXTVAL INTO :NEW.CYTK_1_ID FROM DUAL;
	END IF;
	-- Dodanie rekordu powoduje zapisanie automatycznie daty dodania	
	:NEW.CYT_DODANO := to_date(SYSDATE, 'yyyy/mm/dd hh24:mi:ss');
END;
/

-- # -------------------------------------------------

CREATE OR REPLACE TRIGGER T_BI_ULUBIONE_KSIAZKI
BEFORE INSERT ON ULUBIONE_KSIAZKI
FOR EACH ROW
BEGIN	
	-- Dodanie rekordu powoduje zapisanie automatycznie daty dodania	
	:NEW.ULU_DODANO := to_date(SYSDATE, 'yyyy/mm/dd hh24:mi:ss');
END;
/

-- # -------------------------------------------------

CREATE OR REPLACE TRIGGER T_BI_ULA_ULUBIENI_AUTORZY
BEFORE INSERT ON ULA_ULUBIENI_AUTORZY
FOR EACH ROW
BEGIN	
	-- Dodanie rekordu powoduje zapisanie automatycznie daty dodania	
	:NEW.ULA_DODANO := to_date(SYSDATE, 'yyyy/mm/dd hh24:mi:ss');
END;
/

-- # -------------------------------------------------

CREATE OR REPLACE TRIGGER T_BI_RECENZJE_KSIAZEK
BEFORE INSERT ON RECENZJE_KSIAZEK
FOR EACH ROW
BEGIN
	IF :NEW.RECK_1_ID IS NULL THEN 
		SELECT SEQ_RECENZJE_KSIAZEK.NEXTVAL INTO :NEW.RECK_1_ID FROM DUAL;
	END IF;
	-- Dodanie rekordu powoduje zapisanie automatycznie daty dodania	
	:NEW.REC_DODANO := to_date(SYSDATE, 'yyyy/mm/dd hh24:mi:ss');
END;
/

-- # -------------------------------------------------

CREATE OR REPLACE TRIGGER T_BI_KOMENTARZE_DO_RECENZJI
BEFORE INSERT ON KOMENTARZE_DO_RECENZJI
FOR EACH ROW
BEGIN
	IF :NEW.KOMK_1_ID IS NULL THEN 
		SELECT SEQ_KOMENTARZE_DO_RECENZJI.NEXTVAL INTO :NEW.KOMK_1_ID FROM DUAL;
	END IF;
	-- Dodanie rekordu powoduje zapisanie automatycznie daty dodania	
	:NEW.KOM_DODANO := to_date(SYSDATE, 'yyyy/mm/dd hh24:mi:ss');
END;
/

-- # -------------------------------------------------

CREATE OR REPLACE TRIGGER T_BI_OPINIE_DO_KSIAZEK
BEFORE INSERT ON OPINIE_DO_KSIAZEK
FOR EACH ROW
BEGIN
	IF :NEW.OPIK_1_ID IS NULL THEN 
		SELECT SEQ_OPINIE_DO_KSIAZEK.NEXTVAL INTO :NEW.OPIK_1_ID FROM DUAL;
	END IF;
	-- Dodanie rekordu powoduje zapisanie automatycznie daty dodania	
	:NEW.OPI_DODANO := to_date(SYSDATE, 'yyyy/mm/dd hh24:mi:ss');
END;
/

-- # -------------------------------------------------

CREATE OR REPLACE TRIGGER T_BI_WYDAWNICTWO
BEFORE INSERT ON WYDAWNICTWO
FOR EACH ROW
BEGIN
	IF :NEW.WYDK_1_ID IS NULL THEN 
		SELECT SEQ_WYDAWNICTWO.NEXTVAL INTO :NEW.WYDK_1_ID FROM DUAL;
	END IF;
END;
/

-- # -------------------------------------------------

CREATE OR REPLACE TRIGGER T_BI_WERSJA_WYDANIA
BEFORE INSERT ON WERSJA_WYDANIA
FOR EACH ROW
BEGIN
	IF :NEW.WERK_1_ID IS NULL THEN 
		SELECT SEQ_WERSJA_WYDANIA.NEXTVAL INTO :NEW.WERK_1_ID FROM DUAL;
	END IF;	
END;
/

-- # -------------------------------------------------

CREATE OR REPLACE TRIGGER T_BI_WERSJE_WYDANIA_KSIAZEK
BEFORE INSERT ON WERSJE_WYDANIA_KSIAZEK
FOR EACH ROW
BEGIN
	-- Dodanie rekordu powoduje zapisanie automatycznie daty dodania	
	:NEW.WWK_DODANO := to_date(SYSDATE, 'yyyy/mm/dd hh24:mi:ss');
END;
/

-- # -------------------------------------------------

CREATE OR REPLACE TRIGGER T_BI_AUK_AUTORZY_KSIAZKI
BEFORE INSERT ON AUK_AUTORZY_KSIAZKI
FOR EACH ROW
DECLARE
	TEMP_ILE INT;
BEGIN
	-- Dodanie rekordu do tabeli AUK_AUTORZY_KSIAZKI oznacza ¿e do jakiejs ksiazki przypisalismy autora. A wiec 
	-- zaktualizujemy licznik ksiazek napisanych przez danego autora (licznik to pole AUT_LICZBA_KSIAZEK w tabeli AUTORZY)
	
	--moze byc tez tak zapizane zliczanie i  ladowanie do tymczasowej zmiennej
	--SELECT (SELECT count(*) FROM AUK_AUTORZY_KSIAZKI WHERE AUT_ID = :NEW.AUT_ID) INTO TEMP_ILE FROM DUAL; 
	
	--tego zapytania nie moglibysmy wykonac gdyby byl to trigger AFTER INSERT poniewaz powodowaloby to blad '(...) mutating (...)'
	SELECT count(*) INTO TEMP_ILE FROM AUK_AUTORZY_KSIAZKI WHERE AUT_ID = :NEW.AUT_ID; 
	TEMP_ILE := TEMP_ILE+1; --zwiekszamy licznik o jeden czyli o rekord ktory dodajemy teraz
	UPDATE AUTORZY SET AUT_LICZBA_KSIAZEK = TEMP_ILE WHERE AUTK_1_ID = :NEW.AUT_ID;
END;
/

-- # -------------------------------------------------




-- ####################################################################################################
-- LAB 4


-- ##################################################
PROMPT ;
PROMPT ----------------------------------------------;
PROMPT Tworzenie widokow;
PROMPT ----------------------------------------------;
PROMPT ;


-- Mozemy wykorzystac poprzednie grupowanie do zbudowania perspektywy, któr¹ u¿yjemy 
-- do stworzenia listy kategorii i liczby w niej zawartych ksiazek 
CREATE OR REPLACE VIEW V_LICZBA_KSIAZEK_W_KATEGORIACH
(KAT_ID, LICZBA_KSIAZEK)
AS
SELECT KAT_ID, COUNT(KAT_ID)
FROM KSIAZKI 
GROUP BY KAT_ID;


-- Tworzymy widok ktory bedzie sie skladal z tabeli KATEGORIE_KSIAZEK oraz 
-- dodatkowego atrybutu czyli liczby ksiazek w tej kategorii.
-- Wykorzystano funkcje NVL która wstawi 0 do liczby ksiazek jesli dla danej kategorii 
-- nie dopasowano rekordu z widoku V_LICZBA_KSIAZEK_W_KATEGORIACH
CREATE OR REPLACE VIEW V_KAT_KSI_Z_LICZBA_KSIAZEK
(KAT_ID, KAT_NAZWA, LICZBA_KSIAZEK)
AS
SELECT k.KATK_1_ID, k.KAT_NAZWA, NVL(v.LICZBA_KSIAZEK,0)
FROM KATEGORIE_KSIAZEK k LEFT JOIN V_LICZBA_KSIAZEK_W_KATEGORIACH v ON k.KATK_1_ID = v.KAT_ID;








COMMIT;