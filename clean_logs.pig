
-- ============================================================
-- WEB SERVER LOG ANALYTICS USING PIG LATIN
-- ============================================================

-- ------------------------------------------------------------
-- 1. LOAD RAW CSV
-- ------------------------------------------------------------

raw = LOAD '/web_log_project/input/web_server_logs.csv'
USING PigStorage(',')
AS (
    ip_address:chararray,
    log_time:chararray,
    method:chararray,
    url:chararray,
    protocol:chararray,
    status_code:chararray,
    response_size:chararray,
    user_agent:chararray
);

-- ------------------------------------------------------------
-- 2. REMOVE HEADER
-- ------------------------------------------------------------

no_header = FILTER raw BY
    ip_address IS NOT NULL
    AND ip_address != 'ip_address';

-- ------------------------------------------------------------
-- 3. REMOVE MALFORMED RECORDS
-- ------------------------------------------------------------

valid = FILTER no_header BY
    log_time IS NOT NULL
    AND method IS NOT NULL
    AND url IS NOT NULL
    AND status_code MATCHES '[0-9]{3}'
    AND response_size MATCHES '[0-9]+';

-- ------------------------------------------------------------
-- 4. CLEAN AND CAST DATA
-- ------------------------------------------------------------

cleaned = FOREACH valid GENERATE
    TRIM(ip_address) AS ip_address,
    TRIM(log_time) AS log_time,
    UPPER(TRIM(method)) AS method,
    TRIM(url) AS url,
    TRIM(protocol) AS protocol,
    (int)status_code AS status_code,
    (long)response_size AS response_size,
    TRIM(user_agent) AS user_agent;

-- ------------------------------------------------------------
-- 5. STORE CLEANED DATA
-- ------------------------------------------------------------

STORE cleaned
INTO '/web_log_project/output/cleaned_logs'
USING PigStorage(',');

-- ------------------------------------------------------------
-- 6. TOTAL CLEAN RECORDS
-- ------------------------------------------------------------

all_group = GROUP cleaned ALL;

record_count = FOREACH all_group GENERATE
    'TOTAL_CLEAN_RECORDS' AS metric,
    COUNT(cleaned) AS value;

STORE record_count
INTO '/web_log_project/output/pig_total_records'
USING PigStorage(',');

-- ------------------------------------------------------------
-- 7. STATUS CODE DISTRIBUTION
-- ------------------------------------------------------------

status_group = GROUP cleaned BY status_code;

status_counts = FOREACH status_group GENERATE
    group AS status_code,
    COUNT(cleaned) AS requests;

status_sorted = ORDER status_counts BY requests DESC;

STORE status_sorted
INTO '/web_log_project/output/pig_status_distribution'
USING PigStorage(',');

-- ------------------------------------------------------------
-- 8. TOP 10 URLS
-- ------------------------------------------------------------

url_group = GROUP cleaned BY url;

url_counts = FOREACH url_group GENERATE
    group AS url,
    COUNT(cleaned) AS visits;

url_sorted = ORDER url_counts BY visits DESC;

top_urls = LIMIT url_sorted 10;

STORE top_urls
INTO '/web_log_project/output/pig_top_urls'
USING PigStorage(',');

-- ------------------------------------------------------------
-- 9. HTTP ERRORS BY URL
-- ------------------------------------------------------------

errors = FILTER cleaned BY status_code >= 400;

error_url_group = GROUP errors BY url;

error_url_counts = FOREACH error_url_group GENERATE
    group AS url,
    COUNT(errors) AS error_count;

error_url_sorted = ORDER error_url_counts BY error_count DESC;

STORE error_url_sorted
INTO '/web_log_project/output/pig_http_errors'
USING PigStorage(',');

-- ------------------------------------------------------------
-- 10. HTTP METHODS
-- ------------------------------------------------------------

method_group = GROUP cleaned BY method;

method_counts = FOREACH method_group GENERATE
    group AS method,
    COUNT(cleaned) AS requests;

method_sorted = ORDER method_counts BY requests DESC;

STORE method_sorted
INTO '/web_log_project/output/pig_methods'
USING PigStorage(',');

-- ------------------------------------------------------------
-- 11. TRAFFIC BY HOUR
-- ------------------------------------------------------------

with_hour = FOREACH cleaned GENERATE
    SUBSTRING(log_time,11,13) AS hour;

hour_group = GROUP with_hour BY hour;

hour_counts = FOREACH hour_group GENERATE
    group AS hour,
    COUNT(with_hour) AS requests;

hour_sorted = ORDER hour_counts BY requests DESC;

STORE hour_sorted
INTO '/web_log_project/output/pig_peak_hours'
USING PigStorage(',');

-- ------------------------------------------------------------
-- 12. DAILY TRAFFIC
-- ------------------------------------------------------------

with_day = FOREACH cleaned GENERATE
    SUBSTRING(log_time,0,10) AS log_date;

day_group = GROUP with_day BY log_date;

day_counts = FOREACH day_group GENERATE
    group AS log_date,
    COUNT(with_day) AS requests;

day_sorted = ORDER day_counts BY log_date;

STORE day_sorted
INTO '/web_log_project/output/pig_daily_traffic'
USING PigStorage(',');

-- ------------------------------------------------------------
-- 13. USER AGENT DISTRIBUTION
-- ------------------------------------------------------------

agent_group = GROUP cleaned BY user_agent;

agent_counts = FOREACH agent_group GENERATE
    group AS user_agent,
    COUNT(cleaned) AS requests;

agent_sorted = ORDER agent_counts BY requests DESC;

STORE agent_sorted
INTO '/web_log_project/output/pig_user_agents'
USING PigStorage(',');

-- ------------------------------------------------------------
-- 14. RESPONSE BY URL
-- ------------------------------------------------------------

response_group = GROUP cleaned BY url;

response_totals = FOREACH response_group GENERATE
    group AS url,
    SUM(cleaned.response_size) AS total_bytes;

response_sorted = ORDER response_totals BY total_bytes DESC;

top_response_urls = LIMIT response_sorted 10;

STORE top_response_urls
INTO '/web_log_project/output/pig_response_bytes_by_url'
USING PigStorage(',');

