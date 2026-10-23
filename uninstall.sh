#!/system/bin/sh
MODDIR=${0%/*}
LOG="/data/adb/modules/network-tweaks/uninstall.log"
log() { echo "$(date): $*" >> "$LOG"; }
log "restoring network defaults"
# Try to reset congestion control to cubic/reno if available
for dev in $(ls /proc/sys/net/ipv4/tcp_available_congestion_control 2>/dev/null); do
  :
done
# Best effort reset
echo cubic > /proc/sys/net/ipv4/tcp_congestion_control 2>/dev/null || echo reno > /proc/sys/net/ipv4/tcp_congestion_control 2>/dev/null
# Restore net core
echo 1000 > /proc/sys/net/core/netdev_max_backlog 2>/dev/null
echo fq_codel > /proc/sys/net/core/default_qdisc 2>/dev/null
rm -f "$MODDIR/.reload" "$MODDIR/.worker.pid" "$MODDIR/.bootcount" 2>/dev/null
log "done"
