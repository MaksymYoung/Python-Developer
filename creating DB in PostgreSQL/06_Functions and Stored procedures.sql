-- Функції
CREATE OR REPLACE FUNCTION gym.add_member_health_issue( 
    p_member_id BIGINT,
    p_issue_name TEXT,
    p_issue_description TEXT DEFAULT NULL
)
RETURNS SETOF gym.member_health_issues AS $$
DECLARE
    v_issue_id INT;
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM gym.members WHERE id = p_member_id
    ) THEN
        RAISE EXCEPTION 'Member with id % does not exist', p_member_id;
    END IF;

    SELECT id INTO v_issue_id
    FROM gym.health_issues
    WHERE name = p_issue_name;

    IF v_issue_id IS NULL THEN
        BEGIN
            INSERT INTO gym.health_issues(name, description)
            VALUES (p_issue_name, p_issue_description)
            RETURNING id INTO v_issue_id;
        EXCEPTION WHEN unique_violation THEN
            SELECT id INTO v_issue_id
            FROM gym.health_issues
            WHERE name = p_issue_name;
        END;
    END IF;

    BEGIN
        RETURN QUERY
        INSERT INTO gym.member_health_issues(member_id, health_issue_id)
        VALUES (p_member_id, v_issue_id)
        RETURNING *;
    EXCEPTION WHEN unique_violation THEN
		RAISE EXCEPTION 'Member with id % already has issue %', p_member_id, v_issue_id;
    END;
END;
$$ LANGUAGE plpgsql;

SELECT gym.add_member_health_issue(1, 'Avitaminosis', 'Medical condition that occurs when an individual experiences a deficiency of one or more essential vitamins in their diet');

CREATE TYPE gym.member_training_summary AS (
    total_exercises INT,
    total_duration INTERVAL,
    total_reps INT
);

CREATE OR REPLACE FUNCTION gym.get_member_training_summary(p_member_id BIGINT)
RETURNS gym.member_training_summary
LANGUAGE plpgsql
AS $$
DECLARE
    v_total_exercises INT;
    v_total_duration INTERVAL;
    v_total_reps INT;
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM gym.members WHERE id = p_member_id
    ) THEN
        RAISE EXCEPTION 'Member with id % does not exist', p_member_id;
    END IF;
	
    SELECT COUNT(*) 
    INTO v_total_exercises
    FROM gym.exercise_progress
    WHERE member_id = p_member_id;

    SELECT COALESCE(SUM(duration), INTERVAL '0') 
    INTO v_total_duration
    FROM gym.exercise_progress
    WHERE member_id = p_member_id;

    SELECT COALESCE(SUM(sets * reps), 0)
    INTO v_total_reps
    FROM gym.exercise_progress
    WHERE member_id = p_member_id;

    RETURN (v_total_exercises, v_total_duration, v_total_reps);
END;
$$;

SELECT * FROM gym.get_member_training_summary(10);

CREATE OR REPLACE FUNCTION gym.get_member_training_efficiency(p_member_id BIGINT)
RETURNS DECIMAL(5,2)
LANGUAGE plpgsql
AS $$
DECLARE
    v_total_reps INT;
    v_expected_reps INT;
    v_percent_reps DECIMAL(5,2);
    v_member_exists BOOLEAN;
BEGIN
    SELECT EXISTS(SELECT 1 FROM gym.members WHERE id = p_member_id) INTO v_member_exists;

    IF NOT v_member_exists THEN
        RAISE EXCEPTION 'Member with id % does not exist', p_member_id; 
    END IF;

    SELECT COALESCE(SUM(sets * reps), 0)
    INTO v_total_reps
    FROM gym.exercise_progress
    WHERE member_id = p_member_id;

    SELECT COALESCE(SUM(e.expected_reps * ep.sets), 0)
    INTO v_expected_reps
    FROM gym.exercise_progress ep
    JOIN gym.exercises e ON ep.exercise_id = e.id
    WHERE ep.member_id = p_member_id;

	IF v_expected_reps > 0 THEN
        v_percent_reps := (v_total_reps * 100.0) / v_expected_reps;
    ELSE
        v_percent_reps := 0;
    END IF;

    RETURN v_percent_reps;
END;
$$;

SELECT gym.get_member_training_efficiency(25);

CREATE TYPE gym.achievement_result AS (
    total_plans INT,
    average_achievement DECIMAL(5, 2)
);

CREATE OR REPLACE FUNCTION gym.get_member_achievement(p_member_id BIGINT)
RETURNS gym.achievement_result
LANGUAGE plpgsql
AS $$
DECLARE
    v_total_plans INT;
    v_average_achievement DECIMAL(5, 2);
BEGIN
    IF NOT EXISTS (SELECT 1 FROM gym.members WHERE id = p_member_id) THEN
        RAISE EXCEPTION 'Member with id % does not exist', p_member_id;  
    END IF;

    SELECT COUNT(DISTINCT tp.id)
    INTO v_total_plans
    FROM gym.training_plans AS tp
    WHERE member_id = p_member_id;

    SELECT COALESCE(SUM(achievement_percentage), 0)
    INTO v_average_achievement
    FROM gym.training_plans
    WHERE member_id = p_member_id;

    IF v_total_plans > 0 THEN
        v_average_achievement := v_average_achievement / v_total_plans;
    ELSE
        v_average_achievement := 0;
    END IF;

    RETURN (v_total_plans, v_average_achievement);
END;
$$;

SELECT * FROM gym.get_member_achievement(35);

CREATE OR REPLACE FUNCTION gym.insert_training_recommendation(
    p_plan_id BIGINT,
    p_trainer_id SMALLINT,
    p_recommendation_text TEXT
)
RETURNS TABLE(
    rec_id BIGINT,                    
    rec_plan_id BIGINT,               
    rec_trainer_id SMALLINT,           
    rec_recommendation_text TEXT,      
    rec_recommendation_date DATE       
) AS $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM gym.training_plans WHERE "id" = p_plan_id) THEN
        RAISE EXCEPTION 'Training plan with ID "%" does not exist', p_plan_id;
    END IF;

    IF p_trainer_id IS NOT NULL AND NOT EXISTS (SELECT 1 FROM gym.trainers WHERE "id" = p_trainer_id) THEN
        RAISE EXCEPTION 'Trainer with ID "%" does not exist', p_trainer_id;
    END IF;

    INSERT INTO gym.training_recommendations(
        "plan_id",
        "trainer_id",
        "recommendation_text",
        "recommendation_date"
    )
    VALUES (
        p_plan_id,
        p_trainer_id,
        p_recommendation_text,
        CURRENT_DATE
    )
    RETURNING "id", "plan_id", "trainer_id", "recommendation_text", "recommendation_date"
    INTO STRICT rec_id, rec_plan_id, rec_trainer_id, rec_recommendation_text, rec_recommendation_date;  -- змінено на правильні імена змінних

    RETURN NEXT;
END;
$$ LANGUAGE plpgsql;

SELECT * FROM gym.insert_training_recommendation(
    p_plan_id := 1::BIGINT,
    p_trainer_id := 2::SMALLINT,
    p_recommendation_text := 'Focus on high-intensity interval training for optimal muscle gain.'::TEXT
);

CREATE TYPE gym.feedback_result AS (
    target_type TEXT,
    target_id BIGINT,
    member_id BIGINT,
    rating SMALLINT,
    notes TEXT
);

CREATE OR REPLACE FUNCTION gym.leave_feedback(
    p_member_id BIGINT,
    p_target_type TEXT,
    p_target_id BIGINT,
    p_rating SMALLINT,
    p_notes TEXT DEFAULT NULL
) RETURNS gym.feedback_result AS $$
DECLARE
    result gym.feedback_result;
    member_exists BOOLEAN;
    trainer_exists BOOLEAN;
    attended_class BOOLEAN;
    feedback_exists BOOLEAN;
    equipment_exists BOOLEAN;
    class_exists BOOLEAN;
BEGIN
    SELECT EXISTS (
        SELECT 1 FROM gym.members WHERE id = p_member_id
    ) INTO member_exists;

    IF NOT member_exists THEN
        RAISE EXCEPTION 'Member with ID % does not exist.', p_member_id;
    END IF;

    IF p_target_type = 'trainer' THEN
        SELECT EXISTS (
            SELECT 1 FROM gym.trainers WHERE id = p_target_id
        ) INTO trainer_exists;

        IF NOT trainer_exists THEN
            RAISE EXCEPTION 'Trainer with ID % does not exist.', p_target_id;
        END IF;

        INSERT INTO gym.feedback_trainer(member_id, trainer_id, rating, notes)
        VALUES (p_member_id, p_target_id::SMALLINT, p_rating, p_notes);

    ELSIF p_target_type = 'equipment' THEN
        SELECT EXISTS (
            SELECT 1 FROM gym.equipment WHERE id = p_target_id
        ) INTO equipment_exists;

        IF NOT equipment_exists THEN
            RAISE EXCEPTION 'Equipment with ID % does not exist.', p_target_id;
        END IF;

        SELECT EXISTS (
            SELECT 1 FROM gym.feedback_equipment
            WHERE member_id = p_member_id AND equipment_id = p_target_id
        ) INTO feedback_exists;

        IF feedback_exists THEN
            RAISE EXCEPTION 'Feedback for equipment ID % from member ID % already exists.', p_target_id, p_member_id;
        END IF;

        INSERT INTO gym.feedback_equipment(member_id, equipment_id, rating, notes)
        VALUES (p_member_id, p_target_id, p_rating, p_notes);

    ELSIF p_target_type = 'class' THEN
        SELECT EXISTS (
            SELECT 1 FROM gym.class_schedule WHERE id = p_target_id
        ) INTO class_exists;

        IF NOT class_exists THEN
            RAISE EXCEPTION 'Class with ID % does not exist.', p_target_id;
        END IF;

        SELECT attended
        FROM gym.attendance
        WHERE member_id = p_member_id AND class_schedule_id = p_target_id
        INTO attended_class;

        IF NOT attended_class THEN
            RAISE EXCEPTION 'Member with ID % did not attend class schedule ID % or attendance not marked as true.',
                            p_member_id, p_target_id;
        END IF;

        SELECT EXISTS (
            SELECT 1 FROM gym.feedback_class_schedule
            WHERE member_id = p_member_id AND class_schedule_id = p_target_id
        ) INTO feedback_exists;

        IF feedback_exists THEN
            RAISE EXCEPTION 'Feedback for class ID % from member ID % already exists.', p_target_id, p_member_id;
        END IF;

        INSERT INTO gym.feedback_class_schedule(member_id, class_schedule_id, rating, notes)
        VALUES (p_member_id, p_target_id, p_rating, p_notes);

    ELSE
        RAISE EXCEPTION 'Invalid target type: "%". Must be trainer, equipment, or class.', p_target_type;
    END IF;

    result := (p_target_type, p_target_id, p_member_id, p_rating, p_notes);
    RETURN result;
END;
$$ LANGUAGE plpgsql;

SELECT *
FROM gym.leave_feedback(
    p_member_id := 1::BIGINT,
    p_target_type := 'trainer',
    p_target_id := 2::SMALLINT,
    p_rating := 4::SMALLINT,
    p_notes := 'Helpful session!'
);

SELECT *
FROM gym.leave_feedback(
    p_member_id := 1::BIGINT,
    p_target_type := 'equipment',
    p_target_id := 6::BIGINT,
    p_rating := 3::SMALLINT,
    p_notes := 'Needs maintenance.'
);

INSERT INTO gym.attendance ("member_id", "class_schedule_id", "attended")
VALUES (1, 3, TRUE)
RETURNING *;

SELECT *
FROM gym.leave_feedback(
    p_member_id := 1::BIGINT,
    p_target_type := 'class',
    p_target_id := 3::BIGINT,
    p_rating := 5::SMALLINT,
    p_notes := 'Loved the class!'
);

CREATE OR REPLACE FUNCTION gym.add_metric(
    p_name VARCHAR(30),
    p_unit VARCHAR(15),
    p_description VARCHAR(150)
)
RETURNS VOID
LANGUAGE plpgsql
AS
$$
BEGIN
    IF EXISTS (SELECT 1 FROM gym.metrics WHERE name = p_name) THEN
        RAISE EXCEPTION 'Metric with name "%" already exists', p_name;
    END IF;

    INSERT INTO gym.metrics (name, unit, description)
    VALUES (p_name, p_unit, p_description);
    
END;
$$;

SELECT gym.add_metric(
    'Body Mass',             
    'kg',                 
    'Body weight measurement'  
);

CREATE OR REPLACE FUNCTION gym.update_training_plan_classes(
    p_plan_id BIGINT,
    p_class_id SMALLINT,
    p_action VARCHAR(10)
)
RETURNS TABLE (
    action VARCHAR,
    plan_id BIGINT,
    class_id SMALLINT
)
LANGUAGE plpgsql
AS
$$
BEGIN
    IF p_action NOT IN ('add', 'remove') THEN
        RAISE EXCEPTION 'Invalid action: %', p_action;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM gym.training_plans tp WHERE tp.id = p_plan_id) THEN
        RAISE EXCEPTION 'Training plan with id % does not exist', p_plan_id;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM gym.classes c WHERE c.id = p_class_id) THEN
        RAISE EXCEPTION 'Class with id % does not exist', p_class_id;
    END IF;

    IF p_action = 'add' THEN
        IF EXISTS (
            SELECT 1 FROM gym.training_plan_classes tpc
            WHERE tpc.plan_id = p_plan_id AND tpc.class_id = p_class_id
        ) THEN
            RAISE EXCEPTION 'Class with id % is already associated with training plan with id %', p_class_id, p_plan_id;
        ELSE
            INSERT INTO gym.training_plan_classes (plan_id, class_id)
            VALUES (p_plan_id, p_class_id);
            RETURN QUERY SELECT 'added'::VARCHAR AS action, p_plan_id, p_class_id;
        END IF;
    ELSIF p_action = 'remove' THEN
        IF NOT EXISTS (
            SELECT 1 FROM gym.training_plan_classes tpc
            WHERE tpc.plan_id = p_plan_id AND tpc.class_id = p_class_id
        ) THEN
            RAISE EXCEPTION 'Class with id % is not associated with training plan with id %', p_class_id, p_plan_id;
        ELSE
            DELETE FROM gym.training_plan_classes tpc
            WHERE tpc.plan_id = p_plan_id AND tpc.class_id = p_class_id;
            RETURN QUERY SELECT 'removed'::VARCHAR AS action, p_plan_id, p_class_id;
        END IF;
    END IF;
END;
$$;

SELECT * FROM gym.update_training_plan_classes(4::BIGINT, 1::SMALLINT, 'add');
SELECT * FROM gym.update_training_plan_classes(4::BIGINT, 1::SMALLINT, 'remove');

-- Процедури з SELECT+INSERT
CREATE OR REPLACE PROCEDURE create_training_plan_with_classes(
    p_member_id BIGINT,
    p_name VARCHAR(40),
    p_description TEXT,
    p_class_ids SMALLINT[],
    p_goal_type_id SMALLINT
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_class_id SMALLINT; 
    v_achievement_percentage INT;
    v_new_plan_id BIGINT;
    v_existing_plan_count INT;
    v_name_exists BOOLEAN;
BEGIN
    IF NOT EXISTS (SELECT 1 FROM gym.members WHERE id = p_member_id) THEN
        RAISE EXCEPTION 'Member with ID % does not exist', p_member_id;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM gym.goal_types WHERE id = p_goal_type_id) THEN
        RAISE EXCEPTION 'Goal type with ID % does not exist', p_goal_type_id;
    END IF;

    FOR i IN 1..array_length(p_class_ids, 1) LOOP
        IF NOT EXISTS (SELECT 1 FROM gym.classes WHERE id = p_class_ids[i]) THEN
            RAISE EXCEPTION 'Class with ID % does not exist', p_class_ids[i];
        END IF;
    END LOOP;

    SELECT EXISTS (
        SELECT 1 FROM gym.training_plans
        WHERE member_id = p_member_id AND name = p_name
    ) INTO v_name_exists;

    IF v_name_exists THEN
        RAISE EXCEPTION 'Training plan with name "%" already exists for member ID %', p_name, p_member_id;
    END IF;

    SELECT achievement_percentage
    INTO v_achievement_percentage
    FROM gym.training_plans
    WHERE member_id = p_member_id
    ORDER BY start_date DESC
    LIMIT 1;

    IF v_achievement_percentage IS NULL OR v_achievement_percentage < 50 THEN
        RAISE EXCEPTION 'Member with ID % has not yet achieved 50%% or more in their current plan.', p_member_id;
    END IF;

    INSERT INTO gym.training_plans (member_id, name, description, achievement_percentage, goal_type_id)
    VALUES (p_member_id, p_name, p_description, 0, p_goal_type_id)
    RETURNING id INTO v_new_plan_id;

    FOREACH v_class_id IN ARRAY p_class_ids LOOP  
        SELECT COUNT(*) INTO v_existing_plan_count
        FROM gym.training_plan_classes
        WHERE plan_id = v_new_plan_id AND class_id = v_class_id;  
        
        IF v_existing_plan_count = 0 THEN
            INSERT INTO gym.training_plan_classes (plan_id, class_id)
            VALUES (v_new_plan_id, v_class_id);  
            RAISE NOTICE 'Added class_id % to training plan_id %.', v_class_id, v_new_plan_id;
        ELSE
            RAISE NOTICE 'Class_id % already exists in plan_id %.', v_class_id, v_new_plan_id;
        END IF;
    END LOOP;

    RAISE NOTICE 'Successfully created training plan with ID % for member %.', v_new_plan_id, p_member_id;

END;
$$;

CALL create_training_plan_with_classes(
    CAST(35 AS BIGINT),                     
    CAST('Muscle Gain Plan' AS VARCHAR(40)),
    CAST('A plan focused on gaining muscle mass' AS TEXT),
    CAST(ARRAY[1, 5, 7] AS SMALLINT[]),     
    CAST(2 AS SMALLINT)                    
);

CREATE OR REPLACE PROCEDURE gym.sp_add_member_issue_and_plan(
    IN p_member_id BIGINT,
    IN p_issue_name TEXT,
    IN p_issue_description TEXT,
    IN p_plan_name VARCHAR,
    IN p_plan_description TEXT,
    IN p_end_date DATE,
    IN p_achievement SMALLINT,
    IN p_goal_type_id SMALLINT
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_issue_id INT;
    v_goal_type_exists BOOLEAN;
    v_plan_exists BOOLEAN;
    v_member_issue_exists BOOLEAN;
BEGIN
    IF NOT EXISTS (SELECT 1 FROM gym.members WHERE id = p_member_id) THEN
        RAISE EXCEPTION 'Member with ID % does not exist', p_member_id;
    END IF;

    SELECT EXISTS (
        SELECT 1 FROM gym.goal_types
        WHERE id = p_goal_type_id
    ) INTO v_goal_type_exists;
	
    IF NOT v_goal_type_exists THEN
        RAISE EXCEPTION 'Goal type with ID % does not exist', p_goal_type_id;
    END IF;

    SELECT id INTO v_issue_id
    FROM gym.health_issues
    WHERE name = p_issue_name;

    IF v_issue_id IS NULL THEN
        INSERT INTO gym.health_issues(name, description)
        VALUES (p_issue_name, p_issue_description)
        RETURNING id INTO v_issue_id;
    END IF;

    SELECT EXISTS (
        SELECT 1 FROM gym.member_health_issues
        WHERE member_id = p_member_id AND health_issue_id = v_issue_id
    ) INTO v_member_issue_exists;

    IF v_member_issue_exists THEN
        RAISE NOTICE 'Member % already has health issue "%"', p_member_id, p_issue_name;
    ELSE
        INSERT INTO gym.member_health_issues(member_id, health_issue_id)
        VALUES (p_member_id, v_issue_id);
        RAISE NOTICE 'Added health issue "%" for member_id %', p_issue_name, p_member_id;
    END IF;

    SELECT EXISTS (
        SELECT 1 FROM gym.training_plans
        WHERE member_id = p_member_id AND name = p_plan_name
    ) INTO v_plan_exists;

    IF v_plan_exists THEN
        RAISE NOTICE 'Training plan with name "%" already exists for member_id %', p_plan_name, p_member_id;
    ELSE
        INSERT INTO gym.training_plans(
            member_id, name, description, end_date, achievement_percentage, goal_type_id
        )
        VALUES (
            p_member_id, p_plan_name, p_plan_description, p_end_date, p_achievement, p_goal_type_id
        );
        RAISE NOTICE 'Added training plan "%" for member_id %', p_plan_name, p_member_id;
    END IF;
END;
$$;

CALL gym.sp_add_member_issue_and_plan(
    10::BIGINT,
    'Hypertension'::TEXT,
    'High blood pressure condition'::TEXT,
    'Weight Loss Plan'::VARCHAR,
    'Aimed at reducing body weight to healthy range'::TEXT,
    '2025-08-01'::DATE,
    0::SMALLINT,
    10::SMALLINT
);

CREATE OR REPLACE PROCEDURE gym.add_member_exercise_progress(
    p_member_id BIGINT, 
    p_class_schedule_id BIGINT,
    p_exercise_id INT,
    p_sets SMALLINT,
    p_reps SMALLINT,
    p_metric_id INT,
    p_exercise_metric_value DECIMAL(8,2),
    p_duration INTERVAL,
    p_notes TEXT
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_existing_progress INT;
BEGIN
    IF NOT EXISTS (SELECT 1 FROM gym.members WHERE id = p_member_id) THEN
        RAISE EXCEPTION 'Member with ID % does not exist', p_member_id;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM gym.class_schedule WHERE id = p_class_schedule_id) THEN
        RAISE EXCEPTION 'Class schedule with ID % does not exist', p_class_schedule_id;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM gym.exercises WHERE id = p_exercise_id) THEN
        RAISE EXCEPTION 'Exercise with ID % does not exist', p_exercise_id;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM gym.metrics WHERE id = p_metric_id) THEN
        RAISE EXCEPTION 'Metric with ID % does not exist', p_metric_id;
    END IF;

    IF NOT EXISTS (
        SELECT 1
        FROM gym.attendance
        WHERE member_id = p_member_id
        AND class_schedule_id = p_class_schedule_id
        AND attended = TRUE
    ) THEN
        RAISE EXCEPTION 'Member with ID % did not attend class schedule ID %', p_member_id, p_class_schedule_id;
    END IF;

    SELECT COUNT(*) 
    INTO v_existing_progress
    FROM gym.exercise_progress
    WHERE member_id = p_member_id 
    AND class_schedule_id = p_class_schedule_id
    AND exercise_id = p_exercise_id;

    IF v_existing_progress > 0 THEN
        RAISE NOTICE 'Exercise progress record already exists for this member, class, and exercise';
        RETURN;
    END IF;

    INSERT INTO gym.exercise_progress (
        member_id, 
        class_schedule_id, 
        exercise_id, 
        sets, 
        reps, 
        metric_id, 
        exercise_metric_value, 
        duration, 
        notes
    )
    VALUES (
        p_member_id, 
        p_class_schedule_id, 
        p_exercise_id, 
        p_sets, 
        p_reps, 
        p_metric_id, 
        p_exercise_metric_value, 
        p_duration, 
        p_notes
    );

    RAISE NOTICE 'Exercise progress record inserted successfully for member ID %, class schedule ID %, exercise ID %', p_member_id, p_class_schedule_id, p_exercise_id;
END;
$$;

CALL gym.add_member_exercise_progress(
    p_member_id := 1::bigint, 
    p_class_schedule_id := 1::bigint, 
    p_exercise_id := 6::integer, 
    p_sets := 3::smallint, 
    p_reps := 10::smallint, 
    p_metric_id := 2::integer, 
    p_exercise_metric_value := 50.00::numeric, 
    p_duration := '00:30:00'::interval, 
    p_notes := 'Performed at moderate intensity'::text
);

CREATE OR REPLACE PROCEDURE gym.insert_training_plan_with_goal(
    p_member_id BIGINT,
    p_name VARCHAR(40),
    p_description TEXT,
    p_start_date DATE,
    p_end_date DATE,
    p_achievement_percentage SMALLINT,
    p_goal_type_name VARCHAR(40)
) 
LANGUAGE plpgsql
AS $$
DECLARE
    v_goal_type_id SMALLINT;
BEGIN
    IF NOT EXISTS (SELECT 1 FROM gym.members WHERE "id" = p_member_id) THEN
        RAISE EXCEPTION 'Member with ID "%" does not exist', p_member_id;
    END IF;

    SELECT "id"
    INTO v_goal_type_id
    FROM gym.goal_types
    WHERE "name" = p_goal_type_name
    LIMIT 1;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Goal type "%" not found', p_goal_type_name;
    END IF;

    INSERT INTO gym.training_plans(
        "member_id",
        "name",
        "description",
        "start_date",
        "end_date",
        "achievement_percentage",
        "goal_type_id"
    )
    VALUES (
        p_member_id,
        p_name,
        p_description,
        p_start_date,
        p_end_date,
        p_achievement_percentage,
        v_goal_type_id
    );

END;
$$;

CALL gym.insert_training_plan_with_goal(
    p_member_id := 11::BIGINT, 
    p_name := 'Muscle Building Plan'::VARCHAR(40),
    p_description := 'A focused training plan to increase muscle mass.'::TEXT,  
    p_start_date := '2025-01-01'::DATE, 
    p_end_date := '2025-06-01'::DATE,  
    p_achievement_percentage := 50::SMALLINT,  
    p_goal_type_name := 'Muscle gain'::VARCHAR(40)
);

CREATE OR REPLACE PROCEDURE gym.insert_training_recommendation_and_feedback(
    p_plan_id BIGINT,
    p_trainer_id SMALLINT,
    p_recommendation_text TEXT,
    p_member_id BIGINT,  
    p_rating SMALLINT,   
    p_notes TEXT
) 
LANGUAGE plpgsql
AS $$
DECLARE
    plan_name VARCHAR(40);
    trainer_name VARCHAR(200);
BEGIN
    SELECT "name" 
    INTO plan_name
    FROM gym.training_plans
    WHERE "id" = CAST(p_plan_id AS BIGINT);  

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Training plan with ID "%" does not exist', p_plan_id;
    END IF;

    SELECT CONCAT("first_name", ' ', "last_name")
    INTO trainer_name
    FROM gym.trainers
    WHERE "id" = CAST(p_trainer_id AS SMALLINT);  

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Trainer with ID "%" does not exist', p_trainer_id;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM gym.members WHERE "id" = p_member_id) THEN
        RAISE EXCEPTION 'Member with ID "%" does not exist', p_member_id;
    END IF;
	
    INSERT INTO gym.training_recommendations(
        "plan_id", 
        "trainer_id", 
        "recommendation_text", 
        "recommendation_date"
    )
    VALUES (
        CAST(p_plan_id AS BIGINT),  
        CAST(p_trainer_id AS SMALLINT),  
        p_recommendation_text, 
        CURRENT_DATE
    );

    INSERT INTO gym.feedback_trainer(
        "member_id", 
        "trainer_id", 
        "rating", 
        "notes", 
        "created_at"
    )
    VALUES (
        CAST(p_member_id AS BIGINT),  
        CAST(p_trainer_id AS SMALLINT), 
        p_rating, 
        p_notes,  
        CURRENT_TIMESTAMP
    );

    RAISE NOTICE 'Training recommendation and feedback successfully inserted for plan: %, Trainer: %', plan_name, trainer_name;
END;
$$;

CALL gym.insert_training_recommendation_and_feedback(
    p_plan_id := CAST(1 AS BIGINT),      
    p_trainer_id := CAST(5 AS SMALLINT),   
    p_recommendation_text := 'Focus on high-intensity interval training for better endurance.',  
    p_member_id := CAST(33 AS BIGINT),    
    p_rating := CAST(5 AS SMALLINT),       
    p_notes := 'Great performance during the session.'  
);

CREATE OR REPLACE PROCEDURE gym.add_feedback_for_class_schedule(
    p_member_id BIGINT,
    p_class_schedule_id BIGINT,
    p_rating SMALLINT,
    p_notes TEXT
)
LANGUAGE plpgsql
AS
$$
DECLARE
    existing_feedback RECORD;
    member_exists BOOLEAN;
    class_schedule_exists BOOLEAN;
    attended BOOLEAN;
BEGIN
    SELECT EXISTS (SELECT 1 FROM gym.members WHERE id = p_member_id::BIGINT) INTO member_exists;

    IF NOT member_exists THEN
        RAISE EXCEPTION 'Member with ID % does not exist', p_member_id;
    END IF;

    SELECT EXISTS (SELECT 1 FROM gym.class_schedule WHERE id = p_class_schedule_id::BIGINT) INTO class_schedule_exists;

    IF NOT class_schedule_exists THEN
        RAISE EXCEPTION 'Class schedule with ID % does not exist', p_class_schedule_id;
    END IF;

    SELECT a.attended INTO attended
    FROM gym.attendance a
    WHERE a.member_id = p_member_id::BIGINT AND a.class_schedule_id = p_class_schedule_id::BIGINT;

    IF NOT attended THEN
        RAISE EXCEPTION 'Member with ID % did not attend the class with schedule ID %', p_member_id, p_class_schedule_id;
    END IF;

    SELECT * INTO existing_feedback
    FROM gym.feedback_class_schedule
    WHERE member_id = p_member_id::BIGINT AND class_schedule_id = p_class_schedule_id::BIGINT;

    IF FOUND THEN
        UPDATE gym.feedback_class_schedule
        SET rating = p_rating::SMALLINT, notes = p_notes::TEXT, created_at = CURRENT_DATE
        WHERE member_id = p_member_id::BIGINT AND class_schedule_id = p_class_schedule_id::BIGINT;
    ELSE
        INSERT INTO gym.feedback_class_schedule (member_id, class_schedule_id, rating, notes)
        VALUES (p_member_id::BIGINT, p_class_schedule_id::BIGINT, p_rating::SMALLINT, p_notes::TEXT);
    END IF;
END;
$$;

INSERT INTO gym.attendance ("member_id", "class_schedule_id", "attended")
VALUES (1, 6, TRUE)
RETURNING *;

CALL gym.add_feedback_for_class_schedule(
    1::BIGINT,    
    6::BIGINT,         
    4::SMALLINT,      
    'Good class, very informative!'::TEXT  
);

-- Процедури з UPDATE
CREATE OR REPLACE PROCEDURE gym.update_health_issue_description(
    p_health_issue_name VARCHAR,
    p_new_description TEXT
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_health_issue_id INT;
    v_old_description TEXT;
BEGIN
    SELECT "id", "description"
    INTO v_health_issue_id, v_old_description
    FROM gym.health_issues
    WHERE name = p_health_issue_name;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Health issue "%" not found.', p_health_issue_name;
    END IF;

    -- Оновлюємо опис, якщо він відсутній або короткий
    IF v_old_description IS NULL OR length(v_old_description) < 20 THEN
        UPDATE gym.health_issues
        SET description = p_new_description
        WHERE id = v_health_issue_id;

        RAISE NOTICE 'Updated description for health issue "%".', p_health_issue_name;
    ELSE
        RAISE NOTICE 'Existing description for "%" is already sufficient: %', p_health_issue_name, v_old_description;
    END IF;
END;
$$;

INSERT INTO gym.health_issues ("name", "description")
VALUES ('Allergy', NULL);

CALL gym.update_health_issue_description(
    'Allergy',
    'Increased sensitivity of the immune system to certain substances, which can cause various reactions.'
);

CREATE OR REPLACE PROCEDURE gym.update_member_exercise_progress(
    p_member_id BIGINT,
    p_class_schedule_id BIGINT,
    p_exercise_id INT,
    p_sets SMALLINT,
    p_reps SMALLINT,
    p_metric_id INT,
    p_exercise_metric_value DECIMAL(8,2),
    p_duration INTERVAL,
    p_notes TEXT
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_existing_progress INT;
BEGIN
    SELECT COUNT(*) INTO v_existing_progress
    FROM gym.exercise_progress
    WHERE member_id = p_member_id
    AND class_schedule_id = p_class_schedule_id
    AND exercise_id = p_exercise_id;

    IF v_existing_progress = 0 THEN
        RAISE EXCEPTION 'No existing progress record found for member ID %, class schedule ID %, exercise ID %',
            p_member_id, p_class_schedule_id, p_exercise_id;
    END IF;

    UPDATE gym.exercise_progress
    SET
        sets = p_sets,
        reps = p_reps,
        metric_id = p_metric_id,
        exercise_metric_value = p_exercise_metric_value,
        duration = p_duration,
        notes = p_notes
    WHERE member_id = p_member_id
    AND class_schedule_id = p_class_schedule_id
    AND exercise_id = p_exercise_id;

    RAISE NOTICE 'Exercise progress record updated successfully for member ID %, class schedule ID %, exercise ID %',
        p_member_id, p_class_schedule_id, p_exercise_id;
END;
$$;

CALL gym.update_member_exercise_progress(
    p_member_id := 1::bigint,
    p_class_schedule_id := 3::bigint,
    p_exercise_id := 3::integer,
    p_sets := 3::smallint,
    p_reps := 10::smallint,
    p_metric_id := 2::integer,
    p_exercise_metric_value := 50.00::numeric,
    p_duration := '00:30:00'::interval,
    p_notes := 'Performed at moderate intensity'::text
);

CREATE OR REPLACE PROCEDURE gym.update_training_plan(
    p_training_plan_id BIGINT,
    p_name VARCHAR(40),
    p_description TEXT,
    p_start_date DATE,
    p_end_date DATE,
    p_achievement_percentage SMALLINT,
    p_goal_type_name VARCHAR(40)
) 
LANGUAGE plpgsql
AS $$
DECLARE
    v_goal_type_id SMALLINT;
BEGIN
    IF NOT EXISTS (SELECT 1 FROM gym.training_plans WHERE "id" = p_training_plan_id) THEN
        RAISE EXCEPTION 'Training plan with ID "%" does not exist', p_training_plan_id;
    END IF;

    SELECT "id"
    INTO v_goal_type_id
    FROM gym.goal_types
    WHERE "name" = p_goal_type_name
    LIMIT 1;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Goal type "%" not found', p_goal_type_name;
    END IF;

    UPDATE gym.training_plans
    SET 
        "name" = p_name,
        "description" = p_description,
        "start_date" = p_start_date,
        "end_date" = p_end_date,
        "achievement_percentage" = p_achievement_percentage,
        "goal_type_id" = v_goal_type_id
    WHERE "id" = p_training_plan_id;

END;
$$;

CALL gym.update_training_plan(
    p_training_plan_id := 11::BIGINT,
    p_name := 'Updated Muscle Building Plan'::VARCHAR(40),
    p_description := 'Updated description for the muscle building plan.'::TEXT,
    p_start_date := '2025-02-01'::DATE,
    p_end_date := '2025-07-01'::DATE,
    p_achievement_percentage := 75::SMALLINT,
    p_goal_type_name := 'Muscle gain'::VARCHAR(40)
);

CREATE OR REPLACE PROCEDURE gym.update_training_recommendation(
    p_id BIGINT,                           
    p_training_plan_id BIGINT,                     
    p_trainer_id SMALLINT,                
    p_recommendation_text TEXT           
)
LANGUAGE plpgsql
AS $$
DECLARE
    trainer_exists BOOLEAN;
BEGIN
 	IF NOT EXISTS (SELECT 1 FROM gym.training_recommendations WHERE "id" = p_id) THEN
        RAISE EXCEPTION 'Training recommendation with ID "%" does not exist', p_id;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM gym.training_plans WHERE "id" = p_training_plan_id) THEN
        RAISE EXCEPTION 'Training plan with ID "%" does not exist', p_training_plan_id;
    END IF;

    SELECT EXISTS (
        SELECT 1 FROM gym.trainers WHERE "id" = p_trainer_id
    ) INTO trainer_exists;

    IF NOT trainer_exists THEN
        RAISE EXCEPTION 'Trainer with ID % does not exist.', p_trainer_id;
    END IF;

    UPDATE gym.training_recommendations
    SET
        "plan_id" = p_training_plan_id,                    
        "trainer_id" = p_trainer_id,                
        "recommendation_text" = p_recommendation_text,  
        "recommendation_date" = CURRENT_DATE       
    WHERE "id" = p_id;

    RAISE NOTICE 'Training recommendation with ID "%" successfully updated.', p_id;
END;
$$;

CALL gym.update_training_recommendation(
    p_id := 1::BIGINT,
    p_training_plan_id := 5::BIGINT,
    p_trainer_id := 3::SMALLINT,
    p_recommendation_text := 'Increase focus on flexibility training.'::TEXT
);

CREATE OR REPLACE PROCEDURE gym.update_exercise_details(
    p_exercise_id INT,
    p_name VARCHAR(40),
    p_expected_sets SMALLINT,
    p_expected_reps SMALLINT
)
LANGUAGE plpgsql
AS
$$
DECLARE
    exercise_exists BOOLEAN;
BEGIN
    SELECT EXISTS (SELECT 1 FROM gym.exercises WHERE id = p_exercise_id) INTO exercise_exists;

    IF NOT exercise_exists THEN
        RAISE EXCEPTION 'Exercise with ID % does not exist', p_exercise_id;
    END IF;

    IF p_expected_sets <= 0 OR p_expected_reps <= 0 THEN
        RAISE EXCEPTION 'Expected sets and reps must be positive integers';
    END IF;

    UPDATE gym.exercises
    SET 
        name = p_name,
        expected_sets = p_expected_sets,
        expected_reps = p_expected_reps
    WHERE id = p_exercise_id;

    RAISE NOTICE 'Exercise with ID % updated successfully. Update count: %', p_exercise_id, 1;
END;
$$;

CALL gym.update_exercise_details(
    1::INT,                   
    'Push-up Advanced'::VARCHAR(40),  
    4::SMALLINT,              
    12::SMALLINT              
);

CREATE OR REPLACE PROCEDURE gym.update_training_plan_class_id(
    IN p_plan_id BIGINT,
    IN p_old_class_id SMALLINT,
    IN p_new_class_id SMALLINT
)
LANGUAGE plpgsql
AS $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM gym.training_plans WHERE id = p_plan_id
    ) THEN
        RAISE EXCEPTION 'План з id = % не існує.', p_plan_id;
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM gym.classes WHERE id = p_old_class_id
    ) THEN
        RAISE EXCEPTION 'Клас з id = % (старий class_id) не існує.', p_old_class_id;
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM gym.classes WHERE id = p_new_class_id
    ) THEN
        RAISE EXCEPTION 'Клас з id = % (новий class_id) не існує.', p_new_class_id;
    END IF;

    IF NOT EXISTS (
        SELECT 1
        FROM gym.training_plan_classes
        WHERE plan_id = p_plan_id AND class_id = p_old_class_id
    ) THEN
        RAISE EXCEPTION 'Зв''язок з plan_id=%, class_id=% не знайдено.', p_plan_id, p_old_class_id;
    END IF;

    IF EXISTS (
        SELECT 1
        FROM gym.training_plan_classes
        WHERE plan_id = p_plan_id AND class_id = p_new_class_id
    ) THEN
        RAISE EXCEPTION 'Зв''язок з plan_id=%, class_id=% вже існує.', p_plan_id, p_new_class_id;
    END IF;

    UPDATE gym.training_plan_classes
    SET class_id = p_new_class_id
    WHERE plan_id = p_plan_id AND class_id = p_old_class_id;
END;
$$;

CALL gym.update_training_plan_class_id(1::BIGINT, 8::SMALLINT, 7::SMALLINT);
