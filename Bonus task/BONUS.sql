-- Bonus Laboratory Work
-- ID:24B032115
-- Shakirbek Amina Tuesday 14:00-15:00
-- PART 1: TABLE CREATION AND SAMPLE DATA\
CREATE EXTENSION IF NOT EXISTS btree_gin;
CREATE EXTENSION IF NOT EXISTS pg_trgm;

DROP TABLE IF EXISTS audit_log CASCADE;
DROP TABLE IF EXISTS transactions CASCADE;
DROP TABLE IF EXISTS exchange_rates CASCADE;
DROP TABLE IF EXISTS accounts CASCADE;
DROP TABLE IF EXISTS customers CASCADE;

CREATE TABLE customers (
    customer_id SERIAL PRIMARY KEY,
    tin VARCHAR(12) UNIQUE NOT NULL CHECK (tin ~ '^\d{12}$'),
    full_name VARCHAR(100) NOT NULL,
    phone VARCHAR(20) NOT NULL,
    email VARCHAR(100) NOT NULL,
    status VARCHAR(10) CHECK (status IN ('active', 'blocked', 'frozen')) DEFAULT 'active',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    daily_limit_kzt DECIMAL(15,2) DEFAULT 1000000.00
);

CREATE TABLE accounts (
    account_id SERIAL PRIMARY KEY,
    customer_id INTEGER REFERENCES customers(customer_id) ON DELETE CASCADE,
    account_number VARCHAR(34) UNIQUE NOT NULL, -- IBAN format
    currency VARCHAR(3) CHECK (currency IN ('KZT', 'USD', 'EUR', 'RUB')),
    balance DECIMAL(15,2) DEFAULT 0.00 CHECK (balance >= 0),
    is_active BOOLEAN DEFAULT TRUE,
    opened_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    closed_at TIMESTAMP,
    CONSTRAINT valid_closure CHECK (closed_at IS NULL OR closed_at > opened_at)
);

CREATE TABLE exchange_rates (
    rate_id SERIAL PRIMARY KEY,
    from_currency VARCHAR(3) NOT NULL,
    to_currency VARCHAR(3) NOT NULL,
    rate DECIMAL(10,6) NOT NULL CHECK (rate > 0),
    valid_from TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    valid_to TIMESTAMP DEFAULT '9999-12-31 23:59:59',
    UNIQUE(from_currency, to_currency, valid_from)
);

CREATE TABLE exchange_rates (
    rate_id SERIAL PRIMARY KEY,
    from_currency VARCHAR(3) NOT NULL,
    to_currency VARCHAR(3) NOT NULL,
    rate DECIMAL(10,6) NOT NULL CHECK (rate > 0),
    valid_from TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    valid_to TIMESTAMP DEFAULT '9999-12-31 23:59:59',
    UNIQUE(from_currency, to_currency, valid_from)
);

CREATE TABLE transactions (
    transaction_id SERIAL PRIMARY KEY,
    from_account_id INTEGER REFERENCES accounts(account_id),
    to_account_id INTEGER REFERENCES accounts(account_id),
    amount DECIMAL(15,2) NOT NULL CHECK (amount > 0),
    currency VARCHAR(3) NOT NULL,
    exchange_rate DECIMAL(10,6),
    amount_kzt DECIMAL(15,2) NOT NULL,
    type VARCHAR(20) CHECK (type IN ('transfer', 'deposit', 'withdrawal')),
    status VARCHAR(20) CHECK (status IN ('pending', 'completed', 'failed', 'reversed')),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    completed_at TIMESTAMP,
    description TEXT,
    CHECK (from_account_id != to_account_id OR type != 'transfer')
);

CREATE TABLE audit_log (
    log_id SERIAL PRIMARY KEY,
    table_name VARCHAR(50) NOT NULL,
    record_id INTEGER NOT NULL,
    action VARCHAR(10) CHECK (action IN ('INSERT', 'UPDATE', 'DELETE')),
    old_values JSONB,
    new_values JSONB,
    changed_by VARCHAR(100) DEFAULT CURRENT_USER,
    changed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    ip_address INET
);

INSERT INTO customers (tin, full_name, phone, email, status, daily_limit_kzt) VALUES
('123456789012', 'Алиев Али Алиевич', '+77771234567', 'ali.aliyev@email.com', 'active', 2000000.00),
('234567890123', 'Бердиева Бермет Канатовна', '+77772345678', 'bermet.berdiyeva@email.com', 'active', 1500000.00),
('345678901234', 'Сатпаев Саян Дмитриевич', '+77773456789', 'sayan.satpayev@email.com', 'active', 3000000.00),
('456789012345', 'Назарбаева Айгуль Саламатовна', '+77774567890', 'aigul.nazarbayeva@email.com', 'blocked', 1000000.00),
('567890123456', 'Токаев Касым.Жомарт Кемелевич', '+77775678901', 'tokayev.kz@email.com', 'active', 5000000.00),
('678901234567', 'Абдрахманов Азамат Талгатович', '+77776789012', 'azamat.abdr@email.com', 'frozen', 500000.00),
('789012345678', 'Иванова Мария Петровна', '+77777890123', 'maria.ivanova@email.com', 'active', 1000000.00),
('890123456789', 'Смирнов Алексей Владимирович', '+77778901234', 'alex.smirnov@email.com', 'active', 2000000.00),
('901234567890', 'Ким Евгения Сергеевна', '+77779012345', 'evgenia.kim@email.com', 'active', 1500000.00),
('012345678901', 'Петров Дмитрий Александрович', '+77770123456', 'dmitry.petrov@email.com', 'active', 1000000.00);

INSERT INTO accounts (customer_id, account_number, currency, balance, is_active) VALUES
(1, 'KZ12345678901234567890', 'KZT', 5000000.00, TRUE),
(1, 'KZ09876543210987654321', 'USD', 25000.00, TRUE),
(2, 'KZ23456789012345678901', 'KZT', 3000000.00, TRUE),
(2, 'KZ34567890123456789012', 'EUR', 15000.00, TRUE),
(3, 'KZ45678901234567890123', 'KZT', 10000000.00, TRUE),
(4, 'KZ56789012345678901234', 'KZT', 500000.00, FALSE),
(5, 'KZ67890123456789012345', 'KZT', 25000000.00, TRUE),
(5, 'KZ78901234567890123456', 'USD', 100000.00, TRUE),
(6, 'KZ89012345678901234567', 'KZT', 100000.00, TRUE),
(7, 'KZ90123456789012345678', 'KZT', 1500000.00, TRUE),
(8, 'KZ01234567890123456789', 'EUR', 5000.00, TRUE),
(9, 'KZ11223344556677889900', 'RUB', 300000.00, TRUE),
(10, 'KZ22334455667788990011', 'KZT', 2000000.00, TRUE);

INSERT INTO exchange_rates (from_currency, to_currency, rate) VALUES
('USD', 'KZT', 450.00),
('KZT', 'USD', 0.002222),
('EUR', 'KZT', 480.00),
('KZT', 'EUR', 0.002083),
('RUB', 'KZT', 5.00),
('KZT', 'RUB', 0.20),
('USD', 'EUR', 0.85),
('EUR', 'USD', 1.1765),
('USD', 'RUB', 90.00),
('RUB', 'USD', 0.0111);

INSERT INTO transactions (from_account_id, to_account_id, amount, currency, exchange_rate, amount_kzt, type, status, created_at, completed_at, description) VALUES
(1, 3, 100000.00, 'KZT', 1.0, 100000.00, 'transfer', 'completed', NOW() - INTERVAL '2 days', NOW() - INTERVAL '2 days', 'Оплата услуг'),
(2, 4, 1000.00, 'USD', 450.0, 450000.00, 'transfer', 'completed', NOW() - INTERVAL '1 day', NOW() - INTERVAL '1 day', 'Международный перевод'),
(3, 5, 50000.00, 'KZT', 1.0, 50000.00, 'transfer', 'completed', NOW() - INTERVAL '5 hours', NOW() - INTERVAL '5 hours', 'Перевод другу'),
(NULL, 1, 200000.00, 'KZT', 1.0, 200000.00, 'deposit', 'completed', NOW() - INTERVAL '3 days', NOW() - INTERVAL '3 days', 'Пополнение счета'),
(5, NULL, 100000.00, 'KZT', 1.0, 100000.00, 'withdrawal', 'completed', NOW() - INTERVAL '1 day', NOW() - INTERVAL '1 day', 'Снятие наличных');

-- PART 2: AUDIT TRIGGER FUNCTION
CREATE OR REPLACE FUNCTION audit_trigger_function()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        INSERT INTO audit_log (table_name, record_id, action, new_values)
        VALUES (TG_TABLE_NAME, NEW.customer_id, 'INSERT', to_jsonb(NEW));
    ELSIF TG_OP = 'UPDATE' THEN
        INSERT INTO audit_log (table_name, record_id, action, old_values, new_values)
        VALUES (TG_TABLE_NAME, NEW.customer_id, 'UPDATE', to_jsonb(OLD), to_jsonb(NEW));
    ELSIF TG_OP = 'DELETE' THEN
        INSERT INTO audit_log (table_name, record_id, action, old_values)
        VALUES (TG_TABLE_NAME, OLD.customer_id, 'DELETE', to_jsonb(OLD));
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER customers_audit_trigger
AFTER INSERT OR UPDATE OR DELETE ON customers
FOR EACH ROW EXECUTE FUNCTION audit_trigger_function();

CREATE TRIGGER accounts_audit_trigger
AFTER INSERT OR UPDATE OR DELETE ON accounts
FOR EACH ROW EXECUTE FUNCTION audit_trigger_function();

-- PART 3: TASK 1 - TRANSACTION MANAGEMENT
CREATE OR REPLACE FUNCTION process_transfer(
    p_from_account_number VARCHAR(34),
    p_to_account_number VARCHAR(34),
    p_amount DECIMAL(15,2),
    p_currency VARCHAR(3),
    p_description TEXT DEFAULT NULL
)
RETURNS TABLE (
    success BOOLEAN,
    message TEXT,
    transaction_id INTEGER,
    new_balance_from DECIMAL(15,2),
    new_balance_to DECIMAL(15,2)
) AS $$
DECLARE
    v_from_account_id INTEGER;
    v_to_account_id INTEGER;
    v_from_customer_id INTEGER;
    v_to_customer_id INTEGER;
    v_from_currency VARCHAR(3);
    v_to_currency VARCHAR(3);
    v_from_balance DECIMAL(15,2);
    v_to_balance DECIMAL(15,2);
    v_daily_limit DECIMAL(15,2);
    v_daily_spent DECIMAL(15,2);
    v_exchange_rate DECIMAL(10,6);
    v_amount_kzt DECIMAL(15,2);
    v_transaction_id INTEGER;
    v_error_code VARCHAR(5);
    v_error_message TEXT;
    v_savepoint_name TEXT;
BEGIN
    success := FALSE;
    message := '';
    v_savepoint_name := 'before_transfer';

    BEGIN
        SAVEPOINT before_transfer;

        -- Step 1: Validate from account
        SELECT account_id, customer_id, currency, balance
        INTO v_from_account_id, v_from_customer_id, v_from_currency, v_from_balance
        FROM accounts
        WHERE account_number = p_from_account_number
        FOR UPDATE;

        IF v_from_account_id IS NULL THEN
            RAISE EXCEPTION USING
                ERRCODE = 'TR001',
                MESSAGE = 'Sender account not found';
        END IF;

        -- Step 2: Validate to account
        SELECT account_id, customer_id, currency, balance
        INTO v_to_account_id, v_to_customer_id, v_to_currency, v_to_balance
        FROM accounts
        WHERE account_number = p_to_account_number
        FOR UPDATE;

        IF v_to_account_id IS NULL THEN
            RAISE EXCEPTION USING
                ERRCODE = 'TR002',
                MESSAGE = 'Receiver account not found';
        END IF;

        -- Step 3: Check if accounts are active
        IF NOT EXISTS (SELECT 1 FROM accounts WHERE account_id = v_from_account_id AND is_active = TRUE) THEN
            RAISE EXCEPTION USING
                ERRCODE = 'TR003',
                MESSAGE = 'Sender account is inactive';
        END IF;

        IF NOT EXISTS (SELECT 1 FROM accounts WHERE account_id = v_to_account_id AND is_active = TRUE) THEN
            RAISE EXCEPTION USING
                ERRCODE = 'TR004',
                MESSAGE = 'Receiver account is inactive';
        END IF;

        -- Step 4: Check sender customer status
        IF NOT EXISTS (SELECT 1 FROM customers WHERE customer_id = v_from_customer_id AND status = 'active') THEN
            RAISE EXCEPTION USING
                ERRCODE = 'TR005',
                MESSAGE = 'Sender customer is not active';
        END IF;

        -- Step 5: Check sufficient balance
        IF v_from_balance < p_amount THEN
            RAISE EXCEPTION USING
                ERRCODE = 'TR006',
                MESSAGE = 'Insufficient balance';
        END IF;

        -- Step 6: Get exchange rate and calculate amount in KZT
        IF v_from_currency = p_currency THEN
            v_exchange_rate := 1.0;
        ELSE
            SELECT rate INTO v_exchange_rate
            FROM exchange_rates
            WHERE from_currency = p_currency
                AND to_currency = 'KZT'
                AND valid_from <= CURRENT_TIMESTAMP
                AND valid_to >= CURRENT_TIMESTAMP
            ORDER BY valid_from DESC LIMIT 1;

            IF v_exchange_rate IS NULL THEN
                RAISE EXCEPTION USING
                    ERRCODE = 'TR007',
                    MESSAGE = 'Exchange rate not available';
            END IF;
        END IF;

        v_amount_kzt := p_amount * v_exchange_rate;

        -- Step 7: Check daily transaction limit
        SELECT daily_limit_kzt INTO v_daily_limit
        FROM customers
        WHERE customer_id = v_from_customer_id;

        SELECT COALESCE(SUM(amount_kzt), 0) INTO v_daily_spent
        FROM transactions
        WHERE from_account_id = v_from_account_id
            AND status = 'completed'
            AND DATE(created_at) = CURRENT_DATE
            AND type = 'transfer';

        IF v_daily_spent + v_amount_kzt > v_daily_limit THEN
            RAISE EXCEPTION USING
                ERRCODE = 'TR008',
                MESSAGE = 'Daily transaction limit exceeded';
        END IF;

        -- Step 8: Perform currency conversion if needed
        IF v_from_currency != v_to_currency THEN
            DECLARE
                v_conversion_rate DECIMAL(10,6);
            BEGIN
                SELECT rate INTO v_conversion_rate
                FROM exchange_rates
                WHERE from_currency = v_from_currency
                    AND to_currency = v_to_currency
                    AND valid_from <= CURRENT_TIMESTAMP
                    AND valid_to >= CURRENT_TIMESTAMP
                ORDER BY valid_from DESC LIMIT 1;

                IF v_conversion_rate IS NULL THEN
                    RAISE EXCEPTION USING
                        ERRCODE = 'TR009',
                        MESSAGE = 'Currency conversion rate not available';
                END IF;

                p_amount := p_amount * v_conversion_rate;
            END;
        END IF;

        -- Step 9: Update balances
        UPDATE accounts SET balance = balance - p_amount
        WHERE account_id = v_from_account_id;

        UPDATE accounts SET balance = balance + p_amount
        WHERE account_id = v_to_account_id;

        SELECT balance INTO v_from_balance FROM accounts WHERE account_id = v_from_account_id;
        SELECT balance INTO v_to_balance FROM accounts WHERE account_id = v_to_account_id;

        -- Step 10: Create transaction record
        INSERT INTO transactions (
            from_account_id,
            to_account_id,
            amount,
            currency,
            exchange_rate,
            amount_kzt,
            type,
            status,
            completed_at,
            description
        ) VALUES (
            v_from_account_id,
            v_to_account_id,
            p_amount,
            p_currency,
            v_exchange_rate,
            v_amount_kzt,
            'transfer',
            'completed',
            CURRENT_TIMESTAMP,
            p_description
        ) RETURNING transaction_id INTO v_transaction_id;

        -- Step 11: Log success to audit log
        INSERT INTO audit_log (table_name, record_id, action, new_values)
        VALUES ('transactions', v_transaction_id, 'INSERT',
                jsonb_build_object(
                    'transaction_id', v_transaction_id,
                    'from_account', p_from_account_number,
                    'to_account', p_to_account_number,
                    'amount', p_amount,
                    'status', 'completed',
                    'timestamp', CURRENT_TIMESTAMP
                ));

        success := TRUE;
        message := 'Transfer completed successfully';
        transaction_id := v_transaction_id;
        new_balance_from := v_from_balance;
        new_balance_to := v_to_balance;

        RETURN NEXT;

    EXCEPTION
        WHEN SQLSTATE 'TR001' THEN
            message := 'Error TR001: Sender account not found';
            ROLLBACK TO SAVEPOINT before_transfer;
            RETURN NEXT;
        WHEN SQLSTATE 'TR002' THEN
            message := 'Error TR002: Receiver account not found';
            ROLLBACK TO SAVEPOINT before_transfer;
            RETURN NEXT;
        WHEN SQLSTATE 'TR003' THEN
            message := 'Error TR003: Sender account is inactive';
            ROLLBACK TO SAVEPOINT before_transfer;
            RETURN NEXT;
        WHEN SQLSTATE 'TR004' THEN
            message := 'Error TR004: Receiver account is inactive';
            ROLLBACK TO SAVEPOINT before_transfer;
            RETURN NEXT;
        WHEN SQLSTATE 'TR005' THEN
            message := 'Error TR005: Sender customer is not active';
            ROLLBACK TO SAVEPOINT before_transfer;
            RETURN NEXT;
        WHEN SQLSTATE 'TR006' THEN
            message := 'Error TR006: Insufficient balance';
            ROLLBACK TO SAVEPOINT before_transfer;
            RETURN NEXT;
        WHEN SQLSTATE 'TR007' THEN
            message := 'Error TR007: Exchange rate not available';
            ROLLBACK TO SAVEPOINT before_transfer;
            RETURN NEXT;
        WHEN SQLSTATE 'TR008' THEN
            message := 'Error TR008: Daily transaction limit exceeded';
            ROLLBACK TO SAVEPOINT before_transfer;
            RETURN NEXT;
        WHEN SQLSTATE 'TR009' THEN
            message := 'Error TR009: Currency conversion rate not available';
            ROLLBACK TO SAVEPOINT before_transfer;
            RETURN NEXT;
        WHEN OTHERS THEN
            message := 'Error ' || SQLSTATE || ': ' || SQLERRM;
            ROLLBACK TO SAVEPOINT before_transfer;
            RETURN NEXT;
    END;
END;
$$ LANGUAGE plpgsql;

-- PART 4: TASK 2 - VIEWS FOR REPORTING
-- View 1: Customer balance summary
CREATE OR REPLACE VIEW customer_balance_summary AS
WITH customer_balances AS (
    SELECT
        c.customer_id,
        c.full_name,
        c.tin,
        c.daily_limit_kzt,
        a.account_id,
        a.account_number,
        a.currency,
        a.balance,
        COALESCE(
            (SELECT rate
             FROM exchange_rates er
             WHERE er.from_currency = a.currency
                AND er.to_currency = 'KZT'
                AND er.valid_from <= CURRENT_TIMESTAMP
                AND er.valid_to >= CURRENT_TIMESTAMP
             ORDER BY er.valid_from DESC
             LIMIT 1),
            CASE a.currency
                WHEN 'KZT' THEN 1.0
                WHEN 'USD' THEN 450.0  -- Default rates
                WHEN 'EUR' THEN 480.0
                WHEN 'RUB' THEN 5.0
                ELSE 1.0
            END
        ) as exchange_rate_to_kzt
    FROM customers c
    LEFT JOIN accounts a ON c.customer_id = a.customer_id AND a.is_active = TRUE
    WHERE c.status = 'active'
),
balance_calc AS (
    SELECT
        customer_id,
        full_name,
        tin,
        daily_limit_kzt,
        COUNT(account_id) as total_accounts,
        SUM(balance) as total_balance_native,
        SUM(balance * exchange_rate_to_kzt) as total_balance_kzt,
        SUM(CASE WHEN currency = 'KZT' THEN balance ELSE 0 END) as kzt_balance,
        SUM(CASE WHEN currency = 'USD' THEN balance ELSE 0 END) as usd_balance,
        SUM(CASE WHEN currency = 'EUR' THEN balance ELSE 0 END) as eur_balance,
        SUM(CASE WHEN currency = 'RUB' THEN balance ELSE 0 END) as rub_balance
    FROM customer_balances
    GROUP BY customer_id, full_name, tin, daily_limit_kzt
),
daily_spent AS (
    SELECT
        c.customer_id,
        COALESCE(SUM(t.amount_kzt), 0) as daily_spent_kzt
    FROM customers c
    LEFT JOIN accounts a ON c.customer_id = a.customer_id
    LEFT JOIN transactions t ON a.account_id = t.from_account_id
        AND t.status = 'completed'
        AND DATE(t.created_at) = CURRENT_DATE
        AND t.type = 'transfer'
    GROUP BY c.customer_id
)
SELECT
    bc.customer_id,
    bc.full_name,
    bc.tin,
    bc.total_accounts,
    bc.total_balance_kzt,
    bc.kzt_balance,
    bc.usd_balance,
    bc.eur_balance,
    bc.rub_balance,
    bc.daily_limit_kzt,
    ds.daily_spent_kzt,
    CASE
        WHEN bc.daily_limit_kzt > 0
        THEN ROUND((ds.daily_spent_kzt / bc.daily_limit_kzt) * 100, 2)
        ELSE 0
    END as limit_utilization_percent,
    RANK() OVER (ORDER BY bc.total_balance_kzt DESC) as balance_rank,
    ROUND(bc.total_balance_kzt / NULLIF(SUM(bc.total_balance_kzt) OVER(), 0) * 100, 2) as market_share_percent
FROM balance_calc bc
LEFT JOIN daily_spent ds ON bc.customer_id = ds.customer_id
ORDER BY balance_rank;

-- View 2: Daily transaction report
CREATE OR REPLACE VIEW daily_transaction_report AS
WITH daily_stats AS (
    SELECT
        DATE(created_at) as transaction_date,
        type,
        status,
        COUNT(*) as transaction_count,
        SUM(amount_kzt) as total_volume_kzt,
        AVG(amount_kzt) as avg_amount_kzt,
        MIN(amount_kzt) as min_amount_kzt,
        MAX(amount_kzt) as max_amount_kzt
    FROM transactions
    WHERE created_at >= CURRENT_DATE - INTERVAL '30 days'
    GROUP BY DATE(created_at), type, status
),
running_totals AS (
    SELECT
        transaction_date,
        type,
        status,
        transaction_count,
        total_volume_kzt,
        avg_amount_kzt,
        min_amount_kzt,
        max_amount_kzt,
        SUM(total_volume_kzt) OVER (
            PARTITION BY type, status
            ORDER BY transaction_date
        ) as cumulative_volume_kzt,
        SUM(transaction_count) OVER (
            PARTITION BY type, status
            ORDER BY transaction_date
        ) as cumulative_count,
        LAG(total_volume_kzt) OVER (
            PARTITION BY type, status
            ORDER BY transaction_date
        ) as previous_day_volume,
        LAG(transaction_count) OVER (
            PARTITION BY type, status
            ORDER BY transaction_date
        ) as previous_day_count
    FROM daily_stats
)
SELECT
    transaction_date,
    type,
    status,
    transaction_count,
    total_volume_kzt,
    avg_amount_kzt,
    min_amount_kzt,
    max_amount_kzt,
    cumulative_volume_kzt,
    cumulative_count,
    previous_day_volume,
    previous_day_count,
    CASE
        WHEN previous_day_volume > 0
        THEN ROUND(((total_volume_kzt - previous_day_volume) / previous_day_volume) * 100, 2)
        ELSE NULL
    END as volume_growth_percent,
    CASE
        WHEN previous_day_count > 0
        THEN ROUND(((transaction_count - previous_day_count) / previous_day_count) * 100, 2)
        ELSE NULL
    END as count_growth_percent
FROM running_totals
ORDER BY transaction_date DESC, type, status;

-- View 3: Suspicious activity view (with security barrier)
CREATE OR REPLACE VIEW suspicious_activity_view WITH (security_barrier = true) AS
WITH large_transactions AS (
    -- Transactions over 5,000,000 KZT equivalent
    SELECT
        t.transaction_id,
        t.created_at,
        'LARGE_AMOUNT' as suspicion_type,
        'Transaction amount: ' || t.amount_kzt || ' KZT' as reason,
        c1.full_name as from_customer,
        c2.full_name as to_customer,
        t.amount_kzt
    FROM transactions t
    JOIN accounts a1 ON t.from_account_id = a1.account_id
    JOIN customers c1 ON a1.customer_id = c1.customer_id
    JOIN accounts a2 ON t.to_account_id = a2.account_id
    JOIN customers c2 ON a2.customer_id = c2.customer_id
    WHERE t.amount_kzt > 5000000
        AND t.status = 'completed'
        AND t.created_at >= CURRENT_DATE - INTERVAL '7 days'
),
frequent_transactions AS (
    -- Customers with >10 transactions in a single hour
    SELECT
        c.customer_id,
        c.full_name,
        'FREQUENT_TRANSACTIONS' as suspicion_type,
        'Transactions in hour: ' || COUNT(*) as reason,
        COUNT(*) as transaction_count,
        DATE_TRUNC('hour', t.created_at) as hour_window,
        MAX(t.created_at) as last_transaction
    FROM customers c
    JOIN accounts a ON c.customer_id = a.customer_id
    JOIN transactions t ON a.account_id = t.from_account_id
    WHERE t.status = 'completed'
        AND t.created_at >= CURRENT_DATE - INTERVAL '1 day'
    GROUP BY c.customer_id, c.full_name, DATE_TRUNC('hour', t.created_at)
    HAVING COUNT(*) > 10
),
rapid_sequential AS (
    -- Rapid sequential transfers (same sender, <1 minute apart)
    SELECT
        t1.transaction_id,
        t1.created_at,
        'RAPID_SEQUENTIAL' as suspicion_type,
        'Time between transfers: ' ||
        EXTRACT(EPOCH FROM (t2.created_at - t1.created_at)) || ' seconds' as reason,
        c.full_name as customer_name,
        EXTRACT(EPOCH FROM (t2.created_at - t1.created_at)) as seconds_between
    FROM transactions t1
    JOIN transactions t2 ON t1.from_account_id = t2.from_account_id
        AND t2.transaction_id > t1.transaction_id
        AND t2.created_at - t1.created_at < INTERVAL '1 minute'
    JOIN accounts a ON t1.from_account_id = a.account_id
    JOIN customers c ON a.customer_id = c.customer_id
    WHERE t1.status = 'completed'
        AND t2.status = 'completed'
        AND t1.created_at >= CURRENT_DATE - INTERVAL '1 day'
    ORDER BY t1.created_at
)
SELECT * FROM large_transactions
UNION ALL
SELECT
    NULL as transaction_id,
    hour_window as created_at,
    suspicion_type,
    reason,
    full_name as from_customer,
    NULL as to_customer,
    NULL as amount_kzt
FROM frequent_transactions
UNION ALL
SELECT
    transaction_id,
    created_at,
    suspicion_type,
    reason,
    customer_name as from_customer,
    NULL as to_customer,
    NULL as amount_kzt
FROM rapid_sequential
ORDER BY created_at DESC;

-- PART 5: TASK 3 - PERFORMANCE OPTIMIZATION WITH INDEXES
-- 1. B-tree index on account_number (most frequent lookup)
CREATE INDEX idx_accounts_account_number ON accounts(account_number);
-- Justification: Used in process_transfer for account validation

-- 2. Composite index on transactions for date-based queries
CREATE INDEX idx_transactions_date_status ON transactions(created_at, status);
-- Justification: Used in daily reports and suspicious activity detection

-- 3. Partial index for active accounts only
CREATE INDEX idx_accounts_active ON accounts(account_id) WHERE is_active = TRUE;
-- Justification: Most queries filter for active accounts

-- 4. Expression index for case-insensitive email search
CREATE INDEX idx_customers_email_lower ON customers(LOWER(email));
-- Justification: Supports case-insensitive email lookups

-- 5. GIN index on audit_log JSONB columns
CREATE INDEX idx_audit_log_jsonb ON audit_log USING gin(old_values, new_values);
-- Justification: Enables efficient JSONB queries on audit data

-- 6. Hash index on transaction type (for equality comparisons)
CREATE INDEX idx_transactions_type_hash ON transactions USING hash(type);
-- Justification: Fast lookups by transaction type

-- 7. Covering index for customer balance queries
CREATE INDEX idx_customers_balance_query ON customers(customer_id, status, daily_limit_kzt)
INCLUDE (full_name, tin);
-- Justification: Covers common customer reporting queries

-- 8. Index on exchange rates for current rate lookups
CREATE INDEX idx_exchange_rates_current ON exchange_rates(from_currency, to_currency, valid_from, valid_to);
-- Justification: Speeds up currency conversion in process_transfer

-- PART 6: TASK 4 - BATCH PROCESSING PROCEDURE
CREATE OR REPLACE FUNCTION process_salary_batch(
    p_company_account_number VARCHAR(34),
    p_payments JSONB,
    p_description TEXT DEFAULT 'Salary Payment'
)
RETURNS TABLE (
    success BOOLEAN,
    message TEXT,
    successful_count INTEGER,
    failed_count INTEGER,
    failed_details JSONB,
    batch_reference VARCHAR(50)
) AS $$
DECLARE
    v_company_account_id INTEGER;
    v_company_balance DECIMAL(15,2);
    v_total_batch_amount DECIMAL(15,2);
    v_successful INTEGER := 0;
    v_failed INTEGER := 0;
    v_failed_items JSONB := '[]'::JSONB;
    v_batch_reference VARCHAR(50);
    v_lock_id BIGINT;
    v_savepoint_name TEXT;
    v_payment RECORD;
    v_counter INTEGER := 0;
BEGIN
    v_batch_reference := 'BATCH_' || TO_CHAR(CURRENT_TIMESTAMP, 'YYYYMMDD_HH24MISS') || '_' ||
                        SUBSTRING(MD5(RANDOM()::TEXT) FROM 1 FOR 8);

    v_lock_id := ABS(HASHTEXT(p_company_account_number));

    IF NOT pg_try_advisory_lock(v_lock_id) THEN
        success := FALSE;
        message := 'Batch processing already in progress for this company';
        successful_count := 0;
        failed_count := 0;
        failed_details := '[]'::JSONB;
        batch_reference := NULL;
        RETURN NEXT;
        RETURN;
    END IF;

    BEGIN
        SAVEPOINT salary_batch_start;

        -- Step 1: Validate company account and get balance
        SELECT account_id, balance INTO v_company_account_id, v_company_balance
        FROM accounts
        WHERE account_number = p_company_account_number
        FOR UPDATE;

        IF v_company_account_id IS NULL THEN
            RAISE EXCEPTION 'Company account not found';
        END IF;

        -- Step 2: Calculate total batch amount
        SELECT SUM((payment->>'amount')::DECIMAL) INTO v_total_batch_amount
        FROM jsonb_array_elements(p_payments) AS payment;

        IF v_total_batch_amount IS NULL THEN
            RAISE EXCEPTION 'No valid payments in batch';
        END IF;

        -- Step 3: Check company balance
        IF v_company_balance < v_total_batch_amount THEN
            RAISE EXCEPTION 'Insufficient company balance. Required: %, Available: %',
                          v_total_batch_amount, v_company_balance;
        END IF;

        -- Step 4: Process each payment individually
        FOR v_payment IN
            SELECT
                (elem->>'iin') as iin,
                (elem->>'amount')::DECIMAL(15,2) as amount,
                COALESCE(elem->>'description', 'Salary') as description
            FROM jsonb_array_elements(p_payments) AS elem
        LOOP
            v_counter := v_counter + 1;
            v_savepoint_name := 'payment_' || v_counter;

            BEGIN
                SAVEPOINT payment_savepoint;
                DECLARE
                    v_employee_account_id INTEGER;
                    v_employee_account_number VARCHAR(34);
                BEGIN
                    SELECT a.account_id, a.account_number
                    INTO v_employee_account_id, v_employee_account_number
                    FROM accounts a
                    JOIN customers c ON a.customer_id = c.customer_id
                    WHERE c.tin = v_payment.iin
                        AND a.is_active = TRUE
                        AND a.currency = 'KZT'  -- Salary in KZT
                    LIMIT 1;

                    IF v_employee_account_id IS NULL THEN
                        RAISE EXCEPTION USING
                            ERRCODE = 'BP001',
                            MESSAGE = 'Employee account not found for IIN: ' || v_payment.iin;
                    END IF;

                    INSERT INTO transactions (
                        from_account_id,
                        to_account_id,
                        amount,
                        currency,
                        exchange_rate,
                        amount_kzt,
                        type,
                        status,
                        completed_at,
                        description
                    ) VALUES (
                        v_company_account_id,
                        v_employee_account_id,
                        v_payment.amount,
                        'KZT',
                        1.0,
                        v_payment.amount,
                        'transfer',
                        'completed',
                        CURRENT_TIMESTAMP,
                        v_payment.description || ' - ' || p_description
                    );

                    -- Update balances (will be committed atomically at the end)
                    -- Note: We don't update balances here, we'll do it atomically later

                    v_successful := v_successful + 1;

                EXCEPTION
                    WHEN SQLSTATE 'BP001' THEN
                        v_failed := v_failed + 1;
                        v_failed_items := v_failed_items ||
                            jsonb_build_object(
                                'iin', v_payment.iin,
                                'amount', v_payment.amount,
                                'error', 'Employee account not found',
                                'error_code', 'BP001'
                            );
                        ROLLBACK TO SAVEPOINT payment_savepoint;
                    WHEN OTHERS THEN
                        v_failed := v_failed + 1;
                        v_failed_items := v_failed_items ||
                            jsonb_build_object(
                                'iin', v_payment.iin,
                                'amount', v_payment.amount,
                                'error', SQLERRM,
                                'error_code', SQLSTATE
                            );
                        ROLLBACK TO SAVEPOINT payment_savepoint;
                END;

            END;
        END LOOP;

        -- Step 5: Atomically update all balances at the end
        IF v_successful > 0 THEN
            UPDATE accounts
            SET balance = balance - v_total_batch_amount
            WHERE account_id = v_company_account_id;

            WITH payment_updates AS (
                SELECT
                    a.account_id,
                    SUM((elem->>'amount')::DECIMAL) as total_amount
                FROM jsonb_array_elements(p_payments) AS elem
                JOIN customers c ON c.tin = elem->>'iin'
                JOIN accounts a ON a.customer_id = c.customer_id
                    AND a.is_active = TRUE
                    AND a.currency = 'KZT'
                WHERE NOT EXISTS (
                    SELECT 1 FROM jsonb_array_elements(v_failed_items) AS failed
                    WHERE failed->>'iin' = elem->>'iin'
                )
                GROUP BY a.account_id
            )
            UPDATE accounts a
            SET balance = balance + pu.total_amount
            FROM payment_updates pu
            WHERE a.account_id = pu.account_id;
        END IF;

        -- Step 6: Create batch audit record
        INSERT INTO audit_log (table_name, record_id, action, new_values)
        VALUES ('batch_processing', 0, 'INSERT',
                jsonb_build_object(
                    'batch_reference', v_batch_reference,
                    'company_account', p_company_account_number,
                    'total_amount', v_total_batch_amount,
                    'successful_count', v_successful,
                    'failed_count', v_failed,
                    'timestamp', CURRENT_TIMESTAMP
                ));

        success := TRUE;
        message := 'Batch processing completed. Successful: ' || v_successful || ', Failed: ' || v_failed;
        successful_count := v_successful;
        failed_count := v_failed;
        failed_details := v_failed_items;
        batch_reference := v_batch_reference;

        RETURN NEXT;

    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK TO SAVEPOINT salary_batch_start;

            success := FALSE;
            message := 'Batch processing failed: ' || SQLERRM;
            successful_count := 0;
            failed_count := 0;
            failed_details := '[]'::JSONB;
            batch_reference := NULL;

            RETURN NEXT;
    END;

    PERFORM pg_advisory_unlock(v_lock_id);

END;
$$ LANGUAGE plpgsql;

-- PART 7: MATERIALIZED VIEW FOR BATCH REPORTS
CREATE MATERIALIZED VIEW salary_batch_summary AS
WITH batch_info AS (
    SELECT
        (new_values->>'batch_reference')::VARCHAR as batch_reference,
        (new_values->>'company_account')::VARCHAR as company_account,
        (new_values->>'total_amount')::DECIMAL as total_amount,
        (new_values->>'successful_count')::INTEGER as successful_count,
        (new_values->>'failed_count')::INTEGER as failed_count,
        changed_at as processed_at
    FROM audit_log
    WHERE table_name = 'batch_processing'
        AND action = 'INSERT'
)
SELECT
    batch_reference,
    company_account,
    total_amount,
    successful_count,
    failed_count,
    processed_at,
    ROUND((successful_count::DECIMAL / NULLIF((successful_count + failed_count), 0)) * 100, 2) as success_rate_percent,
    CASE
        WHEN processed_at::DATE = CURRENT_DATE THEN 'Today'
        WHEN processed_at::DATE = CURRENT_DATE - 1 THEN 'Yesterday'
        ELSE TO_CHAR(processed_at, 'YYYY-MM-DD')
    END as processing_day
FROM batch_info
ORDER BY processed_at DESC;

CREATE UNIQUE INDEX idx_salary_batch_ref ON salary_batch_summary(batch_reference);

CREATE OR REPLACE FUNCTION refresh_salary_batch_summary()
RETURNS VOID AS $$
BEGIN
    REFRESH MATERIALIZED VIEW CONCURRENTLY salary_batch_summary;
END;
$$ LANGUAGE plpgsql;

-- PART 8: TEST CASES AND DEMONSTRATION
-- Test Case 1: Successful transfer
SELECT 'Test 1: Successful transfer within limits' as test_case;
SELECT * FROM process_transfer(
    'KZ12345678901234567890',  -- From: Ali's KZT account
    'KZ23456789012345678901',  -- To: Bermet's KZT account
    50000.00,                  -- Amount
    'KZT',                     -- Currency
    'Test transfer'            -- Description
);

-- Test Case 2: Insufficient balance
SELECT 'Test 2: Transfer with insufficient balance' as test_case;
SELECT * FROM process_transfer(
    'KZ90123456789012345678',  -- From: Maria's account (balance 1,500,000)
    'KZ12345678901234567890',  -- To: Ali's account
    2000000.00,                -- Amount (more than balance)
    'KZT',
    'Should fail - insufficient funds'
);

-- Test Case 3: Daily limit exceeded
SELECT 'Test 3: Daily limit exceeded' as test_case;
-- First, let's simulate some daily transactions
INSERT INTO transactions (from_account_id, to_account_id, amount, currency, exchange_rate, amount_kzt, type, status, created_at, completed_at)
SELECT
    1,  -- from_account_id
    3,  -- to_account_id
    900000.00,  -- amount
    'KZT',      -- currency
    1.0,        -- exchange_rate
    900000.00,  -- amount_kzt
    'transfer', -- type
    'completed',-- status
    CURRENT_DATE + INTERVAL '8 hours', -- created_at (today)
    CURRENT_DATE + INTERVAL '8 hours'  -- completed_at
FROM generate_series(1, 2);

-- Now try to transfer more (should exceed daily limit of 1,000,000)
SELECT * FROM process_transfer(
    'KZ12345678901234567890',
    'KZ23456789012345678901',
    150000.00,
    'KZT',
    'Should fail - daily limit'
);

-- Test Case 4: Currency conversion transfer
SELECT 'Test 4: Cross-currency transfer' as test_case;
SELECT * FROM process_transfer(
    'KZ09876543210987654321',  -- From: Ali's USD account
    'KZ34567890123456789012',  -- To: Bermet's EUR account
    1000.00,                   -- Amount in USD
    'USD',                     -- Currency
    'International business payment'
);

-- Test Case 5: Batch processing test
SELECT 'Test 5: Salary batch processing' as test_case;
SELECT * FROM process_salary_batch(
    'KZ67890123456789012345',  -- Company account
    '[
        {"iin": "123456789012", "amount": 500000, "description": "Salary March"},
        {"iin": "234567890123", "amount": 450000, "description": "Salary March"},
        {"iin": "345678901234", "amount": 600000, "description": "Salary March"},
        {"iin": "999999999999", "amount": 400000, "description": "Salary March"}  -- Invalid IIN
    ]'::JSONB,
    'March 2024 Salary Batch'
);

SELECT * FROM salary_batch_summary;

-- Test Case 6: View demonstrations
SELECT 'Test 6: Customer balance summary view' as test_case;
SELECT * FROM customer_balance_summary LIMIT 5;

SELECT 'Test 7: Daily transaction report view' as test_case;
SELECT * FROM daily_transaction_report WHERE transaction_date >= CURRENT_DATE - 7;

SELECT 'Test 8: Suspicious activity view' as test_case;
SELECT * FROM suspicious_activity_view LIMIT 5;

-- PART 9: EXPLAIN ANALYZE FOR INDEXES
-- Analyze index performance
SELECT 'Index Performance Analysis' as analysis;

-- 1. Account lookup performance
EXPLAIN ANALYZE
SELECT * FROM accounts WHERE account_number = 'KZ12345678901234567890';

-- 2. Active accounts query
EXPLAIN ANALYZE
SELECT * FROM accounts WHERE is_active = TRUE;

-- 3. Email search (case-insensitive)
EXPLAIN ANALYZE
SELECT * FROM customers WHERE LOWER(email) = LOWER('ali.aliyev@email.com');

-- 4. Date-based transaction query
EXPLAIN ANALYZE
SELECT * FROM transactions
WHERE created_at >= '2024-01-01'
    AND status = 'completed'
ORDER BY created_at DESC
LIMIT 100;

-- 5. JSONB query on audit log
EXPLAIN ANALYZE
SELECT * FROM audit_log
WHERE new_values @> '{"status": "completed"}'::JSONB;

-- 6. Customer reporting query (using covering index)
EXPLAIN ANALYZE
SELECT customer_id, full_name, tin, daily_limit_kzt
FROM customers
WHERE status = 'active'
ORDER BY customer_id;

-- PART 10: CONCURRENCY TEST DEMONSTRATION
-- Demonstration of concurrent transaction handling
-- This would typically be run in two separate psql sessions

-- SESSION 1:
-- BEGIN;
-- SELECT * FROM accounts WHERE account_number = 'KZ12345678901234567890' FOR UPDATE;
-- -- Wait here, do not commit

-- SESSION 2 (run in another terminal):
-- BEGIN;
-- SELECT * FROM accounts WHERE account_number = 'KZ12345678901234567890' FOR UPDATE;
-- -- This will wait until SESSION 1 commits or rolls back

/*
-- To clean up and start fresh:
DROP MATERIALIZED VIEW IF EXISTS salary_batch_summary CASCADE;
DROP FUNCTION IF EXISTS process_salary_batch CASCADE;
DROP FUNCTION IF EXISTS process_transfer CASCADE;
DROP FUNCTION IF EXISTS refresh_salary_batch_summary CASCADE;
DROP FUNCTION IF EXISTS audit_trigger_function CASCADE;
DROP VIEW IF EXISTS suspicious_activity_view CASCADE;
DROP VIEW IF EXISTS daily_transaction_report CASCADE;
DROP VIEW IF EXISTS customer_balance_summary CASCADE;
DROP TABLE IF EXISTS audit_log CASCADE;
DROP TABLE IF EXISTS transactions CASCADE;
DROP TABLE IF EXISTS exchange_rates CASCADE;
DROP TABLE IF EXISTS accounts CASCADE;
DROP TABLE IF EXISTS customers CASCADE;
*/