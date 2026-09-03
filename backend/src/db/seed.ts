import { initDb, query } from './index';
import bcrypt from 'bcryptjs';

async function seed() {
  await initDb();
  console.log('[Seed] Seeding sample data for Framz Reporting...');

  // 1. Branches
  let branches = await query('SELECT * FROM branches');
  if (branches.length === 0) {
    await query("INSERT INTO branches (name, location) VALUES (?, ?)", ['Main Campus', 'Abuja Central']);
    branches = await query('SELECT * FROM branches');
  }
  const branchId = branches[0].id;

  // 2. Users
  const users = await query('SELECT * FROM users');
  if (users.length === 0) {
    const passwordHash = await bcrypt.hash('admin123', 10);
    await query(
      "INSERT INTO users (email, password_hash, full_name, role, branch_id) VALUES (?, ?, ?, ?, ?)",
      ['admin@church.org', passwordHash, 'Pastor Emmanuel', 'ADMIN', branchId]
    );
    await query(
      "INSERT INTO users (email, password_hash, full_name, role, branch_id) VALUES (?, ?, ?, ?, ?)",
      ['finance@church.org', passwordHash, 'Deaconess Grace', 'FINANCE', branchId]
    );
    await query(
      "INSERT INTO users (email, password_hash, full_name, role, branch_id) VALUES (?, ?, ?, ?, ?)",
      ['attendance@church.org', passwordHash, 'Brother David', 'ATTENDANCE', branchId]
    );
    console.log('[Seed] Created default users: admin@church.org (pass: admin123)');
  }

  // 3. Service Types
  let serviceTypes = await query('SELECT * FROM service_types');
  if (serviceTypes.length === 0) {
    await query("INSERT INTO service_types (name, category) VALUES (?, ?)", ['Sunday Main Service', 'SUNDAY']);
    await query("INSERT INTO service_types (name, category) VALUES (?, ?)", ['Wednesday Bible Study', 'MIDWEEK']);
    await query("INSERT INTO service_types (name, category) VALUES (?, ?)", ['Cell Fellowship Meeting', 'CELL']);
    await query("INSERT INTO service_types (name, category) VALUES (?, ?)", ['Night of Bliss / Special', 'SPECIAL']);
    serviceTypes = await query('SELECT * FROM service_types');
  }
  const sundayServiceId = serviceTypes.find((s: any) => s.category === 'SUNDAY')?.id || 1;
  const bibleStudyId = serviceTypes.find((s: any) => s.category === 'MIDWEEK')?.id || 2;
  const cellServiceId = serviceTypes.find((s: any) => s.category === 'CELL')?.id || 3;

  // 4. Cell Groups
  let cellGroups = await query('SELECT * FROM cell_groups');
  if (cellGroups.length === 0) {
    await query("INSERT INTO cell_groups (name, leader_name, branch_id) VALUES (?, ?, ?)", ['Grace Cell', 'Bro John', branchId]);
    await query("INSERT INTO cell_groups (name, leader_name, branch_id) VALUES (?, ?, ?)", ['Victory Cell', 'Sis Mary', branchId]);
    await query("INSERT INTO cell_groups (name, leader_name, branch_id) VALUES (?, ?, ?)", ['Shalom Cell', 'Bro Peter', branchId]);
    cellGroups = await query('SELECT * FROM cell_groups');
  }

  // 5. Members
  const members = await query('SELECT * FROM members');
  if (members.length === 0) {
    const sampleMembers = [
      ['Kofi', 'Annan', 'Male', '08011112222', 'kofi@example.com', 'ACTIVE', '2025-01-10'],
      ['Chiamaka', 'Okonkwo', 'Female', '08022223333', 'chia@example.com', 'ACTIVE', '2025-02-15'],
      ['Daniel', 'Adeboye', 'Male', '08033334444', 'dan@example.com', 'ACTIVE', '2025-03-01'],
      ['Blessing', 'Eze', 'Female', '08044445555', 'blessing@example.com', 'NEW_CONVERT', '2026-08-01'],
      ['Samuel', 'Turay', 'Male', '08055556666', 'sam@example.com', 'FIRST_TIMER', '2026-08-15'],
      ['Ruth', 'Johnson', 'Female', '08066667777', 'ruth@example.com', 'ACTIVE', '2025-04-20'],
      ['Michael', 'Chen', 'Male', '08077778888', 'mike@example.com', 'ACTIVE', '2025-05-12'],
      ['Esther', 'Nwachukwu', 'Female', '08088889999', 'esther@example.com', 'NEW_CONVERT', '2026-08-20']
    ];
    for (const m of sampleMembers) {
      await query(
        "INSERT INTO members (first_name, last_name, gender, phone, email, status, date_joined, branch_id, cell_id) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)",
        [m[0], m[1], m[2], m[3], m[4], m[5], m[6], branchId, cellGroups[0].id]
      );
    }
    console.log('[Seed] Created 8 sample members.');
  }

  // 6. Attendance logs over last 12 weeks
  const attendances = await query('SELECT * FROM attendances');
  if (attendances.length === 0) {
    const weeks = 12;
    const now = new Date();
    for (let i = weeks; i >= 0; i--) {
      const sundayDate = new Date(now.getTime() - i * 7 * 24 * 60 * 60 * 1000).toISOString().split('T')[0];
      const wednesdayDate = new Date(now.getTime() - (i * 7 + 4) * 24 * 60 * 60 * 1000).toISOString().split('T')[0];

      // Sunday attendance (gradually growing)
      const male = 180 + (12 - i) * 6 + Math.floor(Math.random() * 15);
      const female = 220 + (12 - i) * 8 + Math.floor(Math.random() * 20);
      const children = 80 + (12 - i) * 3 + Math.floor(Math.random() * 10);
      await query(
        "INSERT INTO attendances (service_type_id, event_date, headcount_male, headcount_female, headcount_children, branch_id, notes) VALUES (?, ?, ?, ?, ?, ?, ?)",
        [sundayServiceId, sundayDate, male, female, children, branchId, `Sunday Service Week -${i}`]
      );

      // Midweek attendance
      const bMale = 80 + (12 - i) * 3;
      const bFemale = 110 + (12 - i) * 4;
      const bChild = 25;
      await query(
        "INSERT INTO attendances (service_type_id, event_date, headcount_male, headcount_female, headcount_children, branch_id, notes) VALUES (?, ?, ?, ?, ?, ?, ?)",
        [bibleStudyId, wednesdayDate, bMale, bFemale, bChild, branchId, `Bible Study Week -${i}`]
      );

      // Sunday Offering & Tithes
      const offeringAmount = 350000 + (12 - i) * 15000 + Math.floor(Math.random() * 25000);
      const titheAmount = 600000 + (12 - i) * 25000 + Math.floor(Math.random() * 50000);
      const seedAmount = 150000 + Math.floor(Math.random() * 40000);

      await query(
        "INSERT INTO offerings (service_type_id, event_date, offering_type, amount, currency, branch_id, notes) VALUES (?, ?, ?, ?, ?, ?, ?)",
        [sundayServiceId, sundayDate, 'SUNDAY_OFFERING', offeringAmount, 'NGN', branchId, 'Sunday Main Offering']
      );
      await query(
        "INSERT INTO offerings (service_type_id, event_date, offering_type, amount, currency, branch_id, notes) VALUES (?, ?, ?, ?, ?, ?, ?)",
        [sundayServiceId, sundayDate, 'TITHE', titheAmount, 'NGN', branchId, 'Tithe Collection']
      );
      await query(
        "INSERT INTO offerings (service_type_id, event_date, offering_type, amount, currency, branch_id, notes) VALUES (?, ?, ?, ?, ?, ?, ?)",
        [sundayServiceId, sundayDate, 'SPECIAL_SEED', seedAmount, 'NGN', branchId, 'Partnership & Special Seeds']
      );
    }
    console.log('[Seed] Created 12 weeks of realistic attendance & financial records.');
  }

  console.log('[Seed] Seeding completed successfully!');
}

seed().catch(err => {
  console.error('[Seed Error]', err);
  process.exit(1);
});
