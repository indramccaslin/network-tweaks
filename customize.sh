#!/system/bin/sh
command -v ui_print >/dev/null 2>&1 || ui_print() { echo "  $1"; }

ui_print " "
ui_print "  #####################################"
ui_print "  #        NETWORK TWEAKS  v1.0.0     #"
ui_print "  #####################################"
ui_print " "
ui_print "  Optimize TCP/UDP latency for gaming"
ui_print "  BBR, buffers, DNS, QoS tuning"
ui_print " "

[ -n "$MODPATH" ] || MODPATH="$(dirname "$0")"

for f in service.sh uninstall.sh; do
  [ -f "$MODPATH/$f" ] && chmod 0755 "$MODPATH/$f" 2>/dev/null
done
for f in module.prop tweak.conf gamelist.txt README.md; do
  [ -f "$MODPATH/$f" ] && chmod 0644 "$MODPATH/$f" 2>/dev/null
done
[ -f "$MODPATH/webroot/index.html" ] && chmod 0644 "$MODPATH/webroot/index.html" 2>/dev/null

ui_print "  Done! Reboot then open WebUI"
ui_print " "
