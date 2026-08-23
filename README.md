# U19965 — Advanced Operating Systems — Assessment 1

**B.Eng (Hons) Software Engineering — Cohort 5, Trimester 1**

This repository contains the implementation for Assessment 1, consisting of three Bash-scripting tasks that apply operating system management techniques and automation tools in real-world scenarios, along with an accompanying 800-word report.

---

## Project Structure

U19965-AOS-Assignment1/
├── task1-iot-management/
│ ├── iot_manager.sh
│ ├── system_monitor_log.txt
│ └── ArchiveLogs/
├── task2-job-scheduler/
│ ├── job_scheduler.sh
│ ├── job_queue.txt
│ ├── completed_jobs.txt
│ └── scheduler_log.txt
├── task3-submission-auth/
│ ├── submission_auth.sh
│ ├── submission_log.txt
│ ├── login_attempts.txt
│ ├── locked_accounts.txt
│ └── submitted_files/
├── report/
│ └── (800-word report + screenshots)
└── README.md


---

## Task 1 — Smart Campus IoT Device Management (Bash)

Simulates an intelligent system administration tool for managing IoT sensor gateways via a menu-driven interface.

**Features:**
- Display current CPU and memory usage
- List top 10 memory-consuming processes (PID, user, CPU%, memory%)
- Terminate a selected process with confirmation
- Protection against termination of critical system processes
- Inspect disk usage of a specified log directory
- Detect log files larger than 50MB and archive them into `ArchiveLogs/` with timestamped filenames
- Warning displayed if `ArchiveLogs/` exceeds 1GB
- All administrative actions logged with timestamps to `system_monitor_log.txt`
- Exit mechanism with Y/N confirmation

**How to run:**
```bash
cd task1-iot-management
chmod +x iot_manager.sh
./iot_manager.sh
```

---

## Task 2 — University Research Cluster Job Scheduler (Bash)

Manages computational job requests submitted by researchers/students and processes them using either Round Robin or Priority Scheduling.

**Features:**
- Menu: view pending jobs, submit job request, process queue, view completed jobs, exit
- Each job includes Student ID, Job Name, estimated execution time, and priority (1 = highest, 10 = lowest)
- Round Robin scheduling using a 5-second time quantum
- Priority scheduling — highest priority job executes first
- All job submissions and executions logged to `scheduler_log.txt`
- Pending jobs stored in `job_queue.txt`; completed jobs stored in `completed_jobs.txt`

**How to run:**
```bash
cd task2-job-scheduler
chmod +x job_scheduler.sh
./job_scheduler.sh
```

---

## Task 3 — Secure Student Project Submission and Authentication System (Bash)

Validates student project submissions and monitors login attempts to detect suspicious activity.

**Features:**
- Menu: submit assignment, check submission status, list all submissions, simulate login, exit
- Accepts only `.pdf` and `.docx` files; rejects files over 5MB
- Duplicate submission detection based on identical filename and file content (SHA-256 hash)
- Account lockout after 3 consecutive failed login attempts
- Suspicious activity detection for repeated login attempts within 60 seconds
- All submissions and login attempts logged with timestamps to `submission_log.txt`

**How to run:**
```bash
cd task3-submission-auth
chmod +x submission_auth.sh
./submission_auth.sh
```

---

## Report

An 800-word report (in `report/`) covers design choices, connection to advanced OS concepts, references, challenges encountered, and execution steps with screenshots.

---

## Author

Nishan Jayawickrama — B.Eng (Hons) Software Engineering, Cohort 5
EOF



