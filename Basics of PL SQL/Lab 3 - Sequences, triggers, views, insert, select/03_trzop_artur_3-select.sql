-- ##################################################
--
--	Baza danych dla portalu społecznościowego o książkach
-- 	2010 Copyright (c) Artur Trzop 12K2
--	Script-select v. 4.1.0
--
-- ##################################################

CLEAR SCREEN;
PROMPT ----------------------------------------------;
PROMPT Przyklady selectow;
PROMPT ----------------------------------------------;
PROMPT ;

-- Pobieramy uzytkownikow i miasta z ktorych pochodza. Wyniki posortowane alfabetycznie wg. loginow
PROMPT ********** Przyklady 1 ****************************************;
COLUMN UZY_LOGIN FORMAT A10
COLUMN UZY_DATA_URODZENIA FORMAT A20
COLUMN UZY_EMAIL FORMAT A20
COLUMN MIA_MIASTO FORMAT A20
SELECT UZY_LOGIN, UZY_DATA_URODZENIA, UZY_EMAIL, MIA_MIASTO
FROM UZYTKOWNICY LEFT JOIN MIASTO ON UZYTKOWNICY.MIA_ID = MIASTO.MIAK_1_ID
ORDER BY UZY_LOGIN ASC;

--### Złączenie równościowe
-- Pobranie trzech najmłodszych uzytkownikow i miast z ktorych pochodza.
-- Uzyto where zamiast join a takze dodano aliasy :)
-- Do ograniczenia liczby wynikow wykorzystano parametr ROWNUM
PROMPT
PROMPT
PROMPT ********** Przyklady 2 ****************************************;
COLUMN UZY_LOGIN FORMAT A20
COLUMN UZY_DATA_URODZENIA FORMAT A20
COLUMN MIA_MIASTO FORMAT A20
SELECT u.UZY_LOGIN, u.UZY_DATA_URODZENIA, m.MIA_MIASTO
FROM UZYTKOWNICY u, MIASTO m 
WHERE u.MIA_ID = m.MIAK_1_ID AND ROWNUM <= 3
ORDER BY u.UZY_DATA_URODZENIA DESC;



--### Złączenie ZEWNĘTRZNE (wyświetli kategorie nawet jesli nie jest do nich przypisana zadna ksiazka)
-- Zapytanie zwraca liste ksiazek i nazwe kategorii z ktorej pochodzi dana ksiazka.
-- Dzięki operatorowi (+) wyświetlone zostaną takze nazwy kategorii ktore nie maja zadnych ksiazek
PROMPT
PROMPT
PROMPT ********** Przyklady 3 ****************************************;
COLUMN KAT_NAZWA FORMAT A20
COLUMN KSI_TYTUL FORMAT A25
SELECT KAT_NAZWA, KSI_TYTUL
FROM KATEGORIE_KSIAZEK, KSIAZKI
WHERE KAT_ID(+) = KATK_1_ID
ORDER BY KATK_1_ID ASC;




-- Pobieranie średniej liczby ksiazek napisanych przez danego autora
PROMPT
PROMPT
PROMPT ********** Przyklady 4 ****************************************;
COLUMN AUT_LICZBA_KSIAZEK FORMAT 9999
SELECT AUTK_1_ID, AVG(AUT_LICZBA_KSIAZEK) FROM AUTORZY GROUP BY AUTK_1_ID;


-- Pobieramy autora ktory napisał najwiecej ksiazek
PROMPT
PROMPT
PROMPT ********** Przyklady 5 ****************************************;
COLUMN AUT_LICZBA_KSIAZEK FORMAT 9999
SELECT AUT_LICZBA_KSIAZEK FROM AUTORZY WHERE ROWNUM=1 ORDER BY AUT_LICZBA_KSIAZEK DESC;



-- Pobieramy ksiazki ktorych tytuły skadają się conajmniej z dwóch słów (czyli w tytule występuje spacja)
PROMPT
PROMPT
PROMPT ********** Przyklady 6 ****************************************;
COLUMN KSI_TYTUL FORMAT A20
SELECT KSI_TYTUL FROM KSIAZKI WHERE KSI_TYTUL LIKE '% %' ORDER BY KSI_TYTUL ASC;


-- Pobieramy ksiazki ktore skladaja sie z jednego slowa
PROMPT
PROMPT
PROMPT ********** Przyklady 7 ****************************************;
COLUMN KSI_TYTUL FORMAT A20
SELECT KSI_TYTUL FROM KSIAZKI WHERE KSI_TYTUL NOT LIKE '% %' ORDER BY KSI_TYTUL ASC;



-- Pobieramy autorow ktorzy napisali od 2 do 5 ksiazek i wyswietlamy ich od tych ktorzy napisali najwiecej
PROMPT
PROMPT
PROMPT ********** Przyklady 8 ****************************************;
COLUMN AUT_IMIE FORMAT A20
COLUMN AUT_NAZWISKO FORMAT A20
SELECT AUT_IMIE, AUT_NAZWISKO FROM AUTORZY WHERE AUT_LICZBA_KSIAZEK BETWEEN 2 AND 5 ORDER BY AUT_LICZBA_KSIAZEK DESC;




---############ Ciekawy przyklad 3 zagłębionych w sobie select'ów ########################################################################
-- Pobieramy autorów książek które pochodzą z podkategorii zawartych w kategorii 1 czyli w Literaturze
-- Innymi slowy pobieramy pisarzy trudniących się Literaturą
PROMPT
PROMPT
PROMPT ********** Przyklady 9 ****************************************;
COLUMN AUT_IMIE FORMAT A20
COLUMN AUT_NAZWISKO FORMAT A20
SELECT AUT_IMIE, AUT_NAZWISKO FROM AUTORZY 
WHERE AUTK_1_ID IN (
	SELECT AUT_ID FROM AUK_AUTORZY_KSIAZKI WHERE KSI_ID IN (
		SELECT KSIK_1_ID FROM KSIAZKI WHERE KAT_ID IN (
			SELECT KATK_1_ID FROM KATEGORIE_KSIAZEK WHERE KAT_RODZIC_KATEGORII = 1
		)
	)
)
ORDER BY AUT_IMIE ASC;



--##### Pobieramy kategorie w ktorych sa umieszczone ksiazki napisane przez pisarza 'Marek Nowak'
PROMPT
PROMPT
PROMPT ********** Przyklady 10 ****************************************;
COLUMN KAT_NAZWA FORMAT A20
SELECT DISTINCT KAT_NAZWA FROM KATEGORIE_KSIAZEK 
WHERE KATK_1_ID IN (
	SELECT KAT_ID FROM KSIAZKI
	WHERE KSIK_1_ID IN (
		SELECT KSI_ID FROM AUK_AUTORZY_KSIAZKI WHERE AUT_ID IN (
			SELECT AUTK_1_ID FROM AUTORZY WHERE AUT_IMIE = 'Marek' AND AUT_NAZWISKO = 'Nowak' 
		)
	)	
);
	

-- GROUP BY
-- Pobieramy ID kategorii ksiazek i liczbe ksiazek zawartych w kazdej z nich
PROMPT
PROMPT
PROMPT ********** Przyklady 11 ****************************************;
SELECT KAT_ID, COUNT(KAT_ID)
FROM KSIAZKI 
GROUP BY KAT_ID;


-- Mozemy wykorzystac poprzednie grupowanie do zbudowania perspektywy, którą użyjemy 
-- do stworzenia listy kategorii i liczby w niej zawartych ksiazek 
PROMPT
PROMPT
PROMPT ********** Przyklady 12 ****************************************;
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
PROMPT
PROMPT
PROMPT ********** Przyklady 13 ****************************************;
CREATE OR REPLACE VIEW V_KAT_KSI_Z_LICZBA_KSIAZEK
(KAT_ID, KAT_NAZWA, LICZBA_KSIAZEK)
AS
SELECT k.KATK_1_ID, k.KAT_NAZWA, NVL(v.LICZBA_KSIAZEK,0)
FROM KATEGORIE_KSIAZEK k LEFT JOIN V_LICZBA_KSIAZEK_W_KATEGORIACH v ON k.KATK_1_ID = v.KAT_ID;




-- pobieramy widok
PROMPT
PROMPT
PROMPT ********** Przyklady 14 ****************************************;
COLUMN KAT_ID FORMAT 9999
COLUMN KAT_NAZWA FORMAT A20
COLUMN LICZBA_KSIAZEK FORMAT 9999
SELECT * FROM V_KAT_KSI_Z_LICZBA_KSIAZEK ORDER BY KAT_ID ASC;