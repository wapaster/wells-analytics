-- ===================================================================
-- DWH-слой: звёздная схема (star schema) поверх OLTP-базы wells_analytics
-- ===================================================================
-- Назначение: демонстрация классического подхода DWH — денормализованные
-- таблицы фактов и измерений, оптимизированные под чтение и BI-инструменты,
-- в отличие от нормализованной (3НФ) OLTP-схемы, где данные разложены
-- по независимым таблицам ради целостности и отсутствия дублирования.
--
-- Слой строится ПОВЕРХ существующих таблиц (wells, agzu_tests, stop_events,
-- stop_reasons, electrical_readings, custody_totals) — ничего в них не меняет.
-- ===================================================================


-- ===================================================================
-- ЧАСТЬ 1 — ТАБЛИЦЫ ИЗМЕРЕНИЙ (DIMENSIONS)
-- ===================================================================

DROP TABLE IF EXISTS dim_date CASCADE;
DROP TABLE IF EXISTS dim_well CASCADE;
DROP TABLE IF EXISTS dim_stop_reason CASCADE;

-- ---------- dim_well: измерение "скважина" ----------
-- Суррогатный ключ (well_key) отделён от натурального (well_id) —
-- стандартная практика DWH: если завтра появится вторая система-источник
-- с другой нумерацией скважин, суррогатный ключ останется стабильным.
CREATE TABLE dim_well (
    well_key    SERIAL PRIMARY KEY,
    well_id     INTEGER NOT NULL UNIQUE,   -- натуральный ключ из OLTP
    well_name   TEXT NOT NULL
);

INSERT INTO dim_well (well_id, well_name)
SELECT well_id, name FROM wells;


-- ---------- dim_stop_reason: измерение "причина остановки" ----------
CREATE TABLE dim_stop_reason (
    reason_key   SERIAL PRIMARY KEY,
    reason_code  INTEGER NOT NULL UNIQUE,
    description  TEXT NOT NULL
);

INSERT INTO dim_stop_reason (reason_code, description)
SELECT code, description FROM stop_reasons;


-- ---------- dim_date: классическое измерение "дата" ----------
-- Строится один раз генерацией диапазона дат, не зависит от источника.
-- Позволяет удобно фильтровать/группировать в BI по году, кварталу,
-- месяцу, дню недели — без вычислений на лету в каждом запросе.
CREATE TABLE dim_date (
    date_key      INTEGER PRIMARY KEY,      -- формат YYYYMMDD, удобно для сортировки и JOIN
    full_date     DATE NOT NULL UNIQUE,
    year          INTEGER NOT NULL,
    quarter       INTEGER NOT NULL,
    month         INTEGER NOT NULL,
    month_name    TEXT NOT NULL,
    day           INTEGER NOT NULL,
    day_of_week   INTEGER NOT NULL,         -- 1=Пн ... 7=Вс
    day_name      TEXT NOT NULL,
    is_weekend    BOOLEAN NOT NULL
);

INSERT INTO dim_date (date_key, full_date, year, quarter, month, month_name, day, day_of_week, day_name, is_weekend)
SELECT
    TO_CHAR(d, 'YYYYMMDD')::INTEGER,
    d,
    EXTRACT(YEAR FROM d)::INTEGER,
    EXTRACT(QUARTER FROM d)::INTEGER,
    EXTRACT(MONTH FROM d)::INTEGER,
    TO_CHAR(d, 'TMMonth'),
    EXTRACT(DAY FROM d)::INTEGER,
    EXTRACT(ISODOW FROM d)::INTEGER,
    TO_CHAR(d, 'TMDay'),
    EXTRACT(ISODOW FROM d) IN (6, 7)
FROM generate_series('2026-01-01'::DATE, '2026-12-31'::DATE, '1 day'::INTERVAL) AS d;


-- ===================================================================
-- ЧАСТЬ 2 — ТАБЛИЦЫ ФАКТОВ (FACTS)
-- ===================================================================
-- Факты хранят только числовые измеримые показатели и внешние ключи
-- на измерения — денормализованно, без дополнительных JOIN на этапе
-- чтения текстовых атрибутов (они уже "развёрнуты" в dim_*).

DROP TABLE IF EXISTS fact_production CASCADE;
DROP TABLE IF EXISTS fact_downtime CASCADE;
DROP TABLE IF EXISTS fact_electrical CASCADE;


-- ---------- fact_production: факты по добыче (из agzu_tests) ----------
CREATE TABLE fact_production (
    production_key   SERIAL PRIMARY KEY,
    well_key         INTEGER NOT NULL REFERENCES dim_well(well_key),
    date_key         INTEGER NOT NULL REFERENCES dim_date(date_key),
    oil_rate_t       NUMERIC(10,2),
    liquid_rate_m3   NUMERIC(10,2),
    water_cut_pct    NUMERIC(5,2),
    gas_rate_m3      NUMERIC(10,2),
    density_kg_m3    NUMERIC(8,2),
    pressure_kgcm2   NUMERIC(8,2),
    temp_fluid_c     NUMERIC(6,2),
    gas_factor       NUMERIC(8,4)             -- рассчитанная мера, хранится готовой для быстрого чтения
);

INSERT INTO fact_production (well_key, date_key, oil_rate_t, liquid_rate_m3, water_cut_pct,
                              gas_rate_m3, density_kg_m3, pressure_kgcm2, temp_fluid_c, gas_factor)
SELECT
    dw.well_key,
    TO_CHAR(a.test_date, 'YYYYMMDD')::INTEGER,
    a.oil_rate_t,
    a.liquid_rate_m3,
    a.water_cut_pct,
    a.gas_rate_m3,
    a.density_kg_m3,
    a.pressure_kgcm2,
    a.temp_fluid_c,
    ROUND(a.gas_rate_m3 / NULLIF(a.liquid_rate_m3, 0), 4)
FROM agzu_tests a
JOIN dim_well dw ON dw.well_id = a.well_id;


-- ---------- fact_downtime: факты по простоям (из stop_events) ----------
CREATE TABLE fact_downtime (
    downtime_key     SERIAL PRIMARY KEY,
    well_key         INTEGER NOT NULL REFERENCES dim_well(well_key),
    date_key         INTEGER NOT NULL REFERENCES dim_date(date_key),
    reason_key       INTEGER NOT NULL REFERENCES dim_stop_reason(reason_key),
    duration_hours   NUMERIC(8,2),
    event_count      INTEGER DEFAULT 1        -- аддитивная мера "число событий", удобно для SUM в BI
);

INSERT INTO fact_downtime (well_key, date_key, reason_key, duration_hours, event_count)
SELECT
    dw.well_key,
    TO_CHAR(s.event_date::DATE, 'YYYYMMDD')::INTEGER,
    dr.reason_key,
    s.duration_hours,
    1
FROM stop_events s
JOIN dim_well dw ON dw.well_id = s.well_id
JOIN dim_stop_reason dr ON dr.reason_code = s.reason_code;


-- ---------- fact_electrical: факты по электрике (из electrical_readings) ----------
CREATE TABLE fact_electrical (
    electrical_key        SERIAL PRIMARY KEY,
    well_key              INTEGER NOT NULL REFERENCES dim_well(well_key),
    date_key              INTEGER NOT NULL REFERENCES dim_date(date_key),
    active_power_kw       NUMERIC(8,2),
    full_power_kva        NUMERIC(8,2),
    reactive_power_kvar   NUMERIC(8,2),
    current_imbalance_pct NUMERIC(5,2),
    voltage_ab            NUMERIC(6,1),
    voltage_bc            NUMERIC(6,1),
    voltage_ca            NUMERIC(6,1),
    resistance            NUMERIC(8,1),
    temp_radiator_c       NUMERIC(5,1),
    cos_phi               NUMERIC(5,3)         -- рассчитанная мера, хранится готовой (не считается заново в BI)
);

INSERT INTO fact_electrical (well_key, date_key, active_power_kw, full_power_kva, reactive_power_kvar,
                              current_imbalance_pct, voltage_ab, voltage_bc, voltage_ca,
                              resistance, temp_radiator_c, cos_phi)
SELECT
    dw.well_key,
    TO_CHAR(e.reading_date::DATE, 'YYYYMMDD')::INTEGER,
    e.active_power_kw,
    e.full_power_kva,
    e.reactive_power_kvar,
    e.current_imbalance_pct,
    e.voltage_ab,
    e.voltage_bc,
    e.voltage_ca,
    e.resistance,
    e.temp_radiator_c,
    ROUND(e.active_power_kw / NULLIF(e.full_power_kva, 0), 3)
FROM electrical_readings e
JOIN dim_well dw ON dw.well_id = e.well_id;


-- ===================================================================
-- ЧАСТЬ 3 — ИНДЕКСЫ (для скорости JOIN и фильтрации в BI-запросах)
-- ===================================================================
-- В DWH внешние ключи фактов на измерения почти всегда индексируют,
-- потому что типичный запрос BI-инструмента — это JOIN факта с 2-4
-- измерениями плюс фильтр по дате/скважине.

CREATE INDEX idx_fact_production_well  ON fact_production(well_key);
CREATE INDEX idx_fact_production_date  ON fact_production(date_key);
CREATE INDEX idx_fact_downtime_well    ON fact_downtime(well_key);
CREATE INDEX idx_fact_downtime_date    ON fact_downtime(date_key);
CREATE INDEX idx_fact_downtime_reason  ON fact_downtime(reason_key);
CREATE INDEX idx_fact_electrical_well  ON fact_electrical(well_key);
CREATE INDEX idx_fact_electrical_date  ON fact_electrical(date_key);


-- ===================================================================
-- ЧАСТЬ 4 — ПРИМЕРЫ ЗАПРОСОВ К ЗВЁЗДНОЙ СХЕМЕ
-- ===================================================================
-- Показывают, зачем нужна денормализация: запросы простые, без
-- многоуровневых JOIN на текстовые справочники — они уже "внутри" измерений.

-- 4.1 Добыча нефти по месяцам и скважинам (типичный запрос для BI-таблицы/сводной)
-- SELECT
--     dd.year, dd.month_name, dwl.well_name,
--     ROUND(SUM(fp.oil_rate_t), 1) AS total_oil_t,
--     ROUND(AVG(fp.water_cut_pct), 1) AS avg_water_cut
-- FROM fact_production fp
-- JOIN dim_date dd ON dd.date_key = fp.date_key
-- JOIN dim_well dwl ON dwl.well_key = fp.well_key
-- GROUP BY dd.year, dd.month, dd.month_name, dwl.well_name
-- ORDER BY dd.year, dd.month, dwl.well_name;

-- 4.2 Простои по дням недели — есть ли закономерность (типичный DWH-инсайт)
-- SELECT
--     dd.day_name,
--     COUNT(*) AS stop_events,
--     ROUND(SUM(fdt.duration_hours), 1) AS total_hours
-- FROM fact_downtime fdt
-- JOIN dim_date dd ON dd.date_key = fdt.date_key
-- GROUP BY dd.day_name, dd.day_of_week
-- ORDER BY dd.day_of_week;

-- 4.3 Энергоэффективность по кварталам
-- SELECT
--     dd.year, dd.quarter, dwl.well_name,
--     ROUND(AVG(fe.cos_phi), 3) AS avg_cos_phi,
--     ROUND(MAX(fe.current_imbalance_pct), 1) AS max_imbalance
-- FROM fact_electrical fe
-- JOIN dim_date dd ON dd.date_key = fe.date_key
-- JOIN dim_well dwl ON dwl.well_key = fe.well_key
-- GROUP BY dd.year, dd.quarter, dwl.well_name
-- ORDER BY dd.year, dd.quarter, dwl.well_name;
