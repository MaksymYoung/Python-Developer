// Окрема команда
use gym

// Вставка даних у базу даних
function getRandomElement(arr) {
  return arr[Math.floor(Math.random() * arr.length)];
}

function getRandomDate(start, end) {
  const date = new Date(start.getTime() + Math.random() * (end.getTime() - start.getTime()));
  date.setHours(0, 0, 0, 0);
  return date;
}

function addMonths(date, months) {
  const newDate = new Date(date);
  newDate.setMonth(newDate.getMonth() + months);
  return newDate;
}

function addYears(date, years) {
  const newDate = new Date(date);
  newDate.setFullYear(newDate.getFullYear() + years);
  return newDate;
}

const today = new Date();

function generateRandomMember() {
  const maleFirstNames = ['John', 'Mike', 'David', 'James', 'Robert', 'William', 'Joseph', 'Charles', 'Daniel', 'Thomas'];
  const femaleFirstNames = ['Jane', 'Sarah', 'Anna', 'Emily', 'Mary', 'Jessica', 'Linda', 'Patricia', 'Susan', 'Elizabeth'];
  const lastNames = ['Smith', 'Johnson', 'Williams', 'Jones', 'Brown', 'Taylor', 'Anderson', 'Thomas', 'Jackson', 'White'];
  const genders = ['M', 'F'];
  const trainingLevels = ['beginner', 'intermediate', 'advanced'];
  const membershipTypes = ['monthly', 'yearly', 'premium'];
  const healthIssues = [
    'asthma', 'hypertension', 'diabetes', 'heart disease', 'obesity', 'arthritis', 'migraine', 'depression',
    'anxiety', 'sleep apnea', 'stroke', 'cancer', 'allergy', 'epilepsy', 'none'
  ];

  const trainingTimes = [
    { start_time: '06:00', end_time: '07:00' },
    { start_time: '07:00', end_time: '08:00' },
    { start_time: '08:00', end_time: '09:00' },
    { start_time: '10:00', end_time: '11:00' },
    { start_time: '12:00', end_time: '13:00' },
    { start_time: '14:00', end_time: '15:00' },
    { start_time: '16:00', end_time: '17:00' },
    { start_time: '18:00', end_time: '19:00' },
    { start_time: '19:00', end_time: '20:00' },
    { start_time: '20:00', end_time: '21:00' }
  ];

  const gender = getRandomElement(genders);
  const firstName = gender === 'M' ? getRandomElement(maleFirstNames) : getRandomElement(femaleFirstNames);

  const membershipType = getRandomElement(membershipTypes);

  const startDate = getRandomDate(
    new Date(new Date().setMonth(new Date().getMonth() - 6)),
    new Date()
  );

  let endDate;
  if (membershipType === 'monthly') {
    endDate = addMonths(startDate, 1);
  } else if (membershipType === 'yearly') {
    endDate = addYears(startDate, 1);
  } else if (membershipType === 'premium') {
    endDate = Math.random() < 0.5 ? addMonths(startDate, 1) : addYears(startDate, 1);
  }

  let status;
  const now = new Date();
  if (endDate < now) {
    status = 'expired';
  } else {
    status = getRandomElement(['wait', 'active', 'cancelled']);
  }

  const selectedHealthIssues = [];
  const healthIssueCount = Math.floor(Math.random() * 2) + 1;
  for (let i = 0; i < healthIssueCount; i++) {
    selectedHealthIssues.push(getRandomElement(healthIssues.filter(issue => issue !== 'none')));
  }

  return {
    _id: new ObjectId(),
    firstName: firstName,
    lastName: getRandomElement(lastNames),
    email: `${Math.random().toString(36).substring(7)}@gmail.com`,
    phone: `+1${Math.floor(Math.random() * 9000000000) + 1000000000}`,
    birthDate: getRandomDate(new Date('1980-01-01'), new Date('2000-12-31')),
    gender: gender, 
    account: {
      username: `${Math.random().toString(36).substring(7)}_user`,
      password_hash: `${Math.random().toString(36).substring(7)}`,
      last_login: new Date(),
    },
    trainingLevel: getRandomElement(trainingLevels),
    preferred_training_times: [
      {
        day_of_week: getRandomElement(['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday']),
        ...getRandomElement(trainingTimes),
        priority: Math.floor(Math.random() * 2) + 1,
      }
    ],
    memberships: {
      membershipType: membershipType,
      startDate: startDate,
      endDate: endDate,
      status: status,
    },
    registration_date: new Date(),
    health_issues: selectedHealthIssues.length > 0 ? selectedHealthIssues : ['none'],
    updatedAt: new Date(),
  };
}

for (let i = 0; i < 12; i++) {
  db.members.insertOne(generateRandomMember());
}

function generateActiveMember() {
  const member = generateRandomMember();

  member.memberships.status = "active";

  const now = new Date();

  if (member.memberships.endDate <= now) {
    const membershipType = member.memberships.membershipType;
    if (membershipType === "monthly") {
      member.memberships.endDate = addMonths(now, 1);
    } else if (membershipType === "yearly") {
      member.memberships.endDate = addYears(now, 1);
    } else if (membershipType === "premium") {
      member.memberships.endDate = Math.random() < 0.5 ? addMonths(now, 1) : addYears(now, 1);
    }
    member.memberships.startDate = now;
  }

  return member;
}

for (let i = 0; i < 30; i++) {
  db.members.insertOne(generateActiveMember());
}

const memberIds = db.members.find({}, { _id: 1 }).toArray().map(doc => doc._id);

function generateRandomTrainer() {
  const maleFirstNames = ['John', 'Mike', 'David', 'James', 'Robert', 'William', 'Joseph', 'Charles', 'Daniel', 'Thomas'];
  const femaleFirstNames = ['Jane', 'Sarah', 'Anna', 'Emily', 'Mary', 'Jessica', 'Linda', 'Patricia', 'Susan', 'Elizabeth'];
  const lastNames = ['Smith', 'Johnson', 'Williams', 'Jones', 'Brown', 'Taylor', 'Anderson', 'Thomas', 'Jackson', 'White'];
  const genders = ['M', 'F'];

  const specializationsEducation = {
    "yoga": 'Bachelor of Yoga Studies',
    "weight lifting": 'Certified Strength Coach',
    "pilates": 'Diploma in Pilates Training',
    "cardio fitness": 'Bachelor of Physical Education',
    "aerobics": 'Certified Aerobics Instructor',
    "crossfit": 'CrossFit Level 1 Trainer Certificate',
    "bodybuilding": 'Bachelor of Sports Science',
    "personal training": 'Certified Personal Trainer (CPT)'
  };

  const specializationList = Object.keys(specializationsEducation);

  const gender = getRandomElement(genders);
  const firstName = gender === 'M' ? getRandomElement(maleFirstNames) : getRandomElement(femaleFirstNames);

  const specializationCount = Math.floor(Math.random() * 2) + 1;
  const specializations = [];
  while (specializations.length < specializationCount) {
    const spec = getRandomElement(specializationList);
    if (!specializations.includes(spec)) {
      specializations.push(spec);
    }
  }

  const education = specializationsEducation[getRandomElement(specializations)];

  const historyEntriesCount = Math.random() < 0.5 ? 0 : Math.floor(Math.random() * 2) + 1;
  const trainerClassAssignmentsHistory = [];

  for (let i = 0; i < historyEntriesCount; i++) {
    const start_date = getRandomDate(new Date(2020, 0, 1), new Date());

    const monthsToAdd = Math.floor(Math.random() * (36 - 12)) + 12;
    const potential_end_date = addMonths(start_date, monthsToAdd);
    const end_date = potential_end_date > new Date() ? null : potential_end_date;

    trainerClassAssignmentsHistory.push({
      class_id: ObjectId(),
      start_date: start_date,
      end_date: end_date,
      notes: 'Led group sessions focused on ' + getRandomElement(specializations),
    });
  }

  const experienceYears = trainerClassAssignmentsHistory.length > 0
    ? Math.floor(Math.random() * 11) + 1 // від 1 до 11 років
    : 0;

  return {
    _id: new ObjectId(),
    firstName: firstName,
    lastName: getRandomElement(lastNames),
    email: `${Math.random().toString(36).substring(7)}@gmail.com`,
    phone: `+1${Math.floor(Math.random() * 9000000000) + 1000000000}`,
    address: `${Math.floor(Math.random() * 9999)} Main St`,
    birthDate: getRandomDate(new Date('1970-01-01'), new Date('1995-12-31')),
    gender: gender,
    account: {
      username: `${Math.random().toString(36).substring(7)}_trainer`,
      password_hash: `${Math.random().toString(36).substring(7)}`,
      last_login: new Date(),
    },
    specializations: specializations,
    experienceYears: experienceYears,
    education: education,
    trainerClassAssignmentsHistory: trainerClassAssignmentsHistory,
    availableHours: [
      {
        dayOfWeek: getRandomElement(['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday']),
        startTime: getRandomElement(['06:00', '08:00', '10:00', '14:00', '16:00', '18:00']),
        endTime: getRandomElement(['07:00', '09:00', '11:00', '15:00', '17:00', '19:00']),
      }
    ],
    registration_date: new Date(),
    updatedAt: new Date(),
  };
}

for (let i = 0; i < 5; i++) {
  db.trainers.insertOne(generateRandomTrainer());
}

const trainerIds = db.trainers.find({}, { _id: 1 }).toArray().map(doc => doc._id);

const classTypes = ['yoga', 'pilates', 'strength', 'cardio', 'aerobics'];
const promoDescriptions = ['% off your next class', 'Free trial class', '% off your first month', 'Get a free personal trainer session'];
const discountPercentages = [10, 15, 20, 25, 30];

const classSpecializationMap = {
  yoga: ['flexibility', 'balance', 'mobility'],
  pilates: ['core strength', 'mobility', 'balance'],
  strength: ['strength', 'core strength'],
  cardio: ['endurance', 'mobility'],
  aerobics: ['endurance', 'flexibility'],
};

function generateRandomClass(i, trainerIds) {
  const type = getRandomElement(classTypes);
  const title = `${type} class`;
  
  const allowedSpecializations = classSpecializationMap[type];
  const specialization = Array.from(
    new Set(Array.from({ length: Math.floor(Math.random() * 2) + 1 }, () => getRandomElement(allowedSpecializations)))
  );

  const description = `A ${title} designed to improve your ${specialization.join(' and/or ')}.`;

  const promo_code = `${Math.random().toString(36).substring(7)}_promo`;
  const promo_description = getRandomElement(promoDescriptions);
  const discount_percentage = getRandomElement(discountPercentages);
  const start_date = getRandomDate(new Date(2023, 0, 1), new Date(2023, 6, 1));
  const end_date = getRandomDate(start_date, new Date(start_date.getTime() + 1000 * 60 * 60 * 24 * 90)); // +3 місяці

  const promo = {
    _id: new ObjectId(),
    promo_code: promo_code,
    description: promo_description,
    discount_percentage: discount_percentage,
    start_date: start_date,
    end_date: end_date,
  };

  const createdAt = new Date();
  const updatedAt = new Date();

  return {
    _id: new ObjectId(),
    title: title,
    description: description,
    type: type,
    trainerId: trainerIds[i],
    specialization: specialization,
    promo_codes: [promo],
    createdAt: createdAt,
    updatedAt: updatedAt,
  };
}

const classes = [];
for (let i = 0; i < 10; i++) {
  classes.push(generateRandomClass(i % trainerIds.length, trainerIds)); 
}

db.classes.insertMany(classes);

function generateActiveClass(i, trainerIds) {
  const type = getRandomElement(classTypes);
  const title = `${type} class`;

  const allowedSpecializations = classSpecializationMap[type];
  const specialization = Array.from(
    new Set(Array.from({ length: Math.floor(Math.random() * 2) + 1 }, () => getRandomElement(allowedSpecializations)))
  );

  const description = `A ${title} designed to improve your ${specialization.join(' and/or ')}.`;

  const promo_code = `${Math.random().toString(36).substring(7)}_promo`;
  const promo_description = getRandomElement(promoDescriptions);
  const discount_percentage = getRandomElement(discountPercentages);

  const start_date = getRandomDate(new Date(today.getFullYear(), today.getMonth() - 3, today.getDate()), today);
  const end_date = getRandomDate(new Date(today.getTime() + 86400000), new Date(today.getFullYear(), today.getMonth() + 3, today.getDate())); // від завтра до +3 місяці

  const promo = {
    _id: new ObjectId(),
    promo_code: promo_code,
    description: promo_description,
    discount_percentage: discount_percentage,
    start_date: start_date,
    end_date: end_date,
  };

  const createdAt = new Date();
  const updatedAt = new Date();

  return {
    _id: new ObjectId(),
    title: title,
    description: description,
    type: type,
    trainerId: trainerIds[i],
    specialization: specialization,
    promo_codes: [promo],
    createdAt: createdAt,
    updatedAt: updatedAt,
  };
}

const activeClasses = [];
for (let i = 0; i < 10; i++) {
  activeClasses.push(generateActiveClass(i % trainerIds.length, trainerIds));
}

db.classes.insertMany(activeClasses);

const classIds = db.classes.find({}, { _id: 1 }).toArray().map(function(doc) {
  return doc._id;
});

const halls = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]; 
const capacities = [10, 20, 30, 40, 50, 60]; 
const hallCapacities = halls.map(hallId => {
  const capacity = capacities[Math.floor(Math.random() * capacities.length)];
  return { hallId, capacity };
});

function randomClassScheduleDate(startDate, endDate) {
  const date = new Date(startDate.getTime() + Math.random() * (endDate.getTime() - startDate.getTime()));
  return date.toISOString().split('T')[0]; // Формат YYYY-MM-DD
}

function randomTime() {
  const hours = String(Math.floor(Math.random() * 12) + 8).padStart(2, '0'); // 08:00 – 19:00
  return `${hours}:00`;
}

function addHoursToTime(startTime, hoursToAdd) {
  const timeParts = startTime.split(':'); 
  const date = new Date();

  date.setHours(parseInt(timeParts[0]), parseInt(timeParts[1]), 0, 0);

  date.setHours(date.getHours() + hoursToAdd);

  const newHours = date.getHours().toString().padStart(2, '0');
  const newMinutes = date.getMinutes().toString().padStart(2, '0');
  return `${newHours}:${newMinutes}`;
}

const classSchedules = [];
const sixMonthsAgo = new Date();
sixMonthsAgo.setMonth(today.getMonth() - 6);

classIds.forEach(classId => {
  const scheduleIds = []; 
  for (let i = 0; i < 4; i++) {
    const classDate = randomClassScheduleDate(sixMonthsAgo, today);
    const startTime = randomTime();
    const endTime = addHoursToTime(startTime, 2);
    const hallId = halls[Math.floor(Math.random() * halls.length)];

    const hall = hallCapacities.find(hall => hall.hallId === hallId);
    const capacity = hall ? hall.capacity : 0;

    const createdAt = new Date();
    const updatedAt = new Date();

    const scheduleId = new ObjectId();

    const schedule = {
      _id: scheduleId, 
      classId: classId,
      classDate: classDate,
      startTime: startTime,
      endTime: endTime,
      hallId: hallId,
      capacity: capacity,
      createdAt: createdAt,
      updatedAt: updatedAt
    };

    classSchedules.push(schedule);

    scheduleIds.push(scheduleId);
  }
});

db.class_schedule.insertMany(classSchedules);

const classScheduleIds = db.class_schedule.find({}, { _id: 1 }).toArray().map(function(doc) {
  return doc._id;
});
const classScheduleAndClassIds = classSchedules.map(schedule => ({
  classId: schedule.classId,
  scheduleId: schedule._id 
}));

const goals = {
  "yoga": 'Weight loss',
  "pilates": 'Flexibility',
  "strength": 'Muscle gain',
  "cardio": 'Endurance',
  "aerobics": 'General fitness'
};

const goalDescriptions = {
  "Weight loss": [
    "A program designed to help you burn fat and lose weight effectively.",
    "Focus on calorie burning exercises and a healthy lifestyle!",
    "Achieve your weight loss goals through structured workouts."
  ],
  "Muscle gain": [
    "Gain muscle mass with strength training routines.",
    "Focused on hypertrophy and building a powerful physique.",
    "Maximize your muscle growth with dedicated sessions."
  ],
  "Endurance": [
    "Enhance your stamina and cardiovascular endurance.",
    "Train to go further and last longer with endurance workouts.",
    "Push your limits with tailored endurance training."
  ],
  "Flexibility": [
    "Improve your flexibility with targeted stretching programs.",
    "Increase your range of motion and prevent injuries.",
    "Daily stretching routines to unlock your body's potential."
  ],
  "General fitness": [
    "Overall fitness improvement through balanced exercises.",
    "Stay healthy and active with general fitness routines.",
    "Become a better, healthier version of yourself."
  ]
};

const goalNames = {
  "Weight loss": [
    "Fat Burning Program",
    "Slim Fit Challenge",
    "Weight Loss Bootcamp"
  ],
  "Muscle gain": [
    "Strength Builder Program",
    "Muscle Up Training",
    "Mass Gain Journey"
  ],
  "Endurance": [
    "Stamina Boost Plan",
    "Endurance Warrior Program",
    "Ultimate Endurance Training"
  ],
  "Flexibility": [
    "Flexibility Mastery",
    "Stretch and Strengthen",
    "Full Body Flexibility Plan"
  ],
  "General fitness": [
    "Total Fitness Program",
    "Healthy Lifestyle Journey",
    "Complete Body Workout"
  ]
};

const goalTexts = {
  "Weight loss": [
    "Shed those extra pounds!",
    "Stay committed to your weight loss journey!",
    "Every workout burns fat – keep going!",
    "Slimmer, stronger, healthier – you got this!"
  ],
  "Muscle gain": [
    "Build strength and confidence!",
    "Every rep brings you closer to your goals!",
    "Fuel your gains with persistence!",
    "Stronger muscles, stronger you!"
  ],
  "Endurance": [
    "Push your limits, extend your stamina!",
    "Endurance is built one step at a time!",
    "Stay consistent – endurance takes time!",
    "Every mile makes you tougher!"
  ],
  "Flexibility": [
    "Bend so you don't break!",
    "Flexibility improves with every stretch!",
    "Stay consistent with your stretching routine!",
    "Move freely, live fully!"
  ],
  "General fitness": [
    "A better you starts today!",
    "Consistency is the key to fitness!",
    "Strive for progress, not perfection!",
    "Stay active, stay healthy!"
  ]
};

const classIdsByType = {
  yoga: db.classes.find({ type: 'yoga' }).toArray().map(classDoc => classDoc._id),
  pilates: db.classes.find({ type: 'pilates' }).toArray().map(classDoc => classDoc._id),
  strength: db.classes.find({ type: 'strength' }).toArray().map(classDoc => classDoc._id),
  cardio: db.classes.find({ type: 'cardio' }).toArray().map(classDoc => classDoc._id),
  aerobics: db.classes.find({ type: 'aerobics' }).toArray().map(classDoc => classDoc._id)
};

const docs = memberIds.map(memberId => { 
  const member = db.members.findOne({ _id: memberId });

  if (!member || !member.memberships) {
    print(`Member with id ${memberId} not found or has no memberships`);
    return;
  }

  const membershipStartDate = new Date(member.memberships.startDate);

  const startDate = new Date(membershipStartDate);
  const minEndDate = new Date(membershipStartDate);
  minEndDate.setMonth(minEndDate.getMonth() + 6);

  const maxEndDate = new Date(membershipStartDate);
  maxEndDate.setMonth(maxEndDate.getMonth() + 12);

  const endDate = getRandomDate(minEndDate, maxEndDate);

  const createdAt = new Date();
  const updatedAt = new Date();

  const goalType = getRandomElement(Object.keys(goals));

  if (!goalType || !goalNames[goals[goalType]] || !goalDescriptions[goals[goalType]]) {
    print(`Invalid goal type for member with id ${memberId}`);
    return;
  }

  const goalName = getRandomElement(goalNames[goals[goalType]]);
  const goalDescription = getRandomElement(goalDescriptions[goals[goalType]]);

  if (!classIdsByType[goalType] || !Array.isArray(classIdsByType[goalType])) {
    print(`No classes found for goal type '${goalType}' for member with id ${memberId}`);
    return;
  }

  const selectedClasses = classIdsByType[goalType].slice(0, 2);

  const recommendationDate = getRandomDate(
    new Date(membershipStartDate),
    new Date(membershipStartDate.getTime() + 3 * 24 * 60 * 60 * 1000) // +3 дні
  );

  return {
    _id: new ObjectId(),
    memberId: memberId,
    name: goalName,
    description: goalDescription,
    start_date: startDate,
    end_date: endDate,
    achievement_percentage: Math.floor(Math.random() * 101),
    goal: goals[goalType],
    classes: selectedClasses.map(classId => ({ class_id: classId })),
    recommendations: [
      {
        _id: new ObjectId(),
        trainer_id: getRandomElement(trainerIds),
        recommendation_text: getRandomElement(goalTexts[goals[goalType]]),
        recommendation_date: recommendationDate
      }
    ],
    created_at: createdAt,
    updated_at: updatedAt
  };
}).filter(Boolean); 

db.training_plans.insertMany(docs);

const trainingPlanIds = db.training_plans.find({}, { _id: 1 }).toArray().map(function(doc) {
  return doc._id;
});
const training_plans = db.training_plans.find().toArray();
const memberAndClassIds = training_plans.flatMap(trainingPlan => 
  trainingPlan.classes.map(classEntry => ({
    memberId: trainingPlan.memberId,
    classId: classEntry.class_id
  }))
);

const notificationMessages = [
  "Don't forget your upcoming class tomorrow!",
  "Exclusive promotion: Get 20% off your next session!",
  "System update: We've improved our app experience!",
  "Reminder: Stay hydrated and stay fit!",
  "Promotion: Invite a friend and get a free class!",
  "System notice: Maintenance scheduled for this weekend."
];

const notificationTypes = ["reminder", "promotion", "system"];

const randomBoolean = () => Math.random() < 0.5;

function getRandomNotificationDate(start, end) {
  const date = new Date(start.getTime() + Math.random() * (end.getTime() - start.getTime()));
  return date;
}

const notifications = [];

memberIds.forEach(memberId => { 
  const member = db.members.findOne({ _id: memberId });

  if (!member || !member.memberships) {
    print(`Member with id ${memberId} not found or has no memberships`);
    return;
  }

  const { startDate, endDate } = member.memberships;

  const start = new Date(startDate);
  const end = new Date(endDate) > today ? today : new Date(endDate);

  for (let j = 0; j < 2; j++) { 
    notifications.push({
      _id: new ObjectId(),
      memberId: memberId,
      message: getRandomElement(notificationMessages),
      type: getRandomElement(notificationTypes),
      read: randomBoolean(),
      createdAt: getRandomNotificationDate(start, end)
    });
  }
});

db.notifications.insertMany(notifications);

const futureClassSchedules = [];
const sixMonthsFromNow = new Date();
sixMonthsFromNow.setMonth(today.getMonth() + 6);

for (let i = 0; i < 40; i++) {
  const classId = getRandomElement(classIds); // Випадковий classId
  const classDate = randomClassScheduleDate(today, sixMonthsFromNow);
  const startTime = randomTime();
  const endTime = addHoursToTime(startTime, 2);
  const hallId = getRandomElement(halls);

  const hall = hallCapacities.find(hall => hall.hallId === hallId);
  const capacity = hall ? hall.capacity : 0;

  const createdAt = new Date();
  const updatedAt = new Date();

  const schedule = {
    _id: new ObjectId(),
    classId: classId,
    classDate: classDate,
    startTime: startTime,
    endTime: endTime,
    hallId: hallId,
    capacity: capacity,
    createdAt: createdAt,
    updatedAt: updatedAt
  };

  futureClassSchedules.push(schedule);
}

db.class_schedule.insertMany(futureClassSchedules);

const activeMemberIds = memberIds.filter(memberId => {
  const member = db.members.findOne({ _id: memberId });
  return member && member.memberships && member.memberships.status === "active";
});

const activeMemberStatuses = ["pending", "confirmed", "cancelled"];
const getActiveMemberRandomStatus = () => getRandomElement(activeMemberStatuses);

const activeBookings = [];

today.setHours(0, 0, 0, 0); 

futureClassSchedules.forEach(schedule => {
  const memberId = getRandomElement(activeMemberIds);
  const classDate = new Date(schedule.classDate);

  const daysBefore = Math.floor(Math.random() * 3) + 1;
  const bookingDate = new Date(classDate);
  bookingDate.setDate(classDate.getDate() - daysBefore);
  bookingDate.setHours(0, 0, 0, 0); // нормалізуємо

  const finalBookingDate = bookingDate > today ? new Date(today) : bookingDate;

  const statusName = getActiveMemberRandomStatus();

  const booking = {
    _id: new ObjectId(),
    memberId: memberId,
    classScheduleId: schedule._id,
    bookingDate: finalBookingDate,
    status: {
      name: statusName,
      notes: statusName === "cancelled" ? "User changed plans" : "Automatically assigned"
    },
    cancellationReason: statusName === "cancelled" ? "Personal reasons" : null
  };

  activeBookings.push(booking);
});

db.bookings.insertMany(activeBookings);

const expiredMembers = memberIds
  .map(memberId => {
    const member = db.members.findOne({ _id: memberId });
    if (
      member &&
      member.memberships &&
      member.memberships.status === "expired"
    ) {
      return {
        memberId: member._id,
        startDate: new Date(member.memberships.startDate),
        endDate: new Date(member.memberships.endDate)
      };
    }
    return null;
  })
  .filter(Boolean);

const expiredMemberStatuses = ["confirmed", "cancelled"]; 

function getExpiredMemberRandomStatus() {
  return getRandomElement(expiredMemberStatuses);
}

function getBookingDateBefore(classDate) {
  const daysBefore = Math.floor(Math.random() * 3) + 1;
  const bookingDate = new Date(classDate);
  bookingDate.setDate(classDate.getDate() - daysBefore);
  bookingDate.setHours(0, 0, 0, 0);
  return bookingDate > today ? new Date(today) : bookingDate;
}

const expiredBookings = [];

classSchedules.forEach(schedule => {
  const classDate = new Date(schedule.classDate);

  expiredMembers.forEach(({ memberId, startDate, endDate }) => {
    if (classDate >= startDate && classDate <= endDate) {
      const statusName = getExpiredMemberRandomStatus();

      const booking = {
        _id: new ObjectId(),
        memberId: memberId,
        classScheduleId: schedule._id,
        bookingDate: getBookingDateBefore(classDate),
        status: {
          name: statusName,
          notes: statusName === "cancelled" ? "Expired user cancelled" : "Imported expired user booking"
        }
      };

      expiredBookings.push(booking);
    }
  });
});

db.bookings.insertMany(expiredBookings);

function getRandomText(prefix) {
  const suffix = Math.random().toString(36).substring(2, 10);
  return `${prefix} ${suffix}`;
}

const statuses = ["working", "maintenance", "broken"];
const locations = ["Room A", "Room B", "Lab 1", "Storage", "Gym", "Field"];
const staff = ["John Smith", "Emma Brown", "Alex Taylor", "Sophia Lee", "Staff123"];

const equipmentByClass = {
  yoga: [
    { name: 'Yoga Mat', description: 'High-grip mat for yoga sessions' },
    { name: 'Yoga Block', description: 'Foam block to aid yoga poses' },
    { name: 'Yoga Strap', description: 'Strap for improving stretch range' },
    { name: 'Meditation Cushion', description: 'Cushion for comfortable seating during meditation' },
    { name: 'Yoga Blanket', description: 'Blanket for support and comfort' },
    { name: 'Balance Ball', description: 'Ball for core yoga exercises' },
    { name: 'Bolster Pillow', description: 'Supportive pillow for yoga postures' },
    { name: 'Yoga Wheel', description: 'Wheel for backbends and stretching' },
    { name: 'Eye Pillow', description: 'Aromatherapy pillow for relaxation' },
    { name: 'Resistance Band', description: 'Band for light stretching in yoga' }
  ],
  pilates: [
    { name: 'Pilates Ring', description: 'Resistance ring for pilates workouts' },
    { name: 'Pilates Reformer', description: 'Machine for full-body pilates exercises' },
    { name: 'Foam Roller', description: 'Roller for muscle release and balance' },
    { name: 'Pilates Mat', description: 'Padded mat for floor pilates routines' },
    { name: 'Balance Disc', description: 'Disc for core and posture training' },
    { name: 'Mini Ball', description: 'Small ball for toning and control exercises' },
    { name: 'Magic Circle', description: 'Toning ring for resistance training' },
    { name: 'Stretch Band', description: 'Elastic band for pilates stretches' },
    { name: 'Spine Corrector', description: 'Equipment to align the spine' },
    { name: 'Flex Bar', description: 'Bar for upper body pilates training' }
  ],
  strength: [
    { name: 'Dumbbells', description: 'Hand weights for strength training' },
    { name: 'Barbell', description: 'Heavy bar for weightlifting' },
    { name: 'Kettlebell', description: 'Cast-iron weight for dynamic strength' },
    { name: 'Weight Bench', description: 'Bench for lifting exercises' },
    { name: 'Squat Rack', description: 'Rack for squat and press exercises' },
    { name: 'Pull-up Bar', description: 'Bar for upper body workouts' },
    { name: 'Power Bag', description: 'Weighted bag for dynamic strength' },
    { name: 'Resistance Bands', description: 'Bands for strength building' },
    { name: 'Medicine Ball', description: 'Weighted ball for power training' },
    { name: 'Dip Station', description: 'Station for triceps and core' }
  ],
  cardio: [
    { name: 'Treadmill', description: 'Running machine for cardio workouts' },
    { name: 'Stationary Bike', description: 'Bike for indoor cycling' },
    { name: 'Elliptical Trainer', description: 'Low-impact cardio machine' },
    { name: 'Jump Rope', description: 'Rope for intense cardio training' },
    { name: 'Rowing Machine', description: 'Cardio and full-body training rower' },
    { name: 'Step Platform', description: 'Platform for step aerobics' },
    { name: 'Battle Ropes', description: 'Heavy ropes for high-intensity cardio' },
    { name: 'Agility Ladder', description: 'Ladder for speed and agility drills' },
    { name: 'Spin Bike', description: 'Bike for spin cardio classes' },
    { name: 'Punching Bag', description: 'Bag for boxing cardio workouts' }
  ],
  aerobics: [
    { name: 'Step Bench', description: 'Bench for choreographed step routines' },
    { name: 'Aerobic Mat', description: 'Mat for low-impact aerobic movement' },
    { name: 'Resistance Tubes', description: 'Tubes for light resistance' },
    { name: 'Hand Weights', description: 'Light dumbbells for aerobic routines' },
    { name: 'Stability Ball', description: 'Ball for balance and motion' },
    { name: 'Wrist Weights', description: 'Wearable weights to intensify movement' },
    { name: 'Slide Board', description: 'Board for lateral aerobic moves' },
    { name: 'Jump Platform', description: 'Platform for plyometric jumping' },
    { name: 'Foam Stepper', description: 'Soft step for low-impact aerobics' },
    { name: 'Speed Rope', description: 'Fast rope for high-tempo workouts' }
  ]
};

function getMaintenanceDetail(name) {
  const lower = name.toLowerCase();
  if (lower.includes("mat")) return "Surface cleaned and sanitized";
  if (lower.includes("bike")) return "Chain and resistance system inspected";
  if (lower.includes("ball")) return "Inflated and inspected for leaks";
  if (lower.includes("bench") || lower.includes("rack")) return "Bolts tightened and stability checked";
  if (lower.includes("rope")) return "Rope wear inspected and fraying removed";
  if (lower.includes("machine")) return "Lubricated moving parts and calibrated display";
  if (lower.includes("weights") || lower.includes("bar")) return "Weight integrity and grip checked";
  return "General maintenance and safety inspection performed";
}

const equipmentArray = [];
for (let i = 0; i < 50; i++) {
  const classType = getRandomElement(Object.keys(equipmentByClass));
  const equipment = getRandomElement(equipmentByClass[classType]);

  const purchaseDate = getRandomDate(new Date(2018, 0, 1), new Date());
  const createdAt = getRandomDate(purchaseDate, new Date());
  const updatedAt = getRandomDate(createdAt, new Date());

  const maintenanceCount = Math.floor(Math.random() * 3); // 0 to 2 entries
  const maintenanceHistory = [];

  for (let j = 0; j < maintenanceCount; j++) {
    const maintenanceDate = getRandomDate(purchaseDate, updatedAt);
    maintenanceHistory.push({
      date: maintenanceDate,
      details: getMaintenanceDetail(equipment.name),
      performedBy: getRandomElement(staff)
    });
  }

  const equipmentRecord = {
    _id: new ObjectId(),
    name: equipment.name,
    description: equipment.description,
    purchaseDate: purchaseDate,
    status: getRandomElement(statuses),
    maintenanceHistory: maintenanceHistory,
    location: getRandomElement(locations),
    createdAt: createdAt,
    updatedAt: updatedAt
  };

  equipmentArray.push(equipmentRecord);
}

db.equipment.insertMany(equipmentArray);

const equipmentIds = db.equipment.find({}, { _id: 1 }).toArray().map(function(doc) {
  return doc._id;
});

const exerciseMap = {
  yoga: ['Downward Dog', 'Tree Pose'],
  pilates: ['Hundred', 'Leg Circles'],
  strength: ['Bench Press', 'Deadlift'],
  cardio: ['Running', 'Cycling'],
  aerobics: ['Jumping Jacks', 'High Knees']
};

const metricMap = {
  'Downward Dog':    { unit: 'kg' },         
  'Tree Pose':       { unit: 'kg' },           
  'Hundred':         { unit: 'kg' },         
  'Leg Circles':     { unit: 'kg' },        
  'Bench Press':     { unit: 'kg' },
  'Deadlift':        { unit: 'kg' },
  'Running':         { unit: 'meters' },
  'Cycling':         { unit: 'meters' },
  'Jumping Jacks':   { unit: 'meters' },     
  'High Knees':      { unit: 'meters' }       
};

const members = db.members.find({
  "memberships.status": { $in: ["active", "expired"] }
}).toArray();

const schedules = db.class_schedule.find({}).toArray();

function getValidSchedules(member) {
  const m = member.memberships;
  if (!m || !["active", "expired"].includes(m.status)) return [];

  return schedules.filter(s => {
    return new Date(s.classDate) >= new Date(m.startDate) &&
           new Date(s.classDate) <= new Date(m.endDate);
  });
}

const progressDocs = [];

for (let i = 0; i < 200; i++) {
  const member = getRandomElement(members);
  const validSchedules = getValidSchedules(member);
  if (validSchedules.length === 0) continue;

  const schedule = getRandomElement(validSchedules);
  const classType = getRandomElement(Object.keys(exerciseMap)); 
  const exerciseName = getRandomElement(exerciseMap[classType]);

  const metricInfo = metricMap[exerciseName];
  const sets = Math.floor(Math.random() * 3) + 2;
  const reps = Math.floor(Math.random() * 10) + 1; 
  const durationMultiplier = Math.floor(Math.random() * 3) + 2; 
  const duration = reps * sets * durationMultiplier;

  let metricValue;

  switch (exerciseName) {
    case 'Downward Dog':
    case 'Tree Pose':
    case 'Hundred':
    case 'Leg Circles':
      metricValue = NumberDecimal((Math.random() * 15 + 5).toFixed(0)); 
      break;
    case 'Bench Press':
      metricValue = NumberDecimal((Math.random() * 100 + 20).toFixed(0)); 
      break;
    case 'Deadlift':
      metricValue = NumberDecimal((Math.random() * 160 + 40).toFixed(0)); 
      break;
    case 'Running':
    case 'Cycling':
      metricValue = NumberDecimal((Math.random() * 4000 + 1000).toFixed(0)); 
      break;
    case 'Jumping Jacks':
    case 'High Knees':
      metricValue = NumberDecimal((Math.random() * 1500 + 500).toFixed(0)); 
      break;
    default:
      metricValue = NumberDecimal("0.00");
  }

  progressDocs.push({
    member_id: member._id,
    class_schedule_id: schedule._id,
    exercise: exerciseName,
    sets: sets,
    reps: reps,
    durationMinutes: duration,
    metric: {
      unit: metricInfo.unit,
      value: metricValue
    },
    notes: "Auto-generated progress entry",
    created_at: new Date(),
    updated_at: new Date()
  });
}

db.exercise_progress.insertMany(progressDocs);

const tagsList = ['training', 'before-after'];
const visibilityOptions = ['public', 'private'];
const photos = [];

function generateRandomUrl() {
  const id = Math.random().toString(36).substring(2, 10);
  return `https://cdn.example.com/photos/${id}.jpg`;
}

for (let i = 0; i < 300; i++) {
  const isTrainer = Math.random() < 0.5;
  const entityId = getRandomElement(isTrainer ? trainerIds : memberIds);
  const entityType = isTrainer ? "trainer" : "member";

  photos.push({
    entityId: entityId,
    entityType: entityType,
    url: generateRandomUrl(),
    uploadedAt: new Date(Date.now() - Math.floor(Math.random() * 31536000000)), // within last year
    isProfilePhoto: Math.random() < 0.2,
    tags: tagsList.filter(() => Math.random() < 0.5),
    visibility: getRandomElement(visibilityOptions)
  });
}

db.photos.insertMany(photos);

const promoCodeDocs = db.classes.aggregate([
  { $unwind: "$promo_codes" },
  {
    $project: {
      _id: "$promo_codes._id",
      promo_code: { $toLower: "$promo_codes.promo_code" },
      start_date: "$promo_codes.start_date",
      end_date: "$promo_codes.end_date"
    }
  }
]).toArray();

const paymentMethods = ["credit card", "cash", "bank transfer", "online"];
const statusOptions = ["completed", "pending", "failed"];
const payments = [];

function addDays(date, days) {
  const result = new Date(date);
  result.setDate(result.getDate() + days);
  return result;
}

for (let i = 0; i < 200; i++) {
  const member = getRandomElement(members);
  const startDate = new Date(member.memberships.startDate);
  const paymentDate = addDays(startDate, Math.floor(Math.random() * 3) + 1);
  const createdAt = new Date(paymentDate.getTime() - Math.floor(Math.random() * 10000000));
  const updatedAt = new Date(paymentDate.getTime() + Math.floor(Math.random() * 10000000));

  const referredCandidates = members.filter(m =>
    m._id !== member._id &&
    new Date(m.memberships.startDate) < startDate
  );

  const payment = {
    memberId: member._id,
    amount: +(Math.random() * 200 + 20).toFixed(2),
    paymentDate: paymentDate,
    paymentMethod: getRandomElement(paymentMethods),
    status: getRandomElement(statusOptions),
    createdAt: createdAt,
    updatedAt: updatedAt
  };

  if (referredCandidates.length > 0) {
    const referred = getRandomElement(referredCandidates);
    const daysBefore = Math.floor(Math.random() * 45) + 1;
    const referralDate = addDays(startDate, -daysBefore);

    const validPromoCodes = promoCodeDocs.filter(promo =>
      new Date(promo.start_date) <= referralDate && referralDate <= new Date(promo.end_date)
    );

    if (validPromoCodes.length > 0) {
      const selectedPromo = getRandomElement(validPromoCodes);

      payment.promoCodeUsed = selectedPromo.promo_code;
      payment.referralMemberId = referred._id;
      payment.referral_date = referralDate;
    }
  }

  payments.push(payment);
}

db.payments.insertMany(payments);

const exerciseProgress = db.exercise_progress.find().toArray();

const getRandomItem = (arr) => arr[Math.floor(Math.random() * arr.length)];
const getRandomRating = () => Math.floor(Math.random() * 5) + 1;

const commentsByTypeAndRating = {
  equipmentId: {
    positive: [
      "Обладнання в чудовому стані.",
      "Все працює як слід.",
      "Зручно користуватись."
    ],
    neutral: [
      "Обладнання нормальне, але нічого особливого.",
      "Є і кращі тренажери.",
      "Посередня якість."
    ],
    negative: [
      "Деякі частини розхитані.",
      "Обладнання потрібно оновити.",
      "Незручно і не працює правильно."
    ]
  },
  trainerId: {
    positive: [
      "Тренер мотивує і підтримує!",
      "Дуже професійний підхід.",
      "З ним тренування проходить на одному диханні!"
    ],
    neutral: [
      "Тренер був нормальний, нічого видатного.",
      "Хотілось би більше залучення.",
      "Можна краще."
    ],
    negative: [
      "Тренер був неуважним.",
      "Не пояснював вправи.",
      "Слабкий зворотний зв’язок від тренера."
    ]
  },
  classScheduleId: {
    positive: [
      "Гарне тренування, дякую!",
      "Динамічна і ефективна сесія.",
      "Хочу ще раз прийти на це заняття!"
    ],
    neutral: [
      "Була трохи нудна сесія.",
      "Очікував більшого.",
      "Норм, але без враження."
    ],
    negative: [
      "Не сподобалась сесія.",
      "Було нецікаво.",
      "Тренування не варте часу."
    ]
  }
};

function getComment(targetType, rating) {
  if (rating >= 4) {
    return getRandomItem(commentsByTypeAndRating[targetType].positive);
  } else if (rating === 3) {
    return getRandomItem(commentsByTypeAndRating[targetType].neutral);
  } else {
    return getRandomItem(commentsByTypeAndRating[targetType].negative);
  }
}

const now = new Date();

function getRandomDateAfter(baseDate, minDays, maxDays) {
  const start = new Date(baseDate);
  start.setDate(start.getDate() + minDays);
  const end = new Date(baseDate);
  end.setDate(end.getDate() + maxDays);
  const finalDate = new Date(start.getTime() + Math.random() * (end - start));
  return finalDate > now ? now : finalDate;
}

const feedbacks = [];

for (let i = 0; i < 150; i++) {
  const progress = getRandomItem(exerciseProgress);
  if (!progress?.member_id) continue;

  const member = db.members.findOne({ _id: progress.member_id });
  if (!member?.memberships?.startDate) continue;

  const targetTypes = ["equipmentId", "trainerId", "classScheduleId"];
  const targetType = getRandomItem(targetTypes);

  let targetId;
  let createdAt;

  if (targetType === "classScheduleId") {
    targetId = progress.class_schedule_id;
    createdAt = getRandomDateAfter(new Date(progress.created_at), 1, 3);
  } else {
    targetId = targetType === "equipmentId"
      ? getRandomItem(equipmentIds)
      : getRandomItem(trainerIds);
    createdAt = getRandomDateAfter(new Date(member.memberships.startDate), 1, 90);
  }

  const rating = getRandomRating();
  const comment = getComment(targetType, rating);

  feedbacks.push({
    memberId: progress.member_id,
    targetType: targetType,
    targetId: targetId,
    rating: rating,
    comment: comment,
    createdAt: createdAt
  });
}

db.feedbacks.insertMany(feedbacks);

// Вивід результатів
db.members.find().pretty();
printjson(memberIds);

db.trainers.find().pretty();
printjson(trainerIds);

db.classes.find().pretty();
printjson(classIds);

db.class_schedule.find().pretty();
printjson(classScheduleIds);
printjson(classScheduleAndClassIds);

db.training_plans.find().pretty();
printjson(trainingPlanIds);
printjson(memberAndClassIds);

training_plans.forEach(tp => {
  const member = db.members.findOne({ _id: tp.memberId });
  if (!member) return;

  const uniqueTypes = new Set();

  tp.classes.forEach(classEntry => {
    const cls = db.classes.findOne({ _id: classEntry.class_id });
    if (cls) {
      uniqueTypes.add(cls.type);
    }
  });

  print(`\nMember: ${member.firstName} ${member.lastName || ''} (ID: ${member._id})`);
  print(`  - Class Types: ${Array.from(uniqueTypes).join(', ')}`);
});

db.notifications.find().pretty();
const notificationIds = db.notifications.find({}, { _id: 1 }).toArray().map(function(doc) {
  return doc._id;
});
printjson(notificationIds);

db.bookings.find().pretty();
const bookingIds = db.bookings.find({}, { _id: 1 }).toArray().map(function(doc) {
  return doc._id;
});
printjson(bookingIds);

db.equipment.find().pretty();
printjson(equipmentIds);

db.members.find({ "memberships.status": { $in: ["active", "expired"] } }).count();
db.class_schedule.find().count();

db.exercise_progress.find().pretty();
const exerciseProgressIds = db.exercise_progress.find({}, { _id: 1 }).toArray().map(function(doc) {
  return doc._id;
}); 
printjson(exerciseProgressIds);

db.photos.find().pretty();
const photoIds = db.photos.find({}, { _id: 1 }).toArray().map(function(doc) {
  return doc._id;
});
printjson(photoIds);

db.payments.find().pretty();
const paymentIds = db.payments.find({}, { _id: 1 }).toArray().map(function(doc) {
  return doc._id;
});
printjson(paymentIds);

db.feedbacks.find().pretty();
const feedbackIds = db.feedbacks.find({}, { _id: 1 }).toArray().map(function(doc) {
  return doc._id;
});
printjson(feedbackIds);
