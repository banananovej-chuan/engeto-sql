# Engeto final SQL project

## Popis
Cílem projektu byla tvorba panelových dat, která budou obsahovat proměnné, které mohou mít vliv na vyhodnocované veličiny.

## Nástroje
- BigQuery

## Použité tabulky
- countries
- covid19_basic_differences
- covid19_tests
- economies
- life_expectancy
- lookup_table
- religions
- weather

## Primary keys
- ```country_key```
- ```date```

### Finální tabulka
Finální tabulka se jmenuje ```02_final_table```

### Poznámky
- Tabulky obsahují rozdílná data (počet ```country_key``` a ```date```), proto bylo na začátku nutné zvolit jednu tabulku se státy, se kterými se bude pracovat jako s primárními klíči. V tomto konkrétním případě se braly PKs z následujících tabulek:
  - ```country_key``` z tabulky ```countries```
  - ```date``` z tabulky ```covide19_tests```
- Vzhledem k tomu, že byl projekt, oproti zadání, zpracováván v BigQuery, je **nutné přidělit přístupy**, aby byl schopen zkontrolovat finální tabulku.
