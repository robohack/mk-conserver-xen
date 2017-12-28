#!/bin/sh
#
#	mk-conserver-xen.sh
#
# install on dom0 host in /usr/pkg/etc/xen/scripts/mk-conserver-xen
#
# conserver.cf could define a task which runs "/etc/rc.d/conserver reload"
#
# /etc/rc.conf.d/conserver:
#
#	start_precmd=conserver_precmd
#	reload_precmd=conserver_precmd
#	
#	conserver_precmd() {
#		xenstored_pid=$(check_pidfile /var/run/xenstored.pid /usr/pkg/sbin/xenstored)
#		if [ -n "${xenstored_pid}" ]; then
#			/usr/pkg/etc/xen/scripts/mk-conserver-xen
#		else
#			> /usr/pkg/etc/xen/conserver.xen
#		fi
#	}
#
# /etc/rc.d/xendomains:  edit to add "conserver" to the "REQUIRE:" line
#
# /etc/rc.conf.d/xendomains:
#
#	start_postcmd=xendomains_postcmd
#	
#	xendomains_postcmd() {
#		/usr/pkg/etc/xen/scripts/mk-conserver-xen reload
#	}
#
#ident "@(#):mk-conserver-xen.sh,v 1.5 2017/12/28 16:34:39 woods Exp"

export PATH=/sbin:/bin:/usr/sbin:/usr/bin:/usr/pkg/bin:/usr/pkg/sbin

tab=$(printf "\t")

# XXX should check that xenstored is running, else will hang....

echo "# DO NOT MODIFY -- cretated entirely by ${0}" > /usr/pkg/etc/xen/conserver.xen

for domid in $(xenstore-list /local/domain) ; do
	if [ ${domid} = 0 ]; then
		continue
	fi
	domnm=$(xenstore-read /local/domain/${domid}/name)
	domtty=$(xenstore-read /local/domain/${domid}/console/tty 2>/dev/null)
	domstty=$(xenstore-read /local/domain/${domid}/serial/0/tty 2>/dev/null)
	if [ -z "${domtty}" -a -z "${domstty}" ]; then
		echo "error: ${domnm} has no console or serial tty" 1>&2
		echo "#console ${domnm} {}"
		continue;
	fi
	if [ -n "${domtty}" ]; then
		# if there is a serial tty, it should have the default (simple)
		# name, so append "-cons" to this one if domstty is set
		cat <<- _EOH_
			console ${domnm}${domstty:+"-cons"} {
			${tab}type device;
			${tab}device ${domtty};
			${tab}baud 115200;
			${tab}parity none;
			}
		_EOH_
	fi
	if [ -n "${domstty}" ]; then
		cat <<- _EOH_
			console ${domnm} {
			${tab}type device;
			${tab}device ${domstty};
			${tab}baud 115200;
			${tab}parity none;
			}
		_EOH_
	fi
done >> /usr/pkg/etc/xen/conserver.xen

# XXX the above should probably write to a temporary file, but since the reload
# will normally only be triggered below (i.e. not concurrently by
# someone/something else, nothing should read conserver.xen while it is being
# written.

if [ "${1}" = "reload" ]; then
	/etc/rc.d/conserver reload
fi
