-- Lab4
DROP TABLE IF EXISTS employees;
DROP TABLE IF EXISTS projects;
DROP TABLE IF EXISTS assignments;

CREATE TABLE employees (
 employee_id SERIAL PRIMARY KEY,
 first_name VARCHAR(50),
 last_name VARCHAR(50),
 department VARCHAR(50),
 salary NUMERIC(10,2),
 hire_date DATE,
 manager_id INTEGER,
 email VARCHAR(100)
);

CREATE TABLE projects (
 project_id SERIAL PRIMARY KEY,
 project_name VARCHAR(100),
 budget NUMERIC(12,2),
 start_date DATE,
 end_date DATE,
 status VARCHAR(20)
);

CREATE TABLE assignments (
 assignment_id SERIAL PRIMARY KEY,
 employee_id INTEGER REFERENCES employees(employee_id),
 project_id INTEGER REFERENCES projects(project_id),
 hours_worked NUMERIC(5,1),
 assignment_date DATE
);

--INSERT DATA
INSERT INTO employees (first_name, last_name, department,
salary, hire_date, manager_id, email) VALUES
('John', 'Smith', 'IT', 75000, '2020-01-15', NULL,
'john.smith@company.com'),
('Sarah', 'Johnson', 'IT', 65000, '2020-03-20', 1,
'sarah.j@company.com'),
('Michael', 'Brown', 'Sales', 55000, '2019-06-10', NULL,
'mbrown@company.com'),
('Emily', 'Davis', 'HR', 60000, '2021-02-01', NULL,
'emily.davis@company.com'),
('Robert', 'Wilson', 'IT', 70000, '2020-08-15', 1, NULL),
('Lisa', 'Anderson', 'Sales', 58000, '2021-05-20', 3,
'lisa.a@company.com');

INSERT INTO projects (project_name, budget, start_date,
end_date, status) VALUES
('Website Redesign', 150000, '2024-01-01', '2024-06-30',
'Active'),
('CRM Implementation', 200000, '2024-02-15', '2024-12-31',
'Active'),
('Marketing Campaign', 80000, '2024-03-01', '2024-05-31',
'Completed'),
('Database Migration', 120000, '2024-01-10', NULL, 'Active');

INSERT INTO assignments (employee_id, project_id,
hours_worked, assignment_date) VALUES
(1, 1, 120.5, '2024-01-15'),
(2, 1, 95.0, '2024-01-20'),
(1, 4, 80.0, '2024-02-01'),
(3, 3, 60.0, '2024-03-05'),
(5, 2, 110.0, '2024-02-20'),
(6, 3, 75.5, '2024-03-10');

--Task 1.1
SELECT
  employee_id,
  first_name || ' ' || last_name AS full_name,
  department,
  salary
FROM employees;

-- Task 1.2: We find all unique departments using DISTINCT.
SELECT DISTINCT department
FROM employees;

-- Task 1.3: We select projects and add budget_category using CASE.
SELECT
  project_id,
  project_name,
  budget,
  CASE
    WHEN budget > 150000 THEN 'Large'
    WHEN budget BETWEEN 100000 AND 150000 THEN 'Medium'
    ELSE 'Small'
  END AS budget_category
FROM projects;

-- Task 1.4: We show employee names and email using COALESCE for NULL emails.
SELECT
  employee_id,
  first_name || ' ' || last_name AS full_name,
  COALESCE(email, 'No email provided') AS email_display
FROM employees;


-- Part 2
-- Task 2.1: We find employees hired after 2020-01-01.
SELECT
  employee_id,
  first_name || ' ' || last_name AS full_name,
  hire_date
FROM employees
WHERE hire_date > DATE '2020-01-01';

-- Task 2.2: We find employees with salary between 60000 and 70000.
SELECT
  employee_id,
  first_name || ' ' || last_name AS full_name,
  salary
FROM employees
WHERE salary BETWEEN 60000 AND 70000;

-- Task 2.3: We find employees whose last name starts with 'S' or 'J'.
SELECT
  employee_id,
  first_name || ' ' || last_name AS full_name,
  last_name
FROM employees
WHERE last_name LIKE 'S%' OR last_name LIKE 'J%';

-- Task 2.4: We find employees who have a manager and are in IT department.
SELECT
  employee_id,
  first_name || ' ' || last_name AS full_name,
  department,
  manager_id
FROM employees
WHERE manager_id IS NOT NULL
  AND department = 'IT';


-- Part 3
-- Task 3.1: Names uppercase, length of last name, first 3 chars of email.
SELECT
  employee_id,
  UPPER(first_name || ' ' || last_name) AS name_upper,
  LENGTH(last_name) AS last_name_length,
  -- use LEFT(email, 3) to get the first 3 characters; handle NULL safely
  CASE WHEN email IS NULL THEN NULL ELSE LEFT(email, 3) END AS email_first3
FROM employees;

-- Task 3.2: Annual salary, monthly salary (rounded), and 10% raise amount.
SELECT
  employee_id,
  first_name || ' ' || last_name AS full_name,
  salary AS annual_salary,
  ROUND(salary / 12.0, 2) AS monthly_salary,
  (salary * 0.10) AS raise_10_percent
FROM employees;

-- Task 3.3: Use format() to create a formatted string for each project.
SELECT
  project_id,
  format('Project: %s - Budget: $%s - Status: %s',
         project_name,
         to_char(budget, 'FM999,999,999.00'),
         status) AS project_summary
FROM projects;

-- Task 3.4
SELECT
  employee_id,
  first_name || ' ' || last_name AS full_name,
  hire_date,
  EXTRACT(YEAR FROM AGE(current_date, hire_date))::INT AS years_with_company
FROM employees;


-- Part 4
-- Task 4.1: Average salary per department.
SELECT
  department,
  ROUND(AVG(salary)::numeric, 2) AS avg_salary
FROM employees
GROUP BY department;

-- Task 4.2: Total hours worked on each project, including project name.
SELECT
  p.project_id,
  p.project_name,
  COALESCE(SUM(a.hours_worked), 0) AS total_hours_worked
FROM projects p
LEFT JOIN assignments a ON p.project_id = a.project_id
GROUP BY p.project_id, p.project_name
ORDER BY p.project_id;

-- Task 4.3: Count employees per department; only show departments with more than 1 employee.
SELECT
  department,
  COUNT(*) AS employee_count
FROM employees
GROUP BY department
HAVING COUNT(*) > 1;

-- Task 4.4: Max salary, min salary, and total payroll.
SELECT
  MAX(salary) AS max_salary,
  MIN(salary) AS min_salary,
  SUM(salary) AS total_payroll
FROM employees;


-- Part 5: Set Operations
-- Task 5.1: UNION two queries:
SELECT employee_id, first_name || ' ' || last_name AS full_name, salary
FROM employees
WHERE salary > 65000

UNION

SELECT employee_id, first_name || ' ' || last_name AS full_name, salary
FROM employees
WHERE hire_date > DATE '2020-01-01'
ORDER BY employee_id;

-- Task 5.2: INTERSECT: employees who work in IT AND have salary > 65000.
SELECT employee_id, first_name || ' ' || last_name AS full_name, department, salary
FROM employees
WHERE department = 'IT'

INTERSECT

SELECT employee_id, first_name || ' ' || last_name AS full_name, department, salary
FROM employees
WHERE salary > 65000;

-- Task 5.3
SELECT employee_id, first_name || ' ' || last_name AS full_name
FROM employees

EXCEPT

SELECT e.employee_id, e.first_name || ' ' || e.last_name AS full_name
FROM employees e
JOIN assignments a ON e.employee_id = a.employee_id
ORDER BY employee_id;


-- Part 6
-- Task 6.1: Use EXISTS to find employees who have at least one assignment.
SELECT
  e.employee_id,
  e.first_name || ' ' || e.last_name AS full_name
FROM employees e
WHERE EXISTS (
  SELECT 1 FROM assignments a WHERE a.employee_id = e.employee_id
);

-- Task 6.2: Use IN with subquery to find employees working on 'Active' projects.
SELECT
  e.employee_id,
  e.first_name || ' ' || e.last_name AS full_name
FROM employees e
WHERE e.employee_id IN (
  SELECT a.employee_id
  FROM assignments a
  JOIN projects p ON a.project_id = p.project_id
  WHERE p.status = 'Active'
);

-- Task 6.3: Use ANY to find employees whose salary is greater than ANY employee in Sales.
SELECT
  employee_id,
  first_name || ' ' || last_name AS full_name,
  salary
FROM employees
WHERE salary > ANY (
  SELECT salary FROM employees WHERE department = 'Sales'
);


-- Part 7
-- Task 7.1
SELECT
  e.employee_id,
  e.first_name || ' ' || e.last_name AS full_name,
  e.department,
  COALESCE(ROUND(AVG(a.hours_worked)::numeric, 2), 0) AS avg_hours_worked,
  RANK() OVER (PARTITION BY e.department ORDER BY e.salary DESC) AS dept_salary_rank
FROM employees e
LEFT JOIN assignments a ON e.employee_id = a.employee_id
GROUP BY e.employee_id, e.first_name, e.last_name, e.department, e.salary
ORDER BY e.department, dept_salary_rank;

-- Task 7.2: Find projects where total hours worked exceeds 150 hours.
SELECT
  p.project_id,
  p.project_name,
  SUM(a.hours_worked) AS total_hours,
  COUNT(DISTINCT a.employee_id) AS num_employees_assigned
FROM projects p
JOIN assignments a ON p.project_id = a.project_id
GROUP BY p.project_id, p.project_name
HAVING SUM(a.hours_worked) > 150
ORDER BY total_hours DESC;

-- Task 7.3
SELECT
  d.department,
  d.total_employees,
  ROUND(d.avg_salary::numeric, 2) AS avg_salary,
  d.max_salary,
  d.min_salary,
  -- Demonstrate GREATEST and LEAST: compare avg_salary with max/min for illustration
  GREATEST(d.max_salary, d.avg_salary) AS greatest_of_max_and_avg,
  LEAST(d.min_salary, d.avg_salary) AS least_of_min_and_avg,
  -- Highest paid employee name using a correlated subquery
  (SELECT first_name || ' ' || last_name
   FROM employees e2
   WHERE e2.department = d.department
   ORDER BY salary DESC
   LIMIT 1) AS highest_paid_employee_name
FROM (
  SELECT
    department,
    COUNT(*) AS total_employees,
    AVG(salary) AS avg_salary,
    MAX(salary) AS max_salary,
    MIN(salary) AS min_salary
  FROM employees
  GROUP BY department
) d
ORDER BY d.department;
