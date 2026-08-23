#!/bin/bash

# =====================================================
# Secure Student Project Submission and Authentication System
# U19965 - Advanced Operating Systems - Assessment 1
# Task 3
# =====================================================

SUBMIT_DIR="submitted_files"
LOG_FILE="submission_log.txt"
LOGIN_ATTEMPTS_FILE="login_attempts.txt"
LOCKED_ACCOUNTS_FILE="locked_accounts.txt"
MAX_SIZE_MB=5
SUSPICIOUS_WINDOW=60   # seconds

mkdir -p "$SUBMIT_DIR"
touch "$LOG_FILE" "$LOGIN_ATTEMPTS_FILE" "$LOCKED_ACCOUNTS_FILE"

log_action() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
}

# ---------------------------------------------------
# a. Submit an Assignment
# ---------------------------------------------------
submit_assignment() {
    read -p "Enter Student ID: " sid
    read -p "Enter full path of file to submit: " filepath
    filepath=$(echo "$filepath" | tr -d '\r')
    sid=$(echo "$sid" | tr -d '\r')

    if [ ! -f "$filepath" ]; then
        echo "Error: File does not exist."
        log_action "SubmitFailed - StudentID:$sid - File not found: $filepath"
        return
    fi

    filename=$(basename "$filepath")
    extension="${filename##*.}"

    # File type validation
    if [[ "$extension" != "pdf" && "$extension" != "docx" ]]; then
        echo "Error: Only .pdf and .docx files are accepted."
        log_action "SubmitRejected - StudentID:$sid - Invalid file type: $filename"
        return
    fi

    # File size validation
    filesize_bytes=$(stat -c%s "$filepath")
    max_bytes=$((MAX_SIZE_MB * 1024 * 1024))
    if [ "$filesize_bytes" -gt "$max_bytes" ]; then
        echo "Error: File exceeds ${MAX_SIZE_MB}MB limit."
        log_action "SubmitRejected - StudentID:$sid - File too large: $filename ($filesize_bytes bytes)"
        return
    fi

    # Duplicate detection (same filename + same content hash)
    file_hash=$(sha256sum "$filepath" | awk '{print $1}')
    dest_path="$SUBMIT_DIR/${sid}_${filename}"

    if [ -f "$dest_path" ]; then
        existing_hash=$(sha256sum "$dest_path" | awk '{print $1}')
        if [ "$file_hash" == "$existing_hash" ]; then
            echo "Error: Duplicate submission detected (identical filename and content)."
            log_action "SubmitRejected - StudentID:$sid - Duplicate submission: $filename"
            return
        fi
    fi

    cp "$filepath" "$dest_path"
    echo "Submission successful: $filename"
    log_action "SubmitSuccess - StudentID:$sid - File:$filename - Hash:$file_hash"
}

# ---------------------------------------------------
# b. Check if a File Has Already Been Submitted
# ---------------------------------------------------
check_submission() {
    read -p "Enter Student ID: " sid
    read -p "Enter filename to check: " filename
    sid=$(echo "$sid" | tr -d '\r')
    filename=$(echo "$filename" | tr -d '\r')

    dest_path="$SUBMIT_DIR/${sid}_${filename}"
    if [ -f "$dest_path" ]; then
        echo "Status: Already submitted by Student $sid."
    else
        echo "Status: No submission found for Student $sid with filename '$filename'."
    fi
    log_action "CheckSubmission - StudentID:$sid - File:$filename"
}

# ---------------------------------------------------
# c. List All Submitted Assignments
# ---------------------------------------------------
list_submissions() {
    echo "----- Submitted Assignments -----"
    if [ -z "$(ls -A "$SUBMIT_DIR" 2>/dev/null)" ]; then
        echo "No submissions yet."
        return
    fi
    printf "%-15s %-30s %-10s\n" "StudentID" "FileName" "Size"
    for f in "$SUBMIT_DIR"/*; do
        base=$(basename "$f")
        sid="${base%%_*}"
        fname="${base#*_}"
        size=$(du -h "$f" | cut -f1)
        printf "%-15s %-30s %-10s\n" "$sid" "$fname" "$size"
    done
}

# ---------------------------------------------------
# d. Simulate Login Attempt (with lockout + suspicious detection)
# ---------------------------------------------------
simulate_login() {
    read -p "Enter Student ID: " sid
    read -p "Enter password (any value - simulated): " pass
    read -p "Was this a correct login? (Y/N - simulated): " correct
    sid=$(echo "$sid" | tr -d '\r')
    correct=$(echo "$correct" | tr -d '\r')

    now=$(date +%s)

    # Check if account is locked
    if grep -q "^$sid$" "$LOCKED_ACCOUNTS_FILE" 2>/dev/null; then
        echo "Account LOCKED. Too many failed attempts. Contact administrator."
        log_action "LoginBlocked - StudentID:$sid - Account is locked"
        return
    fi

    # Suspicious activity: repeated attempts within 60s
    last_attempt=$(grep "^$sid|" "$LOGIN_ATTEMPTS_FILE" 2>/dev/null | tail -1 | cut -d'|' -f2)
    if [ -n "$last_attempt" ]; then
        diff=$((now - last_attempt))
        if [ "$diff" -lt "$SUSPICIOUS_WINDOW" ]; then
            echo "WARNING: Suspicious activity detected - repeated login attempt within ${SUSPICIOUS_WINDOW}s."
            log_action "SuspiciousActivity - StudentID:$sid - Repeated attempt after ${diff}s"
        fi
    fi

    echo "$sid|$now" >> "$LOGIN_ATTEMPTS_FILE"

    if [[ "$correct" == "Y" || "$correct" == "y" ]]; then
        echo "Login successful."
        log_action "LoginSuccess - StudentID:$sid"
        # Reset fail count on success
        sed -i "/^$sid|FAILCOUNT/d" "$LOGIN_ATTEMPTS_FILE" 2>/dev/null
    else
        fail_count=$(grep -c "^$sid|FAIL$" "$LOGIN_ATTEMPTS_FILE" 2>/dev/null)
        fail_count=$((fail_count + 1))
        echo "$sid|FAIL" >> "$LOGIN_ATTEMPTS_FILE"
        echo "Login failed. Attempt $fail_count of 3."
        log_action "LoginFailed - StudentID:$sid - Attempt $fail_count"

        if [ "$fail_count" -ge 3 ]; then
            echo "$sid" >> "$LOCKED_ACCOUNTS_FILE"
            echo "Account LOCKED after 3 failed attempts."
            log_action "AccountLocked - StudentID:$sid - 3 failed attempts reached"
        fi
    fi
}

# ---------------------------------------------------
# Exit
# ---------------------------------------------------
exit_system() {
    read -p "Are you sure you want to exit? [Y/N]: " confirm
    if [[ "$confirm" == "Y" || "$confirm" == "y" ]]; then
        echo "Goodbye!"
        exit 0
    fi
}

# ---------------------------------------------------
# Main Menu
# ---------------------------------------------------
while true; do
    echo ""
    echo "===== Secure Student Submission & Authentication System ====="
    echo "1. Submit an Assignment"
    echo "2. Check if a File Has Already Been Submitted"
    echo "3. List All Submitted Assignments"
    echo "4. Simulate Login Attempt"
    echo "5. Exit"
    echo "================================================================"
    read -p "Select an option [1-5]: " choice
    case $choice in
        1) submit_assignment ;;
        2) check_submission ;;
        3) list_submissions ;;
        4) simulate_login ;;
        5) exit_system ;;
        *) echo "Invalid option, please try again." ;;
    esac
done
