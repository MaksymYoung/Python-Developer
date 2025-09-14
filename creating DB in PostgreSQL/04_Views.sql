DO $$
DECLARE
    r RECORD;
BEGIN
    FOR r IN (
        SELECT table_schema, table_name
        FROM information_schema.views
        WHERE table_schema = 'gym'  
    )
    LOOP
        EXECUTE format('DROP VIEW IF EXISTS %I.%I CASCADE;', r.table_schema, r.table_name);
    END LOOP;
END;
$$;

-- I) Standard views
-- 1) Horizontal views
CREATE OR REPLACE VIEW gym.metrics_in_kg_view AS
SELECT *
FROM gym.metrics
WHERE "unit" = 'kg';
SELECT * FROM gym.metrics_in_kg_view;

CREATE OR REPLACE VIEW gym.chronic_conditions_view AS
SELECT *
FROM gym.health_issues
WHERE "name" LIKE 'Chronic%';
SELECT * FROM gym.chronic_conditions_view;

CREATE OR REPLACE VIEW gym.exercises_high_reps_view AS
SELECT *
FROM gym.exercises
WHERE "expected_reps" >= 15;
SELECT * FROM gym.exercises_high_reps_view;

CREATE OR REPLACE VIEW gym.high_intensity_leg_exercises_view AS
SELECT *
FROM gym.exercise_progress
WHERE "sets" = 4 AND "exercise_metric_value"::NUMERIC > 50
   OR "notes" ILIKE '%leg%';
SELECT * FROM gym.high_intensity_leg_exercises_view;

CREATE OR REPLACE VIEW gym.strength_goals_view AS
SELECT *
FROM gym.goal_types
WHERE "name" ILIKE '%strength%' OR "name" ILIKE '%muscle%';
SELECT * FROM gym.strength_goals_view;

CREATE OR REPLACE VIEW gym.progressive_training_plans_view AS
SELECT *
FROM gym.training_plans
WHERE "achievement_percentage" > 80;
SELECT * FROM gym.progressive_training_plans_view;

CREATE OR REPLACE VIEW gym.filtered_recommendations_view AS
SELECT *
FROM gym.training_recommendations
WHERE "recommendation_date" BETWEEN '2025-04-10' AND '2025-04-15'
  AND "trainer_id" IN (1, 4, 5);
SELECT * FROM gym.filtered_recommendations_view;

CREATE OR REPLACE VIEW gym.high_rating_classes_view AS
SELECT *
FROM gym.feedback_class_schedule
WHERE rating >= 4;
SELECT * FROM gym.high_rating_classes_view;

-- 2) Vertical views
CREATE OR REPLACE VIEW gym.metrics_view AS
SELECT "name", "unit"
FROM gym.metrics
ORDER BY "name";
SELECT * FROM gym.metrics_view;

CREATE OR REPLACE VIEW gym.health_issues_view AS
SELECT "name"
FROM gym.health_issues
ORDER BY "name";
SELECT * FROM gym.health_issues_view;

CREATE OR REPLACE VIEW gym.exercises_view AS
SELECT "name", "expected_sets" * "expected_reps" AS "expected_total_sets"
FROM gym.exercises
ORDER BY "name";
SELECT * FROM gym.exercises_view;

CREATE OR REPLACE VIEW gym.goal_types_view AS
SELECT "name"
FROM gym.goal_types
ORDER BY "name";
SELECT * FROM gym.goal_types_view;

CREATE OR REPLACE VIEW gym.training_plans_view AS
SELECT DISTINCT "name"
FROM gym.training_plans
ORDER BY "name";
SELECT * FROM gym.training_plans_view;

CREATE OR REPLACE VIEW gym.feedback_notes_view AS
SELECT "class_schedule_id", "notes"
FROM gym.feedback_class_schedule
ORDER BY "class_schedule_id";
SELECT * FROM gym.feedback_notes_view;

-- 3) Mixed views
CREATE OR REPLACE VIEW gym.metrics_in_cm_view AS
SELECT "name"
FROM gym.metrics
WHERE "unit" = 'cm';
SELECT * FROM gym.metrics_in_cm_view;

CREATE OR REPLACE VIEW gym.diseases_view AS
SELECT "name"
FROM gym.health_issues
WHERE "name" ILIKE '%disease%';
SELECT * FROM gym.diseases_view;

CREATE OR REPLACE VIEW gym.high_rep_exercises_view AS
SELECT "name", "expected_reps"
FROM gym.exercises
WHERE expected_reps > 12;
SELECT * FROM gym.high_rep_exercises_view;

CREATE OR REPLACE VIEW gym.light_members_view AS
SELECT "member_id", "exercise_metric_value" AS "weight_kg"
FROM gym.exercise_progress
WHERE metric_id = (SELECT "id" FROM gym.metrics WHERE "name" = 'Weight') 
	AND exercise_metric_value < 75
ORDER BY "member_id";
SELECT * FROM gym.light_members_view;

CREATE OR REPLACE VIEW gym.men_goal_types_view AS
SELECT "name"
FROM gym.goal_types
WHERE "name" ILIKE '%training%' 
   OR "name" ILIKE '%strength%' 
   OR "name" ILIKE '%performance%'
ORDER BY "name";
SELECT * FROM gym.men_goal_types_view;

CREATE OR REPLACE VIEW gym.actual_training_plans_view AS
SELECT "member_id", "name", "start_date", "end_date", "achievement_percentage"
FROM gym.training_plans
WHERE "achievement_percentage" >= 50
  AND "goal_type_id" IN (SELECT id FROM gym.goal_types WHERE name IN ('Weight loss', 'Muscle gain', 'Endurance'))
  AND "end_date" >= CURRENT_DATE
ORDER BY "start_date";
SELECT * FROM gym.actual_training_plans_view;

CREATE OR REPLACE VIEW gym.current_best_class_view AS
SELECT "member_id", "class_schedule_id", "notes"
FROM gym.feedback_class_schedule
WHERE "rating" = 5
  AND "created_at" BETWEEN '2025-04-01' AND CURRENT_DATE
ORDER BY "created_at" DESC;
SELECT * FROM gym.current_best_class_view;

-- 4) Views with joining
CREATE OR REPLACE VIEW gym.member_count_by_gender_and_training_level_view AS
SELECT m.gender, tl.name AS training_level, COUNT(m.id) AS member_count
FROM gym.members m
JOIN gym.training_levels tl ON m.training_level_id = tl.id
GROUP BY m.gender, tl.name, tl.id
ORDER BY tl.id;
SELECT * FROM gym.member_count_by_gender_and_training_level_view;

CREATE OR REPLACE VIEW gym.member_information_view AS
SELECT m.id AS member_id, m.first_name, m.last_name, m.gender, m.date_of_birth, m.email, 
	     m.phone, m.training_level_id, h.name AS health_issue, tp.name AS plan, tp.description,
	     tp.start_date AS "start", tp.end_date AS "end", tp.achievement_percentage, g.name AS goal
FROM gym.members m
LEFT JOIN gym.member_health_issues mhi ON m.id = mhi.member_id
LEFT JOIN gym.health_issues h ON mhi.health_issue_id = h.id
LEFT JOIN gym.training_plans tp ON m.id = tp.member_id
LEFT JOIN gym.goal_types g ON tp.goal_type_id = g.id
ORDER BY m.gender, m.first_name, m.last_name;
SELECT * FROM gym.member_information_view;

CREATE OR REPLACE VIEW gym.strength_performance_view AS
SELECT "member_id", MAX("exercise_metric_value") AS max_strength
FROM gym.exercise_progress
WHERE "metric_id" = (SELECT "id" FROM gym.metrics WHERE "name" = 'Strength')
GROUP BY "member_id"
ORDER BY max_strength DESC;
SELECT * FROM gym.strength_performance_view;

CREATE OR REPLACE VIEW gym.active_health_issues_view AS
SELECT mhi.member_id, hi.name AS issue_name, mhi.created_at
FROM gym.member_health_issues mhi
JOIN gym.health_issues hi ON mhi.health_issue_id = hi.id
WHERE mhi.created_at >= CURRENT_DATE - INTERVAL '12 days'
ORDER BY mhi.created_at DESC;
SELECT * FROM gym.active_health_issues_view;

CREATE OR REPLACE VIEW gym.health_risk_members_view AS
SELECT mhi.member_id, hi.name AS condition
FROM gym.member_health_issues mhi
JOIN gym.health_issues hi ON mhi.health_issue_id = hi.id
WHERE hi.name IN ('Hypertension', 'Heart Disease')
ORDER BY mhi.member_id;
SELECT * FROM gym.health_risk_members_view;

CREATE OR REPLACE VIEW gym.flexibility_and_endurance_view AS
SELECT 
    m.id AS member_id,
    m.first_name || ' ' || m.last_name AS full_name,
    MAX(CASE WHEN mt.name = 'Flexibility' THEN ep.exercise_metric_value END) AS flexibility,
    MAX(CASE WHEN mt.name = 'Cardio Endurance' THEN ep.exercise_metric_value END) AS cardio_endurance
FROM gym.members m
LEFT JOIN gym.exercise_progress ep ON m.id = ep.member_id
LEFT JOIN gym.metrics mt ON ep.metric_id = mt.id
WHERE mt.name IN ('Flexibility', 'Cardio Endurance')
GROUP BY m.id, m.first_name, m.last_name
ORDER BY m.id;
SELECT * FROM gym.flexibility_and_endurance_view;

CREATE OR REPLACE VIEW gym.member_performance_summary_view AS
SELECT
    ep.member_id,
    e.name AS exercise_name,
    m.name AS metric_name,
    ep.exercise_metric_value,
    ep.duration,
    hi.name AS health_issue
FROM gym.exercise_progress ep
JOIN gym.exercises e ON ep.exercise_id = e.id
JOIN gym.metrics m ON ep.metric_id = m.id
JOIN gym.member_health_issues mhi ON ep.member_id = mhi.member_id
JOIN gym.health_issues hi ON mhi.health_issue_id = hi.id
ORDER BY ep.member_id, ep.exercise_metric_value DESC;
SELECT * FROM gym.member_performance_summary_view;

CREATE OR REPLACE VIEW gym.training_plan_classes_view AS
SELECT 
    p.name AS training_plan_name,
    STRING_AGG(DISTINCT c.name, ', ' ORDER BY c.name) AS class_names
FROM gym.training_plan_classes tpc
JOIN gym.training_plans p ON tpc.plan_id = p.id
JOIN gym.classes c ON tpc.class_id = c.id
GROUP BY p.name
ORDER BY p.name;
SELECT * FROM gym.training_plan_classes_view;

CREATE OR REPLACE VIEW gym.training_plans_by_goal_view AS
SELECT 
    gt.name AS goal,
    COUNT(tp.id) AS total_training_plans,
    ROUND(AVG(tp.achievement_percentage), 2) AS avg_achievement_percentage
FROM gym.training_plans tp
JOIN gym.goal_types gt ON tp.goal_type_id = gt.id
GROUP BY gt.name
ORDER BY total_training_plans DESC, avg_achievement_percentage DESC;
SELECT * FROM gym.training_plans_by_goal_view;

CREATE OR REPLACE VIEW gym.training_plans_with_classes_view AS
SELECT 
    tp.id AS training_plan_id,
    tp.name AS training_plan_name,
    tp.start_date,
    tp.end_date,
    tp.achievement_percentage,
    gt.name AS goal_type,
    c.name AS class_name
FROM gym.training_plans tp
JOIN gym.goal_types gt ON tp.goal_type_id = gt.id
LEFT JOIN gym.training_plan_classes tpc ON tp.id = tpc.plan_id
LEFT JOIN gym.classes c ON tpc.class_id = c.id;
SELECT * FROM gym.training_plans_with_classes_view;

CREATE OR REPLACE VIEW gym.trainer_recommendations_view AS
SELECT
    tr.id AS recommendation_id,
    t.first_name AS trainer_first_name,
    t.last_name AS trainer_last_name,
    m.first_name AS member_first_name,
    m.last_name AS member_last_name,
    tp.name AS training_plan_name,
    tr.recommendation_text,
    tr.recommendation_date
FROM gym.training_recommendations tr
JOIN gym.trainers t ON tr.trainer_id = t.id
JOIN gym.training_plans tp ON tr.plan_id = tp.id
JOIN gym.members m ON tp.member_id = m.id
ORDER BY tr.recommendation_date DESC;
SELECT * FROM gym.trainer_recommendations_view;

CREATE OR REPLACE VIEW gym.trainer_recommendation_summary_view AS
SELECT
    t.id AS trainer_id,
    t.first_name,
    t.last_name,
    COUNT(tr.id) AS total_recommendations,
    MAX(tr.recommendation_date) AS last_recommendation_date
FROM gym.trainers t
LEFT JOIN gym.training_recommendations tr ON t.id = tr.trainer_id
GROUP BY t.id, t.first_name, t.last_name
ORDER BY total_recommendations DESC;
SELECT * FROM gym.trainer_recommendation_summary_view;

CREATE OR REPLACE VIEW gym.class_feedback_overview AS
SELECT
    m.id,
    m.first_name,
    m.last_name,
    ROUND(AVG(f.rating), 1) AS average_rating,
    MAX(f.rating) AS highest_rating,
    MIN(f.rating) AS lowest_rating
FROM gym.members m
LEFT JOIN gym.feedback_class_schedule f ON f.member_id = m.id
GROUP BY m.id, m.first_name, m.last_name
ORDER BY average_rating DESC NULLS LAST;
SELECT * FROM gym.class_feedback_overview;

CREATE OR REPLACE VIEW gym.class_ratings_view AS
SELECT 
    c.id AS class_id,
    c.name AS class_name,
    COUNT(f.class_schedule_id) AS total_sessions,
    ROUND(AVG(f.rating), 1) AS avg_class_rating
FROM gym.classes c
LEFT JOIN gym.class_schedule cs ON cs.class_id = c.id
LEFT JOIN gym.feedback_class_schedule f ON f.class_schedule_id = cs.id
GROUP BY c.id, c.name
ORDER BY c.id;
SELECT * FROM gym.class_ratings_view;

CREATE OR REPLACE VIEW gym.member_feedback_view AS
SELECT 
    m.id AS member_id,
    m.first_name,
    m.last_name,
    m.email,
    m.phone,
    f.class_schedule_id,
    f.rating AS class_rating,
    f.notes AS class_feedback,
    f.created_at AS feedback_date
FROM gym.members m
JOIN gym.feedback_class_schedule f ON f.member_id = m.id
ORDER BY f.created_at DESC;
SELECT * FROM gym.member_feedback_view;

CREATE OR REPLACE VIEW gym.member_training_progress_summary_view AS
SELECT 
    m.id AS member_id,
    m.first_name || ' ' || m.last_name AS member_name,
    tl.name AS training_level,
    COUNT(DISTINCT tp.id) AS total_training_plans,
    COUNT(DISTINCT ep.exercise_id) AS distinct_exercises_performed,
    COUNT(DISTINCT cs.class_id) AS distinct_classes_attended,
    COUNT(DISTINCT tr.id) AS total_recommendations,
    MAX(tp.end_date) AS latest_plan_end_date,
    CASE 
        WHEN MAX(tp.end_date) >= CURRENT_DATE THEN 'Active'
        ELSE 'Inactive'
    END AS membership_status
FROM gym.members m
JOIN gym.training_levels tl ON m.training_level_id = tl.id
LEFT JOIN gym.training_plans tp ON m.id = tp.member_id
LEFT JOIN gym.exercise_progress ep ON m.id = ep.member_id
LEFT JOIN gym.attendance a ON m.id = a.member_id
LEFT JOIN gym.class_schedule cs ON a.class_schedule_id = cs.id
LEFT JOIN gym.training_recommendations tr ON tp.id = tr.plan_id
GROUP BY m.id, m.first_name, m.last_name, tl.name
ORDER BY distinct_classes_attended DESC NULLS LAST;
SELECT * FROM gym.member_training_progress_summary_view;

CREATE OR REPLACE VIEW gym.member_training_plan_details_view AS
SELECT 
    m.id AS member_id,
    m.first_name || ' ' || m.last_name AS member_name,
    tl.name AS training_level,
    tp.name AS plan_name,
    tp.description AS plan_description,
    tp.start_date,
    tp.end_date,
    gt.name AS goal_type,
    STRING_AGG(DISTINCT c.name, ', ') AS included_classes,
    STRING_AGG(DISTINCT tr.recommendation_text, ' | ') AS recommendations,
    COUNT(DISTINCT ep.exercise_id) AS exercises_completed,
    ROUND(AVG(ep.exercise_metric_value), 1) AS avg_performance_metric
FROM gym.members m
LEFT JOIN gym.training_levels tl ON m.training_level_id = tl.id
LEFT JOIN gym.training_plans tp ON m.id = tp.member_id
LEFT JOIN gym.goal_types gt ON tp.goal_type_id = gt.id
LEFT JOIN gym.training_plan_classes tpc ON tp.id = tpc.plan_id
LEFT JOIN gym.classes c ON tpc.class_id = c.id
LEFT JOIN gym.training_recommendations tr ON tp.id = tr.plan_id
LEFT JOIN gym.exercise_progress ep ON m.id = ep.member_id
GROUP BY 
    m.id, m.first_name, m.last_name, tl.name,
    tp.id, tp.name, tp.description, tp.start_date, 
    tp.end_date, gt.name
ORDER BY 
  tp.end_date DESC NULLS LAST, 
  tp.achievement_percentage DESC NULLS LAST, 
  tp.name NULLS LAST;
SELECT * FROM gym.member_training_plan_details_view;

-- 5) Subquery views
CREATE OR REPLACE VIEW gym.member_health_training_summary_view AS
WITH member_health_stats AS (
    SELECT 
        mhi.member_id,
        COUNT(mhi.health_issue_id) AS health_issues_count,
        STRING_AGG(hi.name, ', ' ORDER BY hi.name) AS health_issues_list
    FROM gym.member_health_issues mhi
    LEFT JOIN gym.health_issues hi ON mhi.health_issue_id = hi.id
    GROUP BY mhi.member_id
),
training_stats AS (
    SELECT 
        tp.member_id,
        COUNT(tp.id) AS training_plans_count,
        ROUND(AVG(tp.achievement_percentage)) AS avg_progress_percentage,
        MAX(tp.end_date) AS latest_plan_end_date
    FROM gym.training_plans tp
    GROUP BY tp.member_id
),
attendance_stats AS (
    SELECT 
        a.member_id,
        SUM(CASE WHEN a.attended THEN 1 ELSE 0 END) AS classes_attended,
        SUM(CASE WHEN NOT a.attended THEN 1 ELSE 0 END) AS classes_missed
    FROM gym.attendance a
    GROUP BY a.member_id
),
recommendation_stats AS (
    SELECT 
        tp.member_id,
        COUNT(tr.id) AS recommendations_count
    FROM gym.training_recommendations tr
    LEFT JOIN gym.training_plans tp ON tr.plan_id = tp.id
    GROUP BY tp.member_id
)
SELECT 
    m.id AS member_id,
    m.first_name || ' ' || m.last_name AS member_name,
    m.gender,
    EXTRACT(YEAR FROM AGE(CURRENT_DATE, m.date_of_birth)) AS age,
    tl.name AS training_level,
    COALESCE(mhs.health_issues_list, 'None') AS health_issues_list,
    COALESCE(ts.training_plans_count, 0) AS training_plans_count,
    COALESCE(ts.avg_progress_percentage, 0) AS avg_progress_percentage,
    ts.latest_plan_end_date,
    COALESCE(ats.classes_attended, 0) AS classes_attended,
    COALESCE(ats.classes_missed, 0) AS classes_missed,
    COALESCE(rs.recommendations_count, 0) AS recommendations_count,
    CASE 
        WHEN COALESCE(mhs.health_issues_count, 0) > 3 THEN 'High Risk'
        WHEN COALESCE(mhs.health_issues_count, 0) > 0 THEN 'Moderate Risk'
        ELSE 'Low Risk'
    END AS health_risk_category,
    CASE
        WHEN COALESCE(ts.avg_progress_percentage, 0) > 70 THEN 'Excellent'
        WHEN COALESCE(ts.avg_progress_percentage, 0) > 50 THEN 'Good'
        WHEN COALESCE(ts.avg_progress_percentage, 0) > 30 THEN 'Needs Improvement'
        ELSE 'Poor'
    END AS progress_rating
FROM gym.members m
LEFT JOIN gym.training_levels tl ON m.training_level_id = tl.id
LEFT JOIN member_health_stats mhs ON m.id = mhs.member_id
LEFT JOIN training_stats ts ON m.id = ts.member_id
LEFT JOIN attendance_stats ats ON m.id = ats.member_id
LEFT JOIN recommendation_stats rs ON m.id = rs.member_id
ORDER BY m.id;
SELECT * FROM gym.member_health_training_summary_view;

CREATE OR REPLACE VIEW gym.training_plan_summary_view AS
SELECT 
    tp.id AS plan_id,
    tp.name AS plan_name,
    tp.description,
    tp.start_date,
    tp.end_date,
    tp.achievement_percentage,
    (SELECT gt.name
     FROM gym.goal_types gt
     WHERE gt.id = tp.goal_type_id) AS goal_type,
    (
        SELECT COUNT(*) 
        FROM gym.training_plan_classes tpc 
        WHERE tpc.plan_id = tp.id
    ) AS total_classes
FROM gym.training_plans tp;
SELECT * FROM gym.training_plan_summary_view;

CREATE OR REPLACE VIEW gym.latest_recommendation_per_trainer_view AS
SELECT 
    t.first_name,
    t.last_name,
    t.email,
    (
        SELECT tr.recommendation_text
        FROM gym.training_recommendations tr
        WHERE tr.trainer_id = t.id
        ORDER BY tr.recommendation_date DESC
        LIMIT 1
    ) AS latest_recommendation,
    (
        SELECT tr.recommendation_date
        FROM gym.training_recommendations tr
        WHERE tr.trainer_id = t.id
        ORDER BY tr.recommendation_date DESC
        LIMIT 1
    ) AS latest_recommendation_date
FROM gym.trainers t
ORDER BY latest_recommendation_date DESC NULLS LAST;
SELECT * FROM gym.latest_recommendation_per_trainer_view;

CREATE OR REPLACE VIEW gym.low_rating_members_view AS
WITH avg_ratings AS (
    SELECT 
        m.id AS member_id,
        m.first_name,
        m.last_name,
        m.email,
        m.phone,
        c.name AS class_name,
        c.id AS class_id,
        ROUND(AVG(f.rating), 1) AS avg_rating
    FROM gym.members m
    JOIN gym.attendance a ON a.member_id = m.id
    JOIN gym.class_schedule cs ON cs.id = a.class_schedule_id
    JOIN gym.classes c ON c.id = cs.class_id
    LEFT JOIN gym.feedback_class_schedule f ON f.member_id = m.id AND f.class_schedule_id = cs.id
    GROUP BY m.id, c.id
)
SELECT 
    member_id,
    first_name,
    last_name,
    email,
    phone,
    class_name,
    class_id,
    avg_rating
FROM avg_ratings
WHERE avg_rating <= 3
ORDER BY avg_rating, member_id, class_id;
SELECT * FROM gym.low_rating_members_view;

CREATE OR REPLACE VIEW gym.trainer_latest_class_view AS
SELECT
    t.first_name,
    t.last_name,
    (
        SELECT c.name
        FROM gym.trainer_class_assignments_history h
        JOIN gym.classes c ON h.class_id = c.id
        WHERE h.trainer_id = t.id
        ORDER BY h.start_date DESC
        LIMIT 1
    ) AS latest_class_name
FROM gym.trainers t
ORDER BY t.first_name, t.last_name;
SELECT * FROM gym.trainer_latest_class_view;

CREATE OR REPLACE VIEW gym.training_recommendation_details_view AS
SELECT 
    tr.id AS recommendation_id,
    tr.recommendation_text,
    tr.recommendation_date,
    tr.plan_id,
    (SELECT tp.name 
     FROM gym.training_plans tp 
     WHERE tp.id = tr.plan_id) AS plan_name,
    (SELECT t.first_name || ' ' || t.last_name 
     FROM gym.trainers t 
     WHERE t.id = tr.trainer_id) AS trainer_full_name
FROM gym.training_recommendations tr;
SELECT * FROM gym.training_recommendation_details_view;

CREATE VIEW gym.members_with_last_achievement_view AS
SELECT
    m.id AS member_id,
    m.first_name,
    m.last_name,
    m.email,
    (SELECT tp.name
     FROM gym.training_plans tp
     WHERE tp.member_id = m.id
     ORDER BY tp.start_date DESC
     LIMIT 1) AS last_training_plan,
    (SELECT tp.achievement_percentage
     FROM gym.training_plans tp
     WHERE tp.member_id = m.id
     ORDER BY tp.start_date DESC
     LIMIT 1) AS last_plan_achievement_percentage
FROM gym.members m;
SELECT * FROM gym.members_with_last_achievement_view;

-- 6) Union views
CREATE OR REPLACE VIEW gym.combined_goal_plan_names_view AS
SELECT "name"
FROM gym.goal_types
UNION
SELECT "name"
FROM gym.training_plans
ORDER BY "name";
SELECT * FROM gym.combined_goal_plan_names_view;

CREATE OR REPLACE VIEW gym.people_view AS
SELECT 
    "id",
    "first_name",
    "last_name",
    "email",
    "phone",
    "date_of_birth",
    "gender",
    "address",
    "registration_date",
    'member' AS "role"
FROM gym.members

UNION ALL

SELECT 
    "id"::BIGINT,  
    "first_name",
    "last_name",
    "email",
    "phone",
    "date_of_birth",
    "gender",
    "address",
    "registration_date"::TIMESTAMP,  
    'trainer' AS "role"
FROM gym.trainers;
SELECT * FROM gym.people_view;

CREATE OR REPLACE VIEW gym.all_photos_view AS
SELECT 
    id,
    member_id AS person_id,
    photo_url,
    uploaded_at,
    is_profile_photo,
    'member' AS "role"
FROM gym.member_photos

UNION ALL

SELECT 
    id,
    trainer_id AS person_id,
    photo_url,
    uploaded_at,
    is_profile_photo,
    'trainer' AS "role"
FROM gym.trainer_photos;
SELECT * FROM gym.all_photos_view;

CREATE OR REPLACE VIEW gym.all_feedback_view AS
SELECT
    member_id,
    trainer_id AS target_id,
    'trainer' AS target_type,
    rating,
    notes,
    created_at
FROM gym.feedback_trainer

UNION ALL

SELECT
    member_id,
    class_schedule_id AS target_id,
    'class_schedule' AS target_type,
    rating,
    notes,
    created_at
FROM gym.feedback_class_schedule

UNION ALL

SELECT
    member_id,
    equipment_id AS target_id,
    'equipment' AS target_type,
    rating,
    notes,
    created_at
FROM gym.feedback_equipment;
SELECT * FROM gym.all_feedback_view;

-- 7) View on the select from another view
CREATE OR REPLACE VIEW gym.active_members_info_view AS
SELECT 
    miv.member_id,
    miv.first_name || ' ' || miv.last_name AS member_name,
    miv.gender,
    EXTRACT(YEAR FROM AGE(CURRENT_DATE, miv.date_of_birth)) AS age,
    miv.training_level_id,
    STRING_AGG(DISTINCT miv.health_issue, ', ') AS health_issues_list,
    COUNT(DISTINCT miv.plan) AS active_plans_count,
    ROUND(AVG(miv.achievement_percentage)) AS avg_achievement,
    STRING_AGG(DISTINCT miv.goal, ', ') AS active_goals,
    MAX(miv.end) AS latest_plan_end_date
FROM gym.member_information_view miv
WHERE miv.end >= CURRENT_DATE 
GROUP BY 
    miv.member_id, 
    miv.first_name, 
    miv.last_name, 
    miv.gender, 
    miv.date_of_birth,
    miv.training_level_id
HAVING MAX(miv.end) >= CURRENT_DATE  
ORDER BY member_name;
SELECT * FROM gym.active_members_info_view;

CREATE OR REPLACE VIEW gym.top_strength_members_view AS
SELECT *
FROM gym.strength_performance_view
WHERE max_strength >= 100
ORDER BY max_strength DESC;
SELECT * FROM gym.top_strength_members_view;

CREATE OR REPLACE VIEW gym.successful_training_plans_with_classes_view AS
SELECT *
FROM gym.training_plans_with_classes_view
WHERE achievement_percentage >= 50
ORDER BY achievement_percentage DESC;
SELECT * FROM gym.successful_training_plans_with_classes_view;

CREATE OR REPLACE VIEW gym.advanced_members_summary_view AS
SELECT 
    member_id,
    member_name,
    gender,
    age,
    training_level,
    health_issues_list,
    training_plans_count,
    avg_progress_percentage,
    latest_plan_end_date,
    classes_attended,
    classes_missed,
    recommendations_count,
    health_risk_category,
    progress_rating
FROM gym.member_health_training_summary_view
WHERE LOWER(training_level) = 'advanced'
ORDER BY gender, member_name;
SELECT * FROM gym.advanced_members_summary_view;

CREATE OR REPLACE VIEW gym.successful_training_plans_view AS
SELECT *
FROM gym.training_plan_summary_view
WHERE total_classes >= 4;
SELECT * FROM gym.successful_training_plans_view;

CREATE OR REPLACE VIEW gym.recommendation_count_per_trainer_view AS
SELECT
    trainer_first_name,
    trainer_last_name,
    COUNT(recommendation_id) AS total_recommendations
FROM gym.trainer_recommendations_view
GROUP BY trainer_first_name, trainer_last_name
ORDER BY total_recommendations DESC;
SELECT * FROM gym.recommendation_count_per_trainer_view;

CREATE OR REPLACE VIEW gym.active_classes_ratings_view AS
SELECT 
    class_id,
    class_name,
    total_sessions
FROM gym.class_ratings_view
WHERE total_sessions >= 4;
SELECT * FROM gym.active_classes_ratings_view;

CREATE OR REPLACE VIEW gym.enhanced_member_training_summary_view AS
SELECT 
    mts.member_id,
    mts.member_name,
    mts.training_level,
    mts.total_training_plans,
    mts.distinct_exercises_performed,
    mts.distinct_classes_attended,
    mts.total_recommendations,
    mts.latest_plan_end_date
FROM gym.member_training_progress_summary_view mts
WHERE mts.membership_status = 'Active'
ORDER BY mts.distinct_classes_attended DESC NULLS LAST;
SELECT * FROM gym.enhanced_member_training_summary_view;

CREATE OR REPLACE VIEW gym.enhanced_training_plan_summary_view AS
SELECT 
    mtpdv.member_id,
    mtpdv.member_name,
    mtpdv.training_level,
    mtpdv.plan_name,
    mtpdv.plan_description,
    mtpdv.start_date,
    mtpdv.end_date,
    mtpdv.goal_type,
    mtpdv.included_classes,
    mtpdv.recommendations,
    mtpdv.exercises_completed,
    mtpdv.avg_performance_metric,
    CASE
        WHEN mtpdv.avg_performance_metric >= 7 THEN 'Excellent'
        WHEN mtpdv.avg_performance_metric BETWEEN 4 AND 6 THEN 'Good'
        ELSE 'Needs Improvement'
    END AS performance_status,
    (mtpdv.end_date - mtpdv.start_date) AS plan_duration_days
FROM gym.member_training_plan_details_view mtpdv
WHERE mtpdv.end_date >= CURRENT_DATE
ORDER BY mtpdv.end_date DESC, mtpdv.exercises_completed DESC;
SELECT * FROM gym.enhanced_training_plan_summary_view;

CREATE VIEW gym.enhanced_members_with_achievement_status_view AS
SELECT
    mwla.member_id,
    mwla.first_name,
    mwla.last_name,
    mwla.email,
    mwla.last_training_plan,
    mwla.last_plan_achievement_percentage,
    CASE
        WHEN mwla.last_plan_achievement_percentage >= 80 THEN 'Excellent'
        ELSE 'Good'
    END AS achievement_status,
    (SELECT COUNT(*) 
     FROM gym.training_plans tp
     WHERE tp.member_id = mwla.member_id) AS total_training_plans_completed
FROM gym.members_with_last_achievement_view mwla
WHERE mwla.last_plan_achievement_percentage >= 50
ORDER BY mwla.last_plan_achievement_percentage DESC, mwla.last_training_plan DESC;
SELECT * FROM gym.enhanced_members_with_achievement_status_view;

-- 8) View with check option
CREATE OR REPLACE VIEW gym.exercise_progress_strict_view AS
SELECT *
FROM gym.exercise_progress
WHERE sets >= 3 AND reps >= 10
WITH CHECK OPTION;
SELECT * FROM gym.exercise_progress_strict_view;

DO $$
BEGIN	
	INSERT INTO gym.exercise_progress_strict_view (
	    member_id, class_schedule_id, exercise_id,
	    sets, reps, duration
	) VALUES (2, 16, 3, 3, 8, INTERVAL '00:30:00');
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Помилка: %', SQLERRM;
END;
$$ LANGUAGE plpgsql;
-- ПОВІДОМЛЕННЯ:  Помилка: новий рядок порушує параметр перевірки для подання "exercise_progress_strict_view"

CREATE OR REPLACE VIEW gym.next_year_training_plans_view AS
SELECT *
FROM gym.training_plans
WHERE EXTRACT(YEAR FROM end_date) = 2026
WITH CHECK OPTION;
SELECT * FROM gym.next_year_training_plans_view;

DO $$
BEGIN
    INSERT INTO gym.next_year_training_plans_view (
        member_id, name, description, start_date, end_date,
        achievement_percentage, goal_type_id
    ) VALUES (
        7, 'Expired Plan', 'Should fail',
        CURRENT_DATE - INTERVAL '10 days', CURRENT_DATE,
        20, 2
    );
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Помилка вставки: %', SQLERRM;
END;
$$;
-- ПОВІДОМЛЕННЯ:  Помилка вставки: новий рядок порушує параметр перевірки для подання "active_training_plans_view"

CREATE OR REPLACE VIEW gym.high_feedback_classes_view AS
SELECT 
    fcs.member_id,
    fcs.class_schedule_id,
    fcs.rating,
    fcs.notes
FROM gym.feedback_class_schedule fcs
WHERE fcs.rating BETWEEN 4 AND 5
WITH CHECK OPTION;
SELECT * FROM gym.high_feedback_classes_view;

DO $$
BEGIN
  INSERT INTO gym.attendance VALUES (5, 17, TRUE);
	INSERT INTO gym.high_feedback_classes_view (member_id, class_schedule_id, rating, notes)
	VALUES (5, 17, 3, 'So-so training');
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Помилка вставки: %', SQLERRM;
END;
$$;
-- ПОВІДОМЛЕННЯ:  Помилка вставки: новий рядок порушує параметр перевірки для подання "high_feedback_classes_view"
