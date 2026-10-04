
-- ============================================================
-- WEB SERVER LOG ANALYTICS USING HIVE
-- ============================================================

SET hive.execution.engine=mr;

-- ------------------------------------------------------------
-- CREATE DATABASE
-- ------------------------------------------------------------

CREATE DATABASE IF NOT EXISTS web_log_db;

USE web_log_db;

-- ------------------------------------------------------------
-- RECREATE EXTERNAL TABLE
-- ------------------------------------------------------------

DROP TABLE IF EXISTS web_logs;

CREATE EXTERNAL TABLE web_logs (
    ip_address STRING,
    log_time STRING,
    method STRING,
    url STRING,
    protocol STRING,
    status_code INT,
    response_size BIGINT,
    user_agent STRING
)
ROW FORMAT DELIMITED
FIELDS TERMINATED BY ','
STORED AS TEXTFILE
LOCATION '/web_log_project/input'
TBLPROPERTIES ('skip.header.line.count'='1');

-- ============================================================
-- 1. TOTAL RECORDS
-- ============================================================

SELECT
    'TOTAL RECORDS' AS analysis,
    COUNT(*) AS total_records
FROM web_logs;

-- ============================================================
-- 2. STATUS CODE DISTRIBUTION
-- ============================================================

SELECT
    status_code,
    COUNT(*) AS total_requests
FROM web_logs
GROUP BY status_code
ORDER BY total_requests DESC;

-- ============================================================
-- 3. TOP 10 MOST VISITED URLS
-- ============================================================

SELECT
    url,
    COUNT(*) AS visits
FROM web_logs
GROUP BY url
ORDER BY visits DESC
LIMIT 10;

-- ============================================================
-- 4. HTTP ERRORS BY STATUS CODE
-- ============================================================

SELECT
    status_code,
    COUNT(*) AS error_count
FROM web_logs
WHERE status_code >= 400
GROUP BY status_code
ORDER BY error_count DESC;

-- ============================================================
-- 5. HTTP ERRORS BY URL
-- ============================================================

SELECT
    url,
    COUNT(*) AS error_count
FROM web_logs
WHERE status_code >= 400
GROUP BY url
ORDER BY error_count DESC;

-- ============================================================
-- 6. HTTP METHOD DISTRIBUTION
-- ============================================================

SELECT
    method,
    COUNT(*) AS total_requests
FROM web_logs
GROUP BY method
ORDER BY total_requests DESC;

-- ============================================================
-- 7. REQUESTS BY HOUR
-- ============================================================

SELECT
    SUBSTR(log_time,12,2) AS hour,
    COUNT(*) AS total_requests
FROM web_logs
GROUP BY SUBSTR(log_time,12,2)
ORDER BY total_requests DESC;

-- ============================================================
-- 8. DAILY TRAFFIC
-- ============================================================

SELECT
    SUBSTR(log_time,1,10) AS log_date,
    COUNT(*) AS total_requests
FROM web_logs
GROUP BY SUBSTR(log_time,1,10)
ORDER BY log_date;

-- ============================================================
-- 9. USER AGENT DISTRIBUTION
-- ============================================================

SELECT
    user_agent,
    COUNT(*) AS total_requests
FROM web_logs
GROUP BY user_agent
ORDER BY total_requests DESC;

-- ============================================================
-- 10. RESPONSE BY URL
-- ============================================================

SELECT
    url,
    SUM(response_size) AS total_bytes
FROM web_logs
GROUP BY url
ORDER BY total_bytes DESC
LIMIT 10;

-- ============================================================
-- 11. GET REQUESTS
-- ============================================================

SELECT
    COUNT(*) AS get_requests
FROM web_logs
WHERE method = 'GET';

-- ============================================================
-- 12. POST REQUESTS
-- ============================================================

SELECT
    COUNT(*) AS post_requests
FROM web_logs
WHERE method = 'POST';

-- ============================================================
-- 13. SUCCESSFUL REQUESTS
-- ============================================================

SELECT
    COUNT(*) AS successful_requests
FROM web_logs
WHERE status_code >= 200
AND status_code < 400;

-- ============================================================
-- 14. SERVER ERRORS
-- ============================================================

SELECT
    COUNT(*) AS server_errors
FROM web_logs
WHERE status_code >= 500;

