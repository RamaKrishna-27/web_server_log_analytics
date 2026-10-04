#!/bin/bash
set -euo pipefail

# ============================================================
# WEB SERVER LOG ANALYTICS AND USER BEHAVIOR MONITORING
# COMPLETE HADOOP + HIVE + PIG PROJECT
# ============================================================

# ------------------------------------------------------------
# INPUT CSV
# ------------------------------------------------------------

CSV="${1:-/home/hdp/Downloads/web_server_logs.csv}"

# ------------------------------------------------------------
# PROJECT DIRECTORIES
# ------------------------------------------------------------

BASE="$HOME/web_log_project"
HDFS_BASE="/web_log_project"
HDFS_INPUT="$HDFS_BASE/input"
HDFS_OUTPUT="$HDFS_BASE/output"

# ------------------------------------------------------------
# HADOOP CONFIGURATION
# ------------------------------------------------------------

HADOOP_HOME="${HADOOP_HOME:-$HOME/hadoop-3.3.6}"

export HADOOP_HOME
export HADOOP_CONF_DIR="$HADOOP_HOME/etc/hadoop"
export YARN_CONF_DIR="$HADOOP_HOME/etc/hadoop"

# JobHistoryServer
export MAPRED_HISTORY_SERVER_HOST="localhost"

# ------------------------------------------------------------
# CHECK INPUT CSV
# ------------------------------------------------------------

if [[ ! -f "$CSV" ]]; then
    echo
    echo "ERROR: CSV not found:"
    echo "$CSV"
    echo
    echo "Usage:"
    echo "bash $0 /full/path/to/web_server_logs.csv"
    exit 1
fi

# ------------------------------------------------------------
# CREATE PROJECT DIRECTORIES
# ------------------------------------------------------------

mkdir -p \
    "$BASE/data" \
    "$BASE/pig" \
    "$BASE/hive" \
    "$BASE/output" \
    "$BASE/screenshots" \
    "$BASE/report"

cp -f "$CSV" "$BASE/data/web_server_logs.csv"

echo
echo "============================================================"
echo " WEB SERVER LOG ANALYTICS PROJECT"
echo "============================================================"
echo
echo "Input CSV : $CSV"
echo "Project   : $BASE"
echo "Hadoop    : $HADOOP_HOME"
echo

# ============================================================
# CHECK HADOOP / HDFS
# ============================================================

echo "============================================================"
echo " CHECKING HADOOP SERVICES"
echo "============================================================"

if ! hadoop fs -ls / >/dev/null 2>&1; then

    echo
    echo "ERROR: HDFS is not available."
    echo
    echo "Start Hadoop/YARN using:"
    echo
    echo "start-dfs.sh"
    echo "start-yarn.sh"
    echo
    exit 1
fi

echo
echo "HDFS is available."

# ------------------------------------------------------------
# CHECK JOB HISTORY SERVER
# ------------------------------------------------------------

echo
echo "Checking JobHistoryServer..."

if ! jps | grep -q "JobHistoryServer"; then

    echo "JobHistoryServer is not running."
    echo "Starting JobHistoryServer..."

    mapred --daemon start historyserver

    sleep 3
fi

if jps | grep -q "JobHistoryServer"; then
    echo "JobHistoryServer is running."
else
    echo "WARNING: JobHistoryServer could not be detected."
fi

# ------------------------------------------------------------
# CHECK PORT 10020
# ------------------------------------------------------------

echo
echo "Checking JobHistoryServer port 10020..."

if ss -lnt 2>/dev/null | grep -q ":10020"; then
    echo "JobHistoryServer RPC port 10020 is active."
else
    echo "WARNING: Port 10020 is not currently listening."
fi

# ============================================================
# UPLOAD CSV TO HDFS
# ============================================================

echo
echo "============================================================"
echo " UPLOADING CSV TO HDFS"
echo "============================================================"

hadoop fs -mkdir -p "$HDFS_INPUT"

hadoop fs -put -f \
    "$CSV" \
    "$HDFS_INPUT/web_server_logs.csv"

echo
echo "HDFS input file:"
hadoop fs -ls -h "$HDFS_INPUT"

# ============================================================
# HIVE
# ============================================================

echo
echo "============================================================"
echo " STEP 1: HIVE ANALYSIS"
echo "============================================================"

# ------------------------------------------------------------
# CREATE HIVE QUERY FILE
# ------------------------------------------------------------

cat > "$BASE/hive/project_queries.hql" <<'HQL'

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

HQL

# ------------------------------------------------------------
# RUN ALL HIVE QUERIES
# ------------------------------------------------------------

echo
echo "Running all Hive queries..."

hive \
    --hiveconf hive.execution.engine=mr \
    -f "$BASE/hive/project_queries.hql" \
    2>&1 | tee "$BASE/output/hive_results.txt"

echo
echo "Hive analysis completed successfully."

# ============================================================
# PIG
# ============================================================

echo
echo "============================================================"
echo " STEP 2: PIG LATIN ANALYSIS"
echo "============================================================"

# ------------------------------------------------------------
# REMOVE PREVIOUS PIG OUTPUT
# ------------------------------------------------------------

echo
echo "Removing previous Pig output directories..."

for d in \
    cleaned_logs \
    pig_total_records \
    pig_status_distribution \
    pig_top_urls \
    pig_http_errors \
    pig_methods \
    pig_peak_hours \
    pig_daily_traffic \
    pig_user_agents \
    pig_response_bytes_by_url
do

    hadoop fs -rm -r -f \
        "$HDFS_OUTPUT/$d" \
        >/dev/null 2>&1 || true

done

echo "Previous Pig outputs removed."

# ============================================================
# CREATE PIG SCRIPT
# ============================================================

cat > "$BASE/pig/clean_logs.pig" <<'PIG'

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

PIG

# ============================================================
# RUN PIG WITH EXPLICIT HADOOP/YARN CONFIGURATION
# ============================================================

echo
echo "Running Pig Latin..."

HADOOP_CONF_DIR="$HADOOP_HOME/etc/hadoop" \
YARN_CONF_DIR="$HADOOP_HOME/etc/hadoop" \
PIG_CLASSPATH="$HADOOP_HOME/etc/hadoop" \
pig -x mapreduce "$BASE/pig/clean_logs.pig" \
    2>&1 | tee "$BASE/output/pig_results.txt"

echo
echo "Pig analysis completed."

# ============================================================
# DISPLAY PIG RESULTS
# ============================================================

echo
echo "============================================================"
echo " PIG RESULTS"
echo "============================================================"

for d in \
    pig_total_records \
    pig_status_distribution \
    pig_top_urls \
    pig_http_errors \
    pig_methods \
    pig_peak_hours \
    pig_daily_traffic \
    pig_user_agents \
    pig_response_bytes_by_url
do

    echo
    echo "------------------------------------------------------------"
    echo " $d"
    echo "------------------------------------------------------------"

    hadoop fs -cat \
        "$HDFS_OUTPUT/$d/part-*"

done

# ============================================================
# PROJECT SUMMARY
# ============================================================

echo
echo "============================================================"
echo " CREATING PROJECT SUMMARY"
echo "============================================================"

{
    echo "============================================================"
    echo "WEB SERVER LOG ANALYTICS AND USER BEHAVIOR MONITORING"
    echo "============================================================"
    echo
    echo "Input CSV:"
    echo "$CSV"
    echo
    echo "HDFS Input:"
    echo "$HDFS_INPUT/web_server_logs.csv"
    echo
    echo "Hive Query File:"
    echo "$BASE/hive/project_queries.hql"
    echo
    echo "Pig Script:"
    echo "$BASE/pig/clean_logs.pig"
    echo
    echo "Hive Results:"
    echo "$BASE/output/hive_results.txt"
    echo
    echo "Pig Results:"
    echo "$BASE/output/pig_results.txt"
    echo
    echo "Hadoop Configuration:"
    echo "$HADOOP_CONF_DIR"
    echo
    echo "JobHistoryServer:"
    echo "localhost:10020"
    echo
    echo "Execution Date:"
    date
    echo
    echo "PROJECT EXECUTION COMPLETED SUCCESSFULLY"
    echo "============================================================"

} | tee "$BASE/report/project_run_summary.txt"

# ============================================================
# FINAL MESSAGE
# ============================================================

echo
echo "============================================================"
echo " ALL PROJECT TASKS COMPLETED"
echo "============================================================"
echo
echo "Project directory:"
echo "$BASE"
echo
echo "Hive result:"
echo "$BASE/output/hive_results.txt"
echo
echo "Pig result:"
echo "$BASE/output/pig_results.txt"
echo
echo "Project summary:"
echo "$BASE/report/project_run_summary.txt"
echo
echo "============================================================"
echo " HADOOP + HIVE + PIG PROJECT FINISHED"
echo "============================================================"
```
