--Lab8
--Part2
--exercise 2.1
CREATE INDEX emp_salary_idx ON employees(salary);

SELECT indexname,indexdef
FROM pg_indexes
where tablename='employees';
--Answer:two indexes, emp_id primary key and for the salary column

--exercise 2.2
create index emp_dept_idx on employees(dept_id);

select * from employees where dept_id=101;
--answer:It's beneficial to index foreign key columns because:
--They speed up JOIN operations between related tables
--They improve performance of referential integrity checks during UPDATE/DELETE operations on parent tables

--exercise 2.3
select
    tablename,
    indexname,
    indexdef
from pg_indexes
where schemaname='public'
order by tablename,indexname;
--Answer: The automatically created indexes are:
-- departments_pkey on departments(dept_id)
-- employees_pkey on employees(emp_id)
-- projects_pkey on projects(proj_id)

--Part3
--exercise 3.1
create index emp_dept_salary_idx on employees(dept_id,salary);

select emp_name, salary
from employees
where dept_id=101 and salary>52000;

--exercise 3.2
create index emp_salary_dept_idx on employees(salary,dept_id);

--filters by dept_id first
select * from employees where dept_id=102 and salary>50000;
--filters by salary first
select * from employees where salary>50000 and dept_id=102;
--Answer:Yes, the order of columns in a multicolumn index matters significantly.

--part 4
--exercise 4.1
alter table employees add column email varchar(100);

update employees set email='john.smith@company.com' where emp_id=1;
update employees set email='jane.doe@company.com' where emp_id=2;
update employees set email='mike.johnson@company.com' where emp_id=3;
update employees set email='sarah.williams@company.com' where emp_id=4;
update employees set email='tom.brown@company.com' where emp_id=5;

create unique index emp_email_unique_idx on employees(email);
--test
INSERT INTO employees (emp_id, emp_name, dept_id, salary, email)
VALUES (6, 'New Employee', 101, 55000, 'john.smith@company.com');
--answer:ERROR: duplicate key value violates unique constraint "emp_email_unique_idx"

--exercise 4.2
alter table employees add column phone varchar(20) unique;

select indexname, indexdef
from pg_indexes
where tablename='employees' and indexname like '%phone%';
--answer:Yes, PostgreSQL automatically created a unique B-tree index when adding the UNIQUE constraint.

--part 5
--exercise 5.1
create index emp_salary_desc_idx on employees(salary desc);

select emp_name, salary
from employees
order by salary desc;
--answer:This index helps ORDER BY queries by storing data pre-sorted in descending order

--exercise 5.2
create index proj_budget_nulls_first_idx on projects(budget nulls first);

select project_name, budget
from projects
order by budget nulls first;

--part 6
create index emp_name_lower_idx on employees(lower(emp_name));

select * from employees where lower(emp_name)='john smith';
--answer:Without this index, PostgreSQL would perform a full table scan and apply the LOWER function to every row

--exercise 6.2
alter table employees add column hire_date date;

UPDATE employees SET hire_date = '2020-01-15' WHERE emp_id = 1;
UPDATE employees SET hire_date = '2019-06-20' WHERE emp_id = 2;
UPDATE employees SET hire_date = '2021-03-10' WHERE emp_id = 3;
UPDATE employees SET hire_date = '2020-11-05' WHERE emp_id = 4;
UPDATE employees SET hire_date = '2018-08-25' WHERE emp_id = 5;

create index emp_hire_year_idx on employees(extract(year from hire_date));

select emp_name,hire_date
from employees
where extract(year from hire_date)=2020;

--part 7
--exercise 7.1
alter index emp_salary_idx rename to employees_salary_index;
select indexname from pg_indexes where tablename='employees';

--exercise 7.2
drop index emp_salary_dept_idx;
--Answer: You might want to drop an index to:
-- Reduce overhead on INSERT/UPDATE/DELETE operations
-- Free up disk space
-- Remove redundant or unused indexes

--exercise 7.3
reindex index employees_salary_index;

--part 8
--exercise 8.1
create index emp_salary_filter_idx on employees(salary) where salary>50000;
--exercise 8.2
create index proj_high_budget_idx on projects(budget) where budget>80000;

select project_name,budget
from projects
where budget>80000;
--answer:The advantage of a partial index is that it's smaller, faster, and has less maintenance overhead since it only indexes a subset of rows.

--exercise 8.3
explain select * from employees where salary>52000;
--answer:The output shows either:
-- Index Scan if using an index (efficient for selective queries)
-- Seq Scan if doing a sequential scan (better when retrieving large portions of the table)

--part 9
--exercise 9.1
create index dept_name_hash_idx on departments using hash(dept_name);

select * from departments where dept_name='IT';
--answer:Use HASH indexes only for simple equality comparisons where you'll only use the = operator. B-tree is more versatile as it supports ranges, sorting, and prefix matching.

--exercise 9.2
create index proj_name_btree_idx on projects(project_name);

create index proj_name_hash_idx on projects using hash(project_name);

select * from projects where project_name='Website Redesign';
select * from projects where project_name>'Database';

--part 10
--exercise 10.1
select
    schemaname,
    tablename,
    indexname,
    pg_size_pretty(pg_relation_size(indexname::regclass)) as index_size
from pg_indexes
where schemaname='public'
order by tablename,indexname;
--answer:The largest index is typically the one on columns with the largest data types or the most rows. In our case, indexes on salary (DECIMAL) or expression indexes might be larger.

--exercise 10.2
drop index if exists proj_name_hash_idx;
--exercise 10.3
create view index_documentation as
select
    tablename,
    indexname,
    indexdef,
    'Improves salary-based queries' as purpose
from pg_indexes
where schemaname='public'
and indexname like '%salary%';

select * from index_documentation;

--additional challenges
-- 1. Index for employees hired in specific month
CREATE INDEX emp_hire_month_idx ON employees(EXTRACT(MONTH FROM hire_date));

-- 2. Composite unique index
CREATE UNIQUE INDEX emp_dept_email_unique_idx ON employees(dept_id, email);

-- 3. Compare performance with EXPLAIN ANALYZE
EXPLAIN ANALYZE SELECT * FROM employees WHERE salary > 50000;

-- 4. Covering index
CREATE INDEX emp_covering_idx ON employees(dept_id, salary) INCLUDE (emp_name, email);