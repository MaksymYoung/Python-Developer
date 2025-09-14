CREATE SCHEMA gym;

-- Oleksandr Kopytin
CREATE TYPE gym.gender AS ENUM ('M', 'F');
CREATE TYPE gym.day_of_week AS ENUM ('Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday');

-- Danil Trunov
CREATE TABLE gym.training_levels (
    "id" SMALLSERIAL PRIMARY KEY,
    "name" VARCHAR(20) UNIQUE NOT NULL CHECK ("name" IN ('beginner', 'intermediate', 'advanced')),
    "description" TEXT
);

CREATE TABLE gym.members (
    "id" BIGSERIAL PRIMARY KEY,
    "first_name" VARCHAR(100) NOT NULL CHECK ("first_name" ~ '^[[:alpha:]''\- ]+$'),
    "last_name" VARCHAR(100) NOT NULL CHECK ("last_name" ~ '^[[:alpha:]''\- ]+$'),
    "email" VARCHAR(255) UNIQUE NOT NULL CHECK ("email" ~ '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$'),
    "phone" VARCHAR(20) NOT NULL CHECK ("phone" ~ '^\+?[1-9][0-9\s\-\(\)]{7,20}$'),
    "date_of_birth" DATE NOT NULL CHECK ("date_of_birth" <= CURRENT_DATE - INTERVAL '18 years'),
    "gender" gym.gender NOT NULL, 
    "address" VARCHAR(255),
    "registration_date" TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    "training_level_id" SMALLINT,
    CONSTRAINT "fk_training_level"
        FOREIGN KEY ("training_level_id") 
        REFERENCES gym.training_levels("id")
        ON DELETE SET NULL
        ON UPDATE CASCADE
);
CREATE INDEX "idx_members_first_last_name" ON gym.members ("first_name", "last_name");
CREATE INDEX "idx_members_phone" ON gym.members ("phone");
CREATE INDEX "idx_members_gender" ON gym.members ("gender");

CREATE TABLE gym.member_accounts (
    "member_id" BIGINT PRIMARY KEY,
    "user_name" VARCHAR(50) NOT NULL UNIQUE CHECK ("user_name" ~ '^[[:alpha:][:digit:]._''\- ]+$'),
    "password_hash" VARCHAR(60) NOT NULL,  -- обмеження для bcrypt
    "last_login" TIMESTAMP,
    CONSTRAINT "fk_member_in_member_accounts"
        FOREIGN KEY ("member_id") 
        REFERENCES gym.members("id")
        ON DELETE CASCADE
        ON UPDATE CASCADE
);

CREATE TABLE gym.member_photos (
    "id" BIGSERIAL PRIMARY KEY,
    "member_id" BIGINT NOT NULL,
    "photo_url" VARCHAR(512) NOT NULL,
    "uploaded_at" DATE DEFAULT CURRENT_DATE,
    "is_profile_photo" BOOLEAN DEFAULT FALSE,
    CONSTRAINT "fk_member_in_member_photos"
        FOREIGN KEY ("member_id") 
        REFERENCES gym.members("id")
        ON DELETE CASCADE
        ON UPDATE CASCADE
);
CREATE INDEX idx_photo_per_member ON gym.member_photos("member_id");
CREATE UNIQUE INDEX "idx_unique_profile_photo_per_member"
ON gym.member_photos ("member_id") 
WHERE "is_profile_photo" = TRUE;

CREATE TABLE gym.notifications (
    "id" BIGSERIAL PRIMARY KEY,
    "member_id" BIGINT NOT NULL,
    "message" TEXT NOT NULL,
    "sent_at" TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    "is_read" BOOLEAN DEFAULT FALSE,
    CONSTRAINT "fk_member_in_notifications"
        FOREIGN KEY ("member_id") 
        REFERENCES gym.members("id")
        ON DELETE CASCADE
        ON UPDATE CASCADE
);
CREATE INDEX "idx_notifications_member_id" ON gym.notifications ("member_id");

CREATE TABLE gym.subscription_types (
    "id" SMALLSERIAL PRIMARY KEY,
    "name" VARCHAR(10) NOT NULL UNIQUE CHECK ("name" IN ('monthly', 'yearly', 'premium'))
);

CREATE TABLE gym.membership_statuses (
    "id" SMALLSERIAL PRIMARY KEY,
    "name" VARCHAR(15) NOT NULL UNIQUE CHECK ("name" IN ('wait', 'active', 'expired', 'cancelled')),
    "description" VARCHAR(150)
);

CREATE TABLE gym.memberships (
    "id" BIGSERIAL PRIMARY KEY,
    "member_id" BIGINT NOT NULL,
    "subscription_type_id" SMALLINT DEFAULT 1, 
	"start_date" DATE DEFAULT CURRENT_DATE,
    "end_date" DATE,
    "status_id" SMALLINT DEFAULT 2,
    CONSTRAINT "fk_member_in_memberships"
        FOREIGN KEY ("member_id") 
        REFERENCES gym.members("id")
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    CONSTRAINT "fk_subscription_type"
        FOREIGN KEY ("subscription_type_id") 
        REFERENCES gym.subscription_types("id")
        ON DELETE SET DEFAULT
        ON UPDATE CASCADE,
    CONSTRAINT "fk_membership_status"
        FOREIGN KEY ("status_id") 
        REFERENCES gym.membership_statuses("id")
        ON DELETE SET DEFAULT
        ON UPDATE CASCADE,
	CONSTRAINT "chk_start_end_date_in_memberships"
        CHECK ("start_date" < "end_date")
);
CREATE INDEX "idx_memberships_member_id" ON gym.memberships ("member_id");
CREATE INDEX "idx_memberships_subscription_type_id" ON gym.memberships ("subscription_type_id");
CREATE INDEX "idx_memberships_status_id" ON gym.memberships ("status_id");

-- Vladyslav Pylypenko
CREATE TABLE gym.class_specializations (
    "id" SMALLSERIAL PRIMARY KEY,
    "name" VARCHAR(20) UNIQUE NOT NULL CHECK ("name" IN ('yoga', 'spinning', 'pilates', 'strength training', 'zumba', 'kickboxing', 'aerobics', 'dance', 'body combat', 'circuit training')),
    "description" VARCHAR(150)
);

CREATE TABLE gym.class_types (
    "id" SMALLSERIAL PRIMARY KEY,
    "name" VARCHAR(15) UNIQUE NOT NULL CHECK ("name" IN ('group', 'individual'))
);

CREATE TABLE gym.classes (
    "id" SMALLSERIAL PRIMARY KEY,
    "name" VARCHAR(40) NOT NULL,
    "class_type_id" SMALLINT NOT NULL,
    "specialization_id" SMALLINT NOT NULL,
    CONSTRAINT "fk_class_type"
        FOREIGN KEY ("class_type_id") 
        REFERENCES gym.class_types("id")
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    CONSTRAINT "fk_class_specialization"
        FOREIGN KEY ("specialization_id") 
        REFERENCES gym.class_specializations("id")
        ON DELETE CASCADE
        ON UPDATE CASCADE
);
CREATE INDEX idx_classes_class_type_id ON gym.classes("class_type_id");
CREATE INDEX idx_classes_specialization_id ON gym.classes("specialization_id");
CREATE INDEX idx_classes_name ON gym.classes("name");

CREATE TABLE gym.halls (
    "id" SMALLSERIAL PRIMARY KEY,
    "name" VARCHAR(40) NOT NULL,
    "capacity" SMALLINT NOT NULL CHECK ("capacity" BETWEEN 10 AND 50) 
);

CREATE TABLE gym.class_schedule (
    "id" BIGSERIAL PRIMARY KEY,
    "class_id" SMALLINT NOT NULL,
    "start_time" TIME NOT NULL,
    "end_time" TIME NOT NULL,
    "hall_id" SMALLINT NOT NULL,
    "class_date" DATE NOT NULL,
    CONSTRAINT "fk_class_in_schedule"
        FOREIGN KEY ("class_id") 
        REFERENCES gym.classes("id")
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    CONSTRAINT "fk_hall_in_schedule"
        FOREIGN KEY ("hall_id") 
        REFERENCES gym.halls("id")
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    CONSTRAINT "unique_class_schedule" 
        UNIQUE ("class_id", "hall_id", "class_date", "start_time"),
    CONSTRAINT "chk_start_end_time_in_class_schedule"
        CHECK ("start_time" < "end_time")
);
CREATE INDEX "idx_class_schedule_date" ON gym.class_schedule ("class_date");
CREATE INDEX "idx_class_schedule_class_hall" ON gym.class_schedule ("class_id", "hall_id");

CREATE TABLE gym.attendance (
    "member_id" BIGINT NOT NULL,
    "class_schedule_id" BIGINT NOT NULL,
    "attended" BOOLEAN DEFAULT FALSE,
    CONSTRAINT "fk_member_in_attendance"
        FOREIGN KEY ("member_id") 
        REFERENCES gym.members("id")
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    CONSTRAINT "fk_class_schedule_in_attendance"
        FOREIGN KEY ("class_schedule_id") 
        REFERENCES gym.class_schedule("id")
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    CONSTRAINT "pk_unique_attendance" 
        PRIMARY KEY ("member_id", "class_schedule_id")
);
CREATE INDEX "idx_attendance_member_id" ON gym.attendance ("member_id");
CREATE INDEX "idx_attendance_class_schedule_id" ON gym.attendance ("class_schedule_id");

CREATE TABLE gym.booking_statuses (
    "id" SMALLSERIAL PRIMARY KEY,
    "name" VARCHAR(15) UNIQUE NOT NULL CHECK ("name" IN ('pending', 'confirmed', 'cancelled')), 
	"notes" VARCHAR(150)
);

CREATE TABLE gym.bookings (
    "member_id" BIGINT NOT NULL,
    "class_schedule_id" BIGINT NOT NULL,
    "booking_date" TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    "status_id" SMALLINT NOT NULL,
    "cancellation_reason" TEXT,
    CONSTRAINT "pk_bookings" 
		PRIMARY KEY ("member_id", "class_schedule_id"), 
	CONSTRAINT "fk_member_in_bookings"
	    FOREIGN KEY ("member_id") 
	    REFERENCES gym.members("id") 
	    ON DELETE CASCADE 
	    ON UPDATE CASCADE,  
	CONSTRAINT "fk_class_schedule_in_bookings"
    	FOREIGN KEY ("class_schedule_id") 
        REFERENCES gym.class_schedule("id") 
        ON DELETE CASCADE 
        ON UPDATE CASCADE,  
	CONSTRAINT "fk_booking_status"
    	FOREIGN KEY ("status_id") 
        REFERENCES gym.booking_statuses("id") 
        ON DELETE CASCADE 
        ON UPDATE CASCADE,
    CONSTRAINT "chk_cancellation_reason_in_bookings" 
        CHECK (
            ("status_id" = 3 AND "cancellation_reason" IS NOT NULL) OR 
            ("status_id" <> 3 AND "cancellation_reason" IS NULL)
        )  -- Якщо статус "cancelled" (3), то cancellation_reason не може бути NULL, і навпаки
);
CREATE INDEX "idx_bookings_member_id" ON gym.bookings ("member_id");
CREATE INDEX "idx_bookings_class_schedule_id" ON gym.bookings ("class_schedule_id");
CREATE INDEX "idx_bookings_status_date" ON gym.bookings ("status_id", "booking_date");

CREATE OR REPLACE FUNCTION check_booking_date_before_class()
RETURNS TRIGGER AS $$
DECLARE
    class_date date;
BEGIN
    SELECT cs.class_date INTO class_date
    FROM gym.class_schedule cs
    WHERE cs.id = NEW.class_schedule_id;

    IF NEW.booking_date::date > class_date THEN
        RAISE EXCEPTION 'Booking date must be on or before class date';
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_check_booking_date
BEFORE INSERT OR UPDATE ON gym.bookings
FOR EACH ROW
EXECUTE FUNCTION check_booking_date_before_class();

-- Oleksii Zakharchuk
CREATE TABLE gym.equipment_conditions (
    "id" SMALLSERIAL PRIMARY KEY,
    "name" VARCHAR(30) NOT NULL UNIQUE CHECK (
        "name" IN (
            'brand new',
            'excellent',
            'very good',
            'good',
            'fair',
            'needs maintenance',
            'under inspection',
            'being repaired',
            'out of order',
            'decommissioned'
        )
    )
);
COMMENT ON TABLE gym.equipment_conditions IS 'Describes the physical/technical condition of equipment';

CREATE TABLE gym.equipment_statuses (
    "id" SMALLSERIAL PRIMARY KEY,
    "name" VARCHAR(30) NOT NULL UNIQUE CHECK (
        "name" IN (
            'available',
            'in use',
            'reserved',
            'in queue',
            'cleaning in progress',
            'under maintenance',
            'awaiting parts',
            'testing mode',
            'out of service',
            'retired'
        )
    )
);
COMMENT ON TABLE gym.equipment_statuses IS 'Describes the current usage status of equipment';

CREATE TABLE gym.equipment (
    "id" BIGSERIAL PRIMARY KEY,
    "name" VARCHAR(30) NOT NULL,
    "condition_id" SMALLINT,
    "status_id" SMALLINT,
    "hall_id" SMALLINT NOT NULL,
    CONSTRAINT "fk_equipment_condition"
        FOREIGN KEY ("condition_id") 
        REFERENCES gym.equipment_conditions("id")
        ON DELETE SET NULL
        ON UPDATE CASCADE,
    CONSTRAINT "fk_equipment_status"
        FOREIGN KEY ("status_id") 
        REFERENCES gym.equipment_statuses("id")
		ON DELETE SET NULL
        ON UPDATE CASCADE, 
    CONSTRAINT "fk_hall_in_equipment_in_halls"
        FOREIGN KEY ("hall_id") 
        REFERENCES gym.halls("id") 
        ON DELETE RESTRICT
        ON UPDATE CASCADE
);
CREATE INDEX "idx_equipment_condition_id" ON gym.equipment ("condition_id");
CREATE INDEX "idx_equipment_status_id" ON gym.equipment ("status_id");
CREATE INDEX "idx_equipment_name" ON gym.equipment ("name");
CREATE INDEX "idx_equipment_hall" ON gym.equipment ("hall_id");

CREATE TABLE gym.maintenance_history (
    "id" BIGSERIAL PRIMARY KEY, 
    "equipment_id" BIGINT NOT NULL, 
    "maintenance_date" DATE NOT NULL, 
    "performed_by" VARCHAR(100) NOT NULL, 
    "notes" TEXT,
	CONSTRAINT "fk_equipment_in_maintenance_history"
    	FOREIGN KEY ("equipment_id") 
		REFERENCES gym.equipment("id") 
        ON DELETE CASCADE 
        ON UPDATE CASCADE
);
CREATE INDEX "idx_maintenance_history_equipment_id" ON gym.maintenance_history ("equipment_id");
CREATE INDEX "idx_maintenance_history_maintenance_date" ON gym.maintenance_history ("maintenance_date");

-- Danil Trunov
CREATE TABLE gym.feedback_equipment (
    "member_id" BIGINT NOT NULL,
    "equipment_id" BIGINT NOT NULL,
    "rating" SMALLINT NOT NULL CHECK ("rating" BETWEEN 1 AND 5), 
    "notes" TEXT,
    "created_at" DATE DEFAULT CURRENT_DATE,
    CONSTRAINT "fk_member_in_feedback_equipment"
        FOREIGN KEY ("member_id") 
        REFERENCES gym.members("id")
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    CONSTRAINT "fk_equipment_in_feedback_equipment" 
        FOREIGN KEY ("equipment_id") 
        REFERENCES gym.equipment("id")
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    CONSTRAINT "pk_feedback_equipment"
		PRIMARY KEY ("member_id", "equipment_id")
);
CREATE INDEX idx_feedback_equipment_member_id ON gym.feedback_equipment("member_id");
CREATE INDEX idx_feedback_equipment_equipment_id ON gym.feedback_equipment("equipment_id");

CREATE TABLE gym.member_preferred_training_time (
    "member_id" BIGINT NOT NULL,
    "start_time" TIME NOT NULL,
    "end_time" TIME NOT NULL,
    "day_of_week" gym.day_of_week NOT NULL,  
    "priority" SMALLINT NOT NULL CHECK ("priority" IN (1, 2)),  
    CONSTRAINT "fk_member_in_member_preferred_time"
        FOREIGN KEY ("member_id") 
        REFERENCES gym.members("id")
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    CONSTRAINT "pk_member_preferred_training_time"
        PRIMARY KEY ("member_id", "day_of_week", "priority"),
	CONSTRAINT "chk_start_end_time_in_member_preferred_time"
        CHECK ("start_time" < "end_time")
);
CREATE INDEX idx_member_preferred_training_time_member_id ON gym.member_preferred_training_time("member_id");
CREATE INDEX idx_member_preferred_training_time_day_of_week_priority ON gym.member_preferred_training_time("day_of_week", "priority");

-- Maksym Zymyn
CREATE TABLE gym.metrics (
    "id" SERIAL PRIMARY KEY,
    "name" VARCHAR(30) NOT NULL UNIQUE, -- Weight, Body Fat %, Muscle Mass, etc.
    "unit" VARCHAR(15),                 -- kg, %, bpm, m, km, kcal
	"description" VARCHAR(150),
    "created_at" DATE DEFAULT CURRENT_DATE
);

CREATE TABLE gym.health_issues (
    "id" SERIAL PRIMARY KEY,
    "name" VARCHAR(100) NOT NULL UNIQUE,
    "description" TEXT
);

CREATE TABLE gym.member_health_issues (
    "member_id" BIGINT NOT NULL,
    "health_issue_id" INT NOT NULL,
    "created_at" DATE DEFAULT CURRENT_DATE,
	CONSTRAINT "pk_member_health_issues"
    	PRIMARY KEY ("member_id", "health_issue_id"),
	CONSTRAINT "fk_member_in_member_health_issues"
    	FOREIGN KEY ("member_id") 
		REFERENCES gym.members("id")
        ON DELETE CASCADE
        ON UPDATE CASCADE,
	CONSTRAINT "fk_health_issue_in_member_health_issues"
    	FOREIGN KEY ("health_issue_id") 
		REFERENCES gym.health_issues("id")
        ON DELETE CASCADE
        ON UPDATE CASCADE
);
CREATE INDEX idx_member_health_issues_member_id ON gym.member_health_issues("member_id");
CREATE INDEX idx_member_health_issues_health_issue_id ON gym.member_health_issues("health_issue_id");

CREATE TABLE gym.exercises (
    "id" SERIAL PRIMARY KEY,
    "name" VARCHAR(40) NOT NULL UNIQUE,
    "expected_sets" SMALLINT NOT NULL CHECK ("expected_sets" > 0),
    "expected_reps" SMALLINT NOT NULL CHECK ("expected_reps" > 0),
    "created_at" DATE DEFAULT CURRENT_DATE
);
CREATE INDEX "idx_exercises_name" ON gym.exercises ("name");

CREATE TABLE gym.exercise_progress (
    "member_id" BIGINT NOT NULL,
    "class_schedule_id" BIGINT NOT NULL, 
    "exercise_id" INT NOT NULL,    
    "sets" SMALLINT NOT NULL CHECK ("sets" > 0),
    "reps" SMALLINT NOT NULL CHECK ("reps" > 0),    
    "metric_id" INT,
    "exercise_metric_value" DECIMAL(8,2) CHECK ("exercise_metric_value" >= 0),
    "duration" INTERVAL NOT NULL CHECK ("duration" > INTERVAL '0'),
    "notes" TEXT,
    CONSTRAINT "pk_exercise_progress"
        PRIMARY KEY ("member_id", "class_schedule_id", "exercise_id"),  
    CONSTRAINT "fk_class_schedule_in_exercise_progress"
        FOREIGN KEY ("class_schedule_id") 
        REFERENCES gym.class_schedule("id")
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    CONSTRAINT "fk_exercise_in_exercise_progress"
        FOREIGN KEY ("exercise_id") 
        REFERENCES gym.exercises("id") 
        ON DELETE CASCADE 
        ON UPDATE CASCADE,
    CONSTRAINT "fk_member_in_exercise_progress"
        FOREIGN KEY ("member_id") 
        REFERENCES gym.members("id") 
        ON DELETE CASCADE 
        ON UPDATE CASCADE,
    CONSTRAINT "fk_metric_in_exercise_progress"
        FOREIGN KEY ("metric_id") 
        REFERENCES gym.metrics("id") 
        ON DELETE SET NULL 
        ON UPDATE CASCADE,
    CONSTRAINT "chk_exercise_metric_value"
        CHECK (
            ("metric_id" IS NOT NULL AND "exercise_metric_value" IS NOT NULL) OR 
            ("metric_id" IS NULL AND "exercise_metric_value" IS NULL)
        )
);
CREATE INDEX idx_member_id ON gym.exercise_progress("member_id");
CREATE INDEX idx_class_schedule_id ON gym.exercise_progress("class_schedule_id");
CREATE INDEX idx_exercise_progress_member_exercise 
    ON gym.exercise_progress("member_id", "exercise_id");
CREATE INDEX idx_exercise_progress_member_metric 
    ON gym.exercise_progress("member_id", "metric_id");

CREATE TABLE gym.goal_types (
    "id" SMALLSERIAL PRIMARY KEY,
    "name" VARCHAR(40) NOT NULL UNIQUE,  -- Weight loss, Muscle gain, Endurance
	"description" VARCHAR(150),
    "created_at" DATE DEFAULT CURRENT_DATE
);

CREATE TABLE gym.training_plans (
    "id" BIGSERIAL PRIMARY KEY,
    "member_id" BIGINT NOT NULL,
    "name" VARCHAR(40) NOT NULL,
    "description" TEXT,
    "start_date" DATE DEFAULT CURRENT_DATE,
    "end_date" DATE,
    "achievement_percentage" SMALLINT NOT NULL CHECK ("achievement_percentage" BETWEEN 0 AND 100),
    "goal_type_id" SMALLINT NOT NULL,
    "created_at" DATE DEFAULT CURRENT_DATE,
    CONSTRAINT "fk_member_in_training_plans"
        FOREIGN KEY ("member_id") REFERENCES gym.members("id")
            ON DELETE CASCADE
            ON UPDATE CASCADE,
    CONSTRAINT "fk_goal_type"
        FOREIGN KEY ("goal_type_id") REFERENCES gym.goal_types("id")
            ON DELETE RESTRICT
            ON UPDATE CASCADE,
	CONSTRAINT "chk_start_end_date_in_training_plans"
        CHECK ("start_date" < "end_date")
);
CREATE INDEX idx_training_plans_member ON gym.training_plans("member_id");
CREATE INDEX idx_training_plans_goal_type ON gym.training_plans("goal_type_id");

CREATE TABLE gym.training_plan_classes (
    "plan_id" BIGINT NOT NULL,
    "class_id" SMALLINT NOT NULL,
    CONSTRAINT "pk_training_plan_classes" 
        PRIMARY KEY ("plan_id", "class_id"),
    CONSTRAINT "fk_plan_in_training_plan_classes"
        FOREIGN KEY ("plan_id") REFERENCES gym.training_plans("id")
            ON DELETE CASCADE
            ON UPDATE CASCADE,
    CONSTRAINT "fk_class_in_training_plan_classes"
        FOREIGN KEY ("class_id") REFERENCES gym.classes("id")
            ON DELETE CASCADE
            ON UPDATE CASCADE
);
CREATE INDEX idx_training_plan_classes_plan_id ON gym.training_plan_classes("plan_id");
CREATE INDEX idx_training_plan_classes_class_id ON gym.training_plan_classes("class_id");

-- Oleksandr Kopytin
CREATE TABLE gym.trainers (
    "id" SMALLSERIAL PRIMARY KEY,               
    "first_name" VARCHAR(100) NOT NULL CHECK ("first_name" ~ '^[[:alpha:]''\- ]+$'),
    "last_name" VARCHAR(100) NOT NULL CHECK ("last_name" ~ '^[[:alpha:]''\- ]+$'),
    "email" VARCHAR(255) UNIQUE NOT NULL CHECK ("email" ~ '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$'),
    "phone" VARCHAR(20) NOT NULL CHECK ("phone" ~ '^\+?[1-9][0-9\s\-\(\)]{7,20}$'),
    "date_of_birth" DATE NOT NULL CHECK ("date_of_birth" <= CURRENT_DATE - INTERVAL '21 years'),
    "gender" gym.gender NOT NULL,  
    "education" VARCHAR(255) NOT NULL,
    "address" VARCHAR(255) NOT NULL,                        
    "registration_date" DATE DEFAULT CURRENT_DATE
);
CREATE INDEX "idx_trainers_first_last_name" ON gym.trainers ("first_name", "last_name");

CREATE TABLE gym.trainer_accounts (
    "trainer_id" SMALLINT PRIMARY KEY,
    "user_name" VARCHAR(50) NOT NULL UNIQUE CHECK ("user_name" ~ '^[[:alpha:][:digit:]._''\- ]+$'),
    "password_hash" VARCHAR(60) NOT NULL,  -- обмеження для bcrypt
    "last_login" TIMESTAMP,
	CONSTRAINT "fk_trainer_in_trainer_accounts"
    	FOREIGN KEY ("trainer_id") 
		REFERENCES gym.trainers("id") 
		ON DELETE CASCADE 
		ON UPDATE CASCADE
);

CREATE TABLE gym.trainer_photos (
    "id" BIGSERIAL PRIMARY KEY,
    "trainer_id" SMALLINT NOT NULL,
    "photo_url" VARCHAR(512) NOT NULL,
    "uploaded_at" DATE DEFAULT CURRENT_DATE,
    "is_profile_photo" BOOLEAN DEFAULT FALSE,
	CONSTRAINT "fk_trainer_in_trainer_photos"
    	FOREIGN KEY ("trainer_id") 
		REFERENCES gym.trainers("id") 
		ON DELETE CASCADE 
		ON UPDATE CASCADE
);
CREATE INDEX idx_photo_per_trainer ON gym.trainer_photos("trainer_id");
CREATE UNIQUE INDEX idx_unique_profile_photo_per_trainer
ON gym.trainer_photos ("trainer_id") 
WHERE "is_profile_photo" = TRUE;

CREATE TABLE gym.trainer_class_assignments_history (
    "class_id" SMALLINT NOT NULL,
    "trainer_id" SMALLINT NOT NULL,
    "start_date" DATE DEFAULT CURRENT_DATE,
    "end_date" DATE,
    CONSTRAINT "pk_trainer_class_assignments_history"
        PRIMARY KEY ("class_id", "trainer_id", "start_date"),
    CONSTRAINT "fk_class_in_trainer_class_assignments_history"
        FOREIGN KEY ("class_id") REFERENCES gym.classes("id") 
            ON DELETE CASCADE 
            ON UPDATE CASCADE,
    CONSTRAINT "fk_trainer_in_trainer_class_assignments_history"
        FOREIGN KEY ("trainer_id") REFERENCES gym.trainers("id") 
            ON DELETE CASCADE 
            ON UPDATE CASCADE,
	CONSTRAINT "chk_start_end_date_in_trainer_class_assignments_history"
        CHECK ("end_date" IS NULL OR "start_date" < "end_date")
);
CREATE INDEX idx_trainer_class_assignments_history_class_id ON gym.trainer_class_assignments_history("class_id");
CREATE INDEX idx_trainer_class_assignments_history_trainer_id ON gym.trainer_class_assignments_history("trainer_id");

CREATE EXTENSION IF NOT EXISTS btree_gist;

CREATE TABLE gym.trainer_availability (
    id SERIAL PRIMARY KEY,
    trainer_id SMALLINT NOT NULL,
    day_of_week gym.day_of_week NOT NULL,
    start_time TIME NOT NULL,
    end_time TIME NOT NULL,
    
    time_range tsrange GENERATED ALWAYS AS (
        tsrange(
            '2000-01-01'::timestamp + start_time,
            '2000-01-01'::timestamp + end_time
        )
    ) STORED,

    CONSTRAINT chk_start_before_end
        CHECK (start_time < end_time),
        
    CONSTRAINT fk_trainer
        FOREIGN KEY (trainer_id) REFERENCES gym.trainers(id)
        ON DELETE CASCADE ON UPDATE CASCADE,
        
    EXCLUDE USING GIST (
        trainer_id WITH =,
        day_of_week WITH =,
        time_range WITH &&
    )
);
CREATE INDEX idx_trainer_availability_trainer_id ON gym.trainer_availability("trainer_id");
CREATE INDEX idx_trainer_availability_trainer_day ON gym.trainer_availability("trainer_id", "day_of_week");

CREATE TABLE gym.feedback_trainer (
    "id" BIGSERIAL PRIMARY KEY,  
    "member_id" BIGINT NOT NULL,
    "trainer_id" SMALLINT NOT NULL,
    "rating" SMALLINT NOT NULL CHECK ("rating" BETWEEN 1 AND 5),
    "notes" TEXT,
    "created_at" DATE DEFAULT CURRENT_DATE,
    CONSTRAINT "fk_member_in_feedback_trainer"
        FOREIGN KEY ("member_id") 
        REFERENCES gym.members("id") 
        ON DELETE CASCADE 
        ON UPDATE CASCADE,
    CONSTRAINT "fk_trainer_in_feedback_trainer"
        FOREIGN KEY ("trainer_id") 
        REFERENCES gym.trainers("id")
        ON DELETE CASCADE 
        ON UPDATE CASCADE
);
CREATE INDEX idx_feedback_trainer_member_id ON gym.feedback_trainer("member_id");
CREATE INDEX idx_feedback_trainer_trainer_id ON gym.feedback_trainer("trainer_id");

-- Maksym Zymyn
CREATE TABLE gym.training_recommendations (
    "id" BIGSERIAL PRIMARY KEY,
    "plan_id" BIGINT NOT NULL,
    "trainer_id" SMALLINT,
    "recommendation_text" TEXT NOT NULL,
    "recommendation_date" DATE DEFAULT CURRENT_DATE,
    CONSTRAINT "fk_plan_in_training_recommendations"
        FOREIGN KEY ("plan_id") REFERENCES gym.training_plans("id")
            ON DELETE CASCADE
            ON UPDATE CASCADE,
    CONSTRAINT "fk_trainer_in_training_recommendations"
        FOREIGN KEY ("trainer_id") REFERENCES gym.trainers("id")
            ON DELETE SET NULL
            ON UPDATE CASCADE
);
CREATE INDEX idx_training_recommendations_plan_id ON gym.training_recommendations("plan_id");
CREATE INDEX idx_training_recommendations_trainer_id ON gym.training_recommendations("trainer_id");

CREATE TABLE gym.feedback_class_schedule (
    "member_id" BIGINT NOT NULL,
    "class_schedule_id" BIGINT NOT NULL,
    "rating" SMALLINT NOT NULL CHECK ("rating" BETWEEN 1 AND 5),
    "notes" TEXT,
    "created_at" DATE DEFAULT CURRENT_DATE,
    CONSTRAINT "pk_feedback_class_schedule"
        PRIMARY KEY ("member_id", "class_schedule_id"),
    CONSTRAINT "fk_member_in_feedback_class_schedule"
        FOREIGN KEY ("member_id") REFERENCES gym.members("id")
            ON DELETE CASCADE
            ON UPDATE CASCADE,
    CONSTRAINT "fk_class_schedule_in_feedback_class_schedule"
        FOREIGN KEY ("class_schedule_id") REFERENCES gym.class_schedule("id")
            ON DELETE CASCADE
            ON UPDATE CASCADE
);
CREATE INDEX idx_feedback_class_schedule_member_id ON gym.feedback_class_schedule("member_id");
CREATE INDEX idx_feedback_class_schedule_class_schedule_id ON gym.feedback_class_schedule("class_schedule_id");

CREATE OR REPLACE FUNCTION check_attendance_before_feedback()
RETURNS TRIGGER AS $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM gym.attendance
        WHERE member_id = NEW.member_id
        AND class_schedule_id = NEW.class_schedule_id
        AND attended = TRUE
    ) THEN
        RAISE EXCEPTION 'Member % has not attended the class %', NEW.member_id, NEW.class_schedule_id;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_check_attendance_before_feedback
BEFORE INSERT ON gym.feedback_class_schedule
FOR EACH ROW
EXECUTE FUNCTION check_attendance_before_feedback();

-- Ihor Bohdanovych
CREATE TABLE gym.payment_methods (
    "id" SMALLSERIAL PRIMARY KEY,
    "name" VARCHAR(20) UNIQUE NOT NULL CHECK ("name" IN ('credit card', 'cash', 'bank transfer', 'online')),
	"notes" VARCHAR(150)
);

CREATE TABLE gym.payment_statuses (
    "id" SMALLSERIAL PRIMARY KEY,
    "name" VARCHAR(15) UNIQUE NOT NULL CHECK ("name" IN ('pending', 'completed', 'failed'))
);

CREATE TABLE gym.payments (
    "id" BIGSERIAL PRIMARY KEY,
    "member_id" BIGINT NOT NULL,
    "amount" DECIMAL(7,2) NOT NULL,
    "payment_date" TIMESTAMP NOT NULL,
    "method_id" SMALLINT,
    "status_id" SMALLINT,
    "transaction_id" VARCHAR(100) UNIQUE NOT NULL,
    "comment" TEXT,
    CONSTRAINT "fk_payments_member"
        FOREIGN KEY ("member_id") REFERENCES gym.members("id") 
        ON DELETE CASCADE 
        ON UPDATE CASCADE,
    CONSTRAINT "fk_payments_method"
        FOREIGN KEY ("method_id") REFERENCES gym.payment_methods("id") 
        ON DELETE SET NULL
        ON UPDATE CASCADE,
    CONSTRAINT "fk_payments_status"
        FOREIGN KEY ("status_id") REFERENCES gym.payment_statuses("id") 
        ON DELETE SET NULL
        ON UPDATE CASCADE
);
CREATE INDEX idx_payments_member_id ON gym.payments("member_id");
CREATE INDEX idx_payments_method_id ON gym.payments("method_id");
CREATE INDEX idx_payments_status_id ON gym.payments("status_id");

CREATE TABLE gym.promo_codes (
    "promo_code" VARCHAR(36) PRIMARY KEY,
    "description" TEXT,
    "discount_percentage" SMALLINT NOT NULL CHECK ("discount_percentage" BETWEEN 0 AND 100),
    "start_date" DATE DEFAULT CURRENT_DATE,
    "end_date" DATE,
    "class_id" SMALLINT NOT NULL,
    "created_at" DATE DEFAULT CURRENT_DATE,
	CONSTRAINT "fk_class_in_promo_codes"
    	FOREIGN KEY ("class_id") 
		REFERENCES gym.classes("id") 
		ON DELETE CASCADE 
		ON UPDATE CASCADE,
	CONSTRAINT "chk_start_end_date_in_promo_codes"
        CHECK ("start_date" < "end_date")
);
CREATE INDEX "idx_promo_codes_class_id" ON gym.promo_codes ("class_id");
CREATE INDEX "idx_promo_codes_start_date" ON gym.promo_codes ("start_date");
CREATE INDEX "idx_promo_codes_discount_percentage" ON gym.promo_codes ("discount_percentage");

CREATE TABLE gym.member_referrals (
    "referrer_id" BIGINT NOT NULL,
    "referred_id" BIGINT NOT NULL UNIQUE,
    "referral_date" DATE DEFAULT CURRENT_DATE,
    "promo_code" VARCHAR(36) NOT NULL,
    CONSTRAINT "pk_member_referrals" 
        PRIMARY KEY ("referrer_id", "referred_id"),
    CONSTRAINT "fk_member_referrals_referrer"
        FOREIGN KEY ("referrer_id") 
        REFERENCES gym.members("id") 
        ON DELETE CASCADE 
        ON UPDATE CASCADE,
    CONSTRAINT "fk_member_referrals_referred"
        FOREIGN KEY ("referred_id") 
        REFERENCES gym.members("id") 
        ON DELETE CASCADE 
        ON UPDATE CASCADE,
    CONSTRAINT "fk_member_referrals_promo_code"
        FOREIGN KEY ("promo_code") 
        REFERENCES gym.promo_codes("promo_code") 
        ON DELETE CASCADE 
        ON UPDATE CASCADE,
    CONSTRAINT "chk_referrer_not_referred"
        CHECK ("referrer_id" <> "referred_id")
);
CREATE INDEX idx_member_referrals_referrer_id ON gym.member_referrals("referrer_id");
CREATE UNIQUE INDEX idx_member_referrals_referred_id ON gym.member_referrals("referred_id");
CREATE INDEX idx_member_referrals_promo_code ON gym.member_referrals("promo_code");
