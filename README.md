# 🌐 Web Server Log Analytics

A **Big Data Analytics and Data Engineering project** for analyzing web server logs using **Apache Hadoop, Hive, and Apache Pig**.

The project processes web server access-log data and extracts useful insights such as HTTP request patterns, response-status distribution, URL usage, traffic behavior, and user-agent information.

---

## 📌 Project Overview

Web servers continuously generate large amounts of log data containing information about client requests, URLs, HTTP methods, response codes, response sizes, timestamps, and user agents.

Analyzing these logs manually is difficult when the data becomes large.

This project demonstrates how **Big Data technologies** can be used to store, clean, process, and analyze web server logs.

### Project Pipeline

```text
                    Web Server Logs
                           │
                           ▼
                  web_server_logs.csv
                           │
                           ▼
                    Apache Hadoop
                           │
              ┌────────────┴────────────┐
              ▼                         ▼
            Hive                       Pig
              │                         │
              ▼                         ▼
       Structured Queries         Data Cleaning
              │                         │
              └────────────┬────────────┘
                           ▼
                    Analytics Results
                           │
                           ▼
              Web Server Insights
```

---

## 🎯 Objectives

The main objectives of this project are:

- Analyze web server log data using Big Data technologies.
- Store and process large log datasets using Hadoop.
- Clean and transform log data using Apache Pig.
- Perform structured analytics using Apache Hive.
- Analyze HTTP methods and status codes.
- Identify frequently accessed URLs.
- Analyze response sizes and traffic patterns.
- Study user-agent information.
- Demonstrate practical Data Engineering and Big Data concepts.
- Generate reusable analysis results for further investigation.

---

## 🛠️ Technologies Used

| Technology | Purpose |
|---|---|
| 🐘 Apache Hadoop | Distributed storage and processing |
| 🐝 Apache Hive | SQL-based Big Data analytics |
| 🐷 Apache Pig | Data cleaning and transformation |
| ☕ Java | Hadoop ecosystem support |
| 🐧 Ubuntu Linux | Development environment |
| 📄 CSV | Input dataset format |
| 🖥️ HDFS | Distributed file storage |
| 🐚 Bash | Project automation |

---

## 📂 Repository Structure

```text
web_server_log_analytics/
│
├── web_server_logs.csv
│
├── clean_logs.pig
│
├── project_queries.hql
│
├── webproject.sh
│
├── hive_results.txt
│
├── pig_results.txt
│
└── project_run_summary.txt
```

### File Description

#### `web_server_logs.csv`

Contains the web server log dataset used for analysis.

The dataset contains fields such as:

```text
ip_address
timestamp
method
url
protocol
status_code
response_size
user_agent
```

Example:

```text
192.168.1.67,2026-09-01 00:01:06,GET,/login,HTTP/1.1,301,1196,Chrome-Android
```

---

### `clean_logs.pig`

Apache Pig script used for loading, cleaning, transforming, and analyzing the web server log data.

---

### `project_queries.hql`

Contains the Hive queries used for performing analytical operations on the web server log dataset.

---

### `webproject.sh`

Main shell script for automating the project workflow.

It can be used to execute the required Hadoop/Hive/Pig operations in sequence.

---

### `hive_results.txt`

Contains the output generated from the Hive analysis.

---

### `pig_results.txt`

Contains the output generated from the Pig analysis.

---

### `project_run_summary.txt`

Contains a summary of the project execution and generated results.

---

# 📊 Dataset

The project uses a CSV-based web server log dataset.

### Schema

| Column | Data Type | Description |
|---|---|---|
| `ip_address` | STRING | Client IP address |
| `timestamp` | STRING | Date and time of request |
| `method` | STRING | HTTP request method |
| `url` | STRING | Requested URL |
| `protocol` | STRING | HTTP protocol version |
| `status_code` | INT | HTTP response status code |
| `response_size` | BIGINT | Response size in bytes |
| `user_agent` | STRING | Client/browser information |

---

# 🔍 Analysis Performed

## 1. HTTP Method Analysis

The project analyzes HTTP request methods such as:

```text
GET
POST
PUT
DELETE
```

This helps identify the type of interaction between clients and the web server.

---

## 2. HTTP Status Code Analysis

HTTP response codes are analyzed to understand server responses.

Examples:

| Status Code | Meaning |
|---|---|
| 200 | Successful request |
| 301 | Permanent redirect |
| 302 | Temporary redirect |
| 400 | Bad request |
| 401 | Unauthorized |
| 403 | Forbidden |
| 404 | Not found |
| 500 | Internal server error |

The analysis can help identify successful requests, client-side errors, redirects, and server-side problems.

---

## 3. URL Analysis

The project identifies frequently requested URLs.

Example:

```text
/login
/cart
/home
/products
```

This can help determine which resources receive the highest amount of traffic.

---

## 4. IP Address Analysis

Client IP addresses are analyzed to identify:

- Unique users/clients
- Frequently active IP addresses
- Request distribution
- Potentially unusual traffic patterns

---

## 5. User-Agent Analysis

The `user_agent` field is analyzed to understand the clients generating requests.

Examples include:

```text
Chrome
Firefox
Android
Windows
```

This provides information about browser and operating-system usage.

---

## 6. Response Size Analysis

The project also analyzes response sizes to understand the amount of data transferred by the server.

This can be useful for:

- Traffic analysis
- Bandwidth analysis
- Identifying unusually large responses
- Understanding resource usage

---

# 🐘 Hadoop

Apache Hadoop provides the Big Data infrastructure used by the project.

The general workflow is:

```text
Local CSV
   │
   ▼
HDFS
   │
   ▼
Hive / Pig
   │
   ▼
MapReduce Processing
   │
   ▼
Analytics Results
```

---

# 🐝 Hive Analysis

Hive provides a SQL-like interface for analyzing the log data.

Typical operations include:

```sql
SELECT COUNT(*)
FROM web_logs;
```

Finding HTTP methods:

```sql
SELECT method, COUNT(*)
FROM web_logs
GROUP BY method;
```

Analyzing status codes:

```sql
SELECT status_code, COUNT(*)
FROM web_logs
GROUP BY status_code;
```

Finding frequently accessed URLs:

```sql
SELECT url, COUNT(*)
FROM web_logs
GROUP BY url
ORDER BY COUNT(*) DESC;
```

Analyzing user agents:

```sql
SELECT user_agent, COUNT(*)
FROM web_logs
GROUP BY user_agent
ORDER BY COUNT(*) DESC;
```

---

# 🐷 Pig Analysis

Apache Pig is used for data processing and transformation.

The Pig workflow includes:

```text
LOAD
  ↓
FILTER
  ↓
FOREACH
  ↓
GROUP
  ↓
ORDER
  ↓
STORE
```

The project uses Pig to clean and process the web server log dataset before generating analytical results.

---

# ⚙️ Installation Requirements

The project is designed for a Linux environment such as Ubuntu.

Required software:

- Ubuntu Linux
- Java JDK
- Apache Hadoop
- Apache Hive
- Apache Pig

Verify the installations:

```bash
java -version
```

```bash
hadoop version
```

```bash
hive --version
```

```bash
pig -version
```

---

# 🚀 How to Run the Project

## Step 1 — Clone the Repository

```bash
git clone https://github.com/RamaKrishna-27/web_server_log_analytics.git
```

Move into the project:

```bash
cd web_server_log_analytics
```

---

## Step 2 — Start Hadoop

Start HDFS:

```bash
start-dfs.sh
```

Start YARN:

```bash
start-yarn.sh
```

Verify Hadoop services:

```bash
jps
```

You should see services such as:

```text
NameNode
DataNode
ResourceManager
NodeManager
```

---

## Step 3 — Create HDFS Directory

```bash
hdfs dfs -mkdir -p /web_log_project/input
```

---

## Step 4 — Upload Dataset

```bash
hdfs dfs -put -f web_server_logs.csv /web_log_project/input/
```

Verify:

```bash
hdfs dfs -ls /web_log_project/input
```

---

# 🐝 Run Hive Analysis

Execute the Hive queries:

```bash
hive -f project_queries.hql
```

The results can be redirected to a file:

```bash
hive -f project_queries.hql > hive_results.txt
```

---

# 🐷 Run Pig Analysis

Execute the Pig script:

```bash
pig clean_logs.pig
```

For local execution:

```bash
pig -x local clean_logs.pig
```

---

# ▶️ Run the Complete Project

The repository includes:

```text
webproject.sh
```

Make the script executable:

```bash
chmod +x webproject.sh
```

Run:

```bash
./webproject.sh
```

This script is intended to automate the project execution workflow.

---

# 📈 Expected Results

After successful execution, the project produces analytical information such as:

```text
Total number of web requests
Unique IP addresses
HTTP method distribution
HTTP status code distribution
Most requested URLs
Most active IP addresses
User-agent distribution
Response-size information
```

These results can be used to understand web-server traffic and identify unusual request behavior.

---

# 🔐 Cybersecurity Relevance

Web server logs are an important source of information for cybersecurity monitoring.

Log analysis can help security teams investigate:

- Repeated failed requests
- Suspicious IP addresses
- Large numbers of requests
- Unusual HTTP methods
- Repeated access to sensitive URLs
- High numbers of 404 responses
- Abnormal user-agent activity
- Potential scanning activity

Therefore, this project demonstrates concepts relevant to:

```text
Big Data
     +
Data Engineering
     +
Web Analytics
     +
Cybersecurity
     +
Log Monitoring
```

---

# 📚 Learning Outcomes

After completing this project, the following skills are demonstrated:

- Understanding of Hadoop ecosystem components.
- Working with HDFS.
- Processing CSV datasets.
- Writing Hive queries.
- Creating analytical queries using Hive.
- Data cleaning using Apache Pig.
- Working with MapReduce-based processing.
- Linux command-line usage.
- Shell-script automation.
- Web server log analysis.
- Basic cybersecurity log analysis.
- Big Data workflow implementation.

---

# 🔄 Project Workflow

```text
             ┌───────────────────┐
             │ Web Server Logs   │
             └─────────┬─────────┘
                       │
                       ▼
             ┌───────────────────┐
             │      HDFS         │
             └─────────┬─────────┘
                       │
              ┌────────┴────────┐
              │                 │
              ▼                 ▼
       ┌────────────┐    ┌────────────┐
       │    Hive    │    │    Pig     │
       └──────┬─────┘    └──────┬─────┘
              │                 │
              └────────┬────────┘
                       ▼
             ┌───────────────────┐
             │ Data Processing   │
             └─────────┬─────────┘
                       │
                       ▼
             ┌───────────────────┐
             │ Analytics Results │
             └─────────┬─────────┘
                       │
                       ▼
             ┌───────────────────┐
             │ Web Server        │
             │ Insights          │
             └───────────────────┘
```

---

# 💡 Applications

This type of web server log analytics can be used for:

- Website traffic monitoring
- Server performance analysis
- Security monitoring
- SOC operations
- Incident investigation
- User behavior analysis
- Capacity planning
- Website optimization
- Data Engineering pipelines

---

# 🎓 Academic Project

**Project Title:**  
### Web Server Log Analytics Using Hadoop, Hive and Pig

**Project Type:**  
Big Data / Data Engineering Project

**Domain:**  
Data Engineering & Cybersecurity

**Technologies:**  
Hadoop • HDFS • Hive • Pig • MapReduce • Linux

---

# 👨‍💻 Author

**Puvvala Satya Sai Rama Krishna**

B.Tech – Computer Science Engineering  
IoT & Cybersecurity including Blockchain Technology

GitHub:

[RamaKrishna-27](https://github.com/RamaKrishna-27?utm_source=chatgpt.com)

---

# 📜 License

This project is intended for **educational and academic purposes**.

You are free to study, modify, and extend the project for learning and research.

---

## ⭐ Project Highlights

```text
✓ Hadoop-based Big Data processing
✓ HDFS data storage
✓ Hive SQL analytics
✓ Apache Pig data processing
✓ Web server log analysis
✓ HTTP request analysis
✓ Status-code analysis
✓ IP and URL analysis
✓ User-agent analysis
✓ Shell-script automation
✓ Cybersecurity-oriented log analysis
```

---

## 🚀 Future Enhancements

Possible future improvements include:

- Add Apache Spark processing.
- Create a real-time log-processing pipeline.
- Add Kafka for streaming log data.
- Build a web-based analytics dashboard.
- Add graphical visualizations.
- Implement anomaly detection.
- Add automated security alerts.
- Integrate Elasticsearch and Kibana.
- Deploy the pipeline on a cloud platform.
- Add machine-learning-based threat detection.

---

**If you find this project useful, consider giving the repository a ⭐ on GitHub.**
