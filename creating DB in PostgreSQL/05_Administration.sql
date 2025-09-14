/* Код для перезапуску основної частини коду */
-- Відкликання всіх привілеїв
REVOKE ALL PRIVILEGES ON ALL TABLES IN SCHEMA gym FROM readonly;
REVOKE ALL PRIVILEGES ON ALL TABLES IN SCHEMA gym FROM readwrite;
REVOKE ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA gym FROM readonly;
REVOKE ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA gym FROM readwrite;
REVOKE ALL PRIVILEGES ON ALL FUNCTIONS IN SCHEMA gym FROM readonly;
REVOKE ALL PRIVILEGES ON ALL FUNCTIONS IN SCHEMA gym FROM readwrite;

ALTER DEFAULT PRIVILEGES IN SCHEMA gym REVOKE SELECT ON TABLES FROM readonly;
ALTER DEFAULT PRIVILEGES IN SCHEMA gym REVOKE SELECT, INSERT, UPDATE, DELETE ON TABLES FROM readwrite;

REVOKE ALL PRIVILEGES ON SCHEMA gym FROM training_guru;
REVOKE ALL PRIVILEGES ON gym.member_training_summary_view FROM training_guru;
REVOKE ALL PRIVILEGES ON SCHEMA gym FROM data_overlord;
REVOKE ALL PRIVILEGES ON gym.member_training_summary_view FROM data_overlord;
REVOKE CREATE ON SCHEMA gym FROM data_overlord;

REVOKE training_guru FROM user_readonly;
REVOKE data_overlord FROM user_readwrite;
REVOKE readonly FROM user_readonly;
REVOKE readwrite FROM user_readwrite;

-- Перед видаленням — переведення власності
REASSIGN OWNED BY user_readwrite TO postgres;

-- Видалення користувачів та ролей
DROP USER IF EXISTS user_readonly;
DROP USER IF EXISTS user_readwrite;

DROP ROLE IF EXISTS training_guru;
DROP ROLE IF EXISTS data_overlord;
DROP ROLE IF EXISTS readonly;
DROP ROLE IF EXISTS readwrite;

/* Основна частина коду */
-- Створення ролей
CREATE ROLE readonly;
COMMENT ON ROLE readonly IS 'Read-only role with limited SELECT access to specific tables and columns.';

CREATE ROLE readwrite;
COMMENT ON ROLE readwrite IS 'Read-write role with INSERT, UPDATE, SELECT permissions on selected tables.';

-- Перевірка створення ролей
SELECT rolname FROM pg_roles;

-- Створення користувачів
CREATE USER user_readonly WITH PASSWORD 'readonly_pass';
CREATE USER user_readwrite WITH PASSWORD 'readwrite_pass';

-- Призначення ролей
GRANT readonly TO user_readonly;
GRANT readwrite TO user_readwrite;

-- Привілеї для ролей
GRANT SELECT ON ALL TABLES IN SCHEMA gym TO readonly;
GRANT SELECT, INSERT, UPDATE ON ALL TABLES IN SCHEMA gym TO readwrite;

-- Перевірка призначень
SELECT *
FROM information_schema.role_table_grants
WHERE grantee IN ('readonly', 'readwrite');

-- Очищення доступу перед специфічним розподілом
REVOKE SELECT ON ALL TABLES IN SCHEMA gym FROM readonly;
REVOKE SELECT, INSERT, UPDATE ON ALL TABLES IN SCHEMA gym FROM readwrite;

-- Точкові привілеї
GRANT SELECT ON gym.exercises TO readonly;
GRANT SELECT(member_id, health_issue_id) ON gym.member_health_issues TO readonly;
GRANT SELECT(name, unit) ON gym.metrics TO readonly;

GRANT ALL ON gym.goal_types TO readwrite;
GRANT SELECT, INSERT, UPDATE ON gym.exercise_progress TO readwrite;
GRANT INSERT, UPDATE ON gym.metrics TO readwrite;
GRANT UPDATE(achievement_percentage, description, end_date) ON gym.training_plans TO readwrite;
GRANT UPDATE ON gym.health_issues TO readwrite;
GRANT UPDATE(name, condition_id, status_id) ON gym.equipment TO readwrite;
GRANT REFERENCES ON gym.promo_codes TO readwrite;

-- Створення view
DROP VIEW IF EXISTS gym.member_training_summary_view;
CREATE OR REPLACE VIEW gym.member_training_summary_view AS
SELECT
    m.id AS member_id,
    m.first_name,
    m.last_name,    
    COUNT(DISTINCT ep.exercise_id) AS total_exercises,
    SUM(ep.sets) AS total_sets,
    SUM(ep.reps) AS total_reps,
    ROUND(AVG(EXTRACT(EPOCH FROM ep.duration) / 60.0), 2) AS avg_duration_minutes,
    COUNT(DISTINCT ep.class_schedule_id) AS total_classes_attended,    
    ROUND(AVG(fcs.rating), 2) AS avg_class_rating,    
    tp.name AS current_plan_name,
    gt.name AS goal_type,
    tp.achievement_percentage
FROM gym.members m
LEFT JOIN gym.exercise_progress ep ON m.id = ep.member_id
LEFT JOIN gym.exercises e ON ep.exercise_id = e.id
LEFT JOIN gym.metrics mt ON ep.metric_id = mt.id
LEFT JOIN gym.feedback_class_schedule fcs ON m.id = fcs.member_id
LEFT JOIN gym.training_plans tp ON m.id = tp.member_id AND CURRENT_DATE BETWEEN tp.start_date AND tp.end_date
LEFT JOIN gym.goal_types gt ON tp.goal_type_id = gt.id
GROUP BY m.id, m.first_name, m.last_name, tp.name, gt.name, tp.achievement_percentage;

COMMENT ON VIEW gym.member_training_summary_view IS 'Summary view of member training progress, classes, and goals.';

-- Ролі для view
CREATE ROLE training_guru;
GRANT USAGE ON SCHEMA gym TO training_guru;
GRANT SELECT ON gym.member_training_summary_view TO training_guru;
GRANT training_guru TO user_readonly;

CREATE ROLE data_overlord;
GRANT USAGE ON SCHEMA gym TO data_overlord;
GRANT SELECT ON gym.member_training_summary_view TO data_overlord;
GRANT CREATE ON SCHEMA gym TO data_overlord;
GRANT data_overlord TO user_readwrite;

-- Вивід для перевірки
SELECT rolname FROM pg_roles;

SELECT grantee, table_name, privilege_type
FROM information_schema.role_table_grants
WHERE grantee IN ('readonly', 'readwrite', 'training_guru', 'data_overlord');

-- Налаштування привілеїв за замовчуванням
ALTER DEFAULT PRIVILEGES IN SCHEMA gym GRANT SELECT ON TABLES TO readonly;
ALTER DEFAULT PRIVILEGES IN SCHEMA gym GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO readwrite;

-- Додаткові привілеї для ролей
ALTER ROLE readwrite CREATEROLE CREATEDB;
ALTER ROLE readonly LOGIN;

-- Перевірка фінальних прав
SELECT grantee, table_name, privilege_type
FROM information_schema.role_table_grants
WHERE grantee IN ('readonly', 'readwrite');
