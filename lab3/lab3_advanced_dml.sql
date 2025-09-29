-- Lab 3 - Advanced DML Operations

-- Part A: Database and Table Setup

-- Drop old database if exists
DROP DATABASE IF EXISTS advanced_lab;
CREATE DATABASE advanced_lab;
-- Connect to new database
\c advanced_lab;

-- Create employees table
DROP TABLE IF EXISTS employees CASCADE;
CREATE TABLE employees (
    emp_id SERIAL PRIMARY KEY,                 -- employee id
    first_name VARCHAR(50) NOT NULL,           -- first name
    last_name VARCHAR(50) NOT NULL,            -- last name
    department VARCHAR(50) DEFAULT 'Unassigned', -- default department
    salary INTEGER DEFAULT 30000 CHECK (salary >= 0), -- salary must be >= 0
    hire_date DATE DEFAULT CURRENT_DATE,       -- default today
    status VARCHAR(20) DEFAULT 'Active'        -- default status
);

-- Create departments table
DROP TABLE IF EXISTS departments CASCADE;
CREATE TABLE departments (
    dept_id SERIAL PRIMARY KEY,
    dept_name VARCHAR(50) UNIQUE NOT NULL,     -- department name must be unique
    budget INTEGER CHECK (budget >= 0),        -- budget must be >= 0
    manager_id INTEGER
);

-- sample data
-- Sample employees
INSERT INTO employees (first_name, last_name, department, salary, hire_date, status) VALUES
('Alice', 'Brown', 'IT', 60000, '2019-05-10', 'Active'),
('Bob', 'Smith', 'Sales', 45000, '2021-03-15', 'Active'),
('Charlie', 'White', 'HR', 38000, '2023-06-01', 'Inactive'),
('Diana', 'Green', 'Finance', 90000, '2018-07-20', 'Active');

-- Sample departments
INSERT INTO departments (dept_name, budget, manager_id) VALUES
('IT', 150000, 1),
('Sales', 120000, 2),
('HR', 80000, 3),
('Finance', 100000, 4);

-- Sample projects
INSERT INTO projects (project_name, dept_id, start_date, end_date, budget) VALUES
('Project A', 1, '2022-01-01', '2023-05-01', 60000),
('Project B', 2, '2023-02-01', '2024-01-01', 40000),
('Project C', 3, '2021-06-15', '2022-12-31', 80000);


SELECT * FROM departments;
SELECT * FROM employees;

-- Create projects table
DROP TABLE IF EXISTS projects CASCADE;
CREATE TABLE projects (
    project_id SERIAL PRIMARY KEY,
    project_name VARCHAR(100) NOT NULL,        -- project name
    dept_id INTEGER REFERENCES departments(dept_id) ON DELETE SET NULL, -- foreign key
    start_date DATE,
    end_date DATE,
    budget INTEGER CHECK (budget >= 0)
);

-- Part B: INSERT Operations

-- 2. Insert with column list
INSERT INTO employees (first_name, last_name, department)
VALUES ('Amina', 'Shakirbek', 'IT');

-- 3. Insert with default values
INSERT INTO employees (first_name, last_name, hire_date)
VALUES ('Boris', 'Ivanov', CURRENT_DATE);

-- 4. Insert multiple rows
INSERT INTO departments (dept_name, budget, manager_id)
VALUES
('IT', 150000, 1),
('Sales', 120000, 2),
('HR', 80000, 3);

-- 5. Insert with expression
INSERT INTO employees (first_name, last_name, department, salary, hire_date)
VALUES ('Dana', 'Aliyeva', 'Finance', 50000 * 1.1, CURRENT_DATE);

-- 6. Insert from SELECT into temp table
CREATE TEMP TABLE temp_employees AS
SELECT * FROM employees WHERE department = 'IT';

SELECT * FROM temp_employees;

-- Part C: UPDATE Operations

-- 7. Increase all salaries by 10%
UPDATE employees
SET salary = salary * 1.1;

-- 8. Update status to Senior if condition true
UPDATE employees
SET status = 'Senior'
WHERE salary > 60000 AND hire_date < '2020-01-01';

-- 9. Use CASE to change department
UPDATE employees
SET department = CASE
    WHEN salary > 80000 THEN 'Management'
    WHEN salary BETWEEN 50000 AND 80000 THEN 'Senior'
    ELSE 'Junior'
END;

-- 10. Set department to default if status = Inactive
UPDATE employees
SET department = DEFAULT
WHERE status = 'Inactive';

-- 11. Update department budget with average salary * 1.2
UPDATE departments
SET budget = (SELECT AVG(salary) * 1.2
              FROM employees e
              WHERE e.department = departments.dept_name);

-- 12. Update two columns at the same time
UPDATE employees
SET salary = salary * 1.15,
    status = 'Promoted'
WHERE department = 'Sales';

-- Part D: DELETE Operations

-- 13. Delete employees with status Terminated
DELETE FROM employees WHERE status = 'Terminated';

-- 14. Delete with complex condition
DELETE FROM employees
WHERE salary < 40000 AND hire_date > '2023-01-01' AND department IS NULL;

-- 15. Delete departments without employees
DELETE FROM departments d
WHERE dept_name NOT IN (
    SELECT DISTINCT department FROM employees WHERE department IS NOT NULL
);

-- 16. Delete projects and return deleted rows
DELETE FROM projects
WHERE end_date < '2023-01-01'
RETURNING *;

-- Part E: NULL values

-- 17. Insert row with NULL values
INSERT INTO employees (first_name, last_name, salary, department)
VALUES ('NULL-Test', 'User', NULL, NULL);

-- 18. Update NULL department to Unassigned
UPDATE employees
SET department = 'Unassigned'
WHERE department IS NULL;

-- 19. Delete rows with NULL salary or department
DELETE FROM employees
WHERE salary IS NULL OR department IS NULL;

-- Part F: RETURNING

-- 20. Insert and return emp_id + full name
INSERT INTO employees (first_name, last_name, department)
VALUES ('Return', 'Tester', 'QA')
RETURNING emp_id, first_name || ' ' || last_name AS full_name;

-- 21. Update salary and return old + new values
UPDATE employees
SET salary = salary + 5000
WHERE department = 'IT'
RETURNING emp_id, salary - 5000 AS old_salary, salary AS new_salary;

-- 22. Delete and return all columns
DELETE FROM employees
WHERE hire_date < '2020-01-01'
RETURNING *;

-- Part G: Advanced Patterns

-- 23. Insert only if row does not exist
INSERT INTO employees (first_name, last_name, department)
SELECT 'Unique', 'Person', 'R&D'
WHERE NOT EXISTS (
    SELECT 1 FROM employees WHERE first_name = 'Unique' AND last_name = 'Person'
);

-- 24. Update salary using department budget
UPDATE employees
SET salary = salary * CASE
    WHEN (SELECT budget FROM departments d WHERE d.dept_name = employees.department) > 100000
    THEN 1.1 ELSE 1.05 END;

-- 25. Bulk insert + bulk update
INSERT INTO employees (first_name, last_name, department, salary, hire_date)
VALUES
('E1', 'L1', 'Sales', 40000, CURRENT_DATE),
('E2', 'L2', 'Sales', 42000, CURRENT_DATE),
('E3', 'L3', 'Sales', 43000, CURRENT_DATE),
('E4', 'L4', 'Sales', 44000, CURRENT_DATE),
('E5', 'L5', 'Sales', 45000, CURRENT_DATE);

UPDATE employees
SET salary = salary * 1.1
WHERE last_name LIKE 'L%';

-- 26. Archive inactive employees
DROP TABLE IF EXISTS employee_archive;
CREATE TABLE employee_archive AS TABLE employees WITH NO DATA;

INSERT INTO employee_archive
SELECT * FROM employees WHERE status = 'Inactive';

DELETE FROM employees WHERE status = 'Inactive';

-- 27. Extend project end_date if condition true
UPDATE projects p
SET end_date = end_date + INTERVAL '30 days'
WHERE budget > 50000
AND p.dept_id IN (
    SELECT d.dept_id FROM departments d
    WHERE (SELECT COUNT(*) FROM employees e WHERE e.department = d.dept_name) > 3
);

