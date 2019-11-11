#!/bin/sh

#
#	/etc/rc.conf.d/conserver -- rc.d helper for conserver
#

start_precmd=conserver_precmd
reload_precmd=conserver_precmd

conserver_precmd() {
	xenstored_pid=$(check_pidfile /var/run/xenstored.pid /usr/pkg/sbin/xenstored)
	if [ -n "${xenstored_pid}" ]; then
		/usr/pkg/etc/xen/scripts/mk-conserver-xen
#
# n.b.:  if domU changes are frequent between boots then the config file
# will not reflect how it will look after a dom0 reboot, so clear it to
# avoid connecting the wrong consoles to the wrong ptys:
#
#	else
#		# at least one "console" entry must exist at all times
#		#
#		cat > /usr/pkg/etc/xen/conserver.xen <<- _EOH_
#			console dummy-${hostname} {
#			${tab}type exec;
#		}
#		_EOH_
	fi
}
