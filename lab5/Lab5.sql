-- Laboratory Work: Database Constraints
-- Student: Shakirbek Amina | ID: 24B032115

CREATE DATABASE lab_constraints;

-- PART 1: CHECK Constraints
-- Task 1.1: Basic CHECK Constraint
CREATE TABLE employees (
    employee_id INTEGER,
    first_name TEXT,
    last_name TEXT,
    age INTEGER CHECK (age BETWEEN 18 AND 65),
    salary NUMERIC(12,2) CHECK (salary > 0)
);

-- Valid data
INSERT INTO employees VALUES
(1,'Amina','K.',25,1500),
(2,'Madina','S.',34,3200);

-- Invalid (violates age check)
-- INSERT INTO employees VALUES (3,'Bota','T.',17,1200); -- age < 18


-- Task 1.2: Named CHECK Constraint
CREATE TABLE products_catalog (
    product_id INTEGER,
    product_name TEXT,
    regular_price NUMERIC(10,2),
    discount_price NUMERIC(10,2),
    CONSTRAINT valid_discount CHECK (
        regular_price > 0 AND discount_price > 0 AND discount_price < regular_price
    )
);

-- Valid data
INSERT INTO products_catalog VALUES
(1,'Notebook',100,85),
(2,'Pen',5.5,4.5);

-- Invalid (violates valid_discount)
-- INSERT INTO products_catalog VALUES (3,'Book',10,15); -- discount_price > regular_price


-- Task 1.3: Multiple Column CHECK
CREATE TABLE bookings (
    booking_id INTEGER,
    check_in_date DATE,
    check_out_date DATE,
    num_guests INTEGER CHECK (num_guests BETWEEN 1 AND 10),
    CONSTRAINT chk_dates CHECK (check_out_date > check_in_date)
);

-- Valid
INSERT INTO bookings VALUES (1,'2025-10-01','2025-10-05',2);

-- Invalid (violates chk_dates)
-- INSERT INTO bookings VALUES (2,'2025-10-05','2025-10-03',3);


-- PART 2: NOT NULL Constraints
-- Task 2.1: NOT NULL Implementation
CREATE TABLE customers (
    customer_id INTEGER NOT NULL,
    email TEXT NOT NULL,
    phone TEXT,
    registration_date DATE NOT NULL
);

INSERT INTO customers VALUES (1,'amina@example.com','+7701','2025-01-10');

-- Invalid (email is NOT NULL)
-- INSERT INTO customers VALUES (2,NULL,'+7702','2025-01-11');


-- Task 2.2: Combining Constraints
CREATE TABLE inventory (
    item_id INTEGER NOT NULL,
    item_name TEXT NOT NULL,
    quantity INTEGER NOT NULL CHECK (quantity >= 0),
    unit_price NUMERIC(10,2) NOT NULL CHECK (unit_price > 0),
    last_updated TIMESTAMP NOT NULL
);

INSERT INTO inventory VALUES (1,'Widget',100,2.5,now());

-- PART 3: UNIQUE Constraints
-- Task 3.1: Single Column UNIQUE
CREATE TABLE users (
    user_id INTEGER PRIMARY KEY,
    username TEXT UNIQUE,
    email TEXT UNIQUE,
    created_at TIMESTAMP DEFAULT now()
);

INSERT INTO users VALUES (1,'amina','amina@example.com',now());

-- Invalid (duplicate username)
-- INSERT INTO users VALUES (2,'amina','test@example.com',now());


-- Task 3.2: Multi-Column UNIQUE
CREATE TABLE course_enrollments (
    enrollment_id INTEGER,
    student_id INTEGER,
    course_code TEXT,
    semester TEXT,
    CONSTRAINT uq_student_course UNIQUE (student_id, course_code, semester)
);

INSERT INTO course_enrollments VALUES (1,101,'CS101','2025S');

-- Invalid (duplicate combination)
-- INSERT INTO course_enrollments VALUES (2,101,'CS101','2025S');


-- PART 4: PRIMARY KEY Constraints
-- Task 4.1: Single Column Primary Key
CREATE TABLE departments (
    dept_id INTEGER PRIMARY KEY,
    dept_name TEXT NOT NULL,
    location TEXT
);

INSERT INTO departments VALUES
(10,'Computer Science','Building A'),
(20,'Mathematics','Building B'),
(30,'Physics','Building C');

-- Invalid (duplicate dept_id)
-- INSERT INTO departments VALUES (10,'Chemistry','Building D');


-- Task 4.2: Composite Primary Key
CREATE TABLE student_courses (
    student_id INTEGER,
    course_id INTEGER,
    enrollment_date DATE,
    grade TEXT,
    PRIMARY KEY (student_id, course_id)
);

INSERT INTO student_courses VALUES (201,301,'2025-09-01','A');


-- PART 5: FOREIGN KEY Constraints
-- Task 5.1: Basic Foreign Key
CREATE TABLE employees_dept (
    emp_id INTEGER PRIMARY KEY,
    emp_name TEXT NOT NULL,
    dept_id INTEGER REFERENCES departments(dept_id),
    hire_date DATE
);

INSERT INTO employees_dept VALUES (1001,'Shakirbek',10,'2025-01-05');

-- Invalid (dept_id 99 does not exist)
-- INSERT INTO employees_dept VALUES (1002,'Madina',99,'2025-01-05');


-- Task 5.2: Multiple Foreign Keys (Library Example)
CREATE TABLE authors (
    author_id INTEGER PRIMARY KEY,
    author_name TEXT NOT NULL,
    country TEXT
);

CREATE TABLE publishers (
    publisher_id INTEGER PRIMARY KEY,
    publisher_name TEXT NOT NULL,
    city TEXT
);

CREATE TABLE books (
    book_id INTEGER PRIMARY KEY,
    title TEXT NOT NULL,
    author_id INTEGER REFERENCES authors(author_id),
    publisher_id INTEGER REFERENCES publishers(publisher_id),
    publication_year INTEGER,
    isbn TEXT UNIQUE
);

INSERT INTO authors VALUES (1,'Leo Tolstoy','Russia'),(2,'Jane Austen','UK');
INSERT INTO publishers VALUES (1,'Classic Press','London');
INSERT INTO books VALUES (1,'War and Peace',1,1,1869,'9780140447934');


-- Task 5.3: ON DELETE Options
CREATE TABLE categories (
    category_id INTEGER PRIMARY KEY,
    category_name TEXT NOT NULL
);

CREATE TABLE products_fk (
    product_id INTEGER PRIMARY KEY,
    product_name TEXT NOT NULL,
    category_id INTEGER REFERENCES categories(category_id) ON DELETE RESTRICT
);

CREATE TABLE orders (
    order_id INTEGER PRIMARY KEY,
    order_date DATE NOT NULL
);

CREATE TABLE order_items (
    item_id INTEGER PRIMARY KEY,
    order_id INTEGER REFERENCES orders(order_id) ON DELETE CASCADE,
    product_id INTEGER REFERENCES products_fk(product_id),
    quantity INTEGER CHECK (quantity > 0)
);

-- If we delete category with products, RESTRICT will stop it
-- If we delete order, its order_items will be deleted automatically


-- PART 6: Practical Application (E-commerce System)
CREATE TABLE customers_ecommerce (
    customer_id INTEGER PRIMARY KEY,
    name TEXT NOT NULL,
    email TEXT UNIQUE NOT NULL,
    phone TEXT,
    registration_date DATE NOT NULL
);

CREATE TABLE products_ecommerce (
    product_id INTEGER PRIMARY KEY,
    name TEXT NOT NULL,
    description TEXT,
    price NUMERIC(10,2) CHECK (price >= 0),
    stock_quantity INTEGER CHECK (stock_quantity >= 0)
);

CREATE TABLE orders_ecommerce (
    order_id INTEGER PRIMARY KEY,
    customer_id INTEGER REFERENCES customers_ecommerce(customer_id) ON DELETE RESTRICT,
    order_date DATE NOT NULL,
    total_amount NUMERIC(12,2),
    status TEXT CHECK (status IN ('pending','processing','shipped','delivered','cancelled'))
);

CREATE TABLE order_details (
    order_detail_id INTEGER PRIMARY KEY,
    order_id INTEGER REFERENCES orders_ecommerce(order_id) ON DELETE CASCADE,
    product_id INTEGER REFERENCES products_ecommerce(product_id) ON DELETE RESTRICT,
    quantity INTEGER CHECK (quantity > 0),
    unit_price NUMERIC(10,2)
);

-- Sample data
INSERT INTO customers_ecommerce VALUES
(1,'Amina Shakirbek','amina@mail.com','+7701','2025-01-10'),
(2,'Madina Sarsen','madina@mail.com','+7702','2025-02-14');

INSERT INTO products_ecommerce VALUES
(100,'Phone X','Smartphone with OLED display',699.99,50),
(101,'Laptop Z','High-performance laptop',1299.00,20),
(102,'Headphones','Wireless Bluetooth',99.99,100);

INSERT INTO orders_ecommerce VALUES
(2000,1,'2025-10-01',1998.99,'pending'),
(2001,2,'2025-10-05',99.99,'shipped');

INSERT INTO order_details VALUES
(3000,2000,100,1,699.99),
(3001,2000,101,1,1299.00),
(3002,2001,102,1,99.99);


-- TEST QUERIES
SELECT * FROM employees;
SELECT * FROM products_catalog;
SELECT * FROM customers;
SELECT * FROM departments;
SELECT * FROM books;
SELECT * FROM orders_ecommerce;
SELECT * FROM order_details;


