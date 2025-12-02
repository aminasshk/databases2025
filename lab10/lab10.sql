--Lab10
CREATE TABLE accounts (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    balance DECIMAL(10, 2) DEFAULT 0.00
);

CREATE TABLE products (
    id SERIAL PRIMARY KEY,
    shop VARCHAR(100) NOT NULL,
    product VARCHAR(100) NOT NULL,
    price DECIMAL(10, 2) NOT NULL
);


INSERT INTO accounts (name, balance) VALUES
    ('alice', 1000.00),
    ('bob', 500.00),
    ('wally', 750.00);

INSERT INTO products (shop, product, price) VALUES
    ('joe''s shop', 'coke', 2.50),
    ('joe''s shop', 'pepsi', 3.00);

SELECT * FROM accounts;
SELECT * FROM products;
--task1
begin;
update accounts set balance = balance - 100.00 where name = 'alice';
update accounts set balance = balance + 100.00 where name = 'bob';
commit;
--answers:
--a)Alice: 900.00, Bob: 600.00
--b)To keep both updates atomic — both succeed or both fail
--c)Alice would lose money but Bob wouldn't get it (data corruption)

--task2
begin;
update accounts set balance = balance - 500.00 where name = 'alice';
select * from accounts where name = 'alice';
rollback;
select * from accounts where name = 'alice';

--task3
begin;
update accounts set balance = balance - 100.00 where name = 'alice';
savepoint my_savepoint;
update accounts set balance = balance + 100.00 where name = 'bob';
rollback to my_savepoint;
update accounts set balance = balance + 100.00 where name = 'wally';
commit;

--ЗАДАНИЕ 4: READ COMMITTED
-- Terminal 1:
BEGIN TRANSACTION ISOLATION LEVEL READ COMMITTED;
SELECT * FROM products WHERE shop = 'joe''s shop';
-- ЖДАТЬ Terminal 2
SELECT * FROM products WHERE shop = 'joe''s shop';
COMMIT;

-- Terminal 2 (параллельно):
BEGIN;
DELETE FROM products WHERE shop = 'joe''s shop';
INSERT INTO products VALUES ('joe''s shop', 'fanta', 3.50);
COMMIT;

--ЗАДАНИЕ 4: SERIALIZABLE
DELETE FROM products;
INSERT INTO products VALUES ('joe''s shop', 'coke', 2.50), ('joe''s shop', 'pepsi', 3.00);

-- Terminal 1:
BEGIN TRANSACTION ISOLATION LEVEL SERIALIZABLE;
SELECT * FROM products WHERE shop = 'joe''s shop';
-- ЖДАТЬ Terminal 2
SELECT * FROM products WHERE shop = 'joe''s shop';
COMMIT;

-- Terminal 2 (параллельно):
BEGIN;
DELETE FROM products WHERE shop = 'joe''s shop';
INSERT INTO products VALUES ('joe''s shop', 'fanta', 3.50);
COMMIT;

-- 7. ЗАДАНИЕ 5: PHANTOM READ
DELETE FROM products;
INSERT INTO products VALUES
('joe''s shop', 'coke', 2.50),
('joe''s shop', 'pepsi', 3.00),
('joe''s shop', 'fanta', 3.50);

-- Terminal 1:
BEGIN TRANSACTION ISOLATION LEVEL REPEATABLE READ;
SELECT MAX(price), MIN(price) FROM products WHERE shop = 'joe''s shop';
-- ЖДАТЬ Terminal 2
SELECT MAX(price), MIN(price) FROM products WHERE shop = 'joe''s shop';
COMMIT;

-- Terminal 2:
BEGIN;
INSERT INTO products VALUES ('joe''s shop', 'sprite', 4.00);
COMMIT;

-- 8. ЗАДАНИЕ 6: DIRTY READ
DELETE FROM products;
INSERT INTO products VALUES
('joe''s shop', 'coke', 2.50),
('joe''s shop', 'pepsi', 3.00),
('joe''s shop', 'fanta', 3.50);

-- Terminal 1:
BEGIN TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
SELECT * FROM products WHERE shop = 'joe''s shop';
-- ЖДАТЬ UPDATE Terminal 2
SELECT * FROM products WHERE shop = 'joe''s shop';
-- ЖДАТЬ ROLLBACK Terminal 2
SELECT * FROM products WHERE shop = 'joe''s shop';
COMMIT;

-- Terminal 2:
BEGIN;
UPDATE products SET price = 99.99 WHERE product = 'fanta';
-- НЕ коммитить
ROLLBACK;

-- 9. УПРАЖНЕНИЕ 1
BEGIN;
UPDATE accounts SET balance = balance - 200.00 WHERE name = 'bob' AND balance >= 200.00;
UPDATE accounts SET balance = balance + 200.00 WHERE name = 'wally';
COMMIT;

-- 10. УПРАЖНЕНИЕ 2
BEGIN;
INSERT INTO products VALUES ('test shop', 'water', 1.00);
SAVEPOINT sp1;
UPDATE products SET price = 1.50 WHERE product = 'water';
SAVEPOINT sp2;
DELETE FROM products WHERE product = 'water';
ROLLBACK TO sp1;
COMMIT;

-- 11. УПРАЖНЕНИЕ 3 (две сессии)
-- Сессия 1:
BEGIN;
SELECT balance FROM accounts WHERE name = 'alice';
UPDATE accounts SET balance = balance - 100 WHERE name = 'alice';
COMMIT;

-- Сессия 2 (параллельно):
BEGIN;
SELECT balance FROM accounts WHERE name = 'alice';
UPDATE accounts SET balance = balance - 100 WHERE name = 'alice';
COMMIT;

-- 12. УПРАЖНЕНИЕ 4
CREATE TABLE IF NOT EXISTS sells (shop VARCHAR(100), product VARCHAR(100), price DECIMAL(10,2));
DELETE FROM sells;
INSERT INTO sells VALUES ('shop1', 'apple', 10), ('shop1', 'banana', 20);

-- Проблема:
-- Sally: SELECT MAX(price) FROM sells; -- 20
-- Joe: UPDATE sells SET price = price * 0.9; -- 9, 18
-- Sally: SELECT MIN(price) FROM sells; -- 9

-- Решение:
BEGIN TRANSACTION ISOLATION LEVEL REPEATABLE READ;
SELECT MAX(price) FROM sells;
-- Joe делает изменения
SELECT MIN(price) FROM sells;
COMMIT;

-- 13. ФИНАЛЬНЫЕ ДАННЫЕ
SELECT '=== ACCOUNTS ===' as table_name;
SELECT * FROM accounts;
SELECT '=== PRODUCTS ===' as table_name;
SELECT * FROM products;
SELECT '=== SELLS ===' as table_name;
SELECT * FROM sells;



