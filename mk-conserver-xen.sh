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
# /etc/rc.conf.d/xendomains:  edit to add "conserver" to "REQUIRE:" line
#
#	start_postcmd=xendomains_postcmd
#	
#	xendomains_postcmd() {
#		/usr/pkg/etc/xen/scripts/mk-conserver-xen reload
#	}
#
#ident "@(#):mk-conserver-xen.sh,v 1.3 2015/04/22 20:54:31 woods Exp"

export PATH=/sbin:/usr/sbin:/usr/pkg/bin:/usr/pkg/sbin

tab=$(printf "\t")

# XXX should check that xenstored is running, else will hang....

echo "# DO NOT MODIFY -- cretated entirely by ${0}" > /usr/pkg/etc/xen/conserver.xen

for domid in $(xenstore-list /local/domain) ; do
	if [ ${domid} = 0 ]; then
		continue
	fi
	domnm=$(xenstore-read /local/domain/${domid}/name)
	domtty=$(xenstore-read /local/domain/${domid}/console/tty)
	if [ -z "${domtty}" ]; then
		echo "error: ${domnm} has no console tty" 1>&2
		echo "#console ${domnm} {}"
		continue;
	fi
	cat <<- _EOH_
		console ${domnm} {
		${tab}type device;
		${tab}device ${domtty};
		${tab}baud 115200;
		${tab}parity none;
		}
	_EOH_
done >> /usr/pkg/etc/xen/conserver.xen

if [ "${1}" = "reload" ]; then
	/etc/rc.d/conserver reload
fi
