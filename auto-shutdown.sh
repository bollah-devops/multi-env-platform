#!/bin/bash

# ── Auto Shutdown Script ──────────────────────────────
# Stops EC2 instances if no activity detected for 1 hour
# Run this on your Mac in the background when you start working

LOG="$HOME/Documents/multi-env-platform/shutdown.log"
IDLE_THRESHOLD=3600  # 1 hour in seconds
CHECK_INTERVAL=300   # check every 5 minutes
LAST_ACTIVITY=$(date +%s)

echo "$(date '+%Y-%m-%d %H:%M:%S') - Auto shutdown monitor started" >> $LOG
echo "$(date '+%Y-%m-%d %H:%M:%S') - Will stop instances after ${IDLE_THRESHOLD}s of inactivity" >> $LOG

update_activity() {
    LAST_ACTIVITY=$(date +%s)
}

get_instances() {
    aws ec2 describe-instances \
      --filters "Name=instance-state-name,Values=running" \
                "Name=tag:Name,Values=staging-app-server,production-app-server" \
      --query 'Reservations[*].Instances[*].InstanceId' \
      --output text
}

stop_instances() {
    INSTANCE_IDS=$(get_instances)
    if [ ! -z "$INSTANCE_IDS" ]; then
        echo "$(date '+%Y-%m-%d %H:%M:%S') - IDLE DETECTED - Stopping instances: $INSTANCE_IDS" >> $LOG
        aws ec2 stop-instances --instance-ids $INSTANCE_IDS
        echo "$(date '+%Y-%m-%d %H:%M:%S') - Instances stopped successfully" >> $LOG
    else
        echo "$(date '+%Y-%m-%d %H:%M:%S') - No running instances found" >> $LOG
    fi
}

# Monitor for activity
while true; do
    NOW=$(date +%s)
    IDLE_TIME=$((NOW - LAST_ACTIVITY))

    # Check if any Ansible or SSH activity is happening
    if pgrep -x "ansible" > /dev/null || \
       pgrep -x "ssh" > /dev/null || \
       pgrep -x "terraform" > /dev/null; then
        update_activity
        echo "$(date '+%Y-%m-%d %H:%M:%S') - Activity detected - resetting timer" >> $LOG
    fi

    # Check idle time
    if [ $IDLE_TIME -ge $IDLE_THRESHOLD ]; then
        echo "$(date '+%Y-%m-%d %H:%M:%S') - No activity for ${IDLE_TIME}s - shutting down" >> $LOG
        stop_instances
        echo "$(date '+%Y-%m-%d %H:%M:%S') - Monitor exiting" >> $LOG
        exit 0
    fi

    REMAINING=$((IDLE_THRESHOLD - IDLE_TIME))
    echo "$(date '+%Y-%m-%d %H:%M:%S') - Idle: ${IDLE_TIME}s / Remaining: ${REMAINING}s" >> $LOG

    sleep $CHECK_INTERVAL
done

