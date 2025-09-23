-- Part1
-- Task 1.1
--1.
CREATE DATABASE university_main
    OWNER postgres
    TEMPLATE template0
    ENCODING 'UTF8';
--2.
CREATE DATABASE university_archive
    TEMPLATE template0
    CONNECTION LIMIT 50;
--3.
CREATE DATABASE university_test
    IS_TEMPLATE true
    CONNECTION LIMIT 10;

-- Task 1.2
-- 1.
CREATE TABLESPACE student_data
    LOCATION 'C:\PostgresTablespaces\students';

-- 2.
CREATE TABLESPACE course_data
    OWNER postgres
    LOCATION 'C:\PostgresTablespaces\courses';

-- 3.
CREATE DATABASE university_distributed
    TABLESPACE student_data
    ENCODING 'UTF8';

-- Part2
-- Task 2.1
\c university_main;

CREATE TABLE students (
    student_id SERIAL PRIMARY KEY,
    first_name VARCHAR(50),
    last_name VARCHAR(50),
    email VARCHAR(100),
    phone CHAR(15),
    date_of_birth DATE,
    enrollment_date DATE,
    gpa NUMERIC(3,2),
    is_active BOOLEAN,
    graduation_year SMALLINT
);

CREATE TABLE professors (
    professor_id SERIAL PRIMARY KEY,
    first_name VARCHAR(50),
    last_name VARCHAR(50),
    email VARCHAR(100),
    office_number VARCHAR(20),
    hire_date DATE,
    salary NUMERIC(12,2),
    is_tenured BOOLEAN,
    years_experience INTEGER
);

CREATE TABLE courses (
    course_id SERIAL PRIMARY KEY,
    course_code CHAR(8),
    course_title VARCHAR(100),
    description TEXT,
    credits SMALLINT,
    max_enrollment INTEGER,
    course_fee NUMERIC(10,2),
    is_online BOOLEAN,
    created_at TIMESTAMP WITHOUT TIME ZONE
);

-- Task 2.2
-- Students table
DROP TABLE IF EXISTS students CASCADE;
CREATE TABLE students (
    student_id SERIAL PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    phone CHAR(15),
    date_of_birth DATE CHECK (date_of_birth < CURRENT_DATE),
    enrollment_date DATE DEFAULT CURRENT_DATE,
    gpa NUMERIC(3,2) CHECK (gpa >= 0 AND gpa <= 4),
    is_active BOOLEAN DEFAULT TRUE,
    graduation_year SMALLINT
);

-- Professors table
DROP TABLE IF EXISTS professors CASCADE;
CREATE TABLE professors (
    professor_id SERIAL PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    office_number VARCHAR(20),
    hire_date DATE DEFAULT CURRENT_DATE,
    salary NUMERIC(12,2) CHECK (salary >= 0),
    is_tenured BOOLEAN DEFAULT FALSE,
    years_experience INTEGER CHECK (years_experience >= 0)
);

-- Courses table
DROP TABLE IF EXISTS courses CASCADE;
CREATE TABLE courses (
    course_id SERIAL PRIMARY KEY,
    course_code CHAR(8) UNIQUE NOT NULL,
    course_title VARCHAR(100) NOT NULL,
    description TEXT,
    credits SMALLINT CHECK (credits > 0),
    max_enrollment INTEGER CHECK (max_enrollment > 0),
    course_fee NUMERIC(10,2) CHECK (course_fee >= 0),
    is_online BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Part3
-- Task 3.1

-- STUDENTS
-- 1.
ALTER TABLE students
ADD COLUMN middle_name VARCHAR(30);
-- 2.
ALTER TABLE students
ADD COLUMN student_status VARCHAR(20);
-- 3.
ALTER TABLE students
ALTER COLUMN phone TYPE VARCHAR(20);
-- 4.
ALTER TABLE students
ALTER COLUMN student_status SET DEFAULT 'ACTIVE';
-- 5.
ALTER TABLE students
ALTER COLUMN gpa SET DEFAULT 0.00;


-- PROFESSORS
-- 1.
ALTER TABLE professors
ADD COLUMN department_code CHAR(5);
-- 2.
ALTER TABLE professors
ADD COLUMN research_area TEXT;
-- 3.
ALTER TABLE professors
ALTER COLUMN years_experience TYPE SMALLINT;
-- 4.
ALTER TABLE professors
ALTER COLUMN is_tenured SET DEFAULT false;
-- 5.
ALTER TABLE professors
ADD COLUMN last_promotion_date DATE;

--  COURSES
-- 1.
ALTER TABLE courses
ADD COLUMN prerequisite_course_id INTEGER;
-- 2.
ALTER TABLE courses
ADD COLUMN difficulty_level SMALLINT;
-- 3.
ALTER TABLE courses
ALTER COLUMN course_code TYPE VARCHAR(10);
-- 4.
ALTER TABLE courses
ALTER COLUMN credits SET DEFAULT 3;
-- 5.
ALTER TABLE courses
ADD COLUMN lab_required BOOLEAN DEFAULT false;

-- Task 3.2
-- Создание таблицы class_schedule
CREATE TABLE class_schedule (
    schedule_id SERIAL PRIMARY KEY,
    class_name VARCHAR(100) NOT NULL,
    classroom VARCHAR(20),
    duration INTERVAL
);

-- Создание таблицы student_records
CREATE TABLE student_records (
    record_id SERIAL PRIMARY KEY,
    student_id INT REFERENCES students(student_id),
    course_id INT REFERENCES courses(course_id),
    grade CHAR(2),
    last_updated TIMESTAMP
);


-- For	class_schedule	table:
-- 1. Добавляем колонку room_capacity
ALTER TABLE class_schedule
ADD COLUMN room_capacity integer;

-- 2. Удаляем колонку duration
ALTER TABLE class_schedule
DROP COLUMN duration;

-- 3. Добавляем колонку session_type
ALTER TABLE class_schedule
ADD COLUMN session_type varchar(15);

-- 4. Меняем тип колонки classroom на varchar(30)
ALTER TABLE class_schedule
ALTER COLUMN classroom TYPE varchar(30);

-- 5. Добавляем колонку equipment_needed
ALTER TABLE class_schedule
ADD COLUMN equipment_needed text;

--Part 4
-- Task 4.1
-- 1. Departments table
CREATE TABLE departments (
    department_id SERIAL PRIMARY KEY,
    department_name VARCHAR(100) NOT NULL,
    department_code CHAR(5) NOT NULL,
    building VARCHAR(50),
    phone VARCHAR(15),
    budget NUMERIC(18,2) CHECK (budget >= 0)
);

-- 2. Library_books table
CREATE TABLE library_books (
    book_id SERIAL PRIMARY KEY,
    isbn CHAR(13) NOT NULL UNIQUE,
    title VARCHAR(200) NOT NULL,
    author VARCHAR(100),
    publisher VARCHAR(100),
    publication_date DATE,
    price NUMERIC(10,2) CHECK (price >= 0),
    is_available BOOLEAN DEFAULT TRUE,
    acquisition_timestamp TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 3. Student_book_loans table
CREATE TABLE student_book_loans (
    loan_id SERIAL PRIMARY KEY,
    student_id INT NOT NULL REFERENCES students(student_id),
    book_id INT NOT NULL REFERENCES library_books(book_id),
    loan_date DATE NOT NULL,
    due_date DATE NOT NULL,
    return_date DATE,
    fine_amount NUMERIC(10,2) DEFAULT 0.00,
    loan_status VARCHAR(20) DEFAULT 'ONGOING'
);

-- Task 4.2
-- 1. Add foreign key columns
ALTER TABLE professors
ADD COLUMN department_id INT;

ALTER TABLE students
ADD COLUMN advisor_id INT;

ALTER TABLE courses
ADD COLUMN department_id INT;

-- 2.  grade_scale
CREATE TABLE grade_scale (
    grade_id SERIAL PRIMARY KEY,
    letter_grade CHAR(2) NOT NULL,
    min_percentage DECIMAL(4,1) CHECK (min_percentage >= 0),
    max_percentage DECIMAL(4,1) CHECK (max_percentage <= 100),
    gpa_points DECIMAL(3,2) CHECK (gpa_points >= 0)
);

-- 3. semester_calendar
CREATE TABLE semester_calendar (
    semester_id SERIAL PRIMARY KEY,
    semester_name VARCHAR(20) NOT NULL,
    academic_year INT CHECK (academic_year >= 0),
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    registration_deadline TIMESTAMPTZ,
    is_current BOOLEAN DEFAULT FALSE
);


--Part5
-- Task 5.1
-- 1.Drop tables if they exist
DROP TABLE IF EXISTS student_book_loans;
DROP TABLE IF EXISTS library_books;
DROP TABLE IF EXISTS grade_scale;

--2.
CREATE TABLE grade_scale (
    grade_id SERIAL PRIMARY KEY,
    letter_grade CHAR(2) NOT NULL,
    min_percentage DECIMAL(4,1) CHECK (min_percentage >= 0),
    max_percentage DECIMAL(4,1) CHECK (max_percentage <= 100),
    gpa_points DECIMAL(3,2) CHECK (gpa_points >= 0),
    description TEXT
);

-- 3. Drop and recreate semester_calendar with CASCADE
DROP TABLE IF EXISTS semester_calendar CASCADE;

CREATE TABLE semester_calendar (
    semester_id SERIAL PRIMARY KEY,
    semester_name VARCHAR(20) NOT NULL,
    academic_year INT CHECK (academic_year >= 0),
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    registration_deadline TIMESTAMPTZ,
    is_current BOOLEAN DEFAULT FALSE
);

--Task 5.2
-- Drop databases if they exist
DROP DATABASE IF EXISTS university_test;
DROP DATABASE IF EXISTS university_distributed;

-- Create new database using university_main as template
CREATE DATABASE university_backup
    TEMPLATE university_main
    ENCODING 'UTF8';

