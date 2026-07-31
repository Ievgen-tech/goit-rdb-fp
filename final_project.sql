-- ФІНАЛЬНИЙ ПРОЄКТ: Робота з даними, нормалізація, агрегація та функції
-- ЗАВДАННЯ 1: Створення схеми та вибір її за замовчуванням
-- (Скриншот: p1_import.png - створена схема та імпорт даних)
-- ==========================================
DROP SCHEMA IF EXISTS pandemic;
CREATE SCHEMA pandemic;
USE pandemic;

-- ЗАВДАННЯ 2: Нормалізація даних до 3НФ
-- (Скриншот: p2_normalization.png - результат виконання запиту COUNT)
-- ==========================================

-- Створюємо таблицю-довідник для Entity та Code
CREATE TABLE countries (
    id INT AUTO_INCREMENT PRIMARY KEY,
    entity VARCHAR(255) NOT NULL,
    code VARCHAR(10)
);

-- Заповнюємо довідник унікальними значеннями
INSERT INTO countries (entity, code)
SELECT DISTINCT Entity, Code 
FROM infectious_cases;

-- Створюємо нормалізовану таблицю (без дублювання тексту)
CREATE TABLE infectious_cases_norm (
    id INT AUTO_INCREMENT PRIMARY KEY,
    country_id INT,
    year INT,
    number_yaws DOUBLE,
    polio_cases DOUBLE,
    cases_guinea_worm DOUBLE,
    number_rabies DOUBLE,
    number_malaria DOUBLE,
    number_hiv DOUBLE,
    number_tuberculosis DOUBLE,
    number_smallpox DOUBLE,
    number_cholera_cases DOUBLE,
    FOREIGN KEY (country_id) REFERENCES countries(id)
);

-- Переносимо дані у нормалізовану таблицю
INSERT INTO infectious_cases_norm (
    country_id, year, number_yaws, polio_cases, cases_guinea_worm, 
    number_rabies, number_malaria, number_hiv, number_tuberculosis, 
    number_smallpox, number_cholera_cases
)
SELECT 
    c.id, 
    ic.Year, 
    NULLIF(TRIM(ic.Number_yaws), ''), 
    NULLIF(TRIM(ic.polio_cases), ''), 
    NULLIF(TRIM(ic.cases_guinea_worm), ''), 
    NULLIF(TRIM(ic.Number_rabies), ''), 
    NULLIF(TRIM(ic.Number_malaria), ''), 
    NULLIF(TRIM(ic.Number_hiv), ''), 
    NULLIF(TRIM(ic.Number_tuberculosis), ''), 
    NULLIF(TRIM(ic.Number_smallpox), ''), 
    NULLIF(TRIM(ic.Number_cholera_cases), '')
FROM infectious_cases ic
JOIN countries c ON ic.Entity = c.entity AND ic.Code <=> c.code;

-- Перевірочний запит для ментора
SELECT COUNT(*) AS total_records FROM infectious_cases;

-- ЗАВДАННЯ 3: Аналіз даних (Number_rabies)
-- (Скриншот: p3_analysis.png)
-- ==========================================
SELECT 
    c.entity, 
    c.code, 
    AVG(ic.number_rabies) AS avg_rabies, 
    MIN(ic.number_rabies) AS min_rabies, 
    MAX(ic.number_rabies) AS max_rabies, 
    SUM(ic.number_rabies) AS sum_rabies
FROM infectious_cases_norm ic
JOIN countries c ON ic.country_id = c.id
WHERE ic.number_rabies IS NOT NULL 
GROUP BY c.entity, c.code
ORDER BY avg_rabies DESC
LIMIT 10;

-- ЗАВДАННЯ 4: Побудова колонки різниці в роках
-- (Скриншот: p4_count_dates.png)
-- ==========================================
SELECT 
    year,
    MAKEDATE(year, 1) AS start_of_year,
    CURDATE() AS today_date,
    TIMESTAMPDIFF(YEAR, MAKEDATE(year, 1), CURDATE()) AS years_diff
FROM infectious_cases_norm;

-- ЗАВДАННЯ 5: Побудова власної функції
-- (Скриншот: p5_function.png)
-- ==========================================
DELIMITER //

CREATE FUNCTION calculate_years_diff(input_year INT)
RETURNS INT
DETERMINISTIC
BEGIN
    DECLARE diff INT;
    IF input_year IS NULL THEN
        RETURN NULL;
    END IF;
    
    SET diff = TIMESTAMPDIFF(YEAR, MAKEDATE(input_year, 1), CURDATE());
    RETURN diff;
END //

DELIMITER ;

-- Демонстрація роботи створеної функції
SELECT 
    year, 
    calculate_years_diff(year) AS custom_func_diff
FROM infectious_cases_norm;