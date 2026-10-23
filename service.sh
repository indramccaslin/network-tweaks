#!/system/bin/sh
########################################
# Network Tweaks (service.sh) v1.0.0
########################################
MODDIR=${MODDIR:-$(dirname "$0")}
CONF="$MODDIR/tweak.conf"
LOG="$MODDIR/tweak.log"
RELOAD="$MODDIR/.reload"
GAMELIST="$MODDIR/gamelist.txt"

log() { echo "[network-tweaks] $(date '+%H:%M:%S') $*" >> "$LOG"; }

read_opt() {
	local v; v=$(sed -n "s/^$1=//p" "$CONF" 2>/dev/null | head -n1 | tr -d ' \r'); [ -n "$v" ] && echo "$v" || echo "$2"
}
read_raw() {
	local v; v=$(sed -n "s/^$1=//p" "$CONF" 2>/dev/null | head -n1 | tr -d '\r'); [ -n "$v" ] && echo "$v" || echo "$2"
}

wr() { [ -w "$1" ] && { echo "$2" > "$1" 2>/dev/null; return 0; }; return 1; }

PIDFILE="$MODDIR/.worker.pid"
BOOTCOUNT="$MODDIR/.bootcount"
if [ "$1" != "--worker" ]; then
	c=$(cat "$BOOTCOUNT" 2>/dev/null); case "$c" in ''|*[!0-9]*) c=0 ;; esac; c=$((c+1)); echo "$c" > "$BOOTCOUNT" 2>/dev/null
	if [ "$c" -gt 3 ]; then log "FAILSAFE: disable"; touch "$MODDIR/disable" 2>/dev/null; rm -f "$BOOTCOUNT"; exit 0; fi
	if [ -f "$PIDFILE" ] && kill -0 "$(cat "$PIDFILE" 2>/dev/null)" 2>/dev/null; then exit 0; fi
	: > "$LOG"; log "invoked v1.0.0 boot#$c"
	setsid "$0" --worker </dev/null >>"$LOG" 2>&1 & echo $! > "$PIDFILE"; log "worker pid $!"; exit 0
fi

while [ -z "$(getprop sys.boot_completed)" ]; do sleep 5; done
sleep 10
log "started v1.0.0"

fg_pkg() {
	dumpsys window 2>/dev/null | sed -n 's/.*mCurrentFocus=[^ ]* u[0-9]* \([a-zA-Z0-9_.]*\)\/.*/\1/p' | head -n1
}
in_gamelist() {
	[ -n "$1" ] || return 1
	grep -qxF "$1" "$GAMELIST" 2>/dev/null && return 0
	return 1
}

load_config() {
	MODE=$(read_opt MODE global); case "$MODE" in global|gaming|streaming|download) ;; *) MODE=global ;; esac
	NET_TCP=$(read_opt NET_TCP true); NET_CORE=$(read_opt NET_CORE true); NET_QOS=$(read_opt NET_QOS true); NET_DNS=$(read_opt NET_DNS true); NET_ADV=$(read_opt NET_ADV true)
	GP_DYN=$(read_opt GP_DYNAMIC true); GP_POLL=$(read_opt GP_POLL 2); case "$GP_POLL" in ''|*[!0-9]*) GP_POLL=2 ;; esac
	
	# base
	TCP_CONG_ALGO=$(read_opt TCP_CONG_ALGO bbr); TCP_LOW_LATENCY=$(read_opt TCP_LOW_LATENCY 1); TCP_FASTOPEN=$(read_opt TCP_FASTOPEN 3)
	TCP_AUTOCORKING=$(read_opt TCP_AUTOCORKING 0); TCP_SLOW_START_AFTER_IDLE=$(read_opt TCP_SLOW_START_AFTER_IDLE 0); TCP_NO_METRICS_SAVE=$(read_opt TCP_NO_METRICS_SAVE 1)
	TCP_TW_REUSE=$(read_opt TCP_TW_REUSE 1); TCP_TW_RECYCLE=$(read_opt TCP_TW_RECYCLE 0)
	TCP_FIN_TIMEOUT=$(read_opt TCP_FIN_TIMEOUT 15); TCP_KEEPALIVE_TIME=$(read_opt TCP_KEEPALIVE_TIME 7200); TCP_KEEPALIVE_PROBES=$(read_opt TCP_KEEPALIVE_PROBES 9); TCP_KEEPALIVE_INTVL=$(read_opt TCP_KEEPALIVE_INTVL 75)
	TCP_SYNACK_RETRIES=$(read_opt TCP_SYNACK_RETRIES 2); TCP_SYN_RETRIES=$(read_opt TCP_SYN_RETRIES 2)
	NET_RMEM_MAX=$(read_opt NET_RMEM_MAX 33554432); NET_WMEM_MAX=$(read_opt NET_WMEM_MAX 33554432); NET_RMEM_DEFAULT=$(read_opt NET_RMEM_DEFAULT 262144); NET_WMEM_DEFAULT=$(read_opt NET_WMEM_DEFAULT 262144)
	TCP_RMEM=$(read_raw TCP_RMEM "4096 87380 33554432"); TCP_WMEM=$(read_raw TCP_WMEM "4096 65536 33554432")
	NET_SOMAXCONN=$(read_opt NET_SOMAXCONN 4096); NET_TCP_MAX_SYN_BACKLOG=$(read_opt NET_TCP_MAX_SYN_BACKLOG 4096)
	NET_CORE_NETDEV_MAX_BACKLOG=$(read_opt NET_CORE_NETDEV_MAX_BACKLOG 10000)
	NET_CORE_DEFAULT_QDISC=$(read_opt NET_CORE_DEFAULT_QDISC fq)
	NET_IPV4_IP_NO_PMTU_DISC=$(read_opt NET_IPV4_IP_NO_PMTU_DISC 0)
	NET_CORE_BUSY_POLL=$(read_opt NET_CORE_BUSY_POLL 50); NET_CORE_BUSY_READ=$(read_opt NET_CORE_BUSY_READ 50)
	NET_GAME_BOOST=$(read_opt NET_GAME_BOOST true); NET_NOTSENT_LOWAT=$(read_opt NET_NOTSENT_LOWAT 16384)
	MTU=$(read_opt MTU 0); DNS1=$(read_opt DNS1 1.1.1.1); DNS2=$(read_opt DNS2 8.8.8.8); DNS_AUTO=$(read_opt DNS_AUTO false)
	
	# game
	GAME_TCP_CONG_ALGO=$(read_opt GAME_TCP_CONG_ALGO bbr); GAME_NET_RMEM_MAX=$(read_opt GAME_NET_RMEM_MAX 33554432); GAME_NET_WMEM_MAX=$(read_opt GAME_NET_WMEM_MAX 33554432)
	GAME_TCP_RMEM=$(read_raw GAME_TCP_RMEM "4096 87380 33554432"); GAME_TCP_WMEM=$(read_raw GAME_TCP_WMEM "4096 65536 33554432")
	GAME_NET_SOMAXCONN=$(read_opt GAME_NET_SOMAXCONN 4096); GAME_NET_TCP_MAX_SYN_BACKLOG=$(read_opt GAME_NET_TCP_MAX_SYN_BACKLOG 4096)
	GAME_NET_CORE_NETDEV_MAX_BACKLOG=$(read_opt GAME_NET_CORE_NETDEV_MAX_BACKLOG 10000); GAME_NET_CORE_DEFAULT_QDISC=$(read_opt GAME_NET_CORE_DEFAULT_QDISC fq)
	GAME_TCP_AUTOCORKING=$(read_opt GAME_TCP_AUTOCORKING 0); GAME_TCP_SLOW_START_AFTER_IDLE=$(read_opt GAME_TCP_SLOW_START_AFTER_IDLE 0); GAME_TCP_NO_METRICS_SAVE=$(read_opt GAME_TCP_NO_METRICS_SAVE 1); GAME_TCP_FASTOPEN=$(read_opt GAME_TCP_FASTOPEN 3)
	GAME_NET_NOTSENT_LOWAT=$(read_opt GAME_NET_NOTSENT_LOWAT 16384); GAME_NET_CORE_BUSY_POLL=$(read_opt GAME_NET_CORE_BUSY_POLL 50); GAME_NET_CORE_BUSY_READ=$(read_opt GAME_NET_CORE_BUSY_READ 50)
	
	# streaming
	STREAM_TCP_CONG_ALGO=$(read_opt STREAM_TCP_CONG_ALGO bbr); STREAM_NET_RMEM_MAX=$(read_opt STREAM_NET_RMEM_MAX 16777216); STREAM_NET_WMEM_MAX=$(read_opt STREAM_NET_WMEM_MAX 16777216)
	STREAM_TCP_RMEM=$(read_raw STREAM_TCP_RMEM "4096 87380 16777216"); STREAM_TCP_WMEM=$(read_raw STREAM_TCP_WMEM "4096 65536 16777216")
	STREAM_NET_SOMAXCONN=$(read_opt STREAM_NET_SOMAXCONN 2048); STREAM_NET_TCP_MAX_SYN_BACKLOG=$(read_opt STREAM_NET_TCP_MAX_SYN_BACKLOG 2048)
	STREAM_NET_CORE_NETDEV_MAX_BACKLOG=$(read_opt STREAM_NET_CORE_NETDEV_MAX_BACKLOG 5000); STREAM_NET_CORE_DEFAULT_QDISC=$(read_opt STREAM_NET_CORE_DEFAULT_QDISC fq_codel)
	STREAM_TCP_AUTOCORKING=$(read_opt STREAM_TCP_AUTOCORKING 1); STREAM_TCP_SLOW_START_AFTER_IDLE=$(read_opt STREAM_TCP_SLOW_START_AFTER_IDLE 1); STREAM_TCP_NO_METRICS_SAVE=$(read_opt STREAM_TCP_NO_METRICS_SAVE 1); STREAM_TCP_FASTOPEN=$(read_opt STREAM_TCP_FASTOPEN 3)
	STREAM_NET_NOTSENT_LOWAT=$(read_opt STREAM_NET_NOTSENT_LOWAT 32768); STREAM_NET_CORE_BUSY_POLL=$(read_opt STREAM_NET_CORE_BUSY_POLL 30); STREAM_NET_CORE_BUSY_READ=$(read_opt STREAM_NET_CORE_BUSY_READ 30)
	
	# download
	DOWNLOAD_TCP_CONG_ALGO=$(read_opt DOWNLOAD_TCP_CONG_ALGO cubic); DOWNLOAD_NET_RMEM_MAX=$(read_opt DOWNLOAD_NET_RMEM_MAX 67108864); DOWNLOAD_NET_WMEM_MAX=$(read_opt DOWNLOAD_NET_WMEM_MAX 67108864)
	DOWNLOAD_TCP_RMEM=$(read_raw DOWNLOAD_TCP_RMEM "4096 131072 67108864"); DOWNLOAD_TCP_WMEM=$(read_raw DOWNLOAD_TCP_WMEM "4096 131072 67108864")
	DOWNLOAD_NET_SOMAXCONN=$(read_opt DOWNLOAD_NET_SOMAXCONN 8192); DOWNLOAD_NET_TCP_MAX_SYN_BACKLOG=$(read_opt DOWNLOAD_NET_TCP_MAX_SYN_BACKLOG 8192)
	DOWNLOAD_NET_CORE_NETDEV_MAX_BACKLOG=$(read_opt DOWNLOAD_NET_CORE_NETDEV_MAX_BACKLOG 20000); DOWNLOAD_NET_CORE_DEFAULT_QDISC=$(read_opt DOWNLOAD_NET_CORE_DEFAULT_QDISC fq)
	DOWNLOAD_TCP_AUTOCORKING=$(read_opt DOWNLOAD_TCP_AUTOCORKING 1); DOWNLOAD_TCP_SLOW_START_AFTER_IDLE=$(read_opt DOWNLOAD_TCP_SLOW_START_AFTER_IDLE 0); DOWNLOAD_TCP_NO_METRICS_SAVE=$(read_opt DOWNLOAD_TCP_NO_METRICS_SAVE 0); DOWNLOAD_TCP_FASTOPEN=$(read_opt DOWNLOAD_TCP_FASTOPEN 3)
	DOWNLOAD_NET_NOTSENT_LOWAT=$(read_opt DOWNLOAD_NET_NOTSENT_LOWAT 65536); DOWNLOAD_NET_CORE_BUSY_POLL=$(read_opt DOWNLOAD_NET_CORE_BUSY_POLL 0); DOWNLOAD_NET_CORE_BUSY_READ=$(read_opt DOWNLOAD_NET_CORE_BUSY_READ 0)
}

save_node() { v=$(cat "$1" 2>/dev/null); [ -n "$v" ] && echo "net|$1|$v" >> "$ORIG_LIST"; }
capture_orig() { : > "$ORIG_LIST"; save_node /proc/sys/net/ipv4/tcp_congestion_control; save_node /proc/sys/net/ipv4/tcp_low_latency; save_node /proc/sys/net/ipv4/tcp_fastopen; save_node /proc/sys/net/ipv4/tcp_autocorking; save_node /proc/sys/net/ipv4/tcp_slow_start_after_idle; save_node /proc/sys/net/ipv4/tcp_no_metrics_save; save_node /proc/sys/net/ipv4/tcp_tw_reuse; save_node /proc/sys/net/ipv4/tcp_tw_recycle; save_node /proc/sys/net/ipv4/tcp_fin_timeout; save_node /proc/sys/net/ipv4/tcp_keepalive_time; save_node /proc/sys/net/ipv4/tcp_keepalive_probes; save_node /proc/sys/net/ipv4/tcp_keepalive_intvl; save_node /proc/sys/net/ipv4/tcp_synack_retries; save_node /proc/sys/net/ipv4/tcp_syn_retries; save_node /proc/sys/net/core/rmem_max; save_node /proc/sys/net/core/wmem_max; save_node /proc/sys/net/core/rmem_default; save_node /proc/sys/net/core/wmem_default; save_node /proc/sys/net/ipv4/tcp_rmem; save_node /proc/sys/net/ipv4/tcp_wmem; save_node /proc/sys/net/core/somaxconn; save_node /proc/sys/net/ipv4/tcp_max_syn_backlog; save_node /proc/sys/net/core/netdev_max_backlog; save_node /proc/sys/net/core/default_qdisc; save_node /proc/sys/net/ipv4/ip_no_pmtu_disc; save_node /proc/sys/net/core/busy_poll; save_node /proc/sys/net/core/busy_read; save_node /proc/sys/net/ipv4/tcp_notsent_lowat; }
restore_orig() { [ -s "$ORIG_LIST" ] || return 0; while IFS='|' read -r k p v; do [ -n "$p" ] && wr "$p" "$v"; done < "$ORIG_LIST"; }

apply_net() {
	local c=$1
	if [ "$NET_TCP" = "true" ]; then
		local algo=$(eval echo \$${c}_TCP_CONG_ALGO); [ -z "$algo" ] && algo=$TCP_CONG_ALGO
		local fast=$(eval echo \$${c}_TCP_FASTOPEN); [ -z "$fast" ] && fast=$TCP_FASTOPEN
		local ac=$(eval echo \$${c}_TCP_AUTOCORKING); [ -z "$ac" ] && ac=$TCP_AUTOCORKING
		local ssai=$(eval echo \$${c}_TCP_SLOW_START_AFTER_IDLE); [ -z "$ssai" ] && ssai=$TCP_SLOW_START_AFTER_IDLE
		local nms=$(eval echo \$${c}_TCP_NO_METRICS_SAVE); [ -z "$nms" ] && nms=$TCP_NO_METRICS_SAVE
		local notsent=$(eval echo \$${c}_NET_NOTSENT_LOWAT); [ -z "$notsent" ] && notsent=$NET_NOTSENT_LOWAT
		local bp=$(eval echo \$${c}_NET_CORE_BUSY_POLL); [ -z "$bp" ] && bp=$NET_CORE_BUSY_POLL
		local br=$(eval echo \$${c}_NET_CORE_BUSY_READ); [ -z "$br" ] && br=$NET_CORE_BUSY_READ
		local qdisc=$(eval echo \$${c}_NET_CORE_DEFAULT_QDISC); [ -z "$qdisc" ] && qdisc=$NET_CORE_DEFAULT_QDISC
		local rmem=$(eval echo \$${c}_NET_RMEM_MAX); [ -z "$rmem" ] && rmem=$NET_RMEM_MAX
		local wmem=$(eval echo \$${c}_NET_WMEM_MAX); [ -z "$wmem" ] && wmem=$NET_WMEM_MAX
		local trmem=$(eval echo \$${c}_TCP_RMEM); [ -z "$trmem" ] && trmem="$TCP_RMEM"
		local twmem=$(eval echo \$${c}_TCP_WMEM); [ -z "$twmem" ] && twmem="$TCP_WMEM"
		local somax=$(eval echo \$${c}_NET_SOMAXCONN); [ -z "$somax" ] && somax=$NET_SOMAXCONN
		local backlog=$(eval echo \$${c}_NET_TCP_MAX_SYN_BACKLOG); [ -z "$backlog" ] && backlog=$NET_TCP_MAX_SYN_BACKLOG
		local ndbl=$(eval echo \$${c}_NET_CORE_NETDEV_MAX_BACKLOG); [ -z "$ndbl" ] && ndbl=$NET_CORE_NETDEV_MAX_BACKLOG
		
		avail=$(cat /proc/sys/net/ipv4/tcp_available_congestion_control 2>/dev/null)
		case " $avail " in *" $algo "*) wr /proc/sys/net/ipv4/tcp_congestion_control "$algo" ;; esac
		wr /proc/sys/net/ipv4/tcp_low_latency "$TCP_LOW_LATENCY"
		wr /proc/sys/net/ipv4/tcp_fastopen "$fast"
		wr /proc/sys/net/ipv4/tcp_autocorking "$ac"
		wr /proc/sys/net/ipv4/tcp_slow_start_after_idle "$ssai"
		wr /proc/sys/net/ipv4/tcp_no_metrics_save "$nms"
		wr /proc/sys/net/ipv4/tcp_tw_reuse "$TCP_TW_REUSE"
		wr /proc/sys/net/ipv4/tcp_tw_recycle "$TCP_TW_RECYCLE"
		wr /proc/sys/net/ipv4/tcp_fin_timeout "$TCP_FIN_TIMEOUT"
		wr /proc/sys/net/ipv4/tcp_keepalive_time "$TCP_KEEPALIVE_TIME"
		wr /proc/sys/net/ipv4/tcp_keepalive_probes "$TCP_KEEPALIVE_PROBES"
		wr /proc/sys/net/ipv4/tcp_keepalive_intvl "$TCP_KEEPALIVE_INTVL"
		wr /proc/sys/net/ipv4/tcp_synack_retries "$TCP_SYNACK_RETRIES"
		wr /proc/sys/net/ipv4/tcp_syn_retries "$TCP_SYN_RETRIES"
		wr /proc/sys/net/core/rmem_max "$rmem"; wr /proc/sys/net/core/wmem_max "$wmem"
		wr /proc/sys/net/core/rmem_default "$NET_RMEM_DEFAULT"; wr /proc/sys/net/core/wmem_default "$NET_WMEM_DEFAULT"
		echo "$trmem" > /proc/sys/net/ipv4/tcp_rmem 2>/dev/null
		echo "$twmem" > /proc/sys/net/ipv4/tcp_wmem 2>/dev/null
		wr /proc/sys/net/core/somaxconn "$somax"
		wr /proc/sys/net/ipv4/tcp_max_syn_backlog "$backlog"
		wr /proc/sys/net/core/netdev_max_backlog "$ndbl"
		wr /proc/sys/net/ipv4/ip_no_pmtu_disc "$NET_IPV4_IP_NO_PMTU_DISC"
		wr /proc/sys/net/core/busy_poll "$bp"; wr /proc/sys/net/core/busy_read "$br"
		wr /proc/sys/net/ipv4/tcp_notsent_lowat "$notsent"
		case " $qdisc " in *" fq "*|*"fq_codel "*|*"cake "*|*"pfifo_fast "*|*"mq "*|*"sch_fq_codel "*) wr /proc/sys/net/core/default_qdisc "$qdisc" ;; esac
		log "applied profile=$c cong=$algo notsent=$notsent qdisc=$qdisc"
	fi
	if [ "$NET_DNS" = "true" ] && [ "$DNS_AUTO" = "true" ] && [ -w /etc/resolv.conf ]; then
		{ echo "nameserver $DNS1"; echo "nameserver $DNS2"; } > /etc/resolv.conf 2>/dev/null
	fi
	if [ "$MTU" != "0" ] && [ -n "$MTU" ]; then
		for ifc in /sys/class/net/*; do
			[ -d "$ifc" ] || continue; ifname=$(basename "$ifc"); [ "$ifname" = "lo" ] && continue
			ip link set "$ifname" mtu "$MTU" 2>/dev/null
		done
	fi
}

apply_game_check() {
	if [ "$MODE" = "gaming" ] && [ "$GP_DYN" = "true" ]; then
		fg=$(fg_pkg); if in_gamelist "$fg"; then apply_net GAME; state="game"; else apply_net BASE; state="idle"; fi
	else
		case "$MODE" in gaming) apply_net GAME;; streaming) apply_net STREAM;; download) apply_net DOWNLOAD;; *) apply_net BASE;; esac
	fi
}

ORIG_LIST="$MODDIR/.net_orig"
capture_orig
load_config
if [ "$MODE" = "global" ]; then restore_orig; state=global
else apply_net BASE; apply_game_check; state=${state:-idle}; fi

sleep 30; rm -f "$BOOTCOUNT" 2>/dev/null; log "boot ok"

while :; do
	if [ -f "$RELOAD" ]; then
		rm -f "$RELOAD"; load_config
		if [ "$MODE" = "global" ]; then restore_orig; state=global
		else apply_net BASE; apply_game_check; state=${state:-idle}; fi
	fi
	if [ "$MODE" = "gaming" ] && [ "$GP_DYN" = "true" ]; then
		fg=$(fg_pkg)
		if in_gamelist "$fg"; then [ "$state" != "game" ] && { apply_net GAME; state=game; }
		else [ "$state" != "idle" ] && { apply_net BASE; state=idle; }; fi
	fi
	sleep "$GP_POLL"
done
