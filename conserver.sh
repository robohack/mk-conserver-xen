#
#	/etc/rc.conf.d/conserver -- rc.d config segment for conserver Xen support
#

start_precmd=conserver_precmd
reload_precmd=conserver_precmd

conserver_precmd() {
	if [ -r /etc/xen/scripts/hotplugpath.sh ]; then
		. /etc/xen/scripts/hotplugpath.sh
	else
		sbindir=${PKG:-"/usr/pkg"}/sbin
		bindir=${PKG:-"/usr/pkg"}/bin
		export PATH=/sbin:/bin:/usr/sbin:/usr/bin:${sbindir}:${bindir}

		if type pkg_info >/dev/null 2>&1; then
			XEN_SYSCONFDIR=$(pkg_info -Q PKG_SYSCONFDIR xentools\* | tail -1)
			XEN_CONFIG_DIR=${XEN_SYSCONFDIR}/xen
			XEN_SCRIPT_DIR=${XEN_SYSCONFDIR}/xen/scripts
		else
			XEN_CONFIG_DIR=/etc/xen
			XEN_SCRIPT_DIR=/etc/xen/scripts
		fi
		. ${XEN_SCRIPT_DIR}/hotplugpath.sh
	fi
	export PATH=/sbin:/bin:/usr/sbin:/usr/bin:${sbindir}:${bindir}
	# note $2 for check_pidfile does not really need a full path, and it may move to libexec?
	xenstored_pid=$(check_pidfile ${XEN_RUN_DIR}/xenstored.pid xenstored)
	if [ -n "${xenstored_pid}" ]; then
		${XEN_SCRIPT_DIR}/mk-conserver-xen
#
# n.b.:  if domU changes are frequent between boots then the config file
# will not reflect how it will look after a dom0 reboot, so clear it to
# avoid connecting the wrong consoles to the wrong ptys:
#
#	else
#		# at least one "console" entry must exist at all times
#		#
#		cat > ${XEN_CONFIG_DIR}/conserver.xen <<- _EOH_
#			console empty-${hostname} {
#			${tab}type exec;
#		       	${tab}options ondemand;
#			${tab}exec /usr/bin/true;
#		}
#		_EOH_
	fi
}
