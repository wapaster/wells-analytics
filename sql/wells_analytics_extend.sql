-- ===================================================================
-- Расширение базы данных wells_analytics (PostgreSQL)
-- Больше скважин, больше замеров, все аналитические VIEW
-- ===================================================================

-- ===================================================================
-- ЧАСТЬ 1: ДОПОЛНИТЕЛЬНЫЕ ДАННЫЕ
-- ===================================================================

-- Добавляем ещё скважины
INSERT INTO wells (name) VALUES
    ('СХ-29'),
    ('СХ-31'),
    ('СХ-32'),
    ('СХ-33'),
    ('СХ-34'),
    ('СХ-20'),
    ('СХ-11')
ON CONFLICT (name) DO NOTHING;

-- Дополнительные причины остановки
INSERT INTO stop_reasons (code, description) VALUES
    (6, 'Авария обратный клапан'),
    (7, 'Обрыв штанг'),
    (8, 'Заклинивание насоса'),
    (10, 'Высокая вибрация ССК'),
    (11, 'Перегрев двигателя'),
    (12, 'Низкое сопротивление изоляции')
ON CONFLICT (code) DO NOTHING;

-- Массовая вставка замеров АГЗУ — 12 скважин × 10 дат = 120 записей
INSERT INTO agzu_tests (well_id, test_date, oil_rate_t, liquid_rate_m3,
    water_cut_pct, gas_rate_m3, density_kg_m3, pressure_kgcm2, temp_fluid_c)
VALUES
    -- СХ-23 (well_id=1) — стабильное падение дебита, рост обводнённости
    (1, '2026-05-20', 14.50, 22.30, 42.10, 2.80, 975.00, 5.20, 29.50),
    (1, '2026-05-23', 13.80, 22.80, 44.50, 2.75, 974.20, 5.15, 29.80),
    (1, '2026-05-26', 13.10, 23.50, 47.20, 2.70, 973.10, 5.10, 30.00),
    (1, '2026-05-29', 12.40, 24.00, 50.10, 2.65, 972.00, 5.00, 30.10),
    (1, '2026-06-01', 11.80, 24.50, 53.40, 2.60, 971.50, 4.95, 30.20),
    (1, '2026-06-04', 11.50, 25.00, 55.80, 2.55, 971.00, 4.90, 30.30),
    (1, '2026-06-07', 11.20, 25.20, 57.50, 2.50, 970.50, 4.88, 30.40),

    -- СХ-26 (well_id=2) — стабильная скважина
    (2, '2026-05-20', 9.50, 25.00, 62.00, 2.40, 969.00, 4.85, 30.50),
    (2, '2026-05-23', 9.45, 25.10, 62.20, 2.42, 969.10, 4.83, 30.40),
    (2, '2026-05-26', 9.40, 25.20, 62.50, 2.41, 968.90, 4.84, 30.50),
    (2, '2026-05-29', 9.42, 25.30, 62.30, 2.40, 969.00, 4.82, 30.50),
    (2, '2026-06-01', 9.38, 25.40, 62.10, 2.41, 968.95, 4.83, 30.50),
    (2, '2026-06-04', 9.35, 25.50, 62.40, 2.39, 969.00, 4.82, 30.50),
    (2, '2026-06-07', 9.40, 25.30, 62.00, 2.41, 969.00, 4.82, 30.50),
    (2, '2026-06-10', 9.38, 25.40, 62.10, 2.40, 968.97, 4.82, 30.49),
    (2, '2026-06-13', 9.36, 25.50, 62.30, 2.41, 969.00, 4.82, 30.50),
    (2, '2026-06-16', 9.38, 25.51, 62.05, 2.41, 968.97, 4.82, 30.49),

    -- СХ-30 (well_id=3) — резкое падение + проблемы с двигателем
    (3, '2026-05-20', 18.00, 24.00, 25.00, 1.90, 878.00, 4.60, 28.00),
    (3, '2026-05-23', 17.50, 23.50, 25.50, 1.88, 877.50, 4.58, 28.20),
    (3, '2026-05-26', 16.80, 22.80, 26.30, 1.85, 877.00, 4.55, 28.30),
    (3, '2026-05-29', 16.00, 22.00, 27.30, 1.82, 876.50, 4.50, 28.40),
    (3, '2026-06-01', 15.80, 21.50, 26.50, 1.83, 876.00, 4.52, 28.40),
    (3, '2026-06-04', 15.50, 21.00, 26.20, 1.81, 875.50, 4.50, 28.50),
    (3, '2026-06-07', 15.40, 20.80, 25.90, 1.80, 875.30, 4.50, 28.50),
    (3, '2026-06-10', 15.30, 20.50, 25.40, 1.80, 875.20, 4.48, 28.50),
    (3, '2026-06-13', 15.25, 20.40, 25.30, 1.80, 875.10, 4.50, 28.50),
    (3, '2026-06-16', 15.20, 20.30, 25.10, 1.80, 875.00, 4.50, 28.50),

    -- СХ-15 (well_id=4) — резкий рост обводнённости (прорыв воды)
    (4, '2026-05-20', 22.00, 27.50, 20.00, 3.00, 868.00, 4.20, 27.00),
    (4, '2026-05-23', 20.50, 27.80, 26.30, 3.05, 867.00, 4.15, 27.20),
    (4, '2026-05-26', 18.00, 28.50, 36.80, 3.00, 866.00, 4.10, 27.50),
    (4, '2026-05-29', 15.50, 29.00, 46.60, 2.95, 865.00, 4.00, 27.60),
    (4, '2026-06-01', 14.00, 29.50, 52.50, 2.90, 864.00, 3.95, 27.70),
    (4, '2026-06-04', 13.00, 29.80, 56.40, 2.88, 863.50, 3.92, 27.70),
    (4, '2026-06-07', 12.50, 30.00, 58.30, 2.85, 863.00, 3.90, 27.70),
    (4, '2026-06-10', 12.20, 30.00, 59.30, 2.82, 862.50, 3.90, 27.70),
    (4, '2026-06-13', 12.10, 30.00, 59.70, 2.80, 862.00, 3.90, 27.70),

    -- СХ-16 (well_id=5) — стабильная
    (5, '2026-05-20', 15.00, 25.00, 40.00, 2.20, 890.00, 4.60, 31.00),
    (5, '2026-05-23', 14.90, 24.80, 39.90, 2.22, 889.50, 4.58, 31.10),
    (5, '2026-05-26', 15.10, 25.20, 40.10, 2.20, 890.00, 4.60, 31.00),
    (5, '2026-05-29', 14.95, 24.90, 40.00, 2.21, 889.80, 4.59, 31.00),
    (5, '2026-06-01', 15.00, 25.00, 40.00, 2.20, 889.50, 4.60, 31.10),
    (5, '2026-06-04', 14.85, 24.70, 39.80, 2.22, 889.00, 4.60, 31.20),
    (5, '2026-06-07', 14.90, 24.80, 40.00, 2.20, 889.50, 4.58, 31.10),
    (5, '2026-06-10', 14.80, 24.70, 40.10, 2.20, 889.00, 4.60, 31.20),
    (5, '2026-06-13', 14.85, 24.80, 40.00, 2.21, 889.50, 4.59, 31.10),

    -- СХ-29 (well_id=6) — рост дебита (после ПРС)
    (6, '2026-05-20', 8.00, 20.00, 60.00, 1.50, 870.00, 4.00, 29.00),
    (6, '2026-05-23', 10.00, 22.00, 54.50, 1.70, 871.00, 4.10, 29.20),
    (6, '2026-05-26', 12.00, 23.00, 47.80, 1.90, 872.00, 4.20, 29.30),
    (6, '2026-05-29', 13.50, 24.00, 43.80, 2.00, 872.50, 4.25, 29.40),
    (6, '2026-06-01', 14.50, 24.50, 40.80, 2.10, 873.00, 4.30, 29.50),
    (6, '2026-06-04', 15.50, 25.00, 38.00, 2.15, 873.50, 4.35, 29.50),
    (6, '2026-06-07', 16.00, 25.50, 37.30, 2.20, 874.00, 4.38, 29.60),
    (6, '2026-06-10', 16.50, 25.80, 36.00, 2.22, 874.00, 4.40, 29.60),
    (6, '2026-06-13', 17.00, 26.00, 34.60, 2.25, 874.50, 4.42, 29.60),

    -- СХ-31 (well_id=7) — умеренное падение
    (7, '2026-05-20', 11.00, 18.00, 38.90, 1.60, 882.00, 4.50, 30.00),
    (7, '2026-05-26', 10.50, 18.20, 42.30, 1.55, 881.00, 4.45, 30.10),
    (7, '2026-06-01', 10.00, 18.50, 45.90, 1.50, 880.00, 4.40, 30.20),
    (7, '2026-06-07', 9.80, 18.80, 47.90, 1.48, 879.50, 4.38, 30.20),
    (7, '2026-06-13', 9.50, 19.00, 50.00, 1.45, 879.00, 4.35, 30.30),

    -- СХ-32 (well_id=8) — высокая обводнённость, стабильная
    (8, '2026-05-20', 5.00, 25.00, 80.00, 0.80, 960.00, 3.80, 32.00),
    (8, '2026-05-26', 4.90, 25.10, 80.50, 0.78, 960.50, 3.78, 32.10),
    (8, '2026-06-01', 4.80, 25.20, 81.00, 0.77, 961.00, 3.75, 32.10),
    (8, '2026-06-07', 4.85, 25.00, 80.60, 0.79, 960.80, 3.78, 32.00),
    (8, '2026-06-13', 4.75, 25.30, 81.20, 0.76, 961.20, 3.74, 32.10),

    -- СХ-33 (well_id=9) — газовое влияние
    (9, '2026-05-20', 13.00, 20.00, 35.00, 4.50, 855.00, 3.50, 28.00),
    (9, '2026-05-26', 12.50, 19.50, 35.90, 5.20, 854.00, 3.40, 28.10),
    (9, '2026-06-01', 12.00, 19.00, 36.80, 6.00, 853.00, 3.30, 28.20),
    (9, '2026-06-07', 11.50, 18.50, 37.80, 6.80, 852.00, 3.20, 28.30),
    (9, '2026-06-13', 11.00, 18.00, 38.90, 7.50, 851.00, 3.10, 28.40),

    -- СХ-34 (well_id=10) — стабильная, низкий дебит
    (10, '2026-05-20', 6.00, 12.00, 50.00, 1.00, 900.00, 5.00, 33.00),
    (10, '2026-05-26', 5.90, 12.10, 51.20, 1.00, 900.50, 5.00, 33.00),
    (10, '2026-06-01', 6.10, 12.00, 49.20, 1.02, 899.80, 5.02, 33.10),
    (10, '2026-06-07', 5.95, 12.05, 50.60, 1.00, 900.20, 5.00, 33.00),
    (10, '2026-06-13', 6.00, 12.00, 50.00, 1.01, 900.00, 5.00, 33.00),

    -- СХ-20 (well_id=11) — парафиноотложение, скачки
    (11, '2026-05-20', 16.00, 22.00, 27.30, 2.50, 876.00, 4.80, 27.50),
    (11, '2026-05-26', 14.00, 20.00, 30.00, 2.30, 877.00, 4.70, 27.60),
    (11, '2026-06-01', 10.00, 16.00, 37.50, 1.80, 880.00, 4.50, 27.80),
    (11, '2026-06-04', 15.80, 21.80, 27.50, 2.48, 876.20, 4.78, 27.50),
    (11, '2026-06-07', 13.50, 19.50, 30.80, 2.20, 877.50, 4.65, 27.60),
    (11, '2026-06-13', 9.00, 14.50, 37.90, 1.60, 881.00, 4.40, 27.90),

    -- СХ-11 (well_id=12) — высокий дебит, стабильная
    (12, '2026-05-20', 25.00, 32.00, 21.90, 3.50, 865.00, 5.50, 26.00),
    (12, '2026-05-26', 24.80, 31.80, 22.00, 3.48, 865.20, 5.48, 26.10),
    (12, '2026-06-01', 25.10, 32.20, 22.00, 3.52, 864.80, 5.52, 26.00),
    (12, '2026-06-07', 24.90, 32.00, 22.20, 3.50, 865.00, 5.50, 26.00),
    (12, '2026-06-13', 25.00, 32.10, 22.10, 3.50, 865.00, 5.50, 26.00);


-- Массовая вставка электрических параметров
INSERT INTO electrical_readings (well_id, reading_date,
    active_power_kw, full_power_kva, reactive_power_kvar,
    current_imbalance_pct, voltage_ab, voltage_bc, voltage_ca,
    amp_motor_u, amp_motor_v, amp_motor_w,
    temp_radiator_c, voltage_dc, voltage_out, resistance)
VALUES
    -- СХ-23 (well_id=1) — стабильная электрика
    (1, '2026-05-20 09:00:00', 10.2, 10.8, 3.5, 0.5, 386, 383, 388, 14.8, 14.2, 14.6, 52, 500, 315, 220),
    (1, '2026-05-23 09:00:00', 10.1, 10.7, 3.4, 0.6, 385, 382, 387, 14.7, 14.1, 14.5, 53, 499, 314, 218),
    (1, '2026-05-26 09:00:00', 10.0, 10.6, 3.3, 0.5, 384, 383, 388, 14.6, 14.0, 14.4, 54, 498, 313, 215),
    (1, '2026-05-29 09:00:00', 9.9, 10.5, 3.3, 0.6, 385, 381, 387, 14.5, 13.9, 14.3, 55, 498, 312, 213),
    (1, '2026-06-01 09:00:00', 9.8, 10.4, 3.2, 0.5, 384, 382, 388, 14.5, 13.8, 14.2, 56, 498, 311, 210),
    (1, '2026-06-04 09:00:00', 9.7, 10.3, 3.2, 0.6, 385, 381, 387, 14.4, 13.7, 14.2, 57, 498, 311, 208),
    (1, '2026-06-07 09:00:00', 9.7, 10.2, 3.1, 0.5, 384, 382, 387, 14.5, 13.6, 14.2, 58, 498, 310, 205),
    (1, '2026-06-10 09:00:00', 9.6, 10.1, 3.1, 0.6, 384, 381, 387, 14.5, 13.5, 14.2, 58, 498, 310, 203),
    (1, '2026-06-13 09:00:00', 9.6, 10.1, 3.1, 0.6, 384, 381, 387, 14.5, 13.5, 14.2, 59, 498, 310, 201),
    (1, '2026-06-16 09:00:00', 9.6, 10.0, 3.1, 0.6, 384, 381, 387, 14.5, 13.5, 14.2, 59, 498, 310, 200),

    -- СХ-30 (well_id=3) — растущий дисбаланс токов, падающее сопротивление
    (3, '2026-05-20 09:00:00', 11.5, 12.5, 4.8, 1.5, 392, 382, 396, 13.0, 12.0, 14.5, 55, 495, 308, 180),
    (3, '2026-05-23 09:00:00', 11.2, 12.3, 4.6, 2.0, 391, 381, 396, 12.8, 11.8, 14.8, 56, 494, 306, 175),
    (3, '2026-05-26 09:00:00', 10.8, 12.0, 4.5, 3.0, 390, 380, 396, 12.5, 11.6, 15.0, 58, 493, 305, 170),
    (3, '2026-05-29 09:00:00', 10.5, 11.8, 4.4, 3.5, 390, 380, 395, 12.3, 11.5, 15.2, 59, 492, 304, 168),
    (3, '2026-06-01 09:00:00', 10.2, 11.5, 4.3, 4.0, 391, 380, 395, 12.2, 11.5, 15.3, 60, 492, 303, 165),
    (3, '2026-06-04 09:00:00', 9.8, 11.2, 4.2, 4.5, 390, 380, 395, 12.0, 11.5, 15.5, 61, 491, 302, 160),
    (3, '2026-06-07 09:00:00', 9.5, 11.0, 4.2, 5.5, 390, 380, 395, 12.0, 11.5, 15.6, 62, 491, 301, 158),
    (3, '2026-06-10 09:00:00', 9.2, 10.8, 4.2, 6.0, 390, 380, 395, 12.0, 11.5, 15.7, 63, 490, 300, 155),
    (3, '2026-06-13 09:00:00', 9.0, 10.6, 4.2, 6.8, 390, 380, 395, 12.0, 11.5, 15.8, 64, 490, 300, 152),
    (3, '2026-06-16 09:00:00', 8.8, 10.5, 4.2, 7.5, 390, 380, 395, 12.0, 11.5, 15.8, 65, 490, 300, 150),

    -- СХ-15 (well_id=4) — рост мощности при падении дебита
    (4, '2026-05-20 09:00:00', 15.0, 16.0, 5.0, 1.0, 393, 391, 394, 18.5, 18.0, 18.3, 48, 508, 345, 310),
    (4, '2026-05-26 09:00:00', 16.0, 17.0, 5.5, 1.0, 393, 392, 394, 18.3, 17.8, 18.1, 49, 507, 343, 308),
    (4, '2026-06-01 09:00:00', 17.5, 18.8, 6.0, 1.0, 392, 391, 394, 18.2, 17.7, 18.2, 50, 506, 342, 305),
    (4, '2026-06-07 09:00:00', 18.5, 20.0, 6.3, 1.0, 392, 391, 394, 18.0, 17.5, 18.2, 51, 506, 341, 303),
    (4, '2026-06-13 09:00:00', 19.3, 21.0, 6.5, 1.0, 392, 391, 394, 18.0, 17.5, 18.2, 52, 505, 340, 300),

    -- СХ-16 (well_id=5) — стабильная
    (5, '2026-05-20 09:00:00', 12.5, 13.2, 4.0, 1.8, 393, 391, 394, 15.0, 14.8, 15.1, 45, 502, 330, 280),
    (5, '2026-05-26 09:00:00', 12.6, 13.3, 4.0, 1.7, 393, 391, 394, 15.0, 14.8, 15.0, 45, 502, 330, 280),
    (5, '2026-06-01 09:00:00', 12.4, 13.1, 3.9, 1.9, 392, 391, 394, 15.1, 14.7, 15.0, 46, 502, 329, 278),
    (5, '2026-06-07 09:00:00', 12.5, 13.2, 4.0, 1.8, 393, 391, 394, 15.0, 14.8, 15.1, 45, 502, 330, 280),
    (5, '2026-06-13 09:00:00', 12.5, 13.2, 4.0, 1.7, 393, 391, 394, 15.0, 14.8, 15.0, 46, 502, 330, 279),

    -- СХ-29 (well_id=6) — после ПРС, мощность растёт с дебитом
    (6, '2026-05-20 09:00:00', 8.0, 9.5, 3.0, 2.0, 388, 386, 390, 10.0, 9.8, 10.1, 42, 500, 320, 350),
    (6, '2026-05-26 09:00:00', 10.0, 11.2, 3.5, 1.9, 388, 386, 390, 11.5, 11.2, 11.6, 43, 500, 322, 345),
    (6, '2026-06-01 09:00:00', 11.5, 12.5, 3.8, 1.8, 389, 387, 390, 12.5, 12.2, 12.6, 44, 501, 325, 342),
    (6, '2026-06-07 09:00:00', 12.5, 13.5, 4.0, 1.6, 389, 387, 390, 13.0, 12.8, 13.2, 45, 501, 328, 340),
    (6, '2026-06-13 09:00:00', 12.8, 13.8, 4.1, 1.5, 389, 387, 391, 13.2, 13.0, 13.4, 45, 501, 329, 338),

    -- СХ-33 (well_id=9) — газовое влияние, нестабильная мощность
    (9, '2026-05-20 09:00:00', 13.0, 15.0, 5.5, 2.5, 385, 383, 388, 16.0, 15.5, 16.2, 50, 496, 318, 250),
    (9, '2026-05-26 09:00:00', 12.5, 14.8, 5.8, 2.8, 384, 382, 389, 15.8, 15.2, 16.5, 51, 495, 316, 248),
    (9, '2026-06-01 09:00:00', 11.8, 14.5, 6.2, 3.2, 384, 381, 389, 15.5, 14.8, 16.8, 52, 494, 314, 245),
    (9, '2026-06-07 09:00:00', 11.0, 14.0, 6.5, 3.5, 383, 381, 390, 15.2, 14.5, 17.0, 53, 493, 312, 242),
    (9, '2026-06-13 09:00:00', 10.5, 13.8, 6.8, 3.8, 383, 380, 390, 15.0, 14.2, 17.2, 54, 492, 310, 240),

    -- СХ-20 (well_id=11) — парафин, скачки мощности
    (11, '2026-05-20 09:00:00', 14.0, 15.0, 4.5, 1.5, 390, 388, 392, 16.5, 16.2, 16.7, 48, 500, 325, 260),
    (11, '2026-05-26 09:00:00', 15.5, 17.0, 5.5, 2.0, 390, 387, 392, 17.0, 16.5, 17.5, 52, 498, 320, 258),
    (11, '2026-06-01 09:00:00', 18.0, 20.5, 7.5, 3.0, 389, 386, 393, 18.5, 17.0, 19.0, 58, 496, 312, 255),
    (11, '2026-06-04 09:00:00', 14.2, 15.2, 4.6, 1.6, 390, 388, 392, 16.6, 16.3, 16.8, 48, 500, 324, 260),
    (11, '2026-06-07 09:00:00', 16.0, 17.8, 6.0, 2.2, 390, 387, 392, 17.2, 16.8, 17.8, 53, 498, 318, 257),
    (11, '2026-06-13 09:00:00', 19.0, 21.5, 8.0, 3.2, 389, 385, 393, 19.0, 17.2, 19.5, 60, 495, 310, 252),

    -- СХ-11 (well_id=12) — мощный, стабильный
    (12, '2026-05-20 09:00:00', 22.0, 23.0, 6.0, 0.8, 394, 393, 395, 22.0, 21.8, 22.1, 50, 510, 350, 400),
    (12, '2026-05-26 09:00:00', 22.1, 23.1, 6.0, 0.7, 394, 393, 395, 22.0, 21.9, 22.0, 50, 510, 350, 398),
    (12, '2026-06-01 09:00:00', 21.9, 22.9, 5.9, 0.8, 394, 393, 395, 21.9, 21.7, 22.0, 51, 510, 350, 395),
    (12, '2026-06-07 09:00:00', 22.0, 23.0, 6.0, 0.7, 394, 393, 395, 22.0, 21.8, 22.1, 50, 510, 350, 393),
    (12, '2026-06-13 09:00:00', 22.0, 23.0, 6.0, 0.8, 394, 393, 395, 22.0, 21.8, 22.0, 51, 510, 350, 390);


-- Массовая вставка остановок
INSERT INTO stop_events (well_id, event_date, reason_code, reason_code_2, duration_hours) VALUES
    (1, '2026-05-22 10:30:00', 1, NULL, 0.5),
    (1, '2026-06-18 16:21:47', 1, NULL, 0.5),
    (3, '2026-05-21 06:00:00', 2, 11, 8.0),
    (3, '2026-05-28 14:00:00', 3, NULL, 4.0),
    (3, '2026-06-05 09:00:00', 2, NULL, 6.0),
    (3, '2026-06-12 20:00:00', 11, 2, 12.0),
    (3, '2026-06-15 08:30:00', 2, NULL, 6.0),
    (3, '2026-06-17 14:00:00', 3, NULL, 4.0),
    (4, '2026-06-02 08:00:00', 5, NULL, 10.0),
    (4, '2026-06-09 15:00:00', 5, NULL, 8.0),
    (4, '2026-06-14 10:00:00', 5, NULL, 10.0),
    (4, '2026-06-16 22:00:00', 5, NULL, 8.0),
    (6, '2026-05-18 06:00:00', 4, NULL, 48.0),
    (6, '2026-05-20 06:00:00', 4, NULL, 2.0),
    (7, '2026-06-03 12:00:00', 6, NULL, 5.0),
    (7, '2026-06-10 08:00:00', 3, NULL, 3.0),
    (8, '2026-05-25 16:00:00', 1, NULL, 1.0),
    (9, '2026-06-06 10:00:00', 8, NULL, 24.0),
    (9, '2026-06-12 14:00:00', 10, NULL, 6.0),
    (10, '2026-05-30 08:00:00', 1, NULL, 0.5),
    (11, '2026-05-25 20:00:00', 3, NULL, 12.0),
    (11, '2026-06-03 04:00:00', 3, NULL, 8.0),
    (11, '2026-06-10 22:00:00', 3, NULL, 16.0),
    (12, '2026-06-08 14:00:00', 1, NULL, 0.3);


-- Фактическая сдача за несколько дней (для back allocation)
INSERT INTO custody_totals (total_date, oil_total_t) VALUES
    ('2026-05-20', 168.50),
    ('2026-05-23', 162.30),
    ('2026-05-26', 155.80),
    ('2026-05-29', 148.20),
    ('2026-06-01', 143.50),
    ('2026-06-04', 140.00),
    ('2026-06-07', 137.80),
    ('2026-06-10', 135.50),
    ('2026-06-13', 133.20),
    ('2026-06-16', 131.00);


-- ===================================================================
-- ЧАСТЬ 2: ВСЕ АНАЛИТИЧЕСКИЕ VIEW
-- ===================================================================

-- Удаляем если уже были созданы ранее
DROP VIEW IF EXISTS v_production_trend;
DROP VIEW IF EXISTS v_downtime_by_well;
DROP VIEW IF EXISTS v_downtime_pareto;
DROP VIEW IF EXISTS v_cos_phi;
DROP VIEW IF EXISTS v_voltage_imbalance;
DROP VIEW IF EXISTS v_power_per_oil;
DROP VIEW IF EXISTS v_electrical_health;
DROP VIEW IF EXISTS v_resistance_trend;
DROP VIEW IF EXISTS v_gas_factor;
DROP VIEW IF EXISTS v_pressure_trend;
DROP VIEW IF EXISTS v_back_allocation;
DROP VIEW IF EXISTS v_well_summary;


-- 1. Тренд добычи и обводнённости с автофлагом
CREATE VIEW v_production_trend AS
SELECT
    w.name AS well,
    a.test_date,
    a.oil_rate_t,
    a.liquid_rate_m3,
    a.water_cut_pct,
    LAG(a.oil_rate_t) OVER (PARTITION BY a.well_id ORDER BY a.test_date) AS prev_oil,
    ROUND(
        (a.oil_rate_t - LAG(a.oil_rate_t) OVER (PARTITION BY a.well_id ORDER BY a.test_date))
        / NULLIF(LAG(a.oil_rate_t) OVER (PARTITION BY a.well_id ORDER BY a.test_date), 0) * 100
    , 1) AS oil_change_pct,
    ROUND(
        a.water_cut_pct - LAG(a.water_cut_pct) OVER (PARTITION BY a.well_id ORDER BY a.test_date)
    , 1) AS water_cut_change_pp,
    CASE
        WHEN (a.oil_rate_t - LAG(a.oil_rate_t) OVER (PARTITION BY a.well_id ORDER BY a.test_date))
             / NULLIF(LAG(a.oil_rate_t) OVER (PARTITION BY a.well_id ORDER BY a.test_date), 0) <= -0.1
             AND (a.water_cut_pct - LAG(a.water_cut_pct) OVER (PARTITION BY a.well_id ORDER BY a.test_date)) >= 5
            THEN 'Падение дебита и рост обв.'
        WHEN (a.oil_rate_t - LAG(a.oil_rate_t) OVER (PARTITION BY a.well_id ORDER BY a.test_date))
             / NULLIF(LAG(a.oil_rate_t) OVER (PARTITION BY a.well_id ORDER BY a.test_date), 0) <= -0.1
            THEN 'Падение дебита'
        WHEN (a.water_cut_pct - LAG(a.water_cut_pct) OVER (PARTITION BY a.well_id ORDER BY a.test_date)) >= 5
            THEN 'Рост обводнённости'
        ELSE 'Норма'
    END AS flag
FROM agzu_tests a
JOIN wells w ON w.well_id = a.well_id;


-- 2. Простои по скважинам
CREATE VIEW v_downtime_by_well AS
SELECT
    w.name AS well,
    COUNT(*) AS stop_count,
    ROUND(SUM(s.duration_hours), 1) AS total_downtime_hours,
    ROUND(AVG(s.duration_hours), 1) AS avg_downtime_hours,
    ROUND(MAX(s.duration_hours), 1) AS max_downtime_hours
FROM stop_events s
JOIN wells w ON w.well_id = s.well_id
GROUP BY w.name
ORDER BY total_downtime_hours DESC;


-- 3. Парето по причинам простоев
CREATE VIEW v_downtime_pareto AS
SELECT
    r.description AS reason,
    COUNT(*) AS event_count,
    ROUND(SUM(s.duration_hours), 1) AS total_hours,
    ROUND(100.0 * SUM(s.duration_hours)
        / (SELECT SUM(duration_hours) FROM stop_events), 1) AS pct_of_total,
    ROUND(100.0 * SUM(SUM(s.duration_hours)) OVER (ORDER BY SUM(s.duration_hours) DESC)
        / (SELECT SUM(duration_hours) FROM stop_events), 1) AS cumulative_pct
FROM stop_events s
JOIN stop_reasons r ON r.code = s.reason_code
GROUP BY r.description
ORDER BY total_hours DESC;


-- 4. Коэффициент мощности (cos φ)
CREATE VIEW v_cos_phi AS
SELECT
    w.name AS well,
    e.reading_date,
    e.active_power_kw,
    e.full_power_kva,
    ROUND(e.active_power_kw / NULLIF(e.full_power_kva, 0), 3) AS cos_phi,
    CASE
        WHEN e.active_power_kw / NULLIF(e.full_power_kva, 0) < 0.75 THEN 'Низкий — проверить'
        WHEN e.active_power_kw / NULLIF(e.full_power_kva, 0) < 0.85 THEN 'Допустимый'
        ELSE 'Норма'
    END AS status
FROM electrical_readings e
JOIN wells w ON w.well_id = e.well_id;


-- 5. Дисбаланс напряжений по фазам (формула NEMA)
CREATE VIEW v_voltage_imbalance AS
SELECT
    w.name AS well,
    e.reading_date,
    e.voltage_ab, e.voltage_bc, e.voltage_ca,
    ROUND((e.voltage_ab + e.voltage_bc + e.voltage_ca) / 3.0, 1) AS avg_voltage,
    ROUND(
        GREATEST(
            ABS(e.voltage_ab - (e.voltage_ab + e.voltage_bc + e.voltage_ca) / 3.0),
            ABS(e.voltage_bc - (e.voltage_ab + e.voltage_bc + e.voltage_ca) / 3.0),
            ABS(e.voltage_ca - (e.voltage_ab + e.voltage_bc + e.voltage_ca) / 3.0)
        ) / NULLIF((e.voltage_ab + e.voltage_bc + e.voltage_ca) / 3.0, 0) * 100
    , 2) AS voltage_imbalance_pct,
    e.current_imbalance_pct,
    CASE
        WHEN e.current_imbalance_pct > 5 THEN 'Двигатель — проблема в обмотках'
        WHEN GREATEST(
            ABS(e.voltage_ab - (e.voltage_ab + e.voltage_bc + e.voltage_ca) / 3.0),
            ABS(e.voltage_bc - (e.voltage_ab + e.voltage_bc + e.voltage_ca) / 3.0),
            ABS(e.voltage_ca - (e.voltage_ab + e.voltage_bc + e.voltage_ca) / 3.0)
        ) / NULLIF((e.voltage_ab + e.voltage_bc + e.voltage_ca) / 3.0, 0) * 100 > 2
            THEN 'Сеть — проблема с питанием'
        ELSE 'Норма'
    END AS diagnosis
FROM electrical_readings e
JOIN wells w ON w.well_id = e.well_id;


-- 6. Удельная мощность на нефть
CREATE VIEW v_power_per_oil AS
SELECT
    w.name AS well,
    a.test_date,
    e.active_power_kw,
    a.oil_rate_t,
    a.liquid_rate_m3,
    ROUND(e.active_power_kw / NULLIF(a.oil_rate_t, 0), 2) AS power_per_oil,
    ROUND(e.active_power_kw / NULLIF(a.liquid_rate_m3, 0), 2) AS power_per_liquid
FROM agzu_tests a
JOIN wells w ON w.well_id = a.well_id
JOIN electrical_readings e ON e.well_id = a.well_id
    AND e.reading_date::DATE = a.test_date;


-- 7. Комплексная оценка электрического здоровья скважины
CREATE VIEW v_electrical_health AS
SELECT
    w.name AS well,
    ROUND(AVG(e.active_power_kw / NULLIF(e.full_power_kva, 0)), 3) AS avg_cos_phi,
    ROUND(MAX(e.current_imbalance_pct), 1) AS max_current_imbalance,
    ROUND(AVG(
        GREATEST(
            ABS(e.voltage_ab - (e.voltage_ab + e.voltage_bc + e.voltage_ca) / 3.0),
            ABS(e.voltage_bc - (e.voltage_ab + e.voltage_bc + e.voltage_ca) / 3.0),
            ABS(e.voltage_ca - (e.voltage_ab + e.voltage_bc + e.voltage_ca) / 3.0)
        ) / NULLIF((e.voltage_ab + e.voltage_bc + e.voltage_ca) / 3.0, 0) * 100
    ), 2) AS avg_voltage_imbalance,
    ROUND(AVG(e.temp_radiator_c), 1) AS avg_temp_radiator,
    MIN(e.resistance) AS min_resistance,
    CASE
        WHEN MAX(e.current_imbalance_pct) >= 5 THEN 'Критично'
        WHEN MIN(e.resistance) < 160 THEN 'Внимание: изоляция'
        WHEN AVG(e.active_power_kw / NULLIF(e.full_power_kva, 0)) < 0.75 THEN 'Внимание: cos φ'
        WHEN AVG(e.temp_radiator_c) > 60 THEN 'Внимание: перегрев'
        ELSE 'Норма'
    END AS overall_status
FROM electrical_readings e
JOIN wells w ON w.well_id = e.well_id
GROUP BY w.name
ORDER BY overall_status DESC, w.name;


-- 8. Тренд сопротивления изоляции
CREATE VIEW v_resistance_trend AS
SELECT
    w.name AS well,
    e.reading_date,
    e.resistance,
    LAG(e.resistance) OVER (PARTITION BY e.well_id ORDER BY e.reading_date) AS prev_resistance,
    ROUND(
        e.resistance - LAG(e.resistance) OVER (PARTITION BY e.well_id ORDER BY e.reading_date)
    , 1) AS resistance_change,
    CASE
        WHEN e.resistance < 100 THEN 'Критично'
        WHEN e.resistance < 200 THEN 'Внимание'
        ELSE 'Норма'
    END AS status
FROM electrical_readings e
JOIN wells w ON w.well_id = e.well_id;


-- 9. Газовый фактор и тренд
CREATE VIEW v_gas_factor AS
SELECT
    w.name AS well,
    a.test_date,
    a.gas_rate_m3,
    a.liquid_rate_m3,
    ROUND(a.gas_rate_m3 / NULLIF(a.liquid_rate_m3, 0), 3) AS gas_factor,
    ROUND(
        a.gas_rate_m3 / NULLIF(a.liquid_rate_m3, 0)
        - LAG(a.gas_rate_m3 / NULLIF(a.liquid_rate_m3, 0)) OVER (PARTITION BY a.well_id ORDER BY a.test_date)
    , 4) AS gas_factor_change,
    CASE
        WHEN (a.gas_rate_m3 / NULLIF(a.liquid_rate_m3, 0)
              - LAG(a.gas_rate_m3 / NULLIF(a.liquid_rate_m3, 0)) OVER (PARTITION BY a.well_id ORDER BY a.test_date))
              > 0.05 THEN 'Резкий рост газа'
        ELSE 'Норма'
    END AS flag
FROM agzu_tests a
JOIN wells w ON w.well_id = a.well_id;


-- 10. Скорость изменения давления
CREATE VIEW v_pressure_trend AS
SELECT
    w.name AS well,
    a.test_date,
    a.pressure_kgcm2,
    LAG(a.pressure_kgcm2) OVER (PARTITION BY a.well_id ORDER BY a.test_date) AS prev_pressure,
    a.test_date - LAG(a.test_date) OVER (PARTITION BY a.well_id ORDER BY a.test_date) AS days_between,
    ROUND(
        (a.pressure_kgcm2 - LAG(a.pressure_kgcm2) OVER (PARTITION BY a.well_id ORDER BY a.test_date))
        / NULLIF(a.test_date - LAG(a.test_date) OVER (PARTITION BY a.well_id ORDER BY a.test_date), 0)
    , 4) AS pressure_change_per_day
FROM agzu_tests a
JOIN wells w ON w.well_id = a.well_id;


-- 11. Back allocation на каждую дату сдачи
CREATE VIEW v_back_allocation AS
WITH test_on_date AS (
    SELECT DISTINCT ON (a.well_id, c.total_date)
        a.well_id,
        w.name AS well,
        c.total_date,
        c.oil_total_t AS custody_total,
        a.oil_rate_t,
        a.test_date
    FROM custody_totals c
    CROSS JOIN wells w
    JOIN agzu_tests a ON a.well_id = w.well_id AND a.test_date <= c.total_date
    ORDER BY a.well_id, c.total_date, a.test_date DESC
),
totals AS (
    SELECT total_date, SUM(oil_rate_t) AS sum_rate
    FROM test_on_date
    GROUP BY total_date
)
SELECT
    t.well,
    t.total_date,
    t.oil_rate_t AS test_rate,
    t.test_date AS test_used,
    t.total_date - t.test_date AS test_age_days,
    CASE WHEN t.total_date - t.test_date > 7 THEN 'Да' ELSE 'Нет' END AS test_outdated,
    ROUND(t.oil_rate_t / NULLIF(s.sum_rate, 0) * t.custody_total, 2) AS allocated_oil_t
FROM test_on_date t
JOIN totals s ON s.total_date = t.total_date
ORDER BY t.total_date, t.well;


-- 12. Итоговая сводка по скважинам (всё в одном месте)
CREATE VIEW v_well_summary AS
WITH last_test AS (
    SELECT DISTINCT ON (well_id)
        well_id, test_date, oil_rate_t, water_cut_pct, liquid_rate_m3, gas_rate_m3, pressure_kgcm2
    FROM agzu_tests
    ORDER BY well_id, test_date DESC
),
first_test AS (
    SELECT DISTINCT ON (well_id)
        well_id, oil_rate_t AS first_oil, water_cut_pct AS first_wc, test_date AS first_date
    FROM agzu_tests
    ORDER BY well_id, test_date ASC
),
last_elec AS (
    SELECT DISTINCT ON (well_id)
        well_id, active_power_kw, full_power_kva, current_imbalance_pct, resistance, temp_radiator_c
    FROM electrical_readings
    ORDER BY well_id, reading_date DESC
),
downtime AS (
    SELECT well_id, COUNT(*) AS stops, ROUND(SUM(duration_hours), 1) AS total_down_hrs
    FROM stop_events
    GROUP BY well_id
)
SELECT
    w.name AS well,
    lt.test_date AS last_test_date,
    lt.oil_rate_t AS current_oil_t,
    lt.water_cut_pct AS current_wc_pct,
    lt.liquid_rate_m3 AS current_liquid_m3,
    ROUND((lt.oil_rate_t - ft.first_oil) / NULLIF(ft.first_oil, 0) * 100, 1) AS oil_change_total_pct,
    ROUND(lt.water_cut_pct - ft.first_wc, 1) AS wc_change_total_pp,
    ROUND(le.active_power_kw / NULLIF(le.full_power_kva, 0), 3) AS cos_phi,
    le.current_imbalance_pct,
    le.resistance,
    le.temp_radiator_c,
    ROUND(le.active_power_kw / NULLIF(lt.oil_rate_t, 0), 2) AS power_per_oil,
    ROUND(lt.gas_rate_m3 / NULLIF(lt.liquid_rate_m3, 0), 3) AS gas_factor,
    COALESCE(d.stops, 0) AS total_stops,
    COALESCE(d.total_down_hrs, 0) AS total_downtime_hours,
    CASE
        WHEN le.current_imbalance_pct >= 5 THEN 'Критично: дисбаланс'
        WHEN le.resistance < 160 THEN 'Критично: изоляция'
        WHEN (lt.oil_rate_t - ft.first_oil) / NULLIF(ft.first_oil, 0) <= -0.3
             AND lt.water_cut_pct - ft.first_wc >= 10 THEN 'Критично: обводнение'
        WHEN (lt.oil_rate_t - ft.first_oil) / NULLIF(ft.first_oil, 0) <= -0.2 THEN 'Внимание: падение дебита'
        WHEN lt.water_cut_pct - ft.first_wc >= 10 THEN 'Внимание: рост обводнённости'
        WHEN le.temp_radiator_c >= 60 THEN 'Внимание: перегрев ЧП'
        ELSE 'Стабильно'
    END AS overall_status
FROM wells w
LEFT JOIN last_test lt ON lt.well_id = w.well_id
LEFT JOIN first_test ft ON ft.well_id = w.well_id
LEFT JOIN last_elec le ON le.well_id = w.well_id
LEFT JOIN downtime d ON d.well_id = w.well_id
ORDER BY
    CASE
        WHEN le.current_imbalance_pct >= 5 THEN 1
        WHEN le.resistance < 160 THEN 2
        WHEN (lt.oil_rate_t - ft.first_oil) / NULLIF(ft.first_oil, 0) <= -0.3 THEN 3
        ELSE 10
    END,
    w.name;
