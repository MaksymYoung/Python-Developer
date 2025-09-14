-- Danil Trunov
INSERT INTO gym.training_levels ("name", "description")
VALUES
  ('beginner', 'Level for beginners. Suitable for those who are just starting training or have a low level of physical fitness.'),
  ('intermediate', 'Intermediate level. Suitable for those who already have training experience and want to improve their results.'),
  ('advanced', 'Advanced level. For experienced athletes who want to achieve high results and tackle complex goals.')
RETURNING *;

INSERT INTO gym.members (
    "first_name", "last_name", "email", "phone", "date_of_birth", "gender", "address", "training_level_id"
)
SELECT
    first_names.sample,
    last_names.sample,
    LOWER(first_names.sample || '.' || last_names.sample || FLOOR(RANDOM() * 1000)::TEXT || '@example.com'),
    '+380' || LPAD((FLOOR(RANDOM() * 1000000000)::TEXT), 9, '0'),
    DATE '1970-01-01' + (TRUNC(RANDOM() * 11000)) * INTERVAL '1 day',
    first_names.gender::gym.gender,
    'Street ' || FLOOR(RANDOM() * 100)::TEXT || ', City',
    (ARRAY[1, 2, 3])[FLOOR(RANDOM() * 3 + 1)]
FROM
    (SELECT UNNEST(ARRAY['Andrii', 'Ivan', 'Dmytro', 'Serhii', 'Viktor', 'Oleksandr', 'Yurii', 'Roman', 'Artem', 'Pavlo', 
                         'Olha', 'Oksana', 'Kateryna', 'Nadiia', 'Iryna', 'Tetyana', 'Larysa', 'Svitlana', 'Vira', 'Natalia', 
                         'Mykhailo', 'Yevhen', 'Oleksandr', 'Vladyslav', 'Denys', 'Volodymyr', 'Sergii', 'Igor', 'Maksym']) 
        AS sample, 'M' AS gender
     UNION ALL
     SELECT UNNEST(ARRAY['Olha', 'Oksana', 'Kateryna', 'Nadiia', 'Iryna', 'Tetyana', 'Larysa', 'Svitlana', 'Vira', 'Natalia', 
                         'Anastasiia', 'Alina', 'Daria', 'Mariia', 'Sofia', 'Yulia', 'Tetiana', 'Halyna', 'Ira', 'Lilia']) 
        AS sample, 'F' AS gender) AS first_names,
    (SELECT UNNEST(ARRAY['Shevchenko', 'Kovalchuk', 'Tkachenko', 'Bondarenko', 'Kravchenko', 'Melnyk', 'Boyko', 'Khomenko']) 
        AS sample) AS last_names
ORDER BY RANDOM()
LIMIT 30
RETURNING *;

INSERT INTO gym.members (
    "first_name", "last_name", "email", "phone", "date_of_birth", "gender", "address", "training_level_id"
)
VALUES
    ('John', 'Doe', 'john.doe@example.com', '+1234567890', '1990-05-15', 'M', '123 Main St, New York, NY',
        (SELECT id FROM gym.training_levels WHERE name = 'beginner')),
    ('Emily', 'Smith', 'emily.smith@example.com', '+44 7700 900123', '1988-09-21', 'F', '45 Queen St, London, UK',
        (SELECT id FROM gym.training_levels WHERE name = 'intermediate')),
    ('Carlos', 'Martínez', 'carlos.m@example.com', '+34 600 123 456', '1992-03-03', 'M', 'Calle Mayor 12, Madrid, Spain',
        (SELECT id FROM gym.training_levels WHERE name = 'intermediate')),
    ('Anna', 'Müller', 'anna.mueller@example.de', '+49 151 23456789', '1985-12-30', 'F', 'Berliner Str. 55, Berlin, Germany',
        (SELECT id FROM gym.training_levels WHERE name = 'advanced')),
    ('Liam', 'O''Connor', 'liam.oconnor@example.ie', '+353 86 1234567', '1991-07-10', 'M', 'Dublin Road, Dublin, Ireland',
        (SELECT id FROM gym.training_levels WHERE name = 'beginner')),
    ('Sophie', 'Dubois', 'sophie.dubois@example.fr', '+33 6 12 34 56 78', '1993-04-01', 'F', 'Rue Lafayette 20, Paris, France',
        (SELECT id FROM gym.training_levels WHERE name = 'advanced')),
    ('Mateo', 'Rossi', 'mateo.rossi@example.it', '+39 320 123 4567', '1990-11-22', 'M', 'Via Roma 1, Rome, Italy',
        (SELECT id FROM gym.training_levels WHERE name = 'intermediate')),
    ('Julia', 'Nowak', 'julia.nowak@example.pl', '+48 600 700 800', '1989-08-08', 'F', 'ul. Warszawska 10, Warsaw, Poland',
        (SELECT id FROM gym.training_levels WHERE name = 'beginner')),
    ('Noah', 'Johnson', 'noah.johnson@example.ca', '+1 416 555 0199', '1987-01-18', 'M', 'Bay St 100, Toronto, Canada',
        (SELECT id FROM gym.training_levels WHERE name = 'advanced')),
    ('Isabella', 'Silva', 'isabella.silva@example.br', '+55 21 99999 8888', '1995-06-12', 'F', 'Av. Brasil 500, Rio de Janeiro, Brazil',
        (SELECT id FROM gym.training_levels WHERE name = 'beginner'))
RETURNING *;

CREATE EXTENSION IF NOT EXISTS pgcrypto;

INSERT INTO gym.member_accounts ("member_id", "user_name", "password_hash")
SELECT id, 
       LEFT(first_name, 2) || last_name || FLOOR(RANDOM() * 1000)::TEXT,  
       crypt(gen_random_uuid()::VARCHAR || id::VARCHAR, gen_salt('bf'))
FROM gym.members
RETURNING *;

INSERT INTO gym.member_photos ("member_id", "photo_url", "is_profile_photo") 
SELECT m.id, 
       'gymfit.ua/profile_photos/' || ma.user_name, 
       TRUE  -- Це профільне фото
FROM gym.members AS m
JOIN gym.member_accounts AS ma ON m.id = ma.member_id
RETURNING *;

INSERT INTO gym.member_photos ("member_id", "photo_url")
SELECT m.id, 
       'gymfit.ua/photos/' || ma.user_name -- Це непрофільне фото
FROM gym.members AS m
JOIN gym.member_accounts AS ma ON m.id = ma.member_id
RETURNING *;

INSERT INTO gym.notifications ("member_id", "message")
VALUES
    (1, 'Your training session is scheduled for tomorrow.'),
    (2, 'You have a new friend request.'),
    (3, 'Your membership is about to expire.'),
    (4, 'A new post was shared in the advanced training group.'),
    (5, 'Your weekly training summary is available.'),
    (6, 'You have been tagged in a photo.'),
    (7, 'A new workout routine has been added to your profile.'),
    (8, 'You have a new message from your coach.'),
    (9, 'Your session feedback is available.'),
    (10, 'Your recent workout has been successfully logged.')
RETURNING *;

WITH messages AS (
    SELECT msg, ROW_NUMBER() OVER (ORDER BY RANDOM()) AS row_num
    FROM UNNEST(ARRAY[
        'Your training session is scheduled for tomorrow.',
        'You have a new friend request.',
        'Your membership is about to expire.',
        'A new post was shared in the advanced training group.',
        'Your weekly training summary is available.',
        'You have been tagged in a photo.',
        'A new workout routine has been added to your profile.',
        'You have a new message from your coach.',
        'Your session feedback is available.',
        'Your recent workout has been successfully logged.'
    ]) AS msg
),
members AS (
    SELECT generate_series(11, 40) AS member_id
)
INSERT INTO gym.notifications (member_id, message)
SELECT
    m.member_id,
    msgs.msg
FROM members m
JOIN messages msgs
    ON (m.member_id - 11) % 10 + 1 = msgs.row_num
RETURNING *;

INSERT INTO gym.subscription_types ("name")
VALUES 
    ('monthly'),
    ('yearly'),
    ('premium')
RETURNING *;

INSERT INTO gym.membership_statuses ("name", "description")
VALUES 
    ('wait', 'The membership is pending approval or activation.'),
    ('active', 'The membership is currently active and the member has full access.'),
    ('expired', 'The membership has expired and needs to be renewed.'),
    ('cancelled', 'The membership has been cancelled by the member or admin.')
RETURNING *;

INSERT INTO gym.memberships ("member_id", "subscription_type_id", "end_date", "status_id")
VALUES
    (1, (SELECT id FROM gym.subscription_types WHERE name = 'monthly'), CURRENT_DATE + INTERVAL '1 month', (SELECT id FROM gym.membership_statuses WHERE name = 'active')),
    (2, (SELECT id FROM gym.subscription_types WHERE name = 'yearly'), CURRENT_DATE + INTERVAL '1 year', (SELECT id FROM gym.membership_statuses WHERE name = 'wait')),
    (3, (SELECT id FROM gym.subscription_types WHERE name = 'premium'), CURRENT_DATE + INTERVAL '1 year', (SELECT id FROM gym.membership_statuses WHERE name = 'active')),
    (4, (SELECT id FROM gym.subscription_types WHERE name = 'monthly'), CURRENT_DATE + INTERVAL '1 month', (SELECT id FROM gym.membership_statuses WHERE name = 'expired')),
    (5, (SELECT id FROM gym.subscription_types WHERE name = 'yearly'), CURRENT_DATE + INTERVAL '1 year', (SELECT id FROM gym.membership_statuses WHERE name = 'cancelled')),
    (6, (SELECT id FROM gym.subscription_types WHERE name = 'monthly'), CURRENT_DATE + INTERVAL '1 month', (SELECT id FROM gym.membership_statuses WHERE name = 'active')),
    (7, (SELECT id FROM gym.subscription_types WHERE name = 'yearly'), CURRENT_DATE + INTERVAL '1 year', (SELECT id FROM gym.membership_statuses WHERE name = 'wait')),
    (8, (SELECT id FROM gym.subscription_types WHERE name = 'premium'), CURRENT_DATE + INTERVAL '1 year', (SELECT id FROM gym.membership_statuses WHERE name = 'active')),
    (9, (SELECT id FROM gym.subscription_types WHERE name = 'monthly'), CURRENT_DATE + INTERVAL '1 month', (SELECT id FROM gym.membership_statuses WHERE name = 'expired')),
    (10, (SELECT id FROM gym.subscription_types WHERE name = 'yearly'), CURRENT_DATE + INTERVAL '1 year', (SELECT id FROM gym.membership_statuses WHERE name = 'cancelled'))
RETURNING *;

WITH
subscription_types AS (
    SELECT "id", "name", ROW_NUMBER() OVER (ORDER BY RANDOM()) AS row_num
    FROM gym.subscription_types
),
statuses AS (
    SELECT "id", ROW_NUMBER() OVER (ORDER BY RANDOM()) AS row_num
    FROM gym.membership_statuses
),
member_ids AS (
    SELECT generate_series(11, 40) AS member_id
),
RANDOM_memberships AS (
    SELECT
        m.member_id,
        st.id AS subscription_type_id,
        s.id AS status_id,
        st.name AS sub_name
    FROM member_ids m
    JOIN subscription_types st
        ON (m.member_id - 11) % (SELECT COUNT(*) FROM gym.subscription_types) + 1 = st.row_num
    JOIN statuses s
        ON (m.member_id - 11) % (SELECT COUNT(*) FROM gym.membership_statuses) + 1 = s.row_num
)
INSERT INTO gym.memberships ("member_id", "subscription_type_id", "end_date", "status_id")
SELECT
    "member_id",
    "subscription_type_id",
    CASE 
        WHEN sub_name = 'monthly' THEN CURRENT_DATE + INTERVAL '1 month'
        WHEN sub_name = 'yearly' THEN CURRENT_DATE + INTERVAL '1 year'
        WHEN sub_name = 'premium' THEN CURRENT_DATE + INTERVAL '1 year'
        ELSE CURRENT_DATE + INTERVAL '1 month'
    END,
    "status_id"
FROM RANDOM_memberships
ORDER BY "member_id"
RETURNING *;

-- Vladyslav Pylypenko
INSERT INTO gym.class_specializations ("name", "description")
VALUES
    ('yoga', 'A class focused on breathing exercises and physical postures for flexibility and relaxation.'),
    ('spinning', 'A high-intensity indoor cycling workout that simulates outdoor cycling terrain.'),
    ('pilates', 'A low-impact class that focuses on strengthening muscles while improving postural alignment and flexibility.'),
    ('strength training', 'A workout that focuses on increasing strength through weightlifting and resistance exercises.'),
    ('zumba', 'A dance-based aerobic class that combines Latin and international music with dance moves.'),
    ('kickboxing', 'A high-intensity class combining martial arts techniques with cardio for a full-body workout.'),
    ('aerobics', 'A cardiovascular workout using rhythmic aerobic exercise to improve endurance and coordination.'),
    ('dance', 'A class focused on learning various dance styles for fitness and enjoyment.'),
    ('body combat', 'A high-energy martial arts-inspired workout that combines bodyweight exercises with punches and kicks.'),
    ('circuit training', 'A fast-paced class involving multiple exercise stations for full-body conditioning.')
RETURNING *;

INSERT INTO gym.class_types ("name")
VALUES
    ('group'),
    ('individual')
RETURNING *;

INSERT INTO gym.classes ("name", "class_type_id", "specialization_id")
VALUES
    ('Morning Yoga', (SELECT id FROM gym.class_types WHERE name = 'group'), (SELECT id FROM gym.class_specializations WHERE name = 'yoga')),
    ('Spinning Challenge', (SELECT id FROM gym.class_types WHERE name = 'group'), (SELECT id FROM gym.class_specializations WHERE name = 'spinning')),
    ('Pilates for Beginners', (SELECT id FROM gym.class_types WHERE name = 'group'), (SELECT id FROM gym.class_specializations WHERE name = 'pilates')),
    ('Strength Training Basics', (SELECT id FROM gym.class_types WHERE name = 'group'), (SELECT id FROM gym.class_specializations WHERE name = 'strength training')),
    ('Zumba Party', (SELECT id FROM gym.class_types WHERE name = 'group'), (SELECT id FROM gym.class_specializations WHERE name = 'zumba')),
    ('Kickboxing Extreme', (SELECT id FROM gym.class_types WHERE name = 'group'), (SELECT id FROM gym.class_specializations WHERE name = 'kickboxing')),
    ('Private Pilates', (SELECT id FROM gym.class_types WHERE name = 'individual'), (SELECT id FROM gym.class_specializations WHERE name = 'pilates')),
    ('Aerobics Dance', (SELECT id FROM gym.class_types WHERE name = 'group'), (SELECT id FROM gym.class_specializations WHERE name = 'aerobics')),
    ('Body Combat Session', (SELECT id FROM gym.class_types WHERE name = 'group'), (SELECT id FROM gym.class_specializations WHERE name = 'body combat')),
    ('Circuit Training Challenge', (SELECT id FROM gym.class_types WHERE name = 'group'), (SELECT id FROM gym.class_specializations WHERE name = 'circuit training')),
    ('Dance Fitness', (SELECT id FROM gym.class_types WHERE name = 'group'), (SELECT id FROM gym.class_specializations WHERE name = 'dance'))  
RETURNING *;

INSERT INTO gym.halls ("name", "capacity")
VALUES
    ('Cardio Zone', 30),
    ('Strength Arena', 40),
    ('Yoga Studio', 25),
    ('Cycling Room', 50),
    ('Pilates Studio', 35),
    ('Dance Floor', 45),
    ('Kickboxing Arena', 20),
    ('Stretching Room', 28),
    ('Martial Arts Zone', 38),
    ('Functional Training Room', 33)
RETURNING *;

INSERT INTO gym.class_schedule ("class_id", "start_time", "end_time", "hall_id", "class_date")
VALUES
    ((SELECT id FROM gym.classes WHERE name = 'Morning Yoga'), '08:00', '09:00', (SELECT id FROM gym.halls WHERE name = 'Yoga Studio'), '2025-04-10'),
    ((SELECT id FROM gym.classes WHERE name = 'Spinning Challenge'), '09:00', '10:00', (SELECT id FROM gym.halls WHERE name = 'Cycling Room'), '2025-04-11'),
    ((SELECT id FROM gym.classes WHERE name = 'Pilates for Beginners'), '10:00', '11:00', (SELECT id FROM gym.halls WHERE name = 'Pilates Studio'), '2025-04-12'),
    ((SELECT id FROM gym.classes WHERE name = 'Strength Training Basics'), '11:00', '12:00', (SELECT id FROM gym.halls WHERE name = 'Strength Arena'), '2025-04-13'),
    ((SELECT id FROM gym.classes WHERE name = 'Zumba Party'), '12:00', '13:00', (SELECT id FROM gym.halls WHERE name = 'Dance Floor'), '2025-04-14'),
    ((SELECT id FROM gym.classes WHERE name = 'Kickboxing Extreme'), '13:00', '14:00', (SELECT id FROM gym.halls WHERE name = 'Kickboxing Arena'), '2025-04-15'),
    ((SELECT id FROM gym.classes WHERE name = 'Private Pilates'), '14:00', '15:00', (SELECT id FROM gym.halls WHERE name = 'Pilates Studio'), '2025-04-16'),
    ((SELECT id FROM gym.classes WHERE name = 'Aerobics Dance'), '15:00', '16:00', (SELECT id FROM gym.halls WHERE name = 'Dance Floor'), '2025-04-17'),
    ((SELECT id FROM gym.classes WHERE name = 'Body Combat Session'), '16:00', '17:00', (SELECT id FROM gym.halls WHERE name = 'Martial Arts Zone'), '2025-04-18'),
    ((SELECT id FROM gym.classes WHERE name = 'Circuit Training Challenge'), '17:00', '18:00', (SELECT id FROM gym.halls WHERE name = 'Functional Training Room'), '2025-04-19'),
    ((SELECT id FROM gym.classes WHERE name = 'Morning Yoga'), '08:00', '09:00', (SELECT id FROM gym.halls WHERE name = 'Yoga Studio'), '2025-04-20'),
    ((SELECT id FROM gym.classes WHERE name = 'Spinning Challenge'), '09:00', '10:00', (SELECT id FROM gym.halls WHERE name = 'Cycling Room'), '2025-04-21'),
    ((SELECT id FROM gym.classes WHERE name = 'Pilates for Beginners'), '10:00', '11:00', (SELECT id FROM gym.halls WHERE name = 'Pilates Studio'), '2025-04-22'),
    ((SELECT id FROM gym.classes WHERE name = 'Strength Training Basics'), '11:00', '12:00', (SELECT id FROM gym.halls WHERE name = 'Strength Arena'), '2025-04-23'),
    ((SELECT id FROM gym.classes WHERE name = 'Zumba Party'), '12:00', '13:00', (SELECT id FROM gym.halls WHERE name = 'Dance Floor'), '2025-04-24'),
    ((SELECT id FROM gym.classes WHERE name = 'Kickboxing Extreme'), '13:00', '14:00', (SELECT id FROM gym.halls WHERE name = 'Kickboxing Arena'), '2025-04-25'),
    ((SELECT id FROM gym.classes WHERE name = 'Private Pilates'), '14:00', '15:00', (SELECT id FROM gym.halls WHERE name = 'Pilates Studio'), '2025-04-26'),
    ((SELECT id FROM gym.classes WHERE name = 'Aerobics Dance'), '15:00', '16:00', (SELECT id FROM gym.halls WHERE name = 'Dance Floor'), '2025-04-27'),
    ((SELECT id FROM gym.classes WHERE name = 'Body Combat Session'), '16:00', '17:00', (SELECT id FROM gym.halls WHERE name = 'Martial Arts Zone'), '2025-04-28')
RETURNING *;

WITH class_ids AS (
    SELECT "id" AS class_id FROM gym.classes
),
hall_ids AS (
    SELECT "id" AS hall_id FROM gym.halls
),
dates AS (
    SELECT generate_series('2025-05-01'::DATE, '2025-05-30'::DATE, '1 day') AS class_date
),
time_slots AS (
    SELECT *
    FROM (
        VALUES
            ('08:00'::TIME, '09:00'::TIME),
            ('09:00', '10:00'),
            ('10:00', '11:00'),
            ('11:00', '12:00'),
            ('12:00', '13:00'),
            ('13:00', '14:00'),
            ('14:00', '15:00'),
            ('15:00', '16:00')
    ) AS slot(start_time, end_time)
),
combined AS (
    SELECT
        c.class_id,
        h.hall_id,
        d.class_date,
        t.start_time,
        t.end_time
    FROM class_ids c
    JOIN hall_ids h ON c.class_id % 5 = h.hall_id % 5
    JOIN dates d ON true
    JOIN time_slots t ON true
),
filtered AS (
    SELECT *
    FROM combined
    WHERE NOT EXISTS (
        SELECT 1
        FROM gym.class_schedule cs
        WHERE cs.class_id = combined.class_id
          AND cs.hall_id = combined.hall_id
          AND cs.class_date = combined.class_date
          AND cs.start_time = combined.start_time
    )
    ORDER BY RANDOM()
    LIMIT 30
)
INSERT INTO gym.class_schedule ("class_id", "start_time", "end_time", "hall_id", "class_date")
SELECT
    class_id,
    start_time,
    end_time,
    hall_id,
    class_date
FROM filtered
RETURNING *;

INSERT INTO gym.attendance ("member_id", "class_schedule_id", "attended")
VALUES
    (1, 1, TRUE),
    (2, 2, FALSE),
    (3, 3, TRUE),
    (4, 4, FALSE),
    (5, 5, TRUE),
    (6, 6, FALSE),
    (7, 7, TRUE),
    (8, 8, TRUE),
    (9, 9, FALSE),
    (10, 10, TRUE)
RETURNING *;

WITH schedule AS (
    SELECT id AS class_schedule_id, ROW_NUMBER() OVER (ORDER BY RANDOM()) AS row_num
    FROM gym.class_schedule
    LIMIT 30
),
members AS (
    SELECT generate_series(11, 40) AS member_id
),
attendance_candidates AS (
    SELECT
        m.member_id,
        s.class_schedule_id,
        (RANDOM() > 0.5) AS attended
    FROM members m
    JOIN schedule s
        ON (m.member_id - 11) + 1 = s.row_num
)
INSERT INTO gym.attendance ("member_id", "class_schedule_id", "attended")
SELECT ac.*
FROM attendance_candidates ac
LEFT JOIN gym.attendance a
    ON a.member_id = ac.member_id AND a.class_schedule_id = ac.class_schedule_id
WHERE a.member_id IS NULL  
RETURNING *;

INSERT INTO gym.booking_statuses ("name", "notes")
VALUES
    ('pending', 'Booking is pending confirmation'),
    ('confirmed', 'Booking is confirmed and scheduled'),
    ('cancelled', 'Booking has been cancelled')
RETURNING *;

INSERT INTO gym.bookings ("member_id", "class_schedule_id", "status_id", "cancellation_reason", "booking_date")
VALUES
    (1, 1, (SELECT id FROM gym.booking_statuses WHERE name = 'confirmed'), NULL, '2025-04-10 08:30:00'),
    (2, 2, (SELECT id FROM gym.booking_statuses WHERE name = 'pending'), NULL, '2025-04-11 09:45:00'),
    (3, 3, (SELECT id FROM gym.booking_statuses WHERE name = 'cancelled'), 'Personal reason', '2025-04-12 10:00:00'),
    (4, 4, (SELECT id FROM gym.booking_statuses WHERE name = 'confirmed'), NULL, '2025-04-13 11:15:00'),
    (5, 5, (SELECT id FROM gym.booking_statuses WHERE name = 'pending'), NULL, '2025-04-14 12:30:00'),
    (6, 6, (SELECT id FROM gym.booking_statuses WHERE name = 'confirmed'), NULL, '2025-04-15 13:45:00'),
    (7, 7, (SELECT id FROM gym.booking_statuses WHERE name = 'cancelled'), 'Conflict with another class', '2025-04-16 14:00:00'),
    (8, 8, (SELECT id FROM gym.booking_statuses WHERE name = 'confirmed'), NULL, '2025-04-17 15:30:00'),
    (9, 9, (SELECT id FROM gym.booking_statuses WHERE name = 'pending'), NULL, '2025-04-18 16:00:00'),
    (10, 10, (SELECT id FROM gym.booking_statuses WHERE name = 'cancelled'), 'Health issues', '2025-04-19 17:30:00'),
    (1, 11, (SELECT id FROM gym.booking_statuses WHERE name = 'confirmed'), NULL, '2025-04-20 18:45:00'),
    (2, 12, (SELECT id FROM gym.booking_statuses WHERE name = 'pending'), NULL, '2025-04-21 19:00:00'),
    (3, 13, (SELECT id FROM gym.booking_statuses WHERE name = 'cancelled'), 'Personal reason', '2025-04-22 20:30:00'),
    (4, 14, (SELECT id FROM gym.booking_statuses WHERE name = 'confirmed'), NULL, '2025-04-23 21:45:00'),
    (5, 15, (SELECT id FROM gym.booking_statuses WHERE name = 'pending'), NULL, '2025-04-24 22:00:00'),
    (6, 16, (SELECT id FROM gym.booking_statuses WHERE name = 'confirmed'), NULL, '2025-04-25 23:30:00'),
    (7, 17, (SELECT id FROM gym.booking_statuses WHERE name = 'cancelled'), 'Conflict with another class', '2025-04-26 08:00:00'),
    (8, 18, (SELECT id FROM gym.booking_statuses WHERE name = 'confirmed'), NULL, '2025-04-27 09:30:00'),
    (9, 19, (SELECT id FROM gym.booking_statuses WHERE name = 'pending'), NULL, '2025-04-28 10:15:00'),
    (10, 20, (SELECT id FROM gym.booking_statuses WHERE name = 'cancelled'), 'Health issues', '2025-04-29 11:00:00')
RETURNING *;

WITH class_schedule_data AS (
    SELECT cs.id AS class_schedule_id, cs.class_date, cs.start_time, cs.end_time
    FROM gym.class_schedule cs
    WHERE cs.class_date >= CURRENT_DATE
),
member_booking_data AS (
    SELECT 
        m.id AS member_id,
        cs.class_schedule_id,
        cs.class_date,
        bs.id AS status_id,
        CASE 
            WHEN bs.name = 'cancelled' THEN 
                (ARRAY['Personal reason', 'Health issues', 'Conflict with another class'])[FLOOR(RANDOM() * 3 + 1)]
            ELSE NULL
        END AS cancellation_reason,
        (cs.class_date - INTERVAL '5 days') + 
        (FLOOR(RANDOM() * 6) * INTERVAL '1 day') +  
        (FLOOR(RANDOM() * 12) * INTERVAL '1 hour') + 
        (FLOOR(RANDOM() * 4) * INTERVAL '15 minutes') 
        AS booking_date
    FROM gym.members m
    JOIN class_schedule_data cs ON true
    JOIN gym.booking_statuses bs ON true
    WHERE m.id >= 11
    ORDER BY m.id, RANDOM()
),
numbered AS (
    SELECT 
        DISTINCT ON (member_id, class_schedule_id) 
        member_id, 
        class_schedule_id, 
        status_id, 
        cancellation_reason,
        booking_date,
        ROW_NUMBER() OVER (PARTITION BY member_id ORDER BY RANDOM()) AS rn
    FROM member_booking_data
)
INSERT INTO gym.bookings ("member_id", "class_schedule_id", "status_id", "cancellation_reason", "booking_date")
SELECT 
    member_id, 
    class_schedule_id, 
    status_id, 
    cancellation_reason,
    booking_date
FROM numbered
WHERE rn <= 2
RETURNING *;

-- Oleksii Zakharchuk
INSERT INTO gym.equipment_conditions ("name") 
VALUES 
    ('brand new'),
    ('excellent'),
    ('very good'),
    ('good'),
    ('fair'),
    ('needs maintenance'),
    ('under inspection'),
    ('being repaired'),
    ('out of order'),
    ('decommissioned')
RETURNING *;

INSERT INTO gym.equipment_statuses ("name") 
VALUES 
    ('available'),
    ('in use'),
    ('reserved'),
    ('in queue'),
    ('cleaning in progress'),
    ('under maintenance'),
    ('awaiting parts'),
    ('testing mode'),
    ('out of service'),
    ('retired')
RETURNING *;

INSERT INTO gym.equipment ("name", "condition_id", "status_id", "hall_id") 
VALUES
    ('Treadmill', (SELECT id FROM gym.equipment_conditions WHERE name = 'excellent'), (SELECT id FROM gym.equipment_statuses WHERE name = 'available'), (SELECT id FROM gym.halls WHERE name = 'Cardio Zone')),
    ('Elliptical Trainer', (SELECT id FROM gym.equipment_conditions WHERE name = 'brand new'), (SELECT id FROM gym.equipment_statuses WHERE name = 'available'), (SELECT id FROM gym.halls WHERE name = 'Cardio Zone')),
    ('Barbell', (SELECT id FROM gym.equipment_conditions WHERE name = 'very good'), (SELECT id FROM gym.equipment_statuses WHERE name = 'in use'), (SELECT id FROM gym.halls WHERE name = 'Strength Arena')),
    ('Bench Press', (SELECT id FROM gym.equipment_conditions WHERE name = 'good'), (SELECT id FROM gym.equipment_statuses WHERE name = 'available'), (SELECT id FROM gym.halls WHERE name = 'Strength Arena')),
    ('Yoga Mat', (SELECT id FROM gym.equipment_conditions WHERE name = 'brand new'), (SELECT id FROM gym.equipment_statuses WHERE name = 'available'), (SELECT id FROM gym.halls WHERE name = 'Yoga Studio')),
    ('Foam Roller', (SELECT id FROM gym.equipment_conditions WHERE name = 'good'), (SELECT id FROM gym.equipment_statuses WHERE name = 'available'), (SELECT id FROM gym.halls WHERE name = 'Yoga Studio')),
    ('Spin Bike', (SELECT id FROM gym.equipment_conditions WHERE name = 'very good'), (SELECT id FROM gym.equipment_statuses WHERE name = 'in use'), (SELECT id FROM gym.halls WHERE name = 'Cycling Room')),
    ('Pilates Reformer', (SELECT id FROM gym.equipment_conditions WHERE name = 'fair'), (SELECT id FROM gym.equipment_statuses WHERE name = 'under maintenance'), (SELECT id FROM gym.halls WHERE name = 'Pilates Studio')),
    ('Punching Bag', (SELECT id FROM gym.equipment_conditions WHERE name = 'excellent'), (SELECT id FROM gym.equipment_statuses WHERE name = 'available'), (SELECT id FROM gym.halls WHERE name = 'Kickboxing Arena')),
    ('TRX Bands', (SELECT id FROM gym.equipment_conditions WHERE name = 'good'), (SELECT id FROM gym.equipment_statuses WHERE name = 'available'), (SELECT id FROM gym.halls WHERE name = 'Functional Training Room'))
RETURNING *;

INSERT INTO gym.equipment ("name", "condition_id", "status_id", "hall_id")
VALUES
    -- Cardio Zone
    ('Treadmill', (SELECT id FROM gym.equipment_conditions ORDER BY RANDOM() LIMIT 1),
                (SELECT id FROM gym.equipment_statuses ORDER BY RANDOM() LIMIT 1),
                (SELECT id FROM gym.halls WHERE "name" = 'Cardio Zone')),
    ('Elliptical Trainer', (SELECT id FROM gym.equipment_conditions ORDER BY RANDOM() LIMIT 1),
                        (SELECT id FROM gym.equipment_statuses ORDER BY RANDOM() LIMIT 1),
                        (SELECT id FROM gym.halls WHERE "name" = 'Cardio Zone')),
    ('Rowing Machine', (SELECT id FROM gym.equipment_conditions ORDER BY RANDOM() LIMIT 1),
                    (SELECT id FROM gym.equipment_statuses ORDER BY RANDOM() LIMIT 1),
                    (SELECT id FROM gym.halls WHERE "name" = 'Cardio Zone')),

    -- Strength Arena
    ('Bench Press', (SELECT id FROM gym.equipment_conditions ORDER BY RANDOM() LIMIT 1),
                    (SELECT id FROM gym.equipment_statuses ORDER BY RANDOM() LIMIT 1),
                    (SELECT id FROM gym.halls WHERE "name" = 'Strength Arena')),
    ('Leg Press Machine', (SELECT id FROM gym.equipment_conditions ORDER BY RANDOM() LIMIT 1),
                        (SELECT id FROM gym.equipment_statuses ORDER BY RANDOM() LIMIT 1),
                        (SELECT id FROM gym.halls WHERE "name" = 'Strength Arena')),
    ('Squat Rack', (SELECT id FROM gym.equipment_conditions ORDER BY RANDOM() LIMIT 1),
                (SELECT id FROM gym.equipment_statuses ORDER BY RANDOM() LIMIT 1),
                (SELECT id FROM gym.halls WHERE "name" = 'Strength Arena')),

    -- Yoga Studio
    ('Yoga Mats', (SELECT id FROM gym.equipment_conditions ORDER BY RANDOM() LIMIT 1),
                (SELECT id FROM gym.equipment_statuses ORDER BY RANDOM() LIMIT 1),
                (SELECT id FROM gym.halls WHERE "name" = 'Yoga Studio')),
    ('Blocks & Straps', (SELECT id FROM gym.equipment_conditions ORDER BY RANDOM() LIMIT 1),
                        (SELECT id FROM gym.equipment_statuses ORDER BY RANDOM() LIMIT 1),
                        (SELECT id FROM gym.halls WHERE "name" = 'Yoga Studio')),
    ('Meditation Cushions', (SELECT id FROM gym.equipment_conditions ORDER BY RANDOM() LIMIT 1),
                            (SELECT id FROM gym.equipment_statuses ORDER BY RANDOM() LIMIT 1),
                            (SELECT id FROM gym.halls WHERE "name" = 'Yoga Studio')),

    -- Cycling Room
    ('Exercise Bike', (SELECT id FROM gym.equipment_conditions ORDER BY RANDOM() LIMIT 1),
                    (SELECT id FROM gym.equipment_statuses ORDER BY RANDOM() LIMIT 1),
                    (SELECT id FROM gym.halls WHERE "name" = 'Cycling Room')),
    ('Heart Rate Monitor', (SELECT id FROM gym.equipment_conditions ORDER BY RANDOM() LIMIT 1),
                            (SELECT id FROM gym.equipment_statuses ORDER BY RANDOM() LIMIT 1),
                            (SELECT id FROM gym.halls WHERE "name" = 'Cycling Room')),
    ('Speed Sensor', (SELECT id FROM gym.equipment_conditions ORDER BY RANDOM() LIMIT 1),
                    (SELECT id FROM gym.equipment_statuses ORDER BY RANDOM() LIMIT 1),
                    (SELECT id FROM gym.halls WHERE "name" = 'Cycling Room')),

    -- Pilates Studio
    ('Reformer Machine', (SELECT id FROM gym.equipment_conditions ORDER BY RANDOM() LIMIT 1),
                        (SELECT id FROM gym.equipment_statuses ORDER BY RANDOM() LIMIT 1),
                        (SELECT id FROM gym.halls WHERE "name" = 'Pilates Studio')),
    ('Pilates Ring', (SELECT id FROM gym.equipment_conditions ORDER BY RANDOM() LIMIT 1),
                    (SELECT id FROM gym.equipment_statuses ORDER BY RANDOM() LIMIT 1),
                    (SELECT id FROM gym.halls WHERE "name" = 'Pilates Studio')),
    ('Resistance Bands', (SELECT id FROM gym.equipment_conditions ORDER BY RANDOM() LIMIT 1),
                        (SELECT id FROM gym.equipment_statuses ORDER BY RANDOM() LIMIT 1),
                        (SELECT id FROM gym.halls WHERE "name" = 'Pilates Studio')),

    -- Dance Floor
    ('Sound System', (SELECT id FROM gym.equipment_conditions ORDER BY RANDOM() LIMIT 1),
                    (SELECT id FROM gym.equipment_statuses ORDER BY RANDOM() LIMIT 1),
                    (SELECT id FROM gym.halls WHERE "name" = 'Dance Floor')),
    ('Mirrored Wall', (SELECT id FROM gym.equipment_conditions ORDER BY RANDOM() LIMIT 1),
                    (SELECT id FROM gym.equipment_statuses ORDER BY RANDOM() LIMIT 1),
                    (SELECT id FROM gym.halls WHERE "name" = 'Dance Floor')),
    ('Dance Barres', (SELECT id FROM gym.equipment_conditions ORDER BY RANDOM() LIMIT 1),
                    (SELECT id FROM gym.equipment_statuses ORDER BY RANDOM() LIMIT 1),
                    (SELECT id FROM gym.halls WHERE "name" = 'Dance Floor')),

    -- Kickboxing Arena
    ('Punching Bag', (SELECT id FROM gym.equipment_conditions ORDER BY RANDOM() LIMIT 1),
                    (SELECT id FROM gym.equipment_statuses ORDER BY RANDOM() LIMIT 1),
                    (SELECT id FROM gym.halls WHERE "name" = 'Kickboxing Arena')),
    ('Speed Bag', (SELECT id FROM gym.equipment_conditions ORDER BY RANDOM() LIMIT 1),
                (SELECT id FROM gym.equipment_statuses ORDER BY RANDOM() LIMIT 1),
                (SELECT id FROM gym.halls WHERE "name" = 'Kickboxing Arena')),
    ('Kick Pads', (SELECT id FROM gym.equipment_conditions ORDER BY RANDOM() LIMIT 1),
                (SELECT id FROM gym.equipment_statuses ORDER BY RANDOM() LIMIT 1),
                (SELECT id FROM gym.halls WHERE "name" = 'Kickboxing Arena')),

    -- Stretching Room
    ('Foam Roller', (SELECT id FROM gym.equipment_conditions ORDER BY RANDOM() LIMIT 1),
                    (SELECT id FROM gym.equipment_statuses ORDER BY RANDOM() LIMIT 1),
                    (SELECT id FROM gym.halls WHERE "name" = 'Stretching Room')),
    ('Stretching Mat', (SELECT id FROM gym.equipment_conditions ORDER BY RANDOM() LIMIT 1),
                    (SELECT id FROM gym.equipment_statuses ORDER BY RANDOM() LIMIT 1),
                    (SELECT id FROM gym.halls WHERE "name" = 'Stretching Room')),
    ('Resistance Bands', (SELECT id FROM gym.equipment_conditions ORDER BY RANDOM() LIMIT 1),
                        (SELECT id FROM gym.equipment_statuses ORDER BY RANDOM() LIMIT 1),
                        (SELECT id FROM gym.halls WHERE "name" = 'Stretching Room')),

    -- Martial Arts Zone
    ('Mats', (SELECT id FROM gym.equipment_conditions ORDER BY RANDOM() LIMIT 1),
            (SELECT id FROM gym.equipment_statuses ORDER BY RANDOM() LIMIT 1),
            (SELECT id FROM gym.halls WHERE "name" = 'Martial Arts Zone')),
    ('Headgear', (SELECT id FROM gym.equipment_conditions ORDER BY RANDOM() LIMIT 1),
                (SELECT id FROM gym.equipment_statuses ORDER BY RANDOM() LIMIT 1),
                (SELECT id FROM gym.halls WHERE "name" = 'Martial Arts Zone')),
    ('Gloves', (SELECT id FROM gym.equipment_conditions ORDER BY RANDOM() LIMIT 1),
            (SELECT id FROM gym.equipment_statuses ORDER BY RANDOM() LIMIT 1),
            (SELECT id FROM gym.halls WHERE "name" = 'Martial Arts Zone')),

    -- Functional Training Room
    ('Battle Ropes', (SELECT id FROM gym.equipment_conditions ORDER BY RANDOM() LIMIT 1),
                    (SELECT id FROM gym.equipment_statuses ORDER BY RANDOM() LIMIT 1),
                    (SELECT id FROM gym.halls WHERE "name" = 'Functional Training Room')),
    ('TRX Suspension', (SELECT id FROM gym.equipment_conditions ORDER BY RANDOM() LIMIT 1),
                    (SELECT id FROM gym.equipment_statuses ORDER BY RANDOM() LIMIT 1),
                    (SELECT id FROM gym.halls WHERE "name" = 'Functional Training Room')),
    ('Plyo Box', (SELECT id FROM gym.equipment_conditions ORDER BY RANDOM() LIMIT 1),
                (SELECT id FROM gym.equipment_statuses ORDER BY RANDOM() LIMIT 1),
                (SELECT id FROM gym.halls WHERE "name" = 'Functional Training Room'))
RETURNING *;

WITH RANDOM_performers AS (
  SELECT 
    performer, 
    ROW_NUMBER() OVER () AS rn
  FROM (
    SELECT UNNEST(array[
      'Andrii Shevchenko', 'Oleksandr Melnyk', 'Ivan Kovalenko', 
      'Yurii Tarasenko', 'Dmytro Petrenko'
    ]) AS performer
    ORDER BY RANDOM()
  ) sub
),
RANDOM_data AS (
  SELECT 
    equipment_id,
    (CURRENT_DATE - (TRUNC(RANDOM() * 1460))::INT)::DATE AS maintenance_date,
    note,
    ROW_NUMBER() OVER () AS rn
  FROM (
    VALUES
      (1, 'Replaced the worn-out pedals and adjusted the resistance mechanism.'),
      (2, 'Lubricated the moving parts and calibrated the console.'),
      (3, 'Fixed the belt tension and ensured the flywheel runs quietly.'),
      (4, 'Replaced the seat cushion and tightened all bolts.'),
      (5, 'Repaired the resistance knob and replaced the worn-out pedals.'),
      (6, 'Replaced the damaged seat and checked the alignment of the pedals.'),
      (7, 'Lubricated the chain mechanism and tightened the screws.'),
      (8, 'Replaced the worn-out grips on the barbell.'),
      (9, 'Replaced the belt and motor, recalibrated the speed settings.'),
      (10, 'Repaired the display screen and adjusted the resistance settings.'),
      (11, 'Replaced the worn-out pedals and adjusted the resistance mechanism. The trainer is now functioning smoothly.'),
      (12, 'Lubricated the moving parts and calibrated the console. Everything is working properly now.'),
      (13, 'Fixed the belt tension and ensured the flywheel runs quietly. Tested for performance and stability.'),
      (14, 'Replaced the seat cushion and tightened all bolts. The machine is stable and ready for use.'),
      (15, 'Repaired the resistance knob and replaced the worn-out pedals. Everything is functioning correctly.'),
      (16, 'Replaced the damaged seat and checked the alignment of the pedals. The bike is now in excellent working condition.'),
      (17, 'Lubricated the chain mechanism and tightened the screws. The bike is ready for use without any issues.'),
      (18, 'Replaced the worn-out grips on the barbell. It’s now ready for heavy-duty use in the gym.'),
      (19, 'Replaced the belt and motor, recalibrated the speed settings. The treadmill is now running smoothly.'),
      (20, 'Repaired the display screen and adjusted the resistance settings. The bike is fully operational again.'),
      (21, 'Replaced the damaged foam cover and tightened the handlebar. All functions are working as expected.'),
      (22, 'Recalibrated the resistance settings and replaced the malfunctioning sensor.'),
      (23, 'Lubricated and tightened the foot pedals. The equipment is now operating smoothly.'),
      (24, 'Replaced the faulty display and updated the software.'),
      (25, 'Repaired the hand grips and adjusted the resistance knobs.'),
      (26, 'Checked and repaired the pedal mechanism and updated the software for better performance.'),
      (27, 'Replaced the broken flywheel and tightened the belt tension.'),
      (28, 'Recalibrated the monitor and replaced the control panel.'),
      (29, 'Replaced the sensors and adjusted the braking system.'),
      (30, 'Fixed the alignment of the barbell rack and lubricated the moving parts.'),
      (31, 'Lubricated the joints and replaced the worn-out cables for smoother operation.'),
      (32, 'Fixed the tension in the handles and recalibrated the foot pedals.'),
      (33, 'Replaced the motor and adjusted the settings for smoother operation.'),
      (34, 'Repaired the seat and recalibrated the tension system for improved performance.'),
      (35, 'Replaced the handlebar and adjusted the resistance system.'),
      (36, 'Replaced the seat cushion and tightened all bolts for better stability.'),
      (37, 'Replaced the pedals and updated the resistance settings for better functionality.'),
      (38, 'Lubricated the handle and checked all bolts.'),
      (39, 'Replaced the worn-out grip and checked the overall performance of the equipment.'),
      (40, 'Replaced the damaged pedal mechanism and checked all wiring.')
  ) AS t(equipment_id, note)
)
INSERT INTO gym.maintenance_history ("equipment_id", "maintenance_date", "performed_by", "notes")
SELECT
  d.equipment_id,
  d.maintenance_date,
  p.performer,
  d.note
FROM RANDOM_data d
JOIN RANDOM_performers p ON d.rn % 5 + 1 = p.rn  
RETURNING *;

-- Danil Trunov
INSERT INTO gym.feedback_equipment ("member_id", "equipment_id", "rating", "notes", "created_at")
VALUES 
    (1, 1, 5, 'Great equipment, works perfectly.', '2025-04-10'),
    (2, 2, 4, 'Good, but could use some maintenance.', '2025-04-09'),
    (3, 3, 3, 'Average, not very durable.', '2025-04-08'),
    (4, 4, 5, 'Excellent, really helped with my workout.', '2025-04-07'),
    (5, 5, 4, 'Good condition, but could be improved.', '2025-04-06'),
    (6, 6, 2, 'Broken after one use, needs repair.', '2025-04-05'),
    (7, 7, 5, 'Perfect for my training, highly recommend.', '2025-04-04'),
    (8, 8, 4, 'Solid equipment, a bit worn out though.', '2025-04-03'),
    (9, 9, 3, 'Works fine, but could be more comfortable.', '2025-04-02'),
    (10, 10, 5, 'Amazing, best equipment I have used.', '2025-04-01'),
    (1, 2, 4, 'Still in good condition, some minor issues.', '2025-03-31'),
    (2, 3, 3, 'It’s fine, but not as good as expected.', '2025-03-30'),
    (3, 4, 5, 'Very good equipment, never disappoints.', '2025-03-29'),
    (4, 5, 2, 'Not working as expected, needs repairs.', '2025-03-28'),
    (5, 6, 4, 'Good equipment, works well.', '2025-03-27'),
    (6, 7, 3, 'It could be better, but it’s okay.', '2025-03-26'),
    (7, 8, 5, 'Absolutely love this equipment, no issues.', '2025-03-25'),
    (8, 9, 4, 'Great overall, but some parts need cleaning.', '2025-03-24'),
    (9, 10, 1, 'It broke down after one use, very disappointing.', '2025-03-23'),
    (10, 1, 4, 'Good, but some maintenance is required.', '2025-03-22')
RETURNING *;

WITH unique_pairs AS (
    SELECT
        temp.member_id,
        FLOOR(RANDOM() * (40 - 11 + 1)) + 11 AS equipment_id,
        temp.rating
    FROM
        (SELECT generate_series(11, 40) AS member_id, FLOOR(RANDOM() * (5 - 1 + 1)) + 1 AS rating) AS temp
    WHERE NOT EXISTS (
        SELECT 1 
        FROM gym.feedback_equipment fe
        WHERE fe.member_id = temp.member_id
        AND fe.equipment_id = FLOOR(RANDOM() * (40 - 11 + 1)) + 11
    )
    ORDER BY RANDOM()
    LIMIT 60
), generated_feedback AS (
    SELECT
        up.member_id,
        up.equipment_id,
        up.rating,
        CASE 
            WHEN up.rating = 5 THEN 
                (ARRAY['Outstanding performance, keep it up!', 
                       'Amazing quality, highly recommended!', 
                       'Very effective, love this equipment!', 
                       'Best decision for my workouts!', 
                       'Exceptional, would buy again!'])[FLOOR(RANDOM() * 5)]
            WHEN up.rating = 4 THEN 
                (ARRAY['Good quality, served me well.', 
                       'Very reliable, no issues so far.', 
                       'Solid equipment, met my expectations.',
                       'Works well, but minor issues exist.',
                       'Good performance overall.'])[FLOOR(RANDOM() * 5)]
            WHEN up.rating = 3 THEN 
                (ARRAY['Average, not as great as expected.', 
                       'It’s okay, but could use some work.', 
                       'Decent, serves its purpose.', 
                       'Works fine but not impressive.', 
                       'Just satisfactory, nothing more.'])[FLOOR(RANDOM() * 5)]
            WHEN up.rating = 2 THEN 
                (ARRAY['Could be better, had some issues.', 
                       'Not very useful, needs improvement.', 
                       'Not great quality, disappointed.',
                       'Couldn’t meet my expectations.', 
                       'Problems occurred, needs repairs.'])[FLOOR(RANDOM() * 5)]
            WHEN up.rating = 1 THEN 
                (ARRAY['Very disappointing, does not meet my needs.', 
                       'Broken after first use, very frustrating.', 
                       'Not worth the money, would not recommend.', 
                       'Failed to work properly from start.', 
                       'Unexpectedly poor quality.'])[FLOOR(RANDOM() * 5)]
        END AS notes,
        NOW() - (RANDOM() * INTERVAL '30 days') AS created_at
    FROM unique_pairs up
)
INSERT INTO gym.feedback_equipment ("member_id", "equipment_id", "rating", "notes", "created_at")
SELECT * FROM generated_feedback
RETURNING *;

INSERT INTO gym.member_preferred_training_time ("member_id", "start_time", "end_time", "day_of_week", "priority")
VALUES
    (1, '06:00', '07:00', 'Monday', 1),
    (1, '18:00', '19:00', 'Wednesday', 2),
    (2, '07:00', '08:00', 'Monday', 1),
    (2, '12:00', '13:00', 'Friday', 2),
    (3, '08:00', '09:00', 'Tuesday', 1),
    (3, '17:00', '18:00', 'Thursday', 2),
    (4, '09:00', '10:00', 'Monday', 1),
    (4, '13:00', '14:00', 'Wednesday', 2),
    (5, '10:00', '11:00', 'Tuesday', 1),
    (5, '15:00', '16:00', 'Friday', 2),
    (6, '06:30', '07:30', 'Monday', 1),
    (6, '19:00', '20:00', 'Thursday', 2),
    (7, '11:00', '12:00', 'Wednesday', 1),
    (7, '14:00', '15:00', 'Friday', 2),
    (8, '07:30', '08:30', 'Monday', 1),
    (8, '16:00', '17:00', 'Tuesday', 2),
    (9, '08:30', '09:30', 'Thursday', 1),
    (9, '13:30', '14:30', 'Friday', 2),
    (10, '09:30', '10:30', 'Monday', 1),
    (10, '14:30', '15:30', 'Wednesday', 2)
RETURNING *;

INSERT INTO gym.member_preferred_training_time ("member_id", "start_time", "end_time", "day_of_week", "priority")
SELECT 
    member_id,
    start_time::TIME,
    end_time::TIME,
    day_of_week,
    priority
FROM (
    SELECT 
        member_id,
        CASE 
            WHEN FLOOR(RANDOM() * 5) = 0 THEN '06:00'
            WHEN FLOOR(RANDOM() * 5) = 1 THEN '07:00'
            WHEN FLOOR(RANDOM() * 5) = 2 THEN '08:00'
            WHEN FLOOR(RANDOM() * 5) = 3 THEN '09:00'
            ELSE '10:00'
        END AS start_time,
        CASE 
            WHEN FLOOR(RANDOM() * 5) = 0 THEN '07:00'
            WHEN FLOOR(RANDOM() * 5) = 1 THEN '08:00'
            WHEN FLOOR(RANDOM() * 5) = 2 THEN '09:00'
            WHEN FLOOR(RANDOM() * 5) = 3 THEN '10:00'
            ELSE '11:00'
        END AS end_time,
        CASE 
            WHEN FLOOR(RANDOM() * 7) = 0 THEN 'Monday'::gym.day_of_week
            WHEN FLOOR(RANDOM() * 7) = 1 THEN 'Tuesday'::gym.day_of_week
            WHEN FLOOR(RANDOM() * 7) = 2 THEN 'Wednesday'::gym.day_of_week
            WHEN FLOOR(RANDOM() * 7) = 3 THEN 'Thursday'::gym.day_of_week
            WHEN FLOOR(RANDOM() * 7) = 4 THEN 'Friday'::gym.day_of_week
            WHEN FLOOR(RANDOM() * 7) = 5 THEN 'Saturday'::gym.day_of_week
            ELSE 'Sunday'::gym.day_of_week
        END AS day_of_week,
        FLOOR(RANDOM() * 2) + 1 AS priority  
    FROM 
        (SELECT generate_series(11, 40) AS member_id) AS temp
) AS selections
WHERE end_time > start_time  
ORDER BY RANDOM()
LIMIT 60
RETURNING *;

-- Maksym Zymyn
INSERT INTO gym.metrics ("name", "unit", "description")
VALUES
    ('Weight', 'kg', 'The total body weight of the member'),
    ('Body Fat %', '%', 'The percentage of body fat in the member'),
    ('Muscle Mass', 'kg', 'The weight of muscle tissue in the member'),
    ('BMI', '', 'Body Mass Index, a measure of body fat based on height and weight'),
    ('Resting Heart Rate', 'bpm', 'The number of heartbeats per minute while at rest'),
    ('Max Heart Rate', 'bpm', 'The maximum number of heartbeats per minute during intense exercise'),
    ('Flexibility', 'cm', 'The range of motion of joints'),
    ('Cardio Endurance', 'km', 'Distance covered during a set period at a certain intensity'),
    ('Waist Circumference', 'cm', 'The measurement around the member''s waist'),
    ('Hip Circumference', 'cm', 'The measurement around the member''s hips'),
    ('Thigh Circumference', 'cm', 'The measurement around the member''s thigh'),
    ('Chest Circumference', 'cm', 'The measurement around the member''s chest'),
    ('Body Water %', '%', 'The percentage of water in the member''s body'),
    ('Lean Mass', 'kg', 'The weight of non-fat tissue in the body, including muscle and bone'),
    ('Strength', 'kg', 'The maximum weight a member can lift in a particular exercise')
RETURNING *;

INSERT INTO gym.health_issues ("name", "description")
VALUES
    ('Asthma', 'A condition in which a person''s airways become inflamed, narrow, and swell, causing difficulty in breathing.'),
    ('Hypertension', 'A condition where the force of the blood against the walls of the arteries is too high.'),
    ('Diabetes', 'A metabolic disease that causes high blood sugar due to the body''s inability to produce or use insulin properly.'),
    ('Obesity', 'Excessive body fat that may negatively affect one''s health.'),
    ('Chronic Back Pain', 'Long-lasting pain in the lower back, often due to muscle strain, injuries, or conditions like arthritis.'),
    ('Joint Disorders', 'Conditions that affect the joints, including arthritis and other inflammatory conditions.'),
    ('Heart Disease', 'A range of conditions that affect the heart, including coronary artery disease and heart failure.'),
    ('Stroke', 'A medical emergency where the blood supply to part of the brain is interrupted, leading to brain cell damage.'),
    ('Osteoporosis', 'A condition where bones become weak and brittle, increasing the risk of fractures.'),
    ('Anemia', 'A condition where you lack enough healthy red blood cells to carry adequate oxygen to your tissues.'),
    ('Chronic Fatigue Syndrome', 'A disorder characterized by persistent and unexplained fatigue that doesn''t improve with rest.'),
    ('Migraines', 'Intense headaches often accompanied by nausea, vomiting, and extreme sensitivity to light and sound.'),
    ('Sleep Apnea', 'A serious sleep disorder where breathing repeatedly stops and starts during sleep.'),
    ('Gastroesophageal Reflux Disease (GERD)', 'A digestive disorder where stomach acid or bile irritates the food pipe lining.'),
    ('Depression', 'A mood disorder that causes persistent feelings of sadness, loss of interest, and lack of motivation.')
RETURNING *;

INSERT INTO gym.member_health_issues ("member_id", "health_issue_id", "created_at")
VALUES
    (1, (SELECT id FROM gym.health_issues WHERE name = 'Asthma'), CURRENT_DATE - INTERVAL '1 day'),
    (2, (SELECT id FROM gym.health_issues WHERE name = 'Diabetes'), CURRENT_DATE - INTERVAL '2 day'),
    (3, (SELECT id FROM gym.health_issues WHERE name = 'Heart Disease'), CURRENT_DATE - INTERVAL '3 day'),
    (4, (SELECT id FROM gym.health_issues WHERE name = 'Hypertension'), CURRENT_DATE - INTERVAL '4 day'),
    (5, (SELECT id FROM gym.health_issues WHERE name = 'Anemia'), CURRENT_DATE - INTERVAL '5 day'),
    (6, (SELECT id FROM gym.health_issues WHERE name = 'Stroke'), CURRENT_DATE - INTERVAL '6 day'),
    (7, (SELECT id FROM gym.health_issues WHERE name = 'Joint Disorders'), CURRENT_DATE - INTERVAL '7 day'),
    (8, (SELECT id FROM gym.health_issues WHERE name = 'Obesity'), CURRENT_DATE - INTERVAL '8 day'),
    (9, (SELECT id FROM gym.health_issues WHERE name = 'Osteoporosis'), CURRENT_DATE - INTERVAL '9 day'),
    (10, (SELECT id FROM gym.health_issues WHERE name = 'Chronic Back Pain'), CURRENT_DATE - INTERVAL '10 day')
RETURNING *;

INSERT INTO gym.member_health_issues ("member_id", "health_issue_id", "created_at")
SELECT 
    member_id,
    FLOOR(RANDOM() * 15) + 1 AS health_issue_id,
    CURRENT_DATE - (FLOOR(RANDOM() * 30) + 1) * INTERVAL '1 day' AS created_at  
FROM 
    (SELECT generate_series(11, 40) AS member_id) AS temp
ORDER BY RANDOM()
LIMIT 30
RETURNING *;

INSERT INTO gym.exercises ("name", "expected_sets", "expected_reps")
VALUES
    ('Push-up', 3, 15),
    ('Pull-up', 3, 10),
    ('Squat', 4, 20),
    ('Deadlift', 4, 10),
    ('Bench Press', 4, 12),
    ('Lunges', 3, 15),
    ('Plank', 3, 60),
    ('Bicep Curl', 4, 12),
    ('Tricep Dips', 3, 15),
    ('Leg Press', 4, 12),
    ('Lat Pulldown', 3, 10),
    ('Dumbbell Row', 3, 12),
    ('Overhead Press', 4, 10),
    ('Russian Twist', 3, 20),
    ('Mountain Climbers', 3, 30),
    ('Jump Squats', 3, 15),
    ('Burpees', 4, 10),
    ('Leg Curls', 3, 15),
    ('Chest Fly', 4, 12),
    ('Cable Cross-over', 3, 12)
RETURNING *;

INSERT INTO gym.exercise_progress ("member_id", "class_schedule_id", "exercise_id", "sets", "reps", "metric_id", "exercise_metric_value", "duration", "notes")
VALUES
    (1, 1, (SELECT id FROM gym.exercises WHERE "name" = 'Push-up'), 3, 15, (SELECT id FROM gym.metrics WHERE "name" = 'Weight'), 70.50, INTERVAL '30 minutes', 'Good form'),
    (1, 2, (SELECT id FROM gym.exercises WHERE "name" = 'Pull-up'), 3, 10, (SELECT id FROM gym.metrics WHERE "name" = 'Body Fat %'), 15.30, INTERVAL '20 minutes', 'Struggled on last rep'),
    (2, 3, (SELECT id FROM gym.exercises WHERE "name" = 'Squat'), 4, 20, (SELECT id FROM gym.metrics WHERE "name" = 'Muscle Mass'), 30.00, INTERVAL '45 minutes', 'Heavy weight'),
    (2, 4, (SELECT id FROM gym.exercises WHERE "name" = 'Deadlift'), 4, 10, (SELECT id FROM gym.metrics WHERE "name" = 'BMI'), 25.40, INTERVAL '40 minutes', 'Form needs work'),
    (3, 5, (SELECT id FROM gym.exercises WHERE "name" = 'Bench Press'), 4, 12, (SELECT id FROM gym.metrics WHERE "name" = 'Resting Heart Rate'), 70.00, INTERVAL '35 minutes', 'Felt good'),
    (3, 6, (SELECT id FROM gym.exercises WHERE "name" = 'Lunges'), 3, 15, (SELECT id FROM gym.metrics WHERE "name" = 'Max Heart Rate'), 180.00, INTERVAL '25 minutes', 'Kept pace steady'),
    (4, 7, (SELECT id FROM gym.exercises WHERE "name" = 'Plank'), 3, 60, (SELECT id FROM gym.metrics WHERE "name" = 'Flexibility'), 30.00, INTERVAL '10 minutes', 'Long hold'),
    (4, 8, (SELECT id FROM gym.exercises WHERE "name" = 'Bicep Curl'), 4, 12, (SELECT id FROM gym.metrics WHERE "name" = 'Cardio Endurance'), 5.00, INTERVAL '20 minutes', 'No rest'),
    (5, 9, (SELECT id FROM gym.exercises WHERE "name" = 'Tricep Dips'), 3, 15, (SELECT id FROM gym.metrics WHERE "name" = 'Waist Circumference'), 80.00, INTERVAL '30 minutes', 'Felt tight'),
    (5, 10, (SELECT id FROM gym.exercises WHERE "name" = 'Leg Press'), 4, 12, (SELECT id FROM gym.metrics WHERE "name" = 'Hip Circumference'), 90.00, INTERVAL '50 minutes', 'Increased weight'),
    (6, 11, (SELECT id FROM gym.exercises WHERE "name" = 'Lat Pulldown'), 3, 10, (SELECT id FROM gym.metrics WHERE "name" = 'Thigh Circumference'), 55.00, INTERVAL '30 minutes', 'Maintained form'),
    (6, 12, (SELECT id FROM gym.exercises WHERE "name" = 'Dumbbell Row'), 3, 12, (SELECT id FROM gym.metrics WHERE "name" = 'Chest Circumference'), 95.00, INTERVAL '40 minutes', 'Focused on back'),
    (7, 13, (SELECT id FROM gym.exercises WHERE "name" = 'Overhead Press'), 4, 10, (SELECT id FROM gym.metrics WHERE "name" = 'Body Water %'), 60.00, INTERVAL '30 minutes', 'Core tight'),
    (7, 14, (SELECT id FROM gym.exercises WHERE "name" = 'Russian Twist'), 3, 20, (SELECT id FROM gym.metrics WHERE "name" = 'Lean Mass'), 50.00, INTERVAL '15 minutes', 'Ab focus'),
    (8, 15, (SELECT id FROM gym.exercises WHERE "name" = 'Mountain Climbers'), 3, 30, (SELECT id FROM gym.metrics WHERE "name" = 'Strength'), 100.00, INTERVAL '25 minutes', 'Fast pace'),
    (8, 16, (SELECT id FROM gym.exercises WHERE "name" = 'Jump Squats'), 3, 15, (SELECT id FROM gym.metrics WHERE "name" = 'Weight'), 75.00, INTERVAL '35 minutes', 'Good endurance'),
    (9, 17, (SELECT id FROM gym.exercises WHERE "name" = 'Burpees'), 4, 10, (SELECT id FROM gym.metrics WHERE "name" = 'Body Fat %'), 14.50, INTERVAL '40 minutes', 'Intensity high'),
    (9, 18, (SELECT id FROM gym.exercises WHERE "name" = 'Leg Curls'), 3, 15, (SELECT id FROM gym.metrics WHERE "name" = 'Muscle Mass'), 35.00, INTERVAL '30 minutes', 'Recovery time high'),
    (10, 19, (SELECT id FROM gym.exercises WHERE "name" = 'Chest Fly'), 4, 12, (SELECT id FROM gym.metrics WHERE "name" = 'BMI'), 24.50, INTERVAL '40 minutes', 'Slight strain'),
    (10, 20, (SELECT id FROM gym.exercises WHERE "name" = 'Cable Cross-over'), 3, 12, (SELECT id FROM gym.metrics WHERE "name" = 'Resting Heart Rate'), 65.00, INTERVAL '30 minutes', 'Steady pace'),
	(1, 3, (SELECT id FROM gym.exercises WHERE "name" = 'Squat'), 4, 20, (SELECT id FROM gym.metrics WHERE "name" = 'Body Water %'), 65.00, INTERVAL '45 minutes', 'Leg day'),
    (1, 4, (SELECT id FROM gym.exercises WHERE "name" = 'Deadlift'), 4, 10, (SELECT id FROM gym.metrics WHERE "name" = 'Lean Mass'), 40.00, INTERVAL '50 minutes', 'Focusing on strength'),
    (2, 5, (SELECT id FROM gym.exercises WHERE "name" = 'Bench Press'), 4, 12, (SELECT id FROM gym.metrics WHERE "name" = 'Strength'), 110.00, INTERVAL '35 minutes', 'Barbell press'),
    (2, 6, (SELECT id FROM gym.exercises WHERE "name" = 'Lunges'), 3, 15, (SELECT id FROM gym.metrics WHERE "name" = 'Weight'), 80.00, INTERVAL '30 minutes', 'Good form'),
    (3, 7, (SELECT id FROM gym.exercises WHERE "name" = 'Plank'), 3, 60, (SELECT id FROM gym.metrics WHERE "name" = 'Body Fat %'), 16.20, INTERVAL '20 minutes', 'Core strength'),
    (3, 8, (SELECT id FROM gym.exercises WHERE "name" = 'Bicep Curl'), 4, 12, (SELECT id FROM gym.metrics WHERE "name" = 'Muscle Mass'), 32.00, INTERVAL '25 minutes', 'Focus on biceps'),
    (4, 9, (SELECT id FROM gym.exercises WHERE "name" = 'Tricep Dips'), 3, 15, (SELECT id FROM gym.metrics WHERE "name" = 'BMI'), 23.50, INTERVAL '30 minutes', 'Tricep focus'),
    (4, 10, (SELECT id FROM gym.exercises WHERE "name" = 'Leg Press'), 4, 12, (SELECT id FROM gym.metrics WHERE "name" = 'Resting Heart Rate'), 60.00, INTERVAL '40 minutes', 'Low intensity'),
    (5, 11, (SELECT id FROM gym.exercises WHERE "name" = 'Lat Pulldown'), 3, 10, (SELECT id FROM gym.metrics WHERE "name" = 'Max Heart Rate'), 175.00, INTERVAL '35 minutes', 'Full pull'),
    (5, 12, (SELECT id FROM gym.exercises WHERE "name" = 'Dumbbell Row'), 3, 12, (SELECT id FROM gym.metrics WHERE "name" = 'Flexibility'), 32.00, INTERVAL '45 minutes', 'Back strengthening'),
    (6, 13, (SELECT id FROM gym.exercises WHERE "name" = 'Overhead Press'), 4, 10, (SELECT id FROM gym.metrics WHERE "name" = 'Cardio Endurance'), 6.50, INTERVAL '30 minutes', 'Pressing form'),
    (6, 14, (SELECT id FROM gym.exercises WHERE "name" = 'Russian Twist'), 3, 20, (SELECT id FROM gym.metrics WHERE "name" = 'Waist Circumference'), 78.00, INTERVAL '15 minutes', 'Core strengthening'),
    (7, 15, (SELECT id FROM gym.exercises WHERE "name" = 'Mountain Climbers'), 3, 30, (SELECT id FROM gym.metrics WHERE "name" = 'Hip Circumference'), 91.00, INTERVAL '25 minutes', 'Endurance training'),
    (7, 16, (SELECT id FROM gym.exercises WHERE "name" = 'Jump Squats'), 3, 15, (SELECT id FROM gym.metrics WHERE "name" = 'Thigh Circumference'), 55.00, INTERVAL '30 minutes', 'Leg day workout'),
    (8, 17, (SELECT id FROM gym.exercises WHERE "name" = 'Burpees'), 4, 10, (SELECT id FROM gym.metrics WHERE "name" = 'Chest Circumference'), 97.00, INTERVAL '35 minutes', 'Intensity high'),
    (8, 18, (SELECT id FROM gym.exercises WHERE "name" = 'Leg Curls'), 3, 15, (SELECT id FROM gym.metrics WHERE "name" = 'Body Water %'), 58.00, INTERVAL '30 minutes', 'Leg recovery'),
    (9, 19, (SELECT id FROM gym.exercises WHERE "name" = 'Chest Fly'), 4, 12, (SELECT id FROM gym.metrics WHERE "name" = 'Lean Mass'), 55.00, INTERVAL '45 minutes', 'Focus on chest'),
    (9, 20, (SELECT id FROM gym.exercises WHERE "name" = 'Cable Cross-over'), 3, 12, (SELECT id FROM gym.metrics WHERE "name" = 'Strength'), 115.00, INTERVAL '30 minutes', 'Cable press'),
    (10, 1, (SELECT id FROM gym.exercises WHERE "name" = 'Push-up'), 3, 15, (SELECT id FROM gym.metrics WHERE "name" = 'Weight'), 78.00, INTERVAL '30 minutes', 'Good endurance'),
    (10, 2, (SELECT id FROM gym.exercises WHERE "name" = 'Pull-up'), 3, 10, (SELECT id FROM gym.metrics WHERE "name" = 'Body Fat %'), 18.20, INTERVAL '25 minutes', 'Pull-up form')
RETURNING *;

WITH RANDOM_data AS (
    SELECT 
        FLOOR(RANDOM() * 30) + 11 AS member_id,  
        FLOOR(RANDOM() * 29) + 21 AS class_schedule_id,  
        (SELECT id FROM gym.exercises ORDER BY RANDOM() LIMIT 1) AS exercise_id,
        ROUND((RANDOM() * 100)::NUMERIC, 2) AS exercise_metric_value,
        INTERVAL '10 minutes' * (FLOOR(RANDOM() * 5) + 1) AS duration
    FROM generate_series(1, 60)
),
filtered_data AS (
    SELECT DISTINCT ON (member_id, class_schedule_id, exercise_id)
        rd.member_id,
        rd.class_schedule_id,
        rd.exercise_id,
        rd.exercise_metric_value,
        rd.duration
    FROM RANDOM_data rd
    WHERE NOT EXISTS (
        SELECT 1
        FROM gym.exercise_progress ep
        WHERE ep.member_id = rd.member_id 
        AND ep.class_schedule_id = rd.class_schedule_id 
        AND ep.exercise_id = rd.exercise_id
    )
    ORDER BY rd.member_id, rd.class_schedule_id, rd.exercise_id 
)
INSERT INTO gym.exercise_progress (
    "member_id", 
    "class_schedule_id", 
    "exercise_id", 
    "sets", 
    "reps", 
    "metric_id", 
    "exercise_metric_value", 
    "duration", 
    "notes"
)
SELECT 
    member_id,
    class_schedule_id,
    exercise_id,
    CASE 
        WHEN exercise_id = (SELECT id FROM gym.exercises WHERE name = 'Push-up' LIMIT 1) THEN 3
        WHEN exercise_id = (SELECT id FROM gym.exercises WHERE name = 'Pull-up' LIMIT 1) THEN 3
        WHEN exercise_id = (SELECT id FROM gym.exercises WHERE name = 'Squat' LIMIT 1) THEN 4
        WHEN exercise_id = (SELECT id FROM gym.exercises WHERE name = 'Deadlift' LIMIT 1) THEN 4
        WHEN exercise_id = (SELECT id FROM gym.exercises WHERE name = 'Bench Press' LIMIT 1) THEN 4
        ELSE 3
    END AS sets,
    CASE 
        WHEN exercise_id = (SELECT id FROM gym.exercises WHERE name = 'Push-up' LIMIT 1) THEN 15
        WHEN exercise_id = (SELECT id FROM gym.exercises WHERE name = 'Pull-up' LIMIT 1) THEN 10
        WHEN exercise_id = (SELECT id FROM gym.exercises WHERE name = 'Squat' LIMIT 1) THEN 20
        WHEN exercise_id = (SELECT id FROM gym.exercises WHERE name = 'Deadlift' LIMIT 1) THEN 10
        WHEN exercise_id = (SELECT id FROM gym.exercises WHERE name = 'Bench Press' LIMIT 1) THEN 12
        ELSE 12
    END AS reps,
    CASE
        WHEN exercise_id = (SELECT id FROM gym.exercises WHERE name = 'Push-up' LIMIT 1) THEN (SELECT id FROM gym.metrics WHERE name = 'Strength' LIMIT 1)
        WHEN exercise_id = (SELECT id FROM gym.exercises WHERE name = 'Pull-up' LIMIT 1) THEN (SELECT id FROM gym.metrics WHERE name = 'Strength' LIMIT 1)
        WHEN exercise_id = (SELECT id FROM gym.exercises WHERE name = 'Squat' LIMIT 1) THEN (SELECT id FROM gym.metrics WHERE name = 'Strength' LIMIT 1)
        WHEN exercise_id = (SELECT id FROM gym.exercises WHERE name = 'Deadlift' LIMIT 1) THEN (SELECT id FROM gym.metrics WHERE name = 'Strength' LIMIT 1)
        WHEN exercise_id = (SELECT id FROM gym.exercises WHERE name = 'Bench Press' LIMIT 1) THEN (SELECT id FROM gym.metrics WHERE name = 'Strength' LIMIT 1)
        WHEN exercise_id = (SELECT id FROM gym.exercises WHERE name = 'Plank' LIMIT 1) THEN (SELECT id FROM gym.metrics WHERE name = 'Flexibility' LIMIT 1)
        WHEN exercise_id = (SELECT id FROM gym.exercises WHERE name = 'Mountain Climbers' LIMIT 1) THEN (SELECT id FROM gym.metrics WHERE name = 'Cardio Endurance' LIMIT 1)
        ELSE (SELECT id FROM gym.metrics WHERE name = 'Strength' LIMIT 1)
    END AS metric_id,
    exercise_metric_value, 
    duration,
    CASE 
        WHEN FLOOR(RANDOM() * 5) = 0 THEN 'Good form'
        WHEN FLOOR(RANDOM() * 5) = 1 THEN 'Struggled on last rep'
        WHEN FLOOR(RANDOM() * 5) = 2 THEN 'Heavy weight'
        WHEN FLOOR(RANDOM() * 5) = 3 THEN 'Felt good'
        ELSE 'Focus on technique'
    END AS notes
FROM filtered_data
RETURNING *;

INSERT INTO gym.goal_types ("name", "description")
VALUES
    ('Weight loss', 'Focus on reducing body fat and overall weight through a combination of diet and exercise'),
    ('Muscle gain', 'Concentrates on building muscle mass through strength training and adequate nutrition'),
    ('Endurance', 'Improving stamina and cardiovascular health through consistent aerobic exercise'),
    ('Fat loss', 'Targeted fat reduction through high-intensity workouts and controlled calorie intake'),
    ('Strength building', 'Developing strength through resistance training and progressive overload'),
    ('Powerlifting', 'Specialized in increasing maximal strength in squat, deadlift, and bench press'),
    ('Body toning', 'Focusing on achieving a lean and toned physique through resistance and cardio training'),
    ('Cardio endurance', 'Improving cardiovascular fitness with activities like running, cycling, and swimming'),
    ('Flexibility', 'Enhancing range of motion and muscle elasticity through stretching and mobility exercises'),
    ('High-intensity interval training (HIIT)', 'Short, intense bursts of exercise followed by recovery periods to burn fat and improve fitness'),
    ('Sports performance', 'Training aimed at improving athletic performance in specific sports'),
    ('Rehabilitation', 'Exercises focused on recovery and injury prevention, promoting mobility and strength'),
    ('Balance and coordination', 'Improving stability and body control through specific exercises and movements'),
    ('Posture improvement', 'Exercises aimed at improving posture and alignment to reduce pain and discomfort')
RETURNING *;

INSERT INTO gym.training_plans (
  "member_id", "name", "description", "start_date", "end_date", "achievement_percentage", "goal_type_id", "created_at"
)
VALUES
  (1, 'Shred It Now', 'A training plan focused on reducing body fat through cardio and strength training.',
   DATE '2025-04-01', DATE '2025-06-01',
   50, (SELECT id FROM gym.goal_types WHERE name = 'Weight loss'),
   CURRENT_DATE - (FLOOR(RANDOM() * 30) + 1) * INTERVAL '1 day'),

  (2, 'Muscle Surge', 'A plan for gaining muscle mass with resistance and weight training exercises.',
   DATE '2025-04-03', DATE '2025-06-05',
   40, (SELECT id FROM gym.goal_types WHERE name = 'Muscle gain'),
   CURRENT_DATE - (FLOOR(RANDOM() * 30) + 1) * INTERVAL '1 day'),

  (3, 'Endurance Beast', 'Improving cardiovascular endurance with high-intensity interval training.',
   DATE '2025-04-05', DATE '2025-06-08',
   60, (SELECT id FROM gym.goal_types WHERE name = 'Endurance'),
   CURRENT_DATE - (FLOOR(RANDOM() * 30) + 1) * INTERVAL '1 day'),

  (4, 'Fat-Burn Fury', 'Targeted fat reduction through a combination of strength and HIIT workouts.',
   DATE '2025-04-07', DATE '2025-06-10',
   70, (SELECT id FROM gym.goal_types WHERE name = 'Fat loss'),
   CURRENT_DATE - (FLOOR(RANDOM() * 30) + 1) * INTERVAL '1 day'),

  (5, 'Powerhouse Strength', 'A focus on building strength with progressive overload in compound lifts.',
   DATE '2025-04-09', DATE '2025-06-12',
   45, (SELECT id FROM gym.goal_types WHERE name = 'Strength building'),
   CURRENT_DATE - (FLOOR(RANDOM() * 30) + 1) * INTERVAL '1 day'),

  (6, 'Max Strength Challenge', 'Plan designed for maximal strength in squat, deadlift, and bench press.',
   DATE '2025-04-11', DATE '2025-06-14',
   30, (SELECT id FROM gym.goal_types WHERE name = 'Powerlifting'),
   CURRENT_DATE - (FLOOR(RANDOM() * 30) + 1) * INTERVAL '1 day'),

  (7, 'Tone & Sculpt', 'A combination of resistance and cardio exercises to tone muscles and reduce fat.',
   DATE '2025-04-13', DATE '2025-06-16',
   55, (SELECT id FROM gym.goal_types WHERE name = 'Body toning'),
   CURRENT_DATE - (FLOOR(RANDOM() * 30) + 1) * INTERVAL '1 day'),

  (8, 'Endurance Edge', 'Plan to improve stamina with running, cycling, and swimming.',
   DATE '2025-04-15', DATE '2025-06-18',
   80, (SELECT id FROM gym.goal_types WHERE name = 'Cardio endurance'),
   CURRENT_DATE - (FLOOR(RANDOM() * 30) + 1) * INTERVAL '1 day'),

  (9, 'Flexibility Flow', 'Increasing flexibility through daily stretching and yoga exercises.',
   DATE '2025-04-17', DATE '2025-06-20',
   65, (SELECT id FROM gym.goal_types WHERE name = 'Flexibility'),
   CURRENT_DATE - (FLOOR(RANDOM() * 30) + 1) * INTERVAL '1 day'),

  (10, 'Performance Pro', 'Focused on improving agility, strength, and endurance for athletic performance.',
   DATE '2025-04-19', DATE '2025-06-22',
   50, (SELECT id FROM gym.goal_types WHERE name = 'Sports performance'),
   CURRENT_DATE - (FLOOR(RANDOM() * 30) + 1) * INTERVAL '1 day')
RETURNING *;

WITH RANDOM_training_plans AS ( 
  SELECT 
    member_id,
    CASE 
      WHEN member_id % 10 = 0 THEN 'Fat Burn Pro'
      WHEN member_id % 10 = 1 THEN 'Muscle Growth Surge'
      WHEN member_id % 10 = 2 THEN 'Cardio Boost'
      WHEN member_id % 10 = 3 THEN 'Toned & Defined'
      WHEN member_id % 10 = 4 THEN 'Strength Mastery'
      WHEN member_id % 10 = 5 THEN 'Endurance Hero'
      WHEN member_id % 10 = 6 THEN 'Body Transformation'
      WHEN member_id % 10 = 7 THEN 'Max Strength'
      WHEN member_id % 10 = 8 THEN 'Flexibility Flow'
      ELSE 'HIIT Power'
    END AS name,

    CASE 
      WHEN member_id % 10 = 0 THEN 'A training plan designed for targeted fat loss using a combination of strength training and cardio.'
      WHEN member_id % 10 = 1 THEN 'A strength-building program focused on muscle hypertrophy through resistance exercises.'
      WHEN member_id % 10 = 2 THEN 'A cardio-focused plan to improve cardiovascular endurance and stamina through varied activities.'
      WHEN member_id % 10 = 3 THEN 'A workout plan to tone and sculpt muscles while reducing fat and improving overall physique.'
      WHEN member_id % 10 = 4 THEN 'A comprehensive plan focused on increasing strength using progressive overload techniques.'
      WHEN member_id % 10 = 5 THEN 'A training regimen to build endurance with aerobic exercises and high-intensity intervals.'
      WHEN member_id % 10 = 6 THEN 'A holistic approach to body transformation through a combination of strength training and conditioning.'
      WHEN member_id % 10 = 7 THEN 'A powerlifting-focused plan to maximize strength in squat, deadlift, and bench press.'
      WHEN member_id % 10 = 8 THEN 'A flexibility-enhancing plan that focuses on stretching, mobility, and injury prevention.'
      ELSE 'A high-intensity interval training program designed to burn fat and boost cardiovascular fitness.'
    END AS description,

    CASE 
      WHEN member_id % 10 = 0 THEN '2025-04-01'::DATE
      WHEN member_id % 10 = 1 THEN '2025-05-01'::DATE
      WHEN member_id % 10 = 2 THEN '2025-06-01'::DATE
      WHEN member_id % 10 = 3 THEN '2025-03-01'::DATE
      WHEN member_id % 10 = 4 THEN '2025-07-01'::DATE
      WHEN member_id % 10 = 5 THEN '2025-08-01'::DATE
      WHEN member_id % 10 = 6 THEN '2025-09-01'::DATE
      WHEN member_id % 10 = 7 THEN '2025-10-01'::DATE
      WHEN member_id % 10 = 8 THEN '2025-11-01'::DATE
      ELSE '2025-12-01'::DATE
    END AS start_date,

    CASE 
      WHEN member_id % 10 = 0 THEN '2025-06-01'::DATE
      WHEN member_id % 10 = 1 THEN '2025-08-01'::DATE
      WHEN member_id % 10 = 2 THEN '2025-07-01'::DATE
      WHEN member_id % 10 = 3 THEN '2025-09-01'::DATE
      WHEN member_id % 10 = 4 THEN '2025-10-01'::DATE
      WHEN member_id % 10 = 5 THEN '2025-11-01'::DATE
      WHEN member_id % 10 = 6 THEN '2025-12-01'::DATE
      WHEN member_id % 10 = 7 THEN '2026-01-01'::DATE
      WHEN member_id % 10 = 8 THEN '2026-02-01'::DATE
      ELSE '2026-03-01'::DATE
    END AS end_date,

    FLOOR(RANDOM() * 100) AS achievement_percentage,

    CASE 
      WHEN member_id % 10 = 0 THEN (SELECT id FROM gym.goal_types WHERE name = 'Fat loss' LIMIT 1)
      WHEN member_id % 10 = 1 THEN (SELECT id FROM gym.goal_types WHERE name = 'Muscle gain' LIMIT 1)
      WHEN member_id % 10 = 2 THEN (SELECT id FROM gym.goal_types WHERE name = 'Cardio endurance' LIMIT 1)
      WHEN member_id % 10 = 3 THEN (SELECT id FROM gym.goal_types WHERE name = 'Body toning' LIMIT 1)
      WHEN member_id % 10 = 4 THEN (SELECT id FROM gym.goal_types WHERE name = 'Strength building' LIMIT 1)
      WHEN member_id % 10 = 5 THEN (SELECT id FROM gym.goal_types WHERE name = 'Endurance' LIMIT 1)
      WHEN member_id % 10 = 6 THEN (SELECT id FROM gym.goal_types WHERE name = 'Body toning' LIMIT 1)
      WHEN member_id % 10 = 7 THEN (SELECT id FROM gym.goal_types WHERE name = 'Powerlifting' LIMIT 1)
      WHEN member_id % 10 = 8 THEN (SELECT id FROM gym.goal_types WHERE name = 'Flexibility' LIMIT 1)
      ELSE (SELECT id FROM gym.goal_types WHERE name = 'High-intensity interval training (HIIT)' LIMIT 1)
    END AS goal_type_id,

    CURRENT_DATE - (FLOOR(RANDOM() * 30) + 1) * INTERVAL '1 day' AS created_at

  FROM generate_series(11, 40) AS member_id
)
INSERT INTO gym.training_plans (
  "member_id", "name", "description", "start_date", "end_date", "achievement_percentage", "goal_type_id", "created_at"
)
SELECT 
  "member_id", "name", "description", "start_date", "end_date", "achievement_percentage", "goal_type_id", "created_at"
FROM RANDOM_training_plans
RETURNING *;

INSERT INTO gym.training_plan_classes ("plan_id", "class_id")
VALUES
    ((SELECT "id" FROM gym.training_plans WHERE "name" = 'Shred It Now' LIMIT 1), (SELECT "id" FROM gym.classes WHERE "name" = 'Strength Training Basics' LIMIT 1)),
    ((SELECT "id" FROM gym.training_plans WHERE "name" = 'Muscle Surge' LIMIT 1), (SELECT "id" FROM gym.classes WHERE "name" = 'Spinning Challenge' LIMIT 1)),
    ((SELECT "id" FROM gym.training_plans WHERE "name" = 'Endurance Beast' LIMIT 1), (SELECT "id" FROM gym.classes WHERE "name" = 'Aerobics Dance' LIMIT 1)),
    ((SELECT "id" FROM gym.training_plans WHERE "name" = 'Max Strength Challenge' LIMIT 1), (SELECT "id" FROM gym.classes WHERE "name" = 'Kickboxing Extreme' LIMIT 1)),
    ((SELECT "id" FROM gym.training_plans WHERE "name" = 'Powerhouse Strength' LIMIT 1), (SELECT "id" FROM gym.classes WHERE "name" = 'Strength Training Basics' LIMIT 1)),
    ((SELECT "id" FROM gym.training_plans WHERE "name" = 'Muscle Growth Surge' LIMIT 1), (SELECT "id" FROM gym.classes WHERE "name" = 'Private Pilates' LIMIT 1)),
    ((SELECT "id" FROM gym.training_plans WHERE "name" = 'Tone & Sculpt' LIMIT 1), (SELECT "id" FROM gym.classes WHERE "name" = 'Pilates for Beginners' LIMIT 1)),
    ((SELECT "id" FROM gym.training_plans WHERE "name" = 'Endurance Edge' LIMIT 1), (SELECT "id" FROM gym.classes WHERE "name" = 'Body Combat Session' LIMIT 1)),
    ((SELECT "id" FROM gym.training_plans WHERE "name" = 'Flexibility Flow' LIMIT 1), (SELECT "id" FROM gym.classes WHERE "name" = 'Morning Yoga' LIMIT 1)),
    ((SELECT "id" FROM gym.training_plans WHERE "name" = 'Performance Pro' LIMIT 1), (SELECT "id" FROM gym.classes WHERE "name" = 'Circuit Training Challenge' LIMIT 1)),
    ((SELECT "id" FROM gym.training_plans WHERE "name" = 'Muscle Growth Surge' LIMIT 1 OFFSET 1), (SELECT "id" FROM gym.classes WHERE "name" = 'Zumba Party' LIMIT 1)),
    ((SELECT "id" FROM gym.training_plans WHERE "name" = 'Fat-Burn Fury' LIMIT 1), (SELECT "id" FROM gym.classes WHERE "name" = 'Zumba Party' LIMIT 1))
RETURNING *;

INSERT INTO gym.training_plan_classes ("plan_id", "class_id")
SELECT p.id, c.id
FROM gym.training_plans p
JOIN gym.classes c ON (
  (p.name IN ('Shred It Now', 'Fat-Burn Fury', 'Fat Burn Pro', 'HIIT Power') AND c.name IN ('Zumba Party', 'Kickboxing Extreme', 'Aerobics Dance'))
  OR (p.name IN ('Powerhouse Strength', 'Max Strength Challenge', 'Strength Mastery', 'Muscle Growth Surge', 'Max Strength') AND c.name IN ('Strength Training Basics', 'Body Combat Session', 'Circuit Training Challenge'))
  OR (p.name = 'Flexibility Flow' AND c.name IN ('Morning Yoga', 'Pilates for Beginners', 'Private Pilates'))
  OR (p.name IN ('Endurance Beast', 'Endurance Edge', 'Endurance Hero', 'Cardio Boost') AND c.name IN ('Spinning Challenge', 'Dance Fitness', 'Zumba Party'))
)
WHERE NOT EXISTS (
  SELECT 1
  FROM gym.training_plan_classes t
  WHERE t.plan_id = p.id AND t.class_id = c.id
)
RETURNING *;

-- Oleksandr Kopytin
INSERT INTO gym.trainers ("first_name", "last_name", "email", "phone", "date_of_birth", "gender", "education", "address", "registration_date")
VALUES 
    ('Andrii', 'Shevchenko', 'andrii.shevchenko@gymfit.ua', '+380501234567', '1985-05-12', 'M', 'Bachelor in Physical Education', 'Kyiv, Volodymyrska St, 12', '2023-01-15 09:30:00'),
    ('Olha', 'Ivanenko', 'olha.ivanenko@gymfit.ua', '+380631112233', '1990-09-22', 'F', 'Master in Sports Science', 'Lviv, Franka St, 21', '2023-02-10 10:45:00'),
    ('Dmytro', 'Kovalenko', 'd.kovalenko@gymfit.ua', '+380671234567', '1988-03-30', 'M', 'Bachelor in Physical Education', 'Kharkiv, Nauky Ave, 5', '2023-03-05 11:00:00'),
    ('Iryna', 'Petrenko', 'iryna.petrenko@gymfit.ua', '+380931112244', '1992-11-18', 'F', 'Master in Sports Coaching', 'Dnipro, Gagarina Ave, 45', '2023-03-18 12:15:00'),
    ('Serhii', 'Bondarenko', 'serhii.bondarenko@gymfit.ua', '+380661234567', '1980-07-07', 'M', 'Bachelor in Physical Education', 'Odesa, Deribasivska St, 8', '2023-04-01 08:00:00'),
    ('Kateryna', 'Melnyk', 'kateryna.melnyk@gymfit.ua', '+380951122334', '1995-01-25', 'F', 'Bachelor in Sports Medicine', 'Zaporizhzhia, Sobornyi Ave, 17', '2023-04-10 09:20:00'),
    ('Yurii', 'Tymoshenko', 'yurii.t@gymfit.ua', '+380671112233', '1987-08-14', 'M', 'Master in Sports Science', 'Vinnytsia, Kotsiubynskoho St, 3', '2023-05-01 14:40:00'),
    ('Natalia', 'Zhuk', 'natalia.zhuk@gymfit.ua', '+380931234567', '1993-04-03', 'F', 'Bachelor in Physical Education', 'Poltava, Pushkina St, 19', '2023-05-15 15:30:00'),
    ('Roman', 'Levchenko', 'r.levchenko@gymfit.ua', '+380501112233', '1984-06-17', 'M', 'Master in Sports Coaching', 'Chernihiv, Shevchenka St, 22', '2023-06-01 10:00:00'),
    ('Oksana', 'Krut', 'oksana.krut@gymfit.ua', '+380991234567', '1991-12-09', 'F', 'Bachelor in Sports Medicine', 'Rivne, Soborna St, 10', '2023-06-20 16:00:00')
RETURNING *;

INSERT INTO gym.trainer_accounts ("trainer_id", "user_name", "password_hash")
SELECT id, 
       LEFT(first_name, 2) || last_name || FLOOR(RANDOM() * 1000)::TEXT,  
       crypt(gen_random_uuid()::VARCHAR || id::VARCHAR, gen_salt('bf'))
FROM gym.trainers
RETURNING *;

INSERT INTO gym.trainer_photos ("trainer_id", "photo_url", "is_profile_photo") 
SELECT t.id, 
       'gymfit.ua/profile_photos/' || ta.user_name, 
       TRUE  -- Це профільне фото
FROM gym.trainers AS t
JOIN gym.trainer_accounts AS ta ON t.id = ta.trainer_id
RETURNING *;

INSERT INTO gym.trainer_photos ("trainer_id", "photo_url")
SELECT t.id, 
       'gymfit.ua/photos/' || ta.user_name -- Це непрофільне фото
FROM gym.trainers AS t
JOIN gym.trainer_accounts AS ta ON t.id = ta.trainer_id
RETURNING *;

INSERT INTO gym.trainer_class_assignments_history ("class_id", "trainer_id", "start_date", "end_date")
VALUES 
    ((SELECT id FROM gym.classes WHERE name = 'Morning Yoga'), 1, '2022-04-10', NULL),
    ((SELECT id FROM gym.classes WHERE name = 'Spinning Challenge'), 1, '2022-05-12', NULL),
    ((SELECT id FROM gym.classes WHERE name = 'Pilates for Beginners'), 1, '2021-08-14', '2025-04-14'),
    ((SELECT id FROM gym.classes WHERE name = 'Spinning Challenge'), 2, '2020-11-11', NULL),
    ((SELECT id FROM gym.classes WHERE name = 'Pilates for Beginners'), 2, '2021-12-13', NULL),
    ((SELECT id FROM gym.classes WHERE name = 'Strength Training Basics'), 2, '2020-09-15', NULL),
    ((SELECT id FROM gym.classes WHERE name = 'Morning Yoga'), 3, '2021-04-10', NULL),
    ((SELECT id FROM gym.classes WHERE name = 'Strength Training Basics'), 3, '2022-06-12', '2025-04-12'),
    ((SELECT id FROM gym.classes WHERE name = 'Zumba Party'), 3, '2021-10-14', '2025-04-15')
RETURNING *;

INSERT INTO gym.trainer_class_assignments_history ("class_id", "trainer_id", "start_date", "end_date")
VALUES
    ((SELECT id FROM gym.classes WHERE id BETWEEN 4 AND 10 ORDER BY RANDOM() LIMIT 1),
    (SELECT id FROM gym.trainers ORDER BY RANDOM() LIMIT 1),
    TO_DATE('2021-01-01', 'YYYY-MM-DD') + (TRUNC(RANDOM() * (TO_DATE('2023-12-31', 'YYYY-MM-DD') - TO_DATE('2021-01-01', 'YYYY-MM-DD')))) * INTERVAL '1 day',
    CASE WHEN RANDOM() < 0.5 THEN NULL ELSE TO_DATE('2024-01-01', 'YYYY-MM-DD') + (TRUNC(RANDOM() * 180)) * INTERVAL '1 day' END),
    ((SELECT id FROM gym.classes WHERE id BETWEEN 4 AND 10 ORDER BY RANDOM() LIMIT 1),
    (SELECT id FROM gym.trainers ORDER BY RANDOM() LIMIT 1),
    TO_DATE('2020-01-01', 'YYYY-MM-DD') + (TRUNC(RANDOM() * (TO_DATE('2023-12-31', 'YYYY-MM-DD') - TO_DATE('2020-01-01', 'YYYY-MM-DD')))) * INTERVAL '1 day',
    CASE WHEN RANDOM() < 0.5 THEN NULL ELSE TO_DATE('2024-01-01', 'YYYY-MM-DD') + (TRUNC(RANDOM() * 180)) * INTERVAL '1 day' END),
    ((SELECT id FROM gym.classes WHERE id BETWEEN 4 AND 10 ORDER BY RANDOM() LIMIT 1),
    (SELECT id FROM gym.trainers ORDER BY RANDOM() LIMIT 1),
    TO_DATE('2019-01-01', 'YYYY-MM-DD') + (TRUNC(RANDOM() * (TO_DATE('2023-12-31', 'YYYY-MM-DD') - TO_DATE('2019-01-01', 'YYYY-MM-DD')))) * INTERVAL '1 day',
    CASE WHEN RANDOM() < 0.5 THEN NULL ELSE TO_DATE('2024-01-01', 'YYYY-MM-DD') + (TRUNC(RANDOM() * 180)) * INTERVAL '1 day' END),
    ((SELECT id FROM gym.classes WHERE id BETWEEN 4 AND 10 ORDER BY RANDOM() LIMIT 1),
    (SELECT id FROM gym.trainers ORDER BY RANDOM() LIMIT 1),
    TO_DATE('2021-03-01', 'YYYY-MM-DD') + (TRUNC(RANDOM() * (TO_DATE('2023-12-31', 'YYYY-MM-DD') - TO_DATE('2021-03-01', 'YYYY-MM-DD')))) * INTERVAL '1 day',
    CASE WHEN RANDOM() < 0.5 THEN NULL ELSE TO_DATE('2024-01-01', 'YYYY-MM-DD') + (TRUNC(RANDOM() * 180)) * INTERVAL '1 day' END),
    ((SELECT id FROM gym.classes WHERE id BETWEEN 4 AND 10 ORDER BY RANDOM() LIMIT 1),
    (SELECT id FROM gym.trainers ORDER BY RANDOM() LIMIT 1),
    TO_DATE('2022-06-15', 'YYYY-MM-DD') + (TRUNC(RANDOM() * (TO_DATE('2023-12-31', 'YYYY-MM-DD') - TO_DATE('2022-06-15', 'YYYY-MM-DD')))) * INTERVAL '1 day',
    CASE WHEN RANDOM() < 0.5 THEN NULL ELSE TO_DATE('2024-01-01', 'YYYY-MM-DD') + (TRUNC(RANDOM() * 180)) * INTERVAL '1 day' END),
    ((SELECT id FROM gym.classes WHERE id BETWEEN 4 AND 10 ORDER BY RANDOM() LIMIT 1),
    (SELECT id FROM gym.trainers ORDER BY RANDOM() LIMIT 1),
    TO_DATE('2020-05-20', 'YYYY-MM-DD') + (TRUNC(RANDOM() * (TO_DATE('2023-12-31', 'YYYY-MM-DD') - TO_DATE('2020-05-20', 'YYYY-MM-DD')))) * INTERVAL '1 day',
    CASE WHEN RANDOM() < 0.5 THEN NULL ELSE TO_DATE('2024-01-01', 'YYYY-MM-DD') + (TRUNC(RANDOM() * 180)) * INTERVAL '1 day' END),
    ((SELECT id FROM gym.classes WHERE id BETWEEN 4 AND 10 ORDER BY RANDOM() LIMIT 1),
    (SELECT id FROM gym.trainers ORDER BY RANDOM() LIMIT 1),
    TO_DATE('2022-09-10', 'YYYY-MM-DD') + (TRUNC(RANDOM() * (TO_DATE('2023-12-31', 'YYYY-MM-DD') - TO_DATE('2022-09-10', 'YYYY-MM-DD')))) * INTERVAL '1 day',
    CASE WHEN RANDOM() < 0.5 THEN NULL ELSE TO_DATE('2024-01-01', 'YYYY-MM-DD') + (TRUNC(RANDOM() * 180)) * INTERVAL '1 day' END),
    ((SELECT id FROM gym.classes WHERE id BETWEEN 4 AND 10 ORDER BY RANDOM() LIMIT 1),
    (SELECT id FROM gym.trainers ORDER BY RANDOM() LIMIT 1),
    TO_DATE('2021-11-01', 'YYYY-MM-DD') + (TRUNC(RANDOM() * (TO_DATE('2023-12-31', 'YYYY-MM-DD') - TO_DATE('2021-11-01', 'YYYY-MM-DD')))) * INTERVAL '1 day',
    CASE WHEN RANDOM() < 0.5 THEN NULL ELSE TO_DATE('2024-01-01', 'YYYY-MM-DD') + (TRUNC(RANDOM() * 180)) * INTERVAL '1 day' END),
    ((SELECT id FROM gym.classes WHERE id BETWEEN 4 AND 10 ORDER BY RANDOM() LIMIT 1),
    (SELECT id FROM gym.trainers ORDER BY RANDOM() LIMIT 1),
    TO_DATE('2022-03-05', 'YYYY-MM-DD') + (TRUNC(RANDOM() * (TO_DATE('2023-12-31', 'YYYY-MM-DD') - TO_DATE('2022-03-05', 'YYYY-MM-DD')))) * INTERVAL '1 day',
    CASE WHEN RANDOM() < 0.5 THEN NULL ELSE TO_DATE('2024-01-01', 'YYYY-MM-DD') + (TRUNC(RANDOM() * 180)) * INTERVAL '1 day' END),
    ((SELECT id FROM gym.classes WHERE id BETWEEN 4 AND 10 ORDER BY RANDOM() LIMIT 1),
    (SELECT id FROM gym.trainers ORDER BY RANDOM() LIMIT 1),
    TO_DATE('2021-08-10', 'YYYY-MM-DD') + (TRUNC(RANDOM() * (TO_DATE('2023-12-31', 'YYYY-MM-DD') - TO_DATE('2021-08-10', 'YYYY-MM-DD')))) * INTERVAL '1 day',
    CASE WHEN RANDOM() < 0.5 THEN NULL ELSE TO_DATE('2024-01-01', 'YYYY-MM-DD') + (TRUNC(RANDOM() * 180)) * INTERVAL '1 day' END),
    ((SELECT id FROM gym.classes WHERE id BETWEEN 4 AND 10 ORDER BY RANDOM() LIMIT 1),
    (SELECT id FROM gym.trainers ORDER BY RANDOM() LIMIT 1),
    TO_DATE('2020-04-22', 'YYYY-MM-DD') + (TRUNC(RANDOM() * (TO_DATE('2023-12-31', 'YYYY-MM-DD') - TO_DATE('2020-04-22', 'YYYY-MM-DD')))) * INTERVAL '1 day',
    CASE WHEN RANDOM() < 0.5 THEN NULL ELSE TO_DATE('2024-01-01', 'YYYY-MM-DD') + (TRUNC(RANDOM() * 180)) * INTERVAL '1 day' END),
    ((SELECT id FROM gym.classes WHERE id BETWEEN 4 AND 10 ORDER BY RANDOM() LIMIT 1),
    (SELECT id FROM gym.trainers ORDER BY RANDOM() LIMIT 1),
    TO_DATE('2022-01-15', 'YYYY-MM-DD') + (TRUNC(RANDOM() * (TO_DATE('2023-12-31', 'YYYY-MM-DD') - TO_DATE('2022-01-15', 'YYYY-MM-DD')))) * INTERVAL '1 day',
    CASE WHEN RANDOM() < 0.5 THEN NULL ELSE TO_DATE('2024-01-01', 'YYYY-MM-DD') + (TRUNC(RANDOM() * 180)) * INTERVAL '1 day' END),
    ((SELECT id FROM gym.classes WHERE id BETWEEN 4 AND 10 ORDER BY RANDOM() LIMIT 1),
    (SELECT id FROM gym.trainers ORDER BY RANDOM() LIMIT 1),
    TO_DATE('2021-05-18', 'YYYY-MM-DD') + (TRUNC(RANDOM() * (TO_DATE('2023-12-31', 'YYYY-MM-DD') - TO_DATE('2021-05-18', 'YYYY-MM-DD')))) * INTERVAL '1 day',
    CASE WHEN RANDOM() < 0.5 THEN NULL ELSE TO_DATE('2024-01-01', 'YYYY-MM-DD') + (TRUNC(RANDOM() * 180)) * INTERVAL '1 day' END),
    ((SELECT id FROM gym.classes WHERE id BETWEEN 4 AND 10 ORDER BY RANDOM() LIMIT 1),
    (SELECT id FROM gym.trainers ORDER BY RANDOM() LIMIT 1),
    TO_DATE('2022-07-03', 'YYYY-MM-DD') + (TRUNC(RANDOM() * (TO_DATE('2023-12-31', 'YYYY-MM-DD') - TO_DATE('2022-07-03', 'YYYY-MM-DD')))) * INTERVAL '1 day',
    CASE WHEN RANDOM() < 0.5 THEN NULL ELSE TO_DATE('2024-01-01', 'YYYY-MM-DD') + (TRUNC(RANDOM() * 180)) * INTERVAL '1 day' END),
    ((SELECT id FROM gym.classes WHERE id BETWEEN 4 AND 10 ORDER BY RANDOM() LIMIT 1),
    (SELECT id FROM gym.trainers ORDER BY RANDOM() LIMIT 1),
    TO_DATE('2021-12-12', 'YYYY-MM-DD') + (TRUNC(RANDOM() * (TO_DATE('2023-12-31', 'YYYY-MM-DD') - TO_DATE('2021-12-12', 'YYYY-MM-DD')))) * INTERVAL '1 day',
    CASE WHEN RANDOM() < 0.5 THEN NULL ELSE TO_DATE('2024-01-01', 'YYYY-MM-DD') + (TRUNC(RANDOM() * 180)) * INTERVAL '1 day' END),
    ((SELECT id FROM gym.classes WHERE id BETWEEN 4 AND 10 ORDER BY RANDOM() LIMIT 1),
    (SELECT id FROM gym.trainers ORDER BY RANDOM() LIMIT 1),
    TO_DATE('2020-10-30', 'YYYY-MM-DD') + (TRUNC(RANDOM() * (TO_DATE('2023-12-31', 'YYYY-MM-DD') - TO_DATE('2020-10-30', 'YYYY-MM-DD')))) * INTERVAL '1 day',
    CASE WHEN RANDOM() < 0.5 THEN NULL ELSE TO_DATE('2024-01-01', 'YYYY-MM-DD') + (TRUNC(RANDOM() * 180)) * INTERVAL '1 day' END),
    ((SELECT id FROM gym.classes WHERE id BETWEEN 4 AND 10 ORDER BY RANDOM() LIMIT 1),
    (SELECT id FROM gym.trainers ORDER BY RANDOM() LIMIT 1),
    TO_DATE('2021-04-04', 'YYYY-MM-DD') + (TRUNC(RANDOM() * (TO_DATE('2023-12-31', 'YYYY-MM-DD') - TO_DATE('2021-04-04', 'YYYY-MM-DD')))) * INTERVAL '1 day',
    CASE WHEN RANDOM() < 0.5 THEN NULL ELSE TO_DATE('2024-01-01', 'YYYY-MM-DD') + (TRUNC(RANDOM() * 180)) * INTERVAL '1 day' END),
    ((SELECT id FROM gym.classes WHERE id BETWEEN 4 AND 10 ORDER BY RANDOM() LIMIT 1),
    (SELECT id FROM gym.trainers ORDER BY RANDOM() LIMIT 1),
    TO_DATE('2022-02-28', 'YYYY-MM-DD') + (TRUNC(RANDOM() * (TO_DATE('2023-12-31', 'YYYY-MM-DD') - TO_DATE('2022-02-28', 'YYYY-MM-DD')))) * INTERVAL '1 day',
    CASE WHEN RANDOM() < 0.5 THEN NULL ELSE TO_DATE('2024-01-01', 'YYYY-MM-DD') + (TRUNC(RANDOM() * 180)) * INTERVAL '1 day' END)
RETURNING *;

INSERT INTO gym.trainer_availability ("trainer_id", "day_of_week", "start_time", "end_time")
VALUES 
    (1, 'Monday', '09:00', '13:00'),
    (1, 'Wednesday', '15:00', '18:00'),
    (2, 'Tuesday', '10:00', '14:00'),
    (2, 'Thursday', '16:00', '19:00'),
    (3, 'Monday', '08:00', '12:00'),
    (3, 'Friday', '14:00', '17:00'),
    (4, 'Wednesday', '09:30', '13:30'),
    (4, 'Saturday', '11:00', '15:00'),
    (5, 'Tuesday', '07:00', '11:00'),
    (5, 'Thursday', '13:00', '17:00'),
    (6, 'Friday', '08:00', '12:00'),
    (6, 'Sunday', '14:00', '18:00'),
    (7, 'Monday', '10:00', '13:00'),
    (7, 'Wednesday', '15:00', '19:00'),
    (8, 'Tuesday', '09:00', '12:00'),
    (8, 'Saturday', '13:00', '16:00'),
    (9, 'Thursday', '08:30', '12:30'),
    (9, 'Friday', '14:00', '17:00'),
    (10, 'Monday', '07:00', '10:00'),
    (10, 'Sunday', '15:00', '18:00')
RETURNING *;

INSERT INTO gym.trainer_availability ("trainer_id", "day_of_week", "start_time", "end_time")
SELECT * FROM (
    SELECT 
        trainer_id,
        CASE 
            WHEN i = 0 THEN 'Monday'::gym.day_of_week
            WHEN i = 1 THEN 'Tuesday'::gym.day_of_week
            WHEN i = 2 THEN 'Wednesday'::gym.day_of_week
            WHEN i = 3 THEN 'Thursday'::gym.day_of_week
            WHEN i = 4 THEN 'Friday'::gym.day_of_week
            WHEN i = 5 THEN 'Saturday'::gym.day_of_week
            WHEN i = 6 THEN 'Sunday'::gym.day_of_week
        END AS day_of_week,
        make_time(6 + (i % 5), 0, 0) AS start_time,
        make_time(7 + (i % 5), 0, 0) AS end_time
    FROM (
        SELECT 
            trainer_id,
            generate_series(0, 6) AS i
        FROM generate_series(1, 10) AS trainer_id
    ) AS base
) AS to_insert
WHERE NOT EXISTS (
    SELECT 1 FROM gym.trainer_availability a
    WHERE 
        a.trainer_id = to_insert.trainer_id
        AND a.day_of_week = to_insert.day_of_week
        AND tsrange(
            (DATE '2000-01-01' + to_insert.start_time)::TIMESTAMP,
            (DATE '2000-01-01' + to_insert.end_time)::TIMESTAMP,
            '[)'
        ) && a.time_range::tsrange
)
AND to_insert.start_time IS NOT NULL 
AND to_insert.end_time IS NOT NULL
LIMIT 20
RETURNING "trainer_id", "day_of_week", "start_time", "end_time";

ALTER TABLE gym.trainer_availability DROP COLUMN time_range;

INSERT INTO gym.feedback_trainer ("member_id", "trainer_id", "rating", "notes", "created_at")
VALUES 
    (1, 2, 5, 'Very professional trainer!', NOW() - INTERVAL '2 days'),
    (2, 3, 4, 'Explains clearly, but sometimes late', NOW() - INTERVAL '4 days'),
    (3, 1, 5, 'Motivates to the max!', NOW() - INTERVAL '1 day'),
    (4, 5, 3, 'Okay, but the training could be more interesting', NOW() - INTERVAL '6 days'),
    (5, 4, 4, 'Attentive and precise trainer', NOW() - INTERVAL '3 days'),
    (6, 2, 2, 'Didn’t match my training style', NOW() - INTERVAL '7 days'),
    (7, 6, 5, 'Awesome! Will come again', NOW() - INTERVAL '5 days'),
    (8, 7, 4, 'Everything’s great, except the music :)', NOW() - INTERVAL '2 days'),
    (9, 8, 3, 'Could explain exercises better', NOW() - INTERVAL '10 days'),
    (7, 3, 5, 'Simply the best', NOW() - INTERVAL '1 day'),
    (6, 9, 4, 'Nice trainer and good approach', NOW() - INTERVAL '9 days'),
    (1, 2, 1, 'Didn’t work for me. Poor communication', NOW() - INTERVAL '8 days'),
    (6, 1, 5, 'Love her training sessions!', NOW() - INTERVAL '11 days'),
    (9, 5, 4, 'Great energy and proper technique', NOW() - INTERVAL '6 days'),
    (7, 10, 5, 'My favorite trainer!', NOW() - INTERVAL '3 days'),
    (3, 6, 4, 'Experienced, definitely a professional', NOW() - INTERVAL '4 days'),
    (6, 8, 2, 'Didn’t like how the session was organized', NOW() - INTERVAL '5 days'),
    (7, 7, 5, 'Always cheerful and positive', NOW() - INTERVAL '1 day'),
    (9, 10, 3, 'Average, but consistent', NOW() - INTERVAL '2 days'),
    (1, 4, 5, 'Awesome! Especially the cardio', NOW() - INTERVAL '1 day')
RETURNING *;

INSERT INTO gym.feedback_trainer ("member_id", "trainer_id", "rating", "notes", "created_at")
SELECT
    member_id,
    FLOOR(RANDOM() * (10 - 1 + 1)) + 1 AS trainer_id,
    FLOOR(RANDOM() * (5 - 1 + 1)) + 1 AS rating,
    CASE 
        WHEN rating = 5 THEN 
            (ARRAY['Outstanding performance, keep it up!', 
                   'Amazing quality, highly recommended!', 
                   'Very effective, love this trainer!',
                   'Best decision for my workouts!', 
                   'Exceptional, would work with again!'])[FLOOR(RANDOM() * 5)]
        WHEN rating = 4 THEN 
            (ARRAY['Good trainer, served me well.', 
                   'Very reliable, no issues so far.', 
                   'Solid trainer, met my expectations.',
                   'Works well, but minor issues exist.',
                   'Good performance overall.'])[FLOOR(RANDOM() * 5)]
        WHEN rating = 3 THEN 
            (ARRAY['Average, not as great as expected.', 
                   'It’s okay, but could use some work.', 
                   'Decent, serves its purpose.', 
                   'Works fine but not impressive.', 
                   'Just satisfactory, nothing more.'])[FLOOR(RANDOM() * 5)]
        WHEN rating = 2 THEN 
            (ARRAY['Could be better, had some issues.', 
                   'Not very useful, needs improvement.', 
                   'Not great quality, disappointed.', 
                   'Couldn’t meet my expectations.', 
                   'Problems occurred, needs improvement.'])[FLOOR(RANDOM() * 5)]
        WHEN rating = 1 THEN 
            (ARRAY['Very disappointing, does not meet my needs.', 
                   'Poor trainer, very frustrating.', 
                   'Not worth the time, would not recommend.', 
                   'Failed to teach properly.', 
                   'Unexpectedly poor quality.'])[FLOOR(RANDOM() * 5)]
    END AS notes,
    NOW() - (RANDOM() * INTERVAL '30 days') AS created_at
FROM
    (SELECT generate_series(10, 31) AS member_id, FLOOR(RANDOM() * (5 - 1 + 1)) + 1 AS rating) AS temp
ORDER BY RANDOM()
LIMIT 62
RETURNING *;

-- Maksym Zymyn
INSERT INTO gym.training_recommendations ("plan_id", "trainer_id", "recommendation_text", "recommendation_date")
VALUES
  ((SELECT id FROM gym.training_plans WHERE name = 'Shred It Now' LIMIT 1), 
   1,
   'Increase cardio sessions to 4 times per week and focus on protein intake for better fat loss results.',
   '2025-04-10'),
  
  ((SELECT id FROM gym.training_plans WHERE name = 'Muscle Surge' LIMIT 1),
   2,
   'Add 10% more weight to your lifts each week and ensure proper rest between sets for optimal hypertrophy.',
   '2025-04-11'),
  
  ((SELECT id FROM gym.training_plans WHERE name = 'Endurance Beast' LIMIT 1),
   3,
   'Incorporate interval sprints twice weekly to boost your VO2 max and endurance capacity.',
   '2025-04-08'),
  
  ((SELECT id FROM gym.training_plans WHERE name = 'Fat-Burn Fury' LIMIT 1),
   4,
   'Try fasted cardio in the morning and monitor your heart rate zones for optimal fat burning.',
   '2025-04-12'),
  
  ((SELECT id FROM gym.training_plans WHERE name = 'Powerhouse Strength' LIMIT 1),
   5,
   'Focus on compound lifts with perfect form before increasing weights. Consider deload weeks every 4-6 weeks.',
   '2025-04-05'),
  
  ((SELECT id FROM gym.training_plans WHERE name = 'Max Strength Challenge' LIMIT 1),
   6,
   'Implement conjugate method with dynamic effort days and max effort days for better strength gains.',
   '2025-04-09'),
  
  ((SELECT id FROM gym.training_plans WHERE name = 'Tone & Sculpt' LIMIT 1),
   7,
   'Combine resistance training with metabolic conditioning circuits for optimal toning results.',
   '2025-04-10'),
  
  ((SELECT id FROM gym.training_plans WHERE name = 'Endurance Edge' LIMIT 1),
   8,
   'Gradually increase your long run distance by 10% each week to safely build endurance.',
   '2025-04-12'),
  
  ((SELECT id FROM gym.training_plans WHERE name = 'Flexibility Flow' LIMIT 1),
   9,
   'Hold each stretch for at least 30 seconds and practice deep breathing during stretching sessions.',
   '2025-04-11'),
  
  ((SELECT id FROM gym.training_plans WHERE name = 'Performance Pro' LIMIT 1),
   10,
   'Incorporate sport-specific drills and plyometrics to enhance your athletic performance.',
   '2025-04-05')
RETURNING *;

WITH recommendations AS (
  SELECT *
  FROM (VALUES
    ('Fat-Burn Fury', 'Combine HIIT workouts with moderate-intensity cardio for optimal fat burning. Track your nutrition to maintain a calorie deficit.'),
    ('Fat-Burn Fury', 'Try fasted cardio in the morning 2-3 times per week and monitor your macronutrient ratios for optimal fat loss.'),
    ('Fat-Burn Fury', 'Incorporate circuit training to keep your heart rate elevated while strength training.'),
    ('Fat-Burn Fury', 'Reduce refined sugars and processed foods; aim for whole food sources.'),
    ('Fat-Burn Fury', 'Include active rest days with light walking or yoga to keep metabolism engaged.'),

    ('Muscle Growth Surge', 'Focus on progressive overload in compound lifts. Aim for 3-4 sets of 6-12 reps.'),
    ('Muscle Growth Surge', 'Implement drop sets on your last set to push muscles beyond failure.'),
    ('Muscle Growth Surge', 'Increase protein intake to support muscle recovery and growth.'),
    ('Muscle Growth Surge', 'Track your volume weekly and aim to increase it gradually.'),
    ('Muscle Growth Surge', 'Use mind-muscle connection techniques to isolate and activate muscles.'),

    ('Endurance Hero', 'Incorporate pyramid interval training - start with short high-intensity bursts.'),
    ('Endurance Hero', 'Gradually increase your long-duration cardio by 10% weekly.'),
    ('Endurance Hero', 'Alternate between tempo runs and long runs during the week.'),
    ('Endurance Hero', 'Use heart rate zones to guide your aerobic vs anaerobic training.'),
    ('Endurance Hero', 'Train with incline and resistance to simulate real race conditions.'),

    ('Torch & Tone', 'Use supersets combining upper and lower body exercises.'),
    ('Torch & Tone', 'Incorporate resistance bands to create constant tension.'),
    ('Torch & Tone', 'Alternate strength days with metabolic conditioning.'),
    ('Torch & Tone', 'Limit rest to 30 seconds between sets for a higher burn.'),
    ('Torch & Tone', 'Add bodyweight circuits at the end of sessions for tone.'),

    ('Strength Mastery', 'Prioritize heavy compound lifts with low reps (3-5).'),
    ('Strength Mastery', 'Use the 5/3/1 progression method for main lifts.'),
    ('Strength Mastery', 'Train using low volume but high intensity protocols.'),
    ('Strength Mastery', 'Add pause reps to build bottom-end strength.'),
    ('Strength Mastery', 'Ensure full recovery between sets, resting 3–5 minutes.')
  ) AS r(plan_name, recommendation_text)
),
trainers AS (
  SELECT generate_series(1, 10) AS trainer_id
),
recommendations_with_row_num AS (
  SELECT r.plan_name, r.recommendation_text, ROW_NUMBER() OVER (ORDER BY RANDOM()) AS row_num
  FROM recommendations r
),
selected_recommendations AS (
  SELECT plan.id AS plan_id,
         t.trainer_id,
         r.recommendation_text,
         CURRENT_DATE - (INTERVAL '1 day' * FLOOR(RANDOM() * 7)) AS recommendation_date
  FROM recommendations_with_row_num r
  JOIN gym.training_plans plan ON plan.name LIKE r.plan_name || '%'
  JOIN trainers t
    ON (r.row_num - 1) % 10 + 1 = t.trainer_id
  ORDER BY plan.id, RANDOM()
  LIMIT 30
)
INSERT INTO gym.training_recommendations ("plan_id", "trainer_id", "recommendation_text", "recommendation_date")
SELECT * FROM selected_recommendations
RETURNING *;

INSERT INTO gym.feedback_class_schedule (
    "member_id", "class_schedule_id", "rating", "notes", "created_at"
)
VALUES
    (1, 1, 5, 'Great class!', '2025-04-01'),
    (3, 3, 4, 'Really enjoyed it.', '2025-04-03'),
    (5, 5, 3, 'It was okay.', '2025-04-05'),
    (7, 7, 4, 'Nice instructor.', '2025-04-07'),
    (8, 8, 5, 'Everything was perfect.', '2025-04-09'),
    (10, 10, 2, 'Too intense for me.', '2025-04-11');

WITH attended_pairs AS (
    SELECT
        a.member_id,
        a.class_schedule_id,
        FLOOR(RANDOM() * 5 + 1)::SMALLINT AS rating
    FROM gym.attendance a
    WHERE a.attended = TRUE
    AND NOT EXISTS (
        SELECT 1
        FROM gym.feedback_class_schedule f
        WHERE f.member_id = a.member_id
          AND f.class_schedule_id = a.class_schedule_id
    )
    ORDER BY RANDOM()
), generated_feedback AS (
    SELECT
        ap.member_id,
        ap.class_schedule_id,
        ap.rating,
        CASE 
            WHEN ap.rating = 5 THEN 
                (ARRAY['Outstanding performance, keep it up!', 
                       'Amazing quality, highly recommended!', 
                       'Very effective, love this class!', 
                       'Best class for my workouts!', 
                       'Exceptional, would recommend again!'])[FLOOR(RANDOM() * 5)]
            WHEN ap.rating = 4 THEN 
                (ARRAY['Good quality, served me well.', 
                       'Very reliable, no issues so far.', 
                       'Solid class, met my expectations.',
                       'Works well, but minor issues exist.',
                       'Good experience overall.'])[FLOOR(RANDOM() * 5)]
            WHEN ap.rating = 3 THEN 
                (ARRAY['Average, not as great as expected.', 
                       'It’s okay, but could use some improvement.', 
                       'Decent, serves its purpose.', 
                       'Works fine but not impressive.', 
                       'Just satisfactory, nothing more.'])[FLOOR(RANDOM() * 5)]
            WHEN ap.rating = 2 THEN 
                (ARRAY['Could be better, had some issues.', 
                       'Not very useful, needs improvement.', 
                       'Not great quality, disappointed.',
                       'Couldn’t meet my expectations.', 
                       'Problems occurred, needs repairs.'])[FLOOR(RANDOM() * 5)]
            WHEN ap.rating = 1 THEN 
                (ARRAY['Very disappointing, does not meet my needs.', 
                       'Broken after first use, very frustrating.', 
                       'Not worth the money, would not recommend.', 
                       'Failed to work properly from start.', 
                       'Unexpectedly poor quality.'])[FLOOR(RANDOM() * 5)]
        END AS notes,
        NOW() - (RANDOM() * INTERVAL '30 days') AS created_at
    FROM attended_pairs ap
)
INSERT INTO gym.feedback_class_schedule (
    "member_id", "class_schedule_id", "rating", "notes", "created_at"
)
SELECT * FROM generated_feedback
RETURNING *;

-- Ihor Bohdanovych
INSERT INTO gym.payment_methods ("name", "notes") VALUES
    ('credit card', 'Visa, MasterCard, etc.'),
    ('cash', 'Cash payment at the gym'),
    ('bank transfer', 'Via bank account'),
    ('online', 'Through online payment systems');

INSERT INTO gym.payment_statuses ("name") VALUES
    ('pending'),
    ('completed'),
    ('failed');

INSERT INTO gym.payments (member_id, amount, payment_date, method_id, status_id, transaction_id, comment)
VALUES
    (1, 50.00, '2023-01-05 10:30:00', 
    (SELECT id FROM gym.payment_methods WHERE "name" = 'credit card'), 
    (SELECT id FROM gym.payment_statuses WHERE "name" = 'completed'), 
    'txn_001_a1b2c3', 'Monthly membership fee'),
    (1, 30.00, '2023-02-05 11:15:00', 
    (SELECT id FROM gym.payment_methods WHERE "name" = 'credit card'), 
    (SELECT id FROM gym.payment_statuses WHERE "name" = 'completed'), 
    'txn_002_d4e5f6', 'Monthly membership fee'),

    (2, 125.00, '2023-01-10 14:20:00', 
    (SELECT id FROM gym.payment_methods WHERE "name" = 'bank transfer'), 
    (SELECT id FROM gym.payment_statuses WHERE "name" = 'completed'), 
    'txn_003_g7h8i9', 'Quarterly payment'),
    (2, 25.00, '2023-01-15 09:45:00', 
    (SELECT id FROM gym.payment_methods WHERE "name" = 'cash'), 
    (SELECT id FROM gym.payment_statuses WHERE "name" = 'completed'), 
    'txn_004_j1k2l3', 'Personal training session'),

    (3, 900.00, '2023-01-20 16:30:00', 
    (SELECT id FROM gym.payment_methods WHERE "name" = 'online'), 
    (SELECT id FROM gym.payment_statuses WHERE "name" = 'completed'), 
    'txn_005_m4n5o6', 'Premium membership'),
    (3, 60.00, '2023-02-20 17:10:00', 
    (SELECT id FROM gym.payment_methods WHERE "name" = 'online'), 
    (SELECT id FROM gym.payment_statuses WHERE "name" = 'pending'), 
    'txn_006_p7q8r9', 'Premium membership - processing'),

    (4, 60.00, '2023-01-25 12:00:00', 
    (SELECT id FROM gym.payment_methods WHERE "name" = 'credit card'), 
    (SELECT id FROM gym.payment_statuses WHERE "name" = 'failed'), 
    'txn_007_s1t2u3', 'Annual fee - card declined'),
    (4, 60.00, '2023-01-26 13:30:00', 
    (SELECT id FROM gym.payment_methods WHERE "name" = 'bank transfer'), 
    (SELECT id FROM gym.payment_statuses WHERE "name" = 'completed'), 
    'txn_008_v4w5x6', 'Annual fee - paid via transfer'),

    (5, 840.00, '2023-02-01 10:00:00', 
    (SELECT id FROM gym.payment_methods WHERE "name" = 'cash'), 
    (SELECT id FROM gym.payment_statuses WHERE "name" = 'completed'), 
    'txn_009_y7z8a1', 'Yearly membership'),
    (5, 35.00, '2023-02-10 18:45:00', 
    (SELECT id FROM gym.payment_methods WHERE "name" = 'cash'), 
    (SELECT id FROM gym.payment_statuses WHERE "name" = 'completed'), 
    'txn_010_b2c3d4', 'Locker rental'),

    (6, 80.00, '2023-02-15 15:20:00', 
    (SELECT id FROM gym.payment_methods WHERE "name" = 'credit card'), 
    (SELECT id FROM gym.payment_statuses WHERE "name" = 'completed'), 
    'txn_011_e5f6g7', 'Bi-monthly payment'),
    (6, 20.00, '2023-02-20 11:30:00', 
    (SELECT id FROM gym.payment_methods WHERE "name" = 'online'), 
    (SELECT id FROM gym.payment_statuses WHERE "name" = 'completed'), 
    'txn_012_h8i9j1', 'Sauna access'),

    (7, 1055.00, '2023-02-25 09:15:00', 
    (SELECT id FROM gym.payment_methods WHERE "name" = 'bank transfer'), 
    (SELECT id FROM gym.payment_statuses WHERE "name" = 'pending'), 
    'txn_013_k2l3m4', 'Yearly payment - processing'),
    (7, 130.00, '2023-03-01 14:00:00', 
    (SELECT id FROM gym.payment_methods WHERE "name" = 'credit card'), 
    (SELECT id FROM gym.payment_statuses WHERE "name" = 'completed'), 
    'txn_014_n5o6p7', 'Yearly payment'),

    (8, 240.00, '2023-03-05 16:45:00', 
    (SELECT id FROM gym.payment_methods WHERE "name" = 'online'), 
    (SELECT id FROM gym.payment_statuses WHERE "name" = 'completed'), 
    'txn_015_q8r9s1', 'Quarterly payment'),
    (8, 15.00, '2023-03-10 12:30:00', 
    (SELECT id FROM gym.payment_methods WHERE "name" = 'cash'), 
    (SELECT id FROM gym.payment_statuses WHERE "name" = 'completed'), 
    'txn_016_t2u3v4', 'Towel service'),

    (9, 55.00, '2023-03-15 10:20:00', 
    (SELECT id FROM gym.payment_methods WHERE "name" = 'credit card'), 
    (SELECT id FROM gym.payment_statuses WHERE "name" = 'failed'), 
    'txn_017_w5x6y7', 'Monthly payment - expired card'),
    (9, 45.00, '2023-03-16 11:10:00', 
    (SELECT id FROM gym.payment_methods WHERE "name" = 'credit card'), 
    (SELECT id FROM gym.payment_statuses WHERE "name" = 'completed'), 
    'txn_018_z8a9b1', 'Monthly payment - new card'),

    (10, 720.00, '2023-03-20 13:50:00', 
    (SELECT id FROM gym.payment_methods WHERE "name" = 'bank transfer'), 
    (SELECT id FROM gym.payment_statuses WHERE "name" = 'completed'), 
    'txn_019_c2d3e4', 'Semi-annual payment'),
    (10, 25.00, '2023-03-25 17:30:00', 
    (SELECT id FROM gym.payment_methods WHERE "name" = 'cash'), 
    (SELECT id FROM gym.payment_statuses WHERE "name" = 'completed'), 
    'txn_020_f5g6h7', 'Massage session')
 RETURNING *;

WITH 
member_ids AS (
    SELECT generate_series(11, 40) AS member_id
),
payment_methods AS (
    SELECT "id", "name" FROM gym.payment_methods
),
payment_statuses AS (
    SELECT "id", "name" FROM gym.payment_statuses
),
payment_records AS (
    SELECT
        m.member_id,
        (RANDOM() * 100 + 10)::NUMERIC(7,2) AS amount,
        (CURRENT_DATE - (RANDOM() * 90)::int * INTERVAL '1 day') AS payment_date,
        (SELECT id FROM payment_methods ORDER BY RANDOM() LIMIT 1) AS method_id,
        (SELECT id FROM payment_statuses ORDER BY RANDOM() LIMIT 1) AS status_id,
        'txn_' || SUBSTR(md5(RANDOM()::VARCHAR), 1, 10) AS transaction_id,
        CASE (RANDOM() * 4)::INT
            WHEN 0 THEN 'Monthly membership fee'
            WHEN 1 THEN 'Annual subscription'
            WHEN 2 THEN 'Personal training session'
            WHEN 3 THEN 'Additional services'
            ELSE 'Gym equipment rental'
        END AS comment,
        gs.payment_num
    FROM member_ids m
    JOIN generate_series(1, 2) AS gs(payment_num) ON true
)
INSERT INTO gym.payments (
    member_id, 
    amount, 
    payment_date, 
    method_id, 
    status_id, 
    transaction_id, 
    comment
)
SELECT 
    member_id,
    amount,
    payment_date,
    method_id,
    status_id,
    transaction_id,
    comment
FROM payment_records
ORDER BY member_id, payment_date;
SELECT 
    p.member_id,
    COUNT(*) AS payment_count,
    MIN(p.payment_date) AS first_payment,
    MAX(p.payment_date) AS last_payment,
    SUM(p.amount) AS total_paid
FROM gym.payments p
WHERE p.member_id BETWEEN 11 AND 40
GROUP BY p.member_id
ORDER BY p.member_id;

INSERT INTO gym.promo_codes (
    "promo_code", "description", "discount_percentage", 
    "start_date", "end_date", "class_id", "created_at"
)
VALUES
    ('YOGA20', '20% off Morning Yoga class', 20, '2023-01-01', '2023-12-31', 
        (SELECT id FROM gym.classes WHERE "name" = 'Morning Yoga'), 
        NOW() - INTERVAL '365 days' * RANDOM()),
        
    ('SPIN25', '25% off Spinning Challenge', 25, '2023-01-01', '2023-06-30', 
        (SELECT id FROM gym.classes WHERE "name" = 'Spinning Challenge'), 
        NOW() - INTERVAL '365 days' * RANDOM()),
        
    ('PILATES15', '15% off Pilates for Beginners', 15, '2023-02-01', '2023-08-31', 
        (SELECT id FROM gym.classes WHERE "name" = 'Pilates for Beginners'), 
        NOW() - INTERVAL '365 days' * RANDOM()),
        
    ('STRENGTH30', '30% off Strength Training', 30, '2023-03-01', '2023-09-30', 
        (SELECT id FROM gym.classes WHERE "name" = 'Strength Training Basics'), 
        NOW() - INTERVAL '365 days' * RANDOM()),
        
    ('ZUMBA10', '10% off Zumba Party', 10, '2023-01-15', '2023-07-15', 
        (SELECT id FROM gym.classes WHERE "name" = 'Zumba Party'), 
        NOW() - INTERVAL '365 days' * RANDOM()),
        
    ('KICKBOX20', '20% off Kickboxing Extreme', 20, '2023-04-01', '2023-10-31', 
        (SELECT id FROM gym.classes WHERE "name" = 'Kickboxing Extreme'), 
        NOW() - INTERVAL '365 days' * RANDOM()),
        
    ('PRIVPILATES25', '25% off Private Pilates', 25, '2023-05-01', '2023-11-30', 
        (SELECT id FROM gym.classes WHERE "name" = 'Private Pilates'), 
        NOW() - INTERVAL '365 days' * RANDOM()),
        
    ('AEROBICS15', '15% off Aerobics Dance', 15, '2023-06-01', '2023-12-31', 
        (SELECT id FROM gym.classes WHERE "name" = 'Aerobics Dance'), 
        NOW() - INTERVAL '365 days' * RANDOM()),
        
    ('COMBAT20', '20% off Body Combat', 20, '2023-07-01', '2024-01-31', 
        (SELECT id FROM gym.classes WHERE "name" = 'Body Combat Session'), 
        NOW() - INTERVAL '365 days' * RANDOM()),
        
    ('CIRCUIT30', '30% off Circuit Training', 30, '2023-08-01', '2024-02-28', 
        (SELECT id FROM gym.classes WHERE "name" = 'Circuit Training Challenge'), 
        NOW() - INTERVAL '365 days' * RANDOM()),

    ('DANCE15', '15% off Dance Fitness', 15, '2023-09-01', '2024-03-31', 
        (SELECT id FROM gym.classes WHERE "name" = 'Dance Fitness'), 
        NOW() - INTERVAL '365 days' * RANDOM()
)
RETURNING *;

INSERT INTO gym.promo_codes (
    "promo_code", "description", "discount_percentage", 
    "start_date", "end_date", "class_id", "created_at"
)
SELECT 
    gen_random_uuid()::VARCHAR,
    CASE 
        WHEN c.name = 'Morning Yoga' THEN 'Special discount for ' || c.name || ' class'
        WHEN c.name = 'Spinning Challenge' THEN 'Limited offer for ' || c.name
        WHEN c.name = 'Pilates for Beginners' THEN 'Introductory deal for ' || c.name
        WHEN c.name = 'Strength Training Basics' THEN 'Get strong with ' || c.name || ' discount'
        WHEN c.name = 'Zumba Party' THEN 'Dance your way to savings with ' || c.name
        WHEN c.name = 'Kickboxing Extreme' THEN 'Fight for your right to save with ' || c.name
        WHEN c.name = 'Private Pilates' THEN 'Exclusive offer for ' || c.name
        WHEN c.name = 'Aerobics Dance' THEN 'Move and save with ' || c.name
        WHEN c.name = 'Body Combat Session' THEN 'Combat high prices with ' || c.name
        WHEN c.name = 'Circuit Training Challenge' THEN 'Challenge yourself and save with ' || c.name        
        WHEN c.name = 'Dance Fitness' THEN 'Get fit and save with ' || c.name
    END,
    (11 + FLOOR(RANDOM() * 22))::SMALLINT, 
    CURRENT_DATE - (FLOOR(RANDOM() * 30))::INTEGER,
    CURRENT_DATE + (30 + FLOOR(RANDOM() * 180))::INTEGER, 
    c.id,
    NOW() - (FLOOR(RANDOM() * 90) || ' days')::INTERVAL
FROM 
    gym.classes c
ORDER BY 
    RANDOM()
LIMIT 11
RETURNING *;

INSERT INTO gym.member_referrals ("referrer_id", "referred_id", "referral_date", "promo_code") 
VALUES
    (1, 2, '2023-01-15', (SELECT promo_code FROM gym.promo_codes ORDER BY promo_code LIMIT 1 OFFSET 0)),
    (2, 3, '2023-02-01', (SELECT promo_code FROM gym.promo_codes ORDER BY promo_code LIMIT 1 OFFSET 1)),
    (3, 4, '2023-03-01', (SELECT promo_code FROM gym.promo_codes ORDER BY promo_code LIMIT 1 OFFSET 2)),
    (4, 5, '2023-04-01', (SELECT promo_code FROM gym.promo_codes ORDER BY promo_code LIMIT 1 OFFSET 3)),
    (5, 6, '2023-05-01', (SELECT promo_code FROM gym.promo_codes ORDER BY promo_code LIMIT 1 OFFSET 4)),
    (6, 7, '2023-06-01', (SELECT promo_code FROM gym.promo_codes ORDER BY promo_code LIMIT 1 OFFSET 5)),
    (7, 8, '2023-07-01', (SELECT promo_code FROM gym.promo_codes ORDER BY promo_code LIMIT 1 OFFSET 6)),
    (8, 9, '2023-08-01', (SELECT promo_code FROM gym.promo_codes ORDER BY promo_code LIMIT 1 OFFSET 7)),
    (9, 10, '2023-09-01', (SELECT promo_code FROM gym.promo_codes ORDER BY promo_code LIMIT 1 OFFSET 8)),
    (10, 1, '2023-10-01', (SELECT promo_code FROM gym.promo_codes ORDER BY promo_code LIMIT 1 OFFSET 9));

WITH 
member_pool AS (
    SELECT id FROM gym.members WHERE id BETWEEN 1 AND 40
),
all_possible_pairs AS (
    SELECT 
        m1.id AS referrer_id,
        m2.id AS referred_id,
        ROW_NUMBER() OVER (PARTITION BY m2.id ORDER BY random()) AS rn
    FROM 
        member_pool m1
    JOIN 
        member_pool m2 
        ON m1.id <> m2.id
    WHERE m2.id NOT IN (SELECT referred_id FROM gym.member_referrals)
),
unique_pairs AS (
    SELECT 
        referrer_id,
        referred_id
    FROM 
        all_possible_pairs
    WHERE rn = 1
    LIMIT 30
),
promo_pool AS (
    SELECT promo_code, ROW_NUMBER() OVER () AS rn
    FROM gym.promo_codes
    WHERE start_date <= CURRENT_DATE 
    AND (end_date IS NULL OR end_date >= CURRENT_DATE)
),
numbered_pairs AS (
    SELECT 
        up.*, 
        ROW_NUMBER() OVER () AS rn
    FROM unique_pairs up
)
INSERT INTO gym.member_referrals (
    "referrer_id", "referred_id", "referral_date", "promo_code"
)
SELECT 
    np.referrer_id,
    np.referred_id,
    CURRENT_DATE - (random() * 30)::INTEGER,
    pp.promo_code
FROM 
    numbered_pairs np
JOIN 
    promo_pool pp ON np.rn = pp.rn
RETURNING *;
