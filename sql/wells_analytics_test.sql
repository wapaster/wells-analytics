-- ===================================================================
-- Проект: аналитика добычи, простоев и электропараметров скважин
-- Источник полей: теги WELLS/AGZU_LAST из конфигурации SCADA (S7+/Modbus)
-- СУБД: SQLite (стандартный SQL, легко переносится на PostgreSQL/MSSQL)
-- ===================================================================

-- ---------- СХЕМА ----------

CREATE TABLE wells (
    well_id INTEGER PRIMARY KEY,
    name TEXT NOT NULL UNIQUE
);

CREATE TABLE agzu_tests (
    test_id INTEGER PRIMARY KEY AUTOINCREMENT,
    well_id INTEGER NOT NULL REFERENCES wells(well_id),
    test_date TEXT NOT NULL,           -- дата замера АГЗУ (ISO yyyy-mm-dd)
    oil_rate_t REAL NOT NULL,          -- AvQmOil, т/сут
    liquid_rate_m3 REAL NOT NULL,      -- AvQvFluid, м3/сут
    water_cut_pct REAL NOT NULL,       -- AvWater, %
    density_kg_m3 REAL                 -- ADfld, кг/м3
);

CREATE TABLE stop_reasons (
    code INTEGER PRIMARY KEY,
    description TEXT NOT NULL
);

CREATE TABLE stop_events (
    event_id INTEGER PRIMARY KEY AUTOINCREMENT,
    well_id INTEGER NOT NULL REFERENCES wells(well_id),
    event_date TEXT NOT NULL,          -- дата остановки (PRICHINA_STOP/DTL_DATE_TIME_LAST_STOP)
    reason_code INTEGER NOT NULL REFERENCES stop_reasons(code),
    duration_hours REAL NOT NULL       -- DTL_TIME_IN_STOP, час
);

CREATE TABLE electrical_readings (
    reading_id INTEGER PRIMARY KEY AUTOINCREMENT,
    well_id INTEGER NOT NULL REFERENCES wells(well_id),
    reading_date TEXT NOT NULL,
    active_power_kw REAL NOT NULL,         -- ACTIVE_POWER
    current_imbalance_pct REAL NOT NULL    -- DISBALANCE_AMP
);

CREATE TABLE custody_totals (
    total_date TEXT PRIMARY KEY,
    oil_total_t REAL NOT NULL          -- факт. сдача на узле учёта за дату
);

-- ---------- СПРАВОЧНИК ПРИЧИН ОСТАНОВКИ ----------

INSERT INTO stop_reasons(code, description) VALUES
 (1, 'Выкл. питания'),
 (2, 'Авария по нагрузке'),
 (3, 'Парафиноотложение'),
 (4, 'Плановый ремонт (ПРС)'),
 (5, 'Авария ТМС');

-- ---------- СКВАЖИНЫ ----------

INSERT INTO wells(well_id, name) VALUES
 (1, 'СХ-23'),
 (2, 'СХ-30'),
 (3, 'СХ-15'),
 (4, 'СХ-16'),
 (5, 'СХ-29');

-- ---------- ЗАМЕРЫ АГЗУ (журнал) ----------

INSERT INTO agzu_tests(well_id, test_date, oil_rate_t, liquid_rate_m3, water_cut_pct, density_kg_m3) VALUES
 (1, '2026-06-01', 20, 28.6, 30, 880),
 (1, '2026-06-04', 19.8, 28.7, 31, 879),
 (1, '2026-06-07', 20.1, 28.7, 30, 881),
 (1, '2026-06-10', 19.5, 27.5, 29, 878),
 (1, '2026-06-13', 19.7, 28.6, 31, 880),
 (1, '2026-06-16', 19.6, 28.0, 30, 879),
 (2, '2026-06-01', 18, 24.0, 25, 875),
 (2, '2026-06-04', 16, 21.6, 26, 874),
 (2, '2026-06-07', 14, 19.4, 28, 876),
 (2, '2026-06-10', 12, 16.9, 29, 873),
 (2, '2026-06-13', 11, 15.9, 31, 875),
 (2, '2026-06-16', 9, 13.4, 33, 872),
 (3, '2026-06-01', 25, 31.2, 20, 865),
 (3, '2026-06-04', 24, 33.3, 28, 866),
 (3, '2026-06-07', 22, 35.5, 38, 864),
 (3, '2026-06-10', 18, 36.0, 50, 863),
 (3, '2026-06-13', 15, 37.5, 60, 862),
 (3, '2026-06-16', 12, 38.7, 69, 860),
 (4, '2026-06-01', 15, 25.0, 40, 890),
 (4, '2026-06-04', 15.2, 25.8, 41, 889),
 (4, '2026-06-07', 14.9, 24.4, 39, 891),
 (4, '2026-06-10', 15.1, 25.2, 40, 888),
 (4, '2026-06-13', 15, 25.4, 41, 890),
 (4, '2026-06-16', 14.8, 24.7, 40, 889),
 (5, '2026-06-01', 10, 22.2, 55, 870),
 (5, '2026-06-04', 11, 22.9, 52, 871),
 (5, '2026-06-07', 13, 25.0, 48, 869),
 (5, '2026-06-10', 14, 25.5, 45, 872),
 (5, '2026-06-13', 16, 27.6, 42, 873),
 (5, '2026-06-16', 17, 28.3, 40, 874);

-- ---------- СОБЫТИЯ ОСТАНОВКИ (тестовый набор) ----------

INSERT INTO stop_events(well_id, event_date, reason_code, duration_hours) VALUES
 (2, '2026-06-04', 2, 6),
 (2, '2026-06-14', 3, 4),
 (3, '2026-06-10', 5, 10),
 (4, '2026-06-01', 1, 1),
 (5, '2026-06-01', 4, 20);

-- ---------- ЭЛЕКТРИЧЕСКИЕ ПАРАМЕТРЫ (по датам замера) ----------

INSERT INTO electrical_readings(well_id, reading_date, active_power_kw, current_imbalance_pct) VALUES
 (1, '2026-06-01', 13.6, 1.2),
 (1, '2026-06-04', 13.6, 1.3),
 (1, '2026-06-07', 13.6, 1.1),
 (1, '2026-06-10', 13.2, 1.4),
 (1, '2026-06-13', 13.6, 1.2),
 (1, '2026-06-16', 13.4, 1.3),
 (2, '2026-06-01', 12.2, 1.5),
 (2, '2026-06-04', 11.5, 2.0),
 (2, '2026-06-07', 10.8, 3.0),
 (2, '2026-06-10', 10.1, 4.5),
 (2, '2026-06-13', 9.8, 6.0),
 (2, '2026-06-16', 9.0, 7.5),
 (3, '2026-06-01', 14.4, 1.0),
 (3, '2026-06-04', 15.0, 1.1),
 (3, '2026-06-07', 15.7, 1.0),
 (3, '2026-06-10', 15.8, 1.2),
 (3, '2026-06-13', 16.2, 1.1),
 (3, '2026-06-16', 16.6, 1.0),
 (4, '2026-06-01', 12.5, 1.8),
 (4, '2026-06-04', 12.7, 1.7),
 (4, '2026-06-07', 12.3, 1.9),
 (4, '2026-06-10', 12.6, 1.8),
 (4, '2026-06-13', 12.6, 1.7),
 (4, '2026-06-16', 12.4, 1.8),
 (5, '2026-06-01', 11.7, 2.0),
 (5, '2026-06-04', 11.9, 1.9),
 (5, '2026-06-07', 12.5, 1.8),
 (5, '2026-06-10', 12.6, 1.6),
 (5, '2026-06-13', 13.3, 1.5),
 (5, '2026-06-16', 13.5, 1.4);

-- ---------- ФАКТИЧЕСКАЯ СДАЧА (узел учёта, для back allocation) ----------

INSERT INTO custody_totals(total_date, oil_total_t) VALUES
 ('2026-06-16', 73.34);

-- ===================================================================
-- АНАЛИТИЧЕСКИЕ ЗАПРОСЫ (оформлены как VIEW — готовы к использованию)
-- ===================================================================

-- 1) Тренд добычи и обводнённости + автоматический флаг отклонения
CREATE VIEW v_production_trend AS
SELECT
    w.name AS well,
    t.test_date,
    t.oil_rate_t,
    t.water_cut_pct,
    ROUND((t.oil_rate_t - LAG(t.oil_rate_t) OVER (PARTITION BY w.well_id ORDER BY t.test_date))
          / LAG(t.oil_rate_t) OVER (PARTITION BY w.well_id ORDER BY t.test_date) * 100, 1) AS oil_change_pct,
    ROUND(t.water_cut_pct - LAG(t.water_cut_pct) OVER (PARTITION BY w.well_id ORDER BY t.test_date), 1) AS water_cut_change_pp,
    CASE
        WHEN (t.oil_rate_t - LAG(t.oil_rate_t) OVER (PARTITION BY w.well_id ORDER BY t.test_date))
             / LAG(t.oil_rate_t) OVER (PARTITION BY w.well_id ORDER BY t.test_date) <= -0.1
             AND (t.water_cut_pct - LAG(t.water_cut_pct) OVER (PARTITION BY w.well_id ORDER BY t.test_date)) >= 5
            THEN 'Падение дебита и рост обв.'
        WHEN (t.oil_rate_t - LAG(t.oil_rate_t) OVER (PARTITION BY w.well_id ORDER BY t.test_date))
             / LAG(t.oil_rate_t) OVER (PARTITION BY w.well_id ORDER BY t.test_date) <= -0.1
            THEN 'Падение дебита'
        WHEN (t.water_cut_pct - LAG(t.water_cut_pct) OVER (PARTITION BY w.well_id ORDER BY t.test_date)) >= 5
            THEN 'Рост обводнённости'
        ELSE 'Норма'
    END AS flag
FROM agzu_tests t
JOIN wells w ON w.well_id = t.well_id;

-- 2) Структура простоев по причинам (Парето: доля и накопленная доля)
CREATE VIEW v_downtime_pareto AS
SELECT
    r.description AS reason,
    SUM(s.duration_hours) AS total_hours,
    ROUND(100.0 * SUM(s.duration_hours) / (SELECT SUM(duration_hours) FROM stop_events), 1) AS pct_of_total,
    ROUND(100.0 * SUM(SUM(s.duration_hours)) OVER (ORDER BY SUM(s.duration_hours) DESC)
          / (SELECT SUM(duration_hours) FROM stop_events), 1) AS cumulative_pct
FROM stop_events s
JOIN stop_reasons r ON r.code = s.reason_code
GROUP BY r.description
ORDER BY total_hours DESC;

-- 3) Энергоэффективность: удельная мощность на тонну добычи + дисбаланс токов
CREATE VIEW v_electrical_efficiency AS
SELECT
    w.name AS well,
    ROUND(AVG(e.active_power_kw), 1) AS avg_power_kw,
    ROUND(AVG(t.oil_rate_t), 1) AS avg_oil_rate_t,
    ROUND(AVG(e.active_power_kw) / AVG(t.oil_rate_t), 2) AS power_per_ton,
    ROUND(MAX(e.current_imbalance_pct), 1) AS max_imbalance_pct,
    CASE WHEN MAX(e.current_imbalance_pct) >= 5 THEN 'Проверить двигатель' ELSE 'Норма' END AS status
FROM electrical_readings e
JOIN agzu_tests t ON t.well_id = e.well_id AND t.test_date = e.reading_date
JOIN wells w ON w.well_id = e.well_id
GROUP BY w.name
ORDER BY power_per_ton DESC;

-- 4) Back allocation на последнюю дату замера с учётом простоев в межтестовый период
CREATE VIEW v_back_allocation_latest AS
WITH latest AS (
    SELECT t.well_id, w.name AS well, t.oil_rate_t, t.test_date
    FROM agzu_tests t
    JOIN wells w ON w.well_id = t.well_id
    WHERE t.test_date = (SELECT MAX(test_date) FROM agzu_tests)
),
downtime AS (
    SELECT well_id, SUM(duration_hours) AS hours_down
    FROM stop_events
    WHERE event_date > (SELECT MAX(test_date) FROM agzu_tests WHERE test_date < (SELECT MAX(test_date) FROM agzu_tests))
      AND event_date <= (SELECT MAX(test_date) FROM agzu_tests)
    GROUP BY well_id
),
adjusted AS (
    SELECT l.well_id, l.well,
           l.oil_rate_t * (1.0 - COALESCE(d.hours_down, 0) / 72.0) AS adj_rate
    FROM latest l
    LEFT JOIN downtime d ON d.well_id = l.well_id
)
SELECT
    a.well,
    ROUND(a.adj_rate, 2) AS adjusted_rate_t,
    ROUND(a.adj_rate / (SELECT SUM(adj_rate) FROM adjusted) * c.oil_total_t, 2) AS allocated_oil_t
FROM adjusted a, custody_totals c
WHERE c.total_date = (SELECT MAX(test_date) FROM agzu_tests);
