-- ##################################################
--
--	Bazy danych 
-- 	2011 Copyright (c) Artur Trzop 12K2
--	Script v. 1.2.0
--
-- ##################################################

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
PROMPT Usuwanie kluczy obcych;
PROMPT Kasowanie danych z tabel oraz calych tabel;
PROMPT ----------------------------------------------;
PROMPT ;

-- Kolejnosc kasowania jest istotna!
DROP INDEX IX_CSR_FK_OSO_ADR;

ALTER TABLE OSOBY DROP CONSTRAINT CSR_FK_OSO_ADR;
ALTER TABLE OSOBY DROP CONSTRAINT CSR_UQ_OSO_PESEL;
ALTER TABLE OSOBY DROP CONSTRAINT CSR_UQ_OSO_NIP;
DELETE FROM OSOBY;
DROP TABLE OSOBY CASCADE CONSTRAINTS;

ALTER TABLE ADRES_POCZTY DROP CONSTRAINT CSR_UQ_ADR_KOD_POCZTOWY;
DELETE FROM ADRES_POCZTY;
DROP TABLE ADRES_POCZTY CASCADE CONSTRAINTS;

DELETE FROM HELP_TABLE;
DROP TABLE HELP_TABLE CASCADE CONSTRAINTS;



-- ####################################################################################################



-- ##################################################
PROMPT ;
PROMPT ----------------------------------------------;
PROMPT Tworzenie tabel;
PROMPT ----------------------------------------------;
PROMPT ;

-- Kolejnosc tworzenia jest istotna!

--### W polu miasto mogą się powtarzać te same nazwy miast ponieważ w jednym mieście może być wiele urzędów pocztowych
CREATE TABLE ADRES_POCZTY 
(
  ADRK_1_ID INT NOT NULL 
, ADR_MIASTO VARCHAR2(100) NOT NULL
, ADR_KOD_POCZTOWY VARCHAR2(6) DEFAULT '00-000'
, ADR_ULICA VARCHAR2(100) NOT NULL
, ADR_NR_LOKALU VARCHAR2(10) DEFAULT '0/0'
);
-- Tworzenie klucza glownego do tabeli wyzej
ALTER TABLE ADRES_POCZTY ADD CONSTRAINT CSR_PK_ADRES_POCZTY PRIMARY KEY (ADRK_1_ID);
-- Ustawiamy klucz unikatowy
ALTER TABLE ADRES_POCZTY ADD CONSTRAINT CSR_UQ_ADR_KOD_POCZTOWY UNIQUE (ADR_KOD_POCZTOWY);



CREATE TABLE OSOBY 
(
  OSOK_1_ID INT NOT NULL 
, OSO_IMIE VARCHAR2(50) NOT NULL
, OSO_NAZWISKO VARCHAR2(50) NOT NULL
, OSO_PLEC CHAR(1) NOT NULL
, OSO_DATA_URODZENIA DATE NOT NULL
, OSO_PESEL VARCHAR2(11)
, OSO_NIP VARCHAR2(10)
, OSO_ULICA VARCHAR2(100) NOT NULL
, OSO_NR_LOKALU VARCHAR2(10) DEFAULT '0/0'
, ADR_ID INT NOT NULL
);
-- Tworzenie klucza glownego do tabeli wyzej
ALTER TABLE OSOBY ADD CONSTRAINT CSR_PK_OSOBY PRIMARY KEY (OSOK_1_ID);
-- Tworzenie kluczy obcych
ALTER TABLE OSOBY ADD CONSTRAINT CSR_FK_OSO_ADR FOREIGN KEY (ADR_ID) REFERENCES ADRES_POCZTY (ADRK_1_ID) ENABLE;
-- Ustawiamy klucz unikatowy
ALTER TABLE OSOBY ADD CONSTRAINT CSR_UQ_OSO_PESEL UNIQUE (OSO_PESEL);
ALTER TABLE OSOBY ADD CONSTRAINT CSR_UQ_OSO_NIP UNIQUE (OSO_NIP);

CREATE INDEX IX_CSR_FK_OSO_ADR
ON OSOBY (ADR_ID)
STORAGE (INITIAL 150k NEXT 150k)
TABLESPACE STUDENT_INDEX;



CREATE TABLE HELP_TABLE 
(
  HELK_1_ID INT NOT NULL 
, HEL_FIELD VARCHAR2(100) NOT NULL
, HEL_TYPE INT NOT NULL
);
-- Tworzenie klucza glownego do tabeli wyzej
ALTER TABLE HELP_TABLE ADD CONSTRAINT CSR_PK_HELP_TABLE PRIMARY KEY (HELK_1_ID);




-- ####################################################################################################



-- ##################################################
PROMPT ;
PROMPT ----------------------------------------------;
PROMPT Tworzenie sekwencji;
PROMPT ----------------------------------------------;
PROMPT ;

DROP SEQUENCE SEQ_ADRES_POCZTY;
CREATE SEQUENCE SEQ_ADRES_POCZTY INCREMENT BY 1 START WITH 1
MAXVALUE 9999999999 MINVALUE 1; 

DROP SEQUENCE SEQ_OSOBY;
CREATE SEQUENCE SEQ_OSOBY INCREMENT BY 1 START WITH 1
MAXVALUE 9999999999 MINVALUE 1; 

DROP SEQUENCE SEQ_HELP_TABLE;
CREATE SEQUENCE SEQ_HELP_TABLE INCREMENT BY 1 START WITH 1
MAXVALUE 9999999999 MINVALUE 1; 




-- ##################################################
PROMPT ;
PROMPT ----------------------------------------------;
PROMPT Tworzenie triggerow;
PROMPT ----------------------------------------------;
PROMPT ;


CREATE OR REPLACE TRIGGER T_BI_ADRES_POCZTY
BEFORE INSERT ON ADRES_POCZTY
FOR EACH ROW
BEGIN
	IF :NEW.ADRK_1_ID IS NULL THEN 
		SELECT SEQ_ADRES_POCZTY.NEXTVAL INTO :NEW.ADRK_1_ID FROM DUAL;
	END IF;
END;
/

-- # -------------------------------------------------

CREATE OR REPLACE TRIGGER T_BI_OSOBY
BEFORE INSERT ON OSOBY
FOR EACH ROW
BEGIN
	IF :NEW.OSOK_1_ID IS NULL THEN 
		SELECT SEQ_OSOBY.NEXTVAL INTO :NEW.OSOK_1_ID FROM DUAL;
	END IF;
END;
/

-- # -------------------------------------------------

CREATE OR REPLACE TRIGGER T_BI_HELP_TABLE
BEFORE INSERT ON HELP_TABLE
FOR EACH ROW
BEGIN
	IF :NEW.HELK_1_ID IS NULL THEN 
		SELECT SEQ_HELP_TABLE.NEXTVAL INTO :NEW.HELK_1_ID FROM DUAL;
	END IF;
END;
/

-- # -------------------------------------------------


-- ####################################################################################################



COMMIT;