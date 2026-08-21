#!/bin/bash

# =====================================================
# University Research Cluster Job Scheduler
# U19965 - Advanced Operating Systems - Assessment 1
# Task 2
# =====================================================

QUEUE_FILE="job_queue.txt"
COMPLETED_FILE="completed_jobs.txt"
LOG_FILE="scheduler_log.txt"
TIME_QUANTUM=5

touch "$QUEUE_FILE" "$COMPLETED_FILE" "$LOG_FILE"

log_action() {
    local student_id="$1"
    local job_name="$2"
    local sched_type="$3"
    local event="$4"
    echo "$(date '+%Y-%m-%d %H:%M:%S') - StudentID:$student_id - Job:$job_name - Type:$sched_type - $event" >> "$LOG_FILE"
}

# ---------------------------------------------------
# View Pending Jobs
# ---------------------------------------------------
view_pending_jobs() {
    echo "----- Pending Jobs -----"
    if [ ! -s "$QUEUE_FILE" ]; then
        echo "No pending jobs."
        return
    fi
    printf "%-12s %-20s %-10s %-8s\n" "StudentID" "JobName" "ExecTime" "Priority"
    while IFS='|' read -r sid jname etime prio; do
        printf "%-12s %-20s %-10s %-8s\n" "$sid" "$jname" "${etime}s" "$prio"
    done < "$QUEUE_FILE"
}

# ---------------------------------------------------
# Submit a Job Request
# ---------------------------------------------------
submit_job() {
    read -p "Enter Student ID: " sid
    read -p "Enter Job Name: " jname
    read -p "Enter Estimated Execution Time (seconds): " etime
    read -p "Enter Priority (1=highest, 10=lowest): " prio

    sid=$(echo "$sid" | tr -d '\r')
    jname=$(echo "$jname" | tr -d '\r')
    etime=$(echo "$etime" | tr -d '\r')
    prio=$(echo "$prio" | tr -d '\r')

    if ! [[ "$etime" =~ ^[0-9]+$ ]]; then
        echo "Error: Execution time must be a positive number."
        return
    fi

    if ! [[ "$prio" =~ ^([1-9]|10)$ ]]; then
        echo "Error: Priority must be between 1 and 10."
        return
    fi

    echo "${sid}|${jname}|${etime}|${prio}" >> "$QUEUE_FILE"
    echo "Job submitted successfully."
    log_action "$sid" "$jname" "N/A" "Job submitted (ExecTime:${etime}s, Priority:$prio)"
}

# ---------------------------------------------------
# Round Robin Scheduling (5s quantum)
# ---------------------------------------------------
process_round_robin() {
    echo "----- Processing Queue: Round Robin (Quantum = ${TIME_QUANTUM}s) -----"

    declare -a sids jnames etimes prios remaining
    while IFS='|' read -r sid jname etime prio; do
        sids+=("$sid"); jnames+=("$jname"); etimes+=("$etime"); prios+=("$prio")
        remaining+=("$etime")
    done < "$QUEUE_FILE"

    n=${#sids[@]}
    round=1

    while true; do
        all_done=true
        for ((i=0; i<n; i++)); do
            if [ "${remaining[i]}" -gt 0 ]; then
                all_done=false
                if [ "${remaining[i]}" -le "$TIME_QUANTUM" ]; then
                    run_time=${remaining[i]}
                    remaining[i]=0
                    echo "Round $round: Job '${jnames[i]}' (Student ${sids[i]}) ran ${run_time}s -> COMPLETED"
                    echo "${sids[i]}|${jnames[i]}|${etimes[i]}|${prios[i]}|$(date '+%Y-%m-%d %H:%M:%S')" >> "$COMPLETED_FILE"
                    log_action "${sids[i]}" "${jnames[i]}" "Round Robin" "Job completed"
                else
                    remaining[i]=$((remaining[i] - TIME_QUANTUM))
                    echo "Round $round: Job '${jnames[i]}' (Student ${sids[i]}) ran ${TIME_QUANTUM}s -> remaining ${remaining[i]}s"
                    log_action "${sids[i]}" "${jnames[i]}" "Round Robin" "Executed ${TIME_QUANTUM}s, remaining ${remaining[i]}s"
                fi
            fi
        done
        round=$((round + 1))
        $all_done && break
    done

    > "$QUEUE_FILE"
    echo "All jobs processed via Round Robin."
}

# ---------------------------------------------------
# Priority Scheduling (1 = highest)
# ---------------------------------------------------
process_priority() {
    echo "----- Processing Queue: Priority Scheduling -----"

    sort -t'|' -k4 -n "$QUEUE_FILE" -o /tmp/sorted_queue_$$.txt

    while IFS='|' read -r sid jname etime prio; do
        echo "Executing Job '${jname}' (Student ${sid}, Priority ${prio}) for ${etime}s -> COMPLETED"
        echo "${sid}|${jname}|${etime}|${prio}|$(date '+%Y-%m-%d %H:%M:%S')" >> "$COMPLETED_FILE"
        log_action "$sid" "$jname" "Priority" "Job completed"
    done < /tmp/sorted_queue_$$.txt

    rm -f /tmp/sorted_queue_$$.txt
    > "$QUEUE_FILE"
    echo "All jobs processed via Priority Scheduling."
}

# ---------------------------------------------------
# Process Job Queue (choose algorithm)
# ---------------------------------------------------
process_queue() {
    if [ ! -s "$QUEUE_FILE" ]; then
        echo "No pending jobs to process."
        return
    fi
    echo "Select scheduling algorithm:"
    echo "1. Round Robin (5s time quantum)"
    echo "2. Priority Scheduling (highest priority first)"
    read -p "Enter choice [1-2]: " algo
    case $algo in
        1) process_round_robin ;;
        2) process_priority ;;
        *) echo "Invalid choice." ;;
    esac
}

# ---------------------------------------------------
# View Completed Jobs
# ---------------------------------------------------
view_completed_jobs() {
    echo "----- Completed Jobs -----"
    if [ ! -s "$COMPLETED_FILE" ]; then
        echo "No completed jobs yet."
        return
    fi
    printf "%-12s %-20s %-10s %-8s %-20s\n" "StudentID" "JobName" "ExecTime" "Priority" "CompletedAt"
    while IFS='|' read -r sid jname etime prio ctime; do
        printf "%-12s %-20s %-10s %-8s %-20s\n" "$sid" "$jname" "${etime}s" "$prio" "$ctime"
    done < "$COMPLETED_FILE"
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
    echo "===== Research Cluster Job Scheduler ====="
    echo "1. View Pending Jobs"
    echo "2. Submit a Job Request"
    echo "3. Process Job Queue (Round Robin / Priority)"
    echo "4. View Completed Jobs"
    echo "5. Exit"
    echo "============================================"
    read -p "Select an option [1-5]: " choice
    case $choice in
        1) view_pending_jobs ;;
        2) submit_job ;;
        3) process_queue ;;
        4) view_completed_jobs ;;
        5) exit_system ;;
        *) echo "Invalid option, please try again." ;;
    esac
done

