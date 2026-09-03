-- Framz Reporting PostgreSQL Schema

CREATE TABLE IF NOT EXISTS branches (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    location VARCHAR(200),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS users (
    id SERIAL PRIMARY KEY,
    email VARCHAR(150) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    full_name VARCHAR(100) NOT NULL,
    role VARCHAR(50) NOT NULL CHECK (role IN ('ADMIN', 'PASTOR', 'FINANCE', 'ATTENDANCE', 'CELL_LEADER')),
    branch_id INT REFERENCES branches(id) ON DELETE SET NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS cell_groups (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    leader_name VARCHAR(100),
    branch_id INT REFERENCES branches(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS members (
    id SERIAL PRIMARY KEY,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    gender VARCHAR(10) CHECK (gender IN ('Male', 'Female')),
    phone VARCHAR(30),
    email VARCHAR(150),
    status VARCHAR(50) NOT NULL CHECK (status IN ('ACTIVE', 'NEW_CONVERT', 'FIRST_TIMER', 'TRANSFERRED', 'INACTIVE')),
    date_joined DATE DEFAULT CURRENT_DATE,
    cell_id INT REFERENCES cell_groups(id) ON DELETE SET NULL,
    branch_id INT REFERENCES branches(id) ON DELETE SET NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS service_types (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    category VARCHAR(50) NOT NULL DEFAULT 'SUNDAY'
);

CREATE TABLE IF NOT EXISTS attendances (
    id SERIAL PRIMARY KEY,
    service_type_id INT REFERENCES service_types(id) ON DELETE RESTRICT,
    event_date DATE NOT NULL,
    headcount_male INT DEFAULT 0,
    headcount_female INT DEFAULT 0,
    headcount_children INT DEFAULT 0,
    total_headcount INT GENERATED ALWAYS AS (headcount_male + headcount_female + headcount_children) STORED,
    cell_id INT REFERENCES cell_groups(id) ON DELETE SET NULL,
    branch_id INT REFERENCES branches(id) ON DELETE SET NULL,
    recorded_by INT REFERENCES users(id) ON DELETE SET NULL,
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS attendance_records (
    id SERIAL PRIMARY KEY,
    attendance_id INT REFERENCES attendances(id) ON DELETE CASCADE,
    member_id INT REFERENCES members(id) ON DELETE CASCADE,
    status VARCHAR(20) DEFAULT 'PRESENT',
    UNIQUE(attendance_id, member_id)
);

CREATE TABLE IF NOT EXISTS offerings (
    id SERIAL PRIMARY KEY,
    service_type_id INT REFERENCES service_types(id) ON DELETE RESTRICT,
    event_date DATE NOT NULL,
    offering_type VARCHAR(50) NOT NULL CHECK (offering_type IN ('SUNDAY_OFFERING', 'TITHE', 'SPECIAL_SEED', 'THANKSGIVING', 'BUILDING_FUND', 'WELFARE', 'OTHER')),
    amount NUMERIC(12, 2) NOT NULL CHECK (amount >= 0),
    currency VARCHAR(10) DEFAULT 'NGN',
    branch_id INT REFERENCES branches(id) ON DELETE SET NULL,
    recorded_by INT REFERENCES users(id) ON DELETE SET NULL,
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
