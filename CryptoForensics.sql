CREATE DATABASE CryptoForensics_db;
USE CryptoForensics_db;

CREATE TABLE blocks (
	block_id           BIGINT PRIMARY KEY,
	timestamp          DATETIME,
	block_hash         TEXT,
	previous_hash      TEXT,
	difficulty         VARCHAR(50),
	transaction_count  INT
);

SELECT * FROM blocks ;

INSERT INTO blocks (block_id, timestamp, block_hash, previous_hash, difficulty, transaction_count) VALUES
	(14321000, '2023-06-15 08:32:45', '0x4a7e...c3d2', '0x3f8b...a1e9', '12,345,678', 214),
	(14321001, '2023-06-15 08:34:12', '0x5b2f...d4e1', '0x4a7e...c3d2', '12,345,712', 187),
	(14321002, '2023-06-15 08:36:03', '0x6c1a...e5f0', '0x5b2f...d4e1', '12,345,689', 203);

CREATE TABLE addresses (
	address_id    INT PRIMARY KEY AUTO_INCREMENT,
	address_hash  TEXT,
	first_seen    DATETIME,
	is_contract   BOOLEAN
);

SELECT * FROM addresses ;

INSERT INTO addresses (address_hash, first_seen, is_contract) VALUES
	('0x742d35Cc6634C0532925a3b844Bc454e4438f44e', '2021-03-12 14:22:10', FALSE), 
	('0x28c6c06298d514Db089934071355E5743bf21d60', '2020-11-05 09:15:33', TRUE), 
	('0x5aAeb6053F3E94C9b9A09f33669435E7Ef1BeAed', '2022-01-18 16:45:21', FALSE), 
	('0x3f5CE5FBFe3E9af3971dD833D26bA9b5C936f0bE', '2019-07-22 11:30:47', FALSE), 
	('0x89d24A6b4CcB1B6fAA2625fE562bDD9a23260359', '2018-05-30 13:18:05', TRUE),
	('0xAb5801a7D398351b8bE11C439e05C5B3259aeC9B', '2022-09-14 17:33:19', FALSE),
	('0x2fAf55a544C5F73666438BC185aeCC8D685E6b83', '2021-12-03 10:47:22', TRUE),
	('0xBE0eB53F46cd790Cd13851d5EFf43D12404d33E8', '2023-01-25 08:12:37', FALSE);

CREATE TABLE transactions (
	tx_id        INT PRIMARY KEY AUTO_INCREMENT,
	tx_hash      TEXT,
	block_id     BIGINT,
	from_address INT,
	to_address   INT,
	value        DECIMAL(15,2),
	gas_price    DECIMAL(20,15),
	gas_used     DECIMAL(15,2),
	timestamp    DATETIME,
    FOREIGN KEY (block_id) REFERENCES blocks(block_id)
); 

SELECT * FROM transactions ;

INSERT INTO transactions (tx_hash, block_id, from_address, to_address, value, gas_price, gas_used, timestamp) VALUES
	('0x9a4b...e7c1', 14321000, 1, 2, 12.5, 0.000000045, 21000, '2023-06-15 08:32:47'),
	('0x8b3c...d6a2', 14321000, 3, 4, 3.2, 0.000000042, 45000, '2023-06-15 08:32:51'),
	('0x7c2d...c583', 14321001, 2, 5, 1500, 0.000000047, 65000, '2023-06-15 08:34:15'),
	('0x6d1e...b474', 14321002, 4, 3, 8.75, 0.000000043, 32000, '2023-06-15 08:36:05'),
	('0x5e3a...a7b5', 14321000, 6, 7, 5.75, 0.000000046, 38000, '2023-06-15 08:32:55'),
	('0x4f29...98c4', 14321001, 8, 1, 22.3, 0.000000044, 42000, '2023-06-15 08:34:18'),
	('0x3e18...89d3', 14321002, 7, 6, 1.25, 0.000000041, 29000, '2023-06-15 08:36:08');

CREATE TABLE token_transfers (
	token__transfer_id       INT PRIMARY KEY AUTO_INCREMENT,
	tx_id                    INT,
	token_address            INT,
	from_address             INT,
	to_address               INT,
	value                    DECIMAL(15,2),
    FOREIGN KEY (tx_id) REFERENCES transactions(tx_id)
);

SELECT * FROM token_transfers ;

INSERT INTO token_transfers (tx_id, token_address, from_address, to_address, value) VALUES
	(2, 5, 3, 4, 3200.0),
	(3, 5, 2, 5, 150000.0),
	(4, 5, 4, 3, 8750.0),
	(5, 5, 6, 7, 5750.0),
	(6, 5, 8, 1, 22300.0),
	(7, 5, 7, 6, 1250.0);

SELECT 
	block_id,timestamp,difficulty,transaction_count
FROM blocks
ORDER BY block_id DESC;

SELECT 
	ROUND(AVG(transaction_count),2) AS Average_transactions_per_block
FROM blocks;

WITH block_gas_usage AS (
    SELECT 
        t.block_id,
        SUM(t.gas_used) AS total_gas_used,
        AVG(t.gas_used) AS avg_gas_per_tx
    FROM transactions t
    GROUP BY t.block_id
),
ranked_blocks AS (
    SELECT 
        *,
        ROW_NUMBER() OVER (ORDER BY total_gas_used DESC) AS ranking,
        COUNT(*) OVER () AS total_blocks
    FROM block_gas_usage
)
SELECT 
    block_id,total_gas_used,
    ROUND(avg_gas_per_tx, 2) AS avg_gas_per_transaction
FROM ranked_blocks
WHERE ranking <= CEIL(total_blocks * 0.10)
ORDER BY total_gas_used DESC;

SELECT 
    a.address_hash,
    COALESCE(sender_tx.count_sender, 0) AS sent_tx_count,
    COALESCE(receiver_tx.count_receiver, 0) AS received_tx_count,
    COALESCE(sender_tx.count_sender, 0) + COALESCE(receiver_tx.count_receiver, 0) AS total_transactions
FROM 
    addresses a
LEFT JOIN (
    SELECT 
        from_address,
        COUNT(*) AS count_sender
    FROM transactions
    GROUP BY from_address
) sender_tx ON a.address_id = sender_tx.from_address
LEFT JOIN (
    SELECT 
        to_address,
        COUNT(*) AS count_receiver
    FROM transactions
    GROUP BY to_address
) receiver_tx ON a.address_id = receiver_tx.to_address
ORDER BY total_transactions DESC;

SELECT 
    a.address_hash,a.is_contract,
    COALESCE(sender_tx.count_sender, 0) + COALESCE(receiver_tx.count_receiver, 0) AS total_transactions
FROM addresses a
LEFT JOIN (
    SELECT 
        from_address,
        COUNT(*) AS count_sender
    FROM transactions
    GROUP BY from_address
) sender_tx ON a.address_id = sender_tx.from_address
LEFT JOIN (
    SELECT 
        to_address,
        COUNT(*) AS count_receiver
    FROM transactions
    GROUP BY to_address
) receiver_tx ON a.address_id = receiver_tx.to_address
WHERE a.is_contract = TRUE
ORDER BY total_transactions DESC;

WITH known_exchanges AS (
    SELECT address_id
    FROM addresses
    WHERE address_hash IN (
        '0x742d35Cc6634C0532925a3b844Bc454e4438f44e',
        '0x28c6c06298d514Db089934071355E5743bf21d60',
        '0x3f5CE5FBFe3E9af3971dD833D26bA9b5C936f0bE'
    )
),
exchange_links AS (
    SELECT 
        from_address AS user_address,
        to_address AS exchange_address,
        value
    FROM transactions
    WHERE to_address IN (SELECT address_id FROM known_exchanges)

    UNION ALL

    SELECT 
        to_address AS user_address,
        from_address AS exchange_address,
        value
    FROM transactions
    WHERE from_address IN (SELECT address_id FROM known_exchanges)
)
SELECT 
    a.address_hash,
    COUNT(DISTINCT e.exchange_address) AS exchange_used,
    SUM(e.value) AS total_value
FROM exchange_links e
JOIN addresses a ON e.user_address = a.address_id
GROUP BY e.user_address
ORDER BY total_value DESC;
    
SELECT 
    HOUR(timestamp) AS hour_of_day,ROUND(AVG(value), 4) 
    AS avg_eth_value,COUNT(*) AS total_transactions
FROM transactions
GROUP BY hour_of_day
ORDER BY hour_of_day;

SELECT 
    t.tx_hash,t.value,fa.address_hash 
    AS from_address,ta.address_hash AS to_address
FROM transactions t
JOIN addresses fa ON t.from_address = fa.address_id
JOIN addresses ta ON t.to_address = ta.address_id
WHERE t.value > 10
ORDER BY t.value DESC;

WITH transaction_chains AS (
    SELECT 
        t1.tx_hash AS start_tx,
        t1.from_address AS original_sender,
        t1.to_address AS first_recipient,
        t1.value AS initial_value,
        t1.timestamp AS start_time,
        t2.tx_hash AS second_tx,
        t2.from_address AS second_sender,
        t2.to_address AS second_recipient,
        t2.value AS second_value,
        t2.timestamp AS second_time,
        t3.tx_hash AS third_tx,
        t3.from_address AS third_sender,
        t3.to_address AS third_recipient,
        t3.value AS third_value,
        t3.timestamp AS third_time,
        TIMESTAMPDIFF(SECOND, t1.timestamp, t3.timestamp) AS time_span_seconds,
        CONCAT(t1.from_address, '-', t1.to_address, '-', 
               IFNULL(t2.to_address, ''), '-', IFNULL(t3.to_address, '')) AS sequence_path,
        (t1.value + IFNULL(t2.value, 0) + IFNULL(t3.value, 0)) AS total_value
    FROM 
        transactions t1
    LEFT JOIN 
        transactions t2 ON t1.to_address = t2.from_address 
        AND t2.timestamp > t1.timestamp 
        AND TIMESTAMPDIFF(MINUTE, t1.timestamp, t2.timestamp) <= 5
    LEFT JOIN 
        transactions t3 ON t2.to_address = t3.from_address 
        AND t3.timestamp > t2.timestamp 
        AND TIMESTAMPDIFF(MINUTE, t2.timestamp, t3.timestamp) <= 5
    WHERE 
        t1.to_address IS NOT NULL
        AND (t2.tx_hash IS NOT NULL OR t3.tx_hash IS NOT NULL)
),
chain_stats AS (
    SELECT 
        sequence_path,
        COUNT(*) AS transaction_count,
        time_span_seconds,
        SUM(total_value) AS total_value,
        original_sender
    FROM transaction_chains
    GROUP BY sequence_path, original_sender,time_span_seconds
    HAVING COUNT(*) > 1
)
SELECT 
    ROW_NUMBER() OVER (ORDER BY total_value DESC) AS sequence_id,
    transaction_count,
    total_value,
    time_span_seconds,
    original_sender AS start_address,
    sequence_path
FROM chain_stats
ORDER BY total_value DESC
LIMIT 20;

SELECT 
    SUM(value) AS total_dai_volume,
    COUNT(DISTINCT from_address) AS unique_senders,
    COUNT(DISTINCT to_address) AS unique_receivers
FROM token_transfers
WHERE token_address = (
    SELECT address_id
    FROM addresses
    WHERE address_hash = '0x89d24A6b4CcB1B6fAA2625fE562bDD9a23260359'
    LIMIT 1
);

WITH dai_token AS (
    SELECT address_id
    FROM addresses
    WHERE address_hash = '0x89d24A6b4CcB1B6fAA2625fE562bDD9a23260359'
    LIMIT 1
),
dai_senders AS (
    SELECT DISTINCT from_address
    FROM token_transfers
    WHERE token_address = (SELECT address_id FROM dai_token)
),
dai_receivers AS (
    SELECT 
        to_address,SUM(value) AS total_dai_received
    FROM token_transfers
    WHERE token_address = (SELECT address_id FROM dai_token)
    GROUP BY to_address
)
SELECT 
    a.address_hash,r.total_dai_received
FROM dai_receivers r
JOIN addresses a ON r.to_address = a.address_id
LEFT JOIN dai_senders s ON r.to_address = s.from_address
WHERE s.from_address IS NULL
ORDER BY r.total_dai_received DESC;

WITH dai_token AS (
    SELECT address_id
    FROM addresses
    WHERE address_hash = '0x89d24A6b4CcB1B6fAA2625fE562bDD9a23260359'
    LIMIT 1
),
received_dai AS (
    SELECT 
        to_address AS address_id,
        SUM(value) AS total_received
    FROM token_transfers
    WHERE token_address = (SELECT address_id FROM dai_token)
    GROUP BY to_address
),
sent_dai AS (
    SELECT 
        from_address AS address_id,
        SUM(value) AS total_sent
    FROM token_transfers
    WHERE token_address = (SELECT address_id FROM dai_token)
    GROUP BY from_address
)
SELECT 
    a.address_hash,
    COALESCE(r.total_received, 0) AS total_received,
    COALESCE(s.total_sent, 0) AS total_sent,
    COALESCE(r.total_received, 0) - COALESCE(s.total_sent, 0) AS net_dai
FROM addresses a
LEFT JOIN received_dai r ON a.address_id = r.address_id
LEFT JOIN sent_dai s ON a.address_id = s.address_id
WHERE r.total_received IS NOT NULL OR s.total_sent IS NOT NULL
ORDER BY net_dai DESC;

WITH circular_transactions AS (
    SELECT 
        t1.from_address AS address_a_id,
        t1.to_address AS address_b_id,
        t1.value AS value_ab,
        t2.value AS value_ba,
        (t1.value + t2.value) / 2 AS avg_value,
        a1.address_hash AS address_a_hash,
        a2.address_hash AS address_b_hash
    FROM transactions t1
    JOIN 
        transactions t2 ON t1.to_address = t2.from_address
        AND t2.to_address = t1.from_address
        AND t2.timestamp > t1.timestamp
        AND TIMESTAMPDIFF(MINUTE, t1.timestamp, t2.timestamp) < 5
    JOIN addresses a1 ON t1.from_address = a1.address_id
    JOIN addresses a2 ON t1.to_address = a2.address_id
    WHERE t1.from_address != t1.to_address
),
wash_trade_stats AS (
    SELECT
        address_a_hash AS address_hash,
        COUNT(*) AS circular_transaction_count,
        ROUND(SUM(avg_value), 4) AS total_value_eth,
        GROUP_CONCAT(DISTINCT address_b_hash) AS counterparties
    FROM circular_transactions
    GROUP BY address_a_hash
    HAVING COUNT(*) >= 1
)
SELECT
    address_hash,
    circular_transaction_count,
    total_value_eth,
    counterparties,
    ROUND(total_value_eth / circular_transaction_count, 4) AS avg_value_per_circle
FROM wash_trade_stats
ORDER BY
    circular_transaction_count DESC,
    total_value_eth DESC;
    
WITH 
gas_costs AS (
    SELECT 
        tx_hash,
        gas_price,
        (gas_price * gas_used) AS gas_cost_eth,
        value
    FROM transactions
),
gas_stats AS (
    SELECT
        AVG(gas_price) AS avg_gas_price,
        STD(gas_price) AS stddev_gas_price
    FROM transactions
)
SELECT
    tx_hash,
    gas_price AS gas_price_gwei,
    ROUND(gas_cost_eth, 6) AS gas_cost_eth,
    value AS transaction_value_eth
FROM gas_costs
CROSS JOIN gas_stats
WHERE gas_price > avg_gas_price + (0.5* stddev_gas_price) 
ORDER BY gas_price DESC;

WITH known_exchanges AS (
    SELECT address_id
    FROM addresses
    WHERE address_hash IN (
        '0x742d35Cc6634C0532925a3b844Bc454e4438f44e',
        '0x28c6c06298d514Db089934071355E5743bf21d60',
        '0x3f5CE5FBFe3E9af3971dD833D26bA9b5C936f0bE'
    )
),
exchange_transfers AS (
    SELECT 
        t.to_address,t.from_address,t.timestamp
    FROM transactions t
    WHERE t.from_address IN (SELECT address_id FROM known_exchanges)
)
SELECT 
    a.address_hash AS receiver_address,
    COUNT(DISTINCT e.from_address) AS exchanges_used,
    MIN(e.timestamp) AS first_received_from_exchange
FROM exchange_transfers e
JOIN addresses a ON e.to_address = a.address_id
GROUP BY e.to_address
HAVING COUNT(DISTINCT e.from_address) > 1
ORDER BY exchanges_used DESC, first_received_from_exchange;
    
SELECT 
    tt.from_address,
    fa.address_hash AS from_address_hash,
    tt.to_address,
    ta.address_hash AS to_address_hash,
    tt.value
FROM token_transfers tt
JOIN addresses a ON tt.token_address = a.address_id
LEFT JOIN addresses fa ON tt.from_address = fa.address_id
LEFT JOIN addresses ta ON tt.to_address = ta.address_id
WHERE tt.token_address = (
    SELECT address_id
    FROM addresses
    WHERE address_hash = '0x89d24A6b4CcB1B6fAA2625fE562bDD9a23260359'
    LIMIT 1
)
ORDER BY tt.tx_id;

SELECT 
    t.tx_hash,a.address_hash AS to_address_hash,
    t.value,(t.gas_used * t.gas_price) AS Gas_cost,
    ROUND(((t.gas_used * t.gas_price) / t.value) * 100, 4) AS gas_cost_percentage
FROM transactions t
JOIN addresses a ON t.to_address = a.address_id
WHERE 
    a.is_contract = TRUE
    AND t.value > 0
ORDER BY gas_cost_percentage DESC;
