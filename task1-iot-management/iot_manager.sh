#!/bin/bash

# =====================================================
# Smart Campus IoT Device Management System
# U19965 - Advanced Operating Systems - Assessment 1
# Task 1
# =====================================================

LOG_FILE="system_monitor_log.txt"
ARCHIVE_DIR="ArchiveLogs"

# Critical processes that must never be killed
CRITICAL_PROCESSES=("systemd" "init" "sshd" "bash" "kernel")

log_action() {
    local message="$1"
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $message" >> "$LOG_FILE"
}

# ---------------------------------------------------
# a. Process Monitoring and Management
# ---------------------------------------------------
show_cpu_mem_usage() {
    echo "----- CPU and Memory Usage -----"
    top -bn1 | head -5
    echo ""
    log_action "Viewed CPU and memory usage"
}

list_top_processes() {
    echo "----- Top 10 Memory Consuming Processes -----"
    printf "%-8s %-12s %-6s %-6s %s\n" "PID" "USER" "CPU%" "MEM%" "COMMAND"
    ps -eo pid,user,%cpu,%mem,comm --sort=-%mem | head -11 | tail -10
    log_action "Listed top 10 memory consuming processes"
}

terminate_process() {
    read -p "Enter PID to terminate: " pid

    if ! ps -p "$pid" > /dev/null 2>&1; then
        echo "Error: No such process with PID $pid"
        log_action "Failed termination attempt - invalid PID $pid"
        return
    fi

    proc_name=$(ps -p "$pid" -o comm=)

    for critical in "${CRITICAL_PROCESSES[@]}"; do
        if [[ "$proc_name" == "$critical" ]]; then
            echo "Error: Cannot terminate critical system process '$proc_name'"
            log_action "Blocked attempt to terminate critical process $proc_name (PID $pid)"
            return
        fi
    done

    read -p "Are you sure you want to terminate PID $pid ($proc_name)? [Y/N]: " confirm
    if [[ "$confirm" == "Y" || "$confirm" == "y" ]]; then
        kill -9 "$pid" 2>/dev/null
        if [ $? -eq 0 ]; then
            echo "Process $pid ($proc_name) terminated."
            log_action "Terminated process $proc_name (PID $pid)"
        else
            echo "Failed to terminate process $pid."
            log_action "Failed to terminate process $proc_name (PID $pid)"
        fi
    else
        echo "Termination cancelled."
        log_action "User cancelled termination of PID $pid"
    fi
}

# ---------------------------------------------------
# b. Log File Management and Archival
# ---------------------------------------------------
inspect_disk_usage() {
    read -p "Enter directory path to inspect: " dir
    dir=$(echo "$dir" | tr -d '\r')
    if [ -d "$dir" ]; then
        du -sh "$dir"
        echo ""
        du -ah "$dir" | sort -rh | head -10
        log_action "Inspected disk usage for $dir"
    else
        echo "Error: Directory does not exist."
    fi
}

archive_large_logs() {
    read -p "Enter directory path containing sensor logs: " dir
    dir=$(echo "$dir" | tr -d '\r')

    if [ ! -d "$dir" ]; then
        echo "Error: Directory does not exist."
        return
    fi

    mkdir -p "$ARCHIVE_DIR"

    large_files=$(find "$dir" -type f -name "*.log" -size +50M)

    if [ -z "$large_files" ]; then
        echo "No log files larger than 50MB found."
        log_action "Checked $dir - no large log files found"
        return
    fi

    for file in $large_files; do
        filename=$(basename "$file")
        timestamp=$(date '+%Y%m%d_%H%M%S')
        archive_name="${filename%.log}_${timestamp}.tar.gz"
        tar -czf "$ARCHIVE_DIR/$archive_name" -C "$(dirname "$file")" "$filename"
        echo "Archived: $filename -> $ARCHIVE_DIR/$archive_name"
        log_action "Archived large log file $filename as $archive_name"
    done

    archive_size_bytes=$(du -sb "$ARCHIVE_DIR" | cut -f1)
    archive_size_gb=$((archive_size_bytes / 1073741824))

    if [ "$archive_size_gb" -ge 1 ]; then
        echo "WARNING: ArchiveLogs directory has exceeded 1GB!"
        log_action "WARNING: ArchiveLogs exceeded 1GB threshold"
    fi
}

# ---------------------------------------------------
# d. Exit Mechanism
# ---------------------------------------------------
exit_system() {
    read -p "Are you sure you want to exit? [Y/N]: " confirm
    if [[ "$confirm" == "Y" || "$confirm" == "y" ]]; then
        echo "Goodbye!"
        log_action "System exited by user"
        exit 0
    fi
}

# ---------------------------------------------------
# Main Menu
# ---------------------------------------------------
touch "$LOG_FILE"

while true; do
    echo ""
    echo "===== Smart Campus IoT Device Management ====="
    echo "1. Show CPU and Memory Usage"
    echo "2. List Top 10 Memory Consuming Processes"
    echo "3. Terminate a Process"
    echo "4. Inspect Disk Usage of Log Directory"
    echo "5. Archive Large Log Files (>50MB)"
    echo "6. Bye (Exit)"
    echo "================================================"
    read -p "Select an option [1-6]: " choice

    case $choice in
        1) show_cpu_mem_usage ;;
        2) list_top_processes ;;
        3) terminate_process ;;
        4) inspect_disk_usage ;;
        5) archive_large_logs ;;
        6) exit_system ;;
        *) echo "Invalid option, please try again." ;;
    esac
done
