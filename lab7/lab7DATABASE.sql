--Lab7
--Using tables from lab6

--Part 2
-- exercise 2.1
CREATE VIEW employee_details AS
SELECT
    e.emp_id,
    e.emp_name,
    e.salary,
    d.dept_name,
    d.location
FROM employees e
INNER JOIN departments d ON e.dept_id=d.dept_id;
--testing
SELECT * FROM employee_details;
--answers for questions
--4 rows are returned. Tom Brown doesn't appear because he has dept_id = NULL and we used INNER JOIN
--which only returns matching records from both tables. Employees without a department assignment are excluded.

--exercise 2.2 with aggregation
CREATE VIEW dept_statistics AS
SELECT
    d.dept_id,
    d.dept_name,
    COUNT(e.emp_id) AS employee_count,
    COALESCE(AVG(e.salary),0) AS avg_salary,
    COALESCE(MAX(e.salary),0) AS max_salary,
    COALESCE(MIN(e.salary),0) AS min_salary
FROM departments d
LEFT JOIN employees e ON d.dept_id=e.dept_id
GROUP BY d.dept_id, d.dept_name;
--testing
SELECT * FROM dept_statistics ORDER BY employee_count DESC;

--exercise 2.3 with multiple joins
CREATE VIEW project_overview AS
SELECT
    p.project_name,
    p.budget,
    d.dept_name,
    d.location,
    COUNT(e.emp_id) AS team_size
FROM projects p
JOIN departments d ON p.dept_id=d.dept_id
LEFT JOIN employees e ON d.dept_id=e.dept_id
GROUP BY P.PROJECT_ID, p.project_name, p.budget, d.dept_name, d.location;
--testing, just my examples
--Проверить проекты по конкретному отделу
SELECT * FROM project_overview
WHERE dept_name = 'IT';
--Проверить проекты с самой большой командой
SELECT * FROM project_overview
ORDER BY team_size DESC;
--Проверить общее количество проектов
SELECT COUNT(*) as total_projects FROM project_overview;
--Проверить сумму бюджетов всех проектов
SELECT SUM(budget) as total_budgets FROM project_overview;

--exercise 2.4 with filtering
CREATE VIEW high_earners AS
SELECT
    e.emp_name,
    e.salary,
    d.dept_name
FROM employees e
LEFT JOIN departments d ON e.dept_id=d.dept_id
WHERE e.salary>55000;
--testing
SELECT * FROM high_earners;
--ya dobavlu
--answers for questions
--Answer: When you query the high_earners view, you only see employees with salaries greater than $55,000.
--Yes, you can see all high-earning employees who meet this criteria, but employees with salaries ≤ $55,000
--(like Tom Brown with $48,000) are excluded.

--PART 3
--exercise 3.1 with replace
CREATE OR REPLACE VIEW employee_details AS
SELECT
    e.emp_id,
    e.emp_name,
    e.salary,
    d.dept_name,
    d.location,
    CASE
        WHEN e.salary > 60000 THEN 'High'
        WHEN e.salary > 50000 THEN 'Medium'
        ELSE 'Standard'
    END AS salary_grade
FROM employees e
INNER JOIN departments d ON e.dept_id=d.dept_id;
--testing
SELECT * FROM employee_details ORDER BY salary DESC;

--exercise 3.2 with rename
ALTER VIEW high_earners RENAME TO top_performers;
--testing
SELECT * FROM top_performers;

--exercise 3.3 with drop
CREATE VIEW temp_view AS
SELECT * FROM employees WHERE salary<50000;

SELECT * FROM temp_view;
DROP VIEW temp_view;

--PART 4
--exercise 4.1 with Updatable View
CREATE VIEW employee_salaries AS
SELECT emp_id, emp_name, dept_id, salary
FROM employees;

--exercise 4.2 update through a view
UPDATE employee_salaries
SET salary=52000
WHERE emp_name='John Smith';
--verify
SELECT * FROM employees WHERE emp_name='John Smith';
--question: Yes, the underlying table was updated.

--exercise 4.3 insert through a view
INSERT INTO employee_salaries(emp_id,emp_name,dept_id,salary)
VALUES(6,'Alice Johnson',102,58000);
--verify
SELECT * FROM employees;
--question: yes, insert was successful.

--exercise 4.4 CHECK OPTION
CREATE VIEW it_employees AS
SELECT emp_id, emp_name, dept_id, salary
FROM employees
WHERE dept_id=101
WITH LOCAL CHECK OPTION;
--Test 4.4 (this should fail)
--INSERT INTO it_employees (emp_id, emp_name, dept_id, salary)
--VALUES (7, 'Bob Wilson', 103, 60000);
--Question: Error "new row violates check option for view 'it_employees'"

--PART 5 Materialized Views

--exercise 5.1: create a Materialized View
CREATE MATERIALIZED VIEW dept_summary_mv AS
SELECT
    d.dept_id,
    d.dept_name,
    COUNT(e.emp_id) AS total_employees,
    COALESCE(SUM(e.salary), 0) AS total_salaries,
    COUNT(p.project_id) AS total_projects,
    COALESCE(SUM(p.budget), 0) AS total_budget
FROM departments d
LEFT JOIN employees e ON d.dept_id = e.dept_id
LEFT JOIN projects p ON d.dept_id = p.dept_id
GROUP BY d.dept_id, d.dept_name
WITH DATA;
--Test 5.1
SELECT * FROM dept_summary_mv ORDER BY total_employees DESC;

--exercise 5.2: Refresh Materialized View
INSERT INTO employees (emp_id, emp_name, dept_id, salary)
VALUES (8, 'Charlie Brown', 101, 54000);
--Before refresh
SELECT * FROM dept_summary_mv WHERE dept_id = 101;
--Refresh
REFRESH MATERIALIZED VIEW dept_summary_mv;
--After refresh
SELECT * FROM dept_summary_mv WHERE dept_id = 101;
--question: before refresh - old data, after refresh - includes new employee.

-- exercise 5.3: Concurrent Refresh
CREATE UNIQUE INDEX idx_dept_summary_mv ON dept_summary_mv (dept_id);
REFRESH MATERIALIZED VIEW CONCURRENTLY dept_summary_mv;
--question: CONCURRENTLY allows queries during refresh, no locking.

--exercise 5.4: Materialized View with NO DATA
CREATE MATERIALIZED VIEW project_stats_mv AS
SELECT
    p.project_name,
    p.budget,
    d.dept_name,
    COUNT(e.emp_id) AS assigned_employees
FROM projects p
JOIN departments d ON p.dept_id = d.dept_id
LEFT JOIN employees e ON d.dept_id = e.dept_id
GROUP BY p.project_id, p.project_name, p.budget, d.dept_name
WITH NO DATA;

--Test 5.4 (this will error)
-- SELECT * FROM project_stats_mv;
-- Question: Error "materialized view has not been populated"

--Fix 5.4
REFRESH MATERIALIZED VIEW project_stats_mv;

-- PART 6 Database Roles
--exercise 6.1: Create Basic Roles
CREATE ROLE analyst;
CREATE ROLE data_viewer WITH LOGIN PASSWORD 'viewer123';
CREATE ROLE report_user WITH LOGIN PASSWORD 'report456';
--View all roles
SELECT rolname FROM pg_roles WHERE rolname NOT LIKE 'pg_%';
--Exercise 6.2: Role with Specific Attributes
CREATE ROLE db_creator WITH CREATEDB LOGIN PASSWORD 'creator789';
CREATE ROLE user_manager WITH CREATEROLE LOGIN PASSWORD 'manager101';
CREATE ROLE admin_user WITH SUPERUSER LOGIN PASSWORD 'admin999';

--Exercise 6.3: Grant Privileges to Roles
GRANT SELECT ON employees, departments, projects TO analyst;
GRANT ALL PRIVILEGES ON employee_details TO data_viewer;
GRANT SELECT, INSERT ON employees TO report_user;

--Exercise 6.4: Create Group Roles
CREATE ROLE hr_team;
CREATE ROLE finance_team;
CREATE ROLE it_team;

CREATE ROLE hr_user1 WITH LOGIN PASSWORD 'hr001';
CREATE ROLE hr_user2 WITH LOGIN PASSWORD 'hr002';
CREATE ROLE finance_user1 WITH LOGIN PASSWORD 'fin001';

GRANT hr_team TO hr_user1, hr_user2;
GRANT finance_team TO finance_user1;

GRANT SELECT, UPDATE ON employees TO hr_team;
GRANT SELECT ON dept_statistics TO finance_team;

--Exercise 6.5: Revoke Privileges
REVOKE UPDATE ON employees FROM hr_team;
REVOKE hr_team FROM hr_user2;
REVOKE ALL PRIVILEGES ON employee_details FROM data_viewer;

--Exercise 6.6: Modify Role Attributes
ALTER ROLE analyst WITH LOGIN PASSWORD 'analyst123';
ALTER ROLE user_manager WITH SUPERUSER;
ALTER ROLE analyst WITH PASSWORD NULL;
ALTER ROLE data_viewer WITH CONNECTION LIMIT 5;

--PART 7 Advanced Role Management

--Exercise 7.1: Role Hierarchies
CREATE ROLE read_only;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO read_only;

CREATE ROLE junior_analyst WITH LOGIN PASSWORD 'junior123';
CREATE ROLE senior_analyst WITH LOGIN PASSWORD 'senior123';

GRANT read_only TO junior_analyst, senior_analyst;
GRANT INSERT, UPDATE ON employees TO senior_analyst;

--Exercise 7.2: Object Ownership
CREATE ROLE project_manager WITH LOGIN PASSWORD 'pm123';
ALTER VIEW dept_statistics OWNER TO project_manager;
ALTER TABLE projects OWNER TO project_manager;
--Check ownership
SELECT tablename, tableowner
FROM pg_tables
WHERE schemaname = 'public';

--Exercise 7.3: Reassign and Drop Roles
CREATE ROLE temp_owner WITH LOGIN;
CREATE TABLE temp_table (id INT);
ALTER TABLE temp_table OWNER TO temp_owner;

REASSIGN OWNED BY temp_owner TO postgres;
DROP OWNED BY temp_owner;
DROP ROLE temp_owner;

--Exercise 7.4: Row-Level Security with Views
CREATE VIEW hr_employee_view AS
SELECT emp_id, emp_name, salary, dept_id
FROM employees
WHERE dept_id = 102;

GRANT SELECT ON hr_employee_view TO hr_team;

CREATE VIEW finance_employee_view AS
SELECT emp_id, emp_name, salary
FROM employees;

GRANT SELECT ON finance_employee_view TO finance_team;

-- PART 8 Practical Scenarios
-- Exercise 8.1: Department Dashboard View
CREATE VIEW dept_dashboard AS
SELECT
    d.dept_name,
    d.location,
    COUNT(e.emp_id) AS employee_count,
    ROUND(COALESCE(AVG(e.salary), 0), 2) AS avg_salary,
    COUNT(p.project_id) AS active_projects,
    COALESCE(SUM(p.budget), 0) AS total_budget,
    CASE
        WHEN COUNT(e.emp_id) > 0 THEN ROUND(COALESCE(SUM(p.budget), 0) / COUNT(e.emp_id), 2)
        ELSE 0
    END AS budget_per_employee
FROM departments d
LEFT JOIN employees e ON d.dept_id = e.dept_id
LEFT JOIN projects p ON d.dept_id = p.dept_id
GROUP BY d.dept_id, d.dept_name, d.location;

--Exercise 8.2: Audit View
ALTER TABLE projects ADD COLUMN created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP;

CREATE VIEW high_budget_projects AS
SELECT
    project_name,
    budget,
    dept_name,
    created_date,
    CASE
        WHEN budget > 150000 THEN 'Critical Review Required'
        WHEN budget > 100000 THEN 'Management Approval Needed'
        ELSE 'Standard Process'
    END AS approval_status
FROM projects p
JOIN departments d ON p.dept_id = d.dept_id
WHERE budget > 75000;

--Exercise 8.3: Create Access Control System
CREATE ROLE viewer_role;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO viewer_role;

CREATE ROLE entry_role;
GRANT viewer_role TO entry_role;
GRANT INSERT ON employees, projects TO entry_role;

CREATE ROLE analyst_role;
GRANT entry_role TO analyst_role;
GRANT UPDATE ON employees, projects TO analyst_role;

CREATE ROLE manager_role;
GRANT analyst_role TO manager_role;
GRANT DELETE ON employees, projects TO manager_role;

CREATE ROLE alice WITH LOGIN PASSWORD 'alice123';
CREATE ROLE bob WITH LOGIN PASSWORD 'bob123';
CREATE ROLE charlie WITH LOGIN PASSWORD 'charlie123';

GRANT viewer_role TO alice;
GRANT analyst_role TO bob;
GRANT manager_role TO charlie;

--TESTING QUERIES
--Test all views
SELECT 'employee_details:' as test;
SELECT * FROM employee_details;

SELECT 'dept_statistics:' as test;
SELECT * FROM dept_statistics ORDER BY employee_count DESC;

SELECT 'project_overview:' as test;
SELECT * FROM project_overview;

SELECT 'top_performers:' as test;
SELECT * FROM top_performers;

SELECT 'dept_dashboard:' as test;
SELECT * FROM dept_dashboard;

SELECT 'high_budget_projects:' as test;
SELECT * FROM high_budget_projects;

--Check roles
SELECT 'Roles:' as test;
SELECT rolname FROM pg_roles WHERE rolname NOT LIKE 'pg_%' AND rolname NOT LIKE 'postgres';