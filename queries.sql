# join tabulek countries a covide19_tests + rozdělení dnů na pracovní a víkend + měsíc v roce
CREATE TABLE `chuans-playground-123.engeto.00_layer_countries_covid19Tests_covid19Differences_dateIndexes` AS
SELECT  
    t1.country AS country_key,
    t2.date,
    t1.capital_city,
    t1.iso2,
    t1.iso3,
    t1.population_density,
    t1.population,
    t1.median_age_2018,
    t2.country AS covid_test_country,
    t2.tests_performed,
    EXTRACT (DAYOFWEEK FROM t2.date) AS day_of_week,
    EXTRACT (MONTH FROM t2.date) AS month_of_year,
    EXTRACT (YEAR from t2.date) AS year
FROM `chuans-playground-123.engeto.countries` AS t1
LEFT JOIN `chuans-playground-123.engeto.covid19_tests` AS t2
ON t1.iso3 = t2.ISO

# Smazání řádků, kde není date
DELETE `chuans-playground-123.engeto.00_layer_countries_covid19Tests_covid19Differences_dateIndexes` WHERE date IS NULL

# Přidělení indexu pro typ dne a ročního období
CREATE TABLE `chuans-playground-123.engeto.00_layer_countries_covid19Tests_covid19Differences_dateIndexes_weatherSeason` AS
SELECT  
    *,
    CASE 
        WHEN day_of_week IN (2,3,4,5,6) THEN 0
        WHEN day_of_week IN (1,7) THEN 1
        END AS day_index,
    CASE 
        WHEN month_of_year IN (1,2,12) THEN 3
        WHEN month_of_year IN (3,4,5) THEN 0
        WHEN month_of_year IN (6,7,8) THEN 1
        WHEN month_of_year IN (9,10,11) THEN 2
        END AS weather_season
FROM `chuans-playground-123.engeto.00_layer_countries_covid19Tests_covid19Differences_dateIndexes`

# Úprava tabulky economies, aby šla joinovat
CREATE TABLE `chuans-playground-123.engeto.00_layer_economies` AS
SELECT  
    DISTINCT country,
    AVG(gini) AS avg_gini,
    AVG((GDP/population)) AS gdp_per_capita,
    AVG(mortaliy_under5) AS avg_mortality,
FROM `chuans-playground-123.engeto.economies` 
GROUP BY country

# JOIN `chuans-playground-123.engeto.00_layer_countries_covid19Tests_covid19Differences_dateIndexes_weatherSeason` a `chuans-playground-123.engeto.00_layer_economies`
CREATE TABLE `chuans-playground-123.engeto.01_layer_weatherSeason_join_economies` AS
SELECT  
    t1.*,
    t2.*
FROM `chuans-playground-123.engeto.00_layer_countries_covid19Tests_covid19Differences_dateIndexes_weatherSeason` AS t1
LEFT JOIN `chuans-playground-123.engeto.00_layer_economies` AS t2
ON t1.country_key = t2.country

# Úprava parametru religions, aby ji BQ mohla zpracovat v následujícím kroku
CREATE TABLE `chuans-playground-123.engeto.00_layer_religions` AS
SELECT 
    *, 
    REGEXP_REPLACE(religion, ' ', '_') AS religion_adjusted
FROM `chuans-playground-123.engeto.religions`

# PIVOT religions do sloupce
CREATE TABLE `chuans-playground-123.engeto.001_layer_religions` AS
SELECT * FROM
    (SELECT 
        country,
        religion_adjusted,
        population  
    FROM `chuans-playground-123.engeto.00_layer_religions`
    )
    PIVOT(AVG(population) 
    FOR religion_adjusted IN ('Islam','Judaism', 'Buddhism', 'Hinduism', 'Christianity', 'Folk_Religions', 'Other_Religions', 'Unaffiliated_Religions' ))

# Nápočet celkového obyvatelstva na základě parametru religions
CREATE TABLE `chuans-playground-123.engeto.002_layer_religions` AS
SELECT 
    *,
    (Islam + Judaism + Buddhism + Hinduism + Christianity + Folk_Religions + Other_Religions + Unaffiliated_Religions) AS total_religion_population,
FROM `chuans-playground-123.engeto.001_layer_religions`

# Výpočet procentuálního podílu jednotlivých náboženství
CREATE TABLE `chuans-playground-123.engeto.003_layer_religions` AS
SELECT  
    country,
    ROUND((Islam/total_religion_population) * 100, 2) AS Islam,
    ROUND((Judaism/total_religion_population) * 100, 2) AS Judaism,
    ROUND((Buddhism/total_religion_population) * 100, 2) AS Buddhism,
    ROUND((Hinduism/total_religion_population) * 100, 2) AS Hinduism,
    ROUND((Christianity/total_religion_population) * 100, 2) AS Christianity,
    ROUND((Folk_Religions/total_religion_population) * 100, 2) AS Folk_Religions,
    ROUND((Other_Religions/total_religion_population) * 100, 2) AS Other_Religions,
    ROUND((Unaffiliated_Religions/total_religion_population) * 100, 2) AS Unaffiliated_Religions
FROM `chuans-playground-123.engeto.002_layer_religions`

# JOIN s další tabulkou z 001 vrstvy
CREATE TABLE `chuans-playground-123.engeto.01_layer_weatherSeason_join_religions` AS
SELECT
    t1.*,
    t2.Islam,
    t2.Judaism,
    t2.Buddhism,
    t2.Hinduism,
    t2.Christianity,
    t2.Folk_Religions,
    t2.Other_Religions,
    t2.Unaffiliated_Religions
FROM `chuans-playground-123.engeto.01_layer_weatherSeason_join_economies` AS t1
LEFT JOIN `chuans-playground-123.engeto.003_layer_religions` AS t2
ON t1.country_key = t2.country

# Filtorvání life_expectancy rok 1965
CREATE TABLE `chuans-playground-123.engeto.001_layer_lifeExpectancy_1965` AS
SELECT  
    *
FROM `chuans-playground-123.engeto.life_expectancy`
WHERE year = 1965

# Filtorvání life_expectancy rok 20015
CREATE TABLE `chuans-playground-123.engeto.001_layer_lifeExpectancy_2015` AS
SELECT  
    *
FROM `chuans-playground-123.engeto.life_expectancy`
WHERE year = 2015

# Life_expectancy difference
CREATE TABLE `chuans-playground-123.engeto.00_layer_lifeExpectancy_difference` AS
SELECT  
    t1.country,
    t1.iso3,
    (t2.life_expectancy - t1.life_expectancy) AS life_expectancy
FROM `chuans-playground-123.engeto.001_layer_lifeExpectancy_1965` AS t1
LEFT JOIN `chuans-playground-123.engeto.001_layer_lifeExpectancy_2015` AS t2
ON t1.country = t2.country

# JOIN weatherSeason a lifeExpectancy_difference
CREATE TABLE `chuans-playground-123.engeto.01_layer_weatherSeason_join_lifeExpectancy_difference` AS
SELECT  
    t1.*,
    t2.life_expectancy
FROM `chuans-playground-123.engeto.01_layer_weatherSeason_join_religions` AS t1
LEFT JOIN `chuans-playground-123.engeto.00_layer_lifeExpectancy_difference` AS t2
ON t1.iso3 = t2.iso3

# Příprava dat z tabulky weather pro následné zpracování
CREATE TABLE `chuans-playground-123.engeto.00_layer_weather` AS
SELECT  
    *,
    REGEXP_REPLACE(temp, r'[°c]','') AS temp_removed_char,
    REGEXP_REPLACE(wind, r'[(a-z\/A-Z)$]', '') AS wind_removed_char,
    CAST(date AS date) AS date_removed_time,
    CASE
        WHEN time BETWEEN '06:00' AND '17:00' THEN 'den'
        ELSE 'noc'
    END AS day_phase
FROM `chuans-playground-123.engeto.weather`

# Tabulka weather, se kterou již můžeme pracovat
CREATE TABLE `chuans-playground-123.engeto.001_layer_weather` AS
SELECT  
    *,
    CAST(TRIM(temp_removed_char) AS int64) temp_int,
    CAST(TRIM(wind_removed_char) AS int64) AS wind_int
FROM `chuans-playground-123.engeto.00_layer_weather`

# Počet hodin, kdy pršelo v daném dni a městě
CREATE TABLE `chuans-playground-123.engeto.001_layer_weather_rainHours` AS
SELECT  
    city,
    date_removed_time,
    COUNT(rain) AS rain_hours,
FROM `chuans-playground-123.engeto.001_layer_weather`
WHERE rain != '0.0 mm'
GROUP BY city, date_removed_time

# Průměrná denní teplota
CREATE TABLE `chuans-playground-123.engeto.001_layer_weather_avgTemp` AS
SELECT 
    city,
    date_removed_time,
    AVG(temp_int) AS avg_day_temp
FROM `chuans-playground-123.engeto.001_layer_weather`
WHERE day_phase = 'den'
GROUP BY city, date_removed_time

# Max wind
CREATE TABLE `chuans-playground-123.engeto.001_layer_weather_maxWind` AS
SELECT  
    city,
    date_removed_time,
    MAX(wind_int) AS max_wind
FROM `chuans-playground-123.engeto.001_layer_weather`
GROUP by city, date_removed_time

# Finální tabulka weather
CREATE TABLE `chuans-playground-123.engeto.00_layer_weather_finalTable` AS
SELECT  
    t1.*,
    t2.avg_day_temp,
    t3.max_wind,
    t4.rain_hours
FROM `chuans-playground-123.engeto.001_layer_weather` as t1
LEFT JOIN `chuans-playground-123.engeto.001_layer_weather_avgTemp` AS t2
    ON t1.city = t2.city AND t1.date_removed_time = t2.date_removed_time
LEFT JOIN `chuans-playground-123.engeto.001_layer_weather_maxWind` AS t3
    ON t1.city = t3.city AND t1.date_removed_time = t3.date_removed_time
LEFT JOIN `chuans-playground-123.engeto.001_layer_weather_rainHours` AS t4
    ON t1.city = t4.city AND t1.date_removed_time = t4.date_removed_time

# FInální tabulka
CREATE TABLE `chuans-playground-123.engeto.02_final_table` AS
SELECT  
    t1.country_key,
    t1.date,    
    t1.day_index,
    t1.weather_season,
    t1.population_density,
    t1.median_age_2018,
    t1.tests_performed,
    t1.avg_gini,
    t1.gdp_per_capita,
    t1.avg_mortality,
    t1.Islam,
    t1.Judaism,
    t1.Buddhism,
    t1.Hinduism,
    t1.Christianity,
    t1.Folk_Religions,
    t1.Other_Religions,
    t1.Unaffiliated_Religions,
    t1.life_expectancy,
    t2.avg_day_temp,
    t2.max_wind,
    t2.rain_hours
FROM `chuans-playground-123.engeto.01_layer_weatherSeason_join_lifeExpectancy_difference` AS t1
LEFT JOIN `chuans-playground-123.engeto.00_layer_weather_finalTable` AS t2
ON t1.capital_city = t2.city AND t1.date = t2.date_removed_time
ORDER BY t1.country_key
