#!/bin/sh
#
#	mk-conserver-xen.sh
#
# Install this on the dom0 host in {/usr/pkg}/etc/xen/scripts/mk-conserver-xen
#
# Run this script by doing "/etc/rc.d/conserver8 reload"
#
# Follow the instructions in the rest of this comment to complete the
# configuration of both conserver and Xen.
#
# edit {/usr/pkg}/etc/conserver.cf to add (replacing XENHOST with $(hostname)):
#
#	#
#	# Xen break into ddb
#	#
#	break 4 { string "+++++"; }
#	
#	# if only handling Xen consoles then add a dummy console to
#	# allow for starting conserver when no Xen domains are (yet)
#	# running.
#	#
#	console dummy-xentastic {
#	        type exec;
#		options ondemand;
#	        exec /usr/bin/true;
#	}
#
#	# this "#include" line is not a comment!
#	# (iff it is preceded by a blank line)
#	
#	#include /usr/pkg/etc/xen/conserver.xen
#
# NOTICE:  watch out for unwanted /usr/pkg above!
#
# put the next section in /etc/rc.conf.d/conserver:
#
#	start_precmd=conserver_precmd
#	reload_precmd=conserver_precmd
#	
#	conserver_precmd() {
#               XEN_SYSCONFDIR=$(/usr/sbin/pkg_info -Q PKG_SYSCONFDIR xentools\* | sed -n 1p)
#               XEN_PREFIX=$(/usr/sbin/pkg_info -Q PREFIX xentools\* | sed -n 1p)
#		xenstored_pid=$(check_pidfile /var/run/xenstored.pid ${XEN_PREFIX}/sbin/xenstored)
#		if [ -n "${xenstored_pid}" ]; then
#			${XEN_SYSCONFDIR}/xen/scripts/mk-conserver-xen
#	#
#	# n.b.:  if domU changes are frequent between boots then the config file
#	# will not reflect how it will look after a dom0 reboot, so clear it to
#	# avoid connecting the wrong consoles to the wrong ptys:
#	#
#	#	else
#	#		# at least one "console" entry must exist at all times
#	#		#
#	#		cat > ${XEN_SYSCONFDIR}/xen/conserver.xen <<- _EOH_
#	#			console empty-${hostname} {
#	#			${tab}type exec;
#	#		       	${tab}options ondemand;
#	#			${tab}exec /usr/bin/true;
#	#		}
#	#		_EOH_
#		fi
#	}
#
# edit /etc/rc.d/xendomains to add "conserver" (and "sshd") to the "REQUIRE:"
# line, like this:
#
#	REQUIRE: xencommons conserver sshd
#
# put the next section in /etc/rc.conf.d/xendomains:
#
#	start_postcmd=xendomains_postcmd
#	
#	xendomains_postcmd() {
#               XEN_SYSCONFDIR=$(/usr/sbin/pkg_info -Q PKG_SYSCONFDIR xentools\* | sed -n 1p)
#		${XEN_SYSCONFDIR}/xen/scripts/mk-conserver-xen reload
#	}
#
# Now you can also run "/etc/rc.d/conserver reload" after you manually start a
# new domU (or shut one down).
#
#ident "@(#):mk-conserver-xen.sh,v 1.9 2019/04/07 21:00:53 woods Exp"

export PATH=/sbin:/bin:/usr/sbin:/usr/bin:/usr/pkg/bin:/usr/pkg/sbin

XEN_SYSCONFDIR=$(/usr/sbin/pkg_info -Q PKG_SYSCONFDIR xentools\* | sed -n 1p)
XEN_PREFIX=$(/usr/sbin/pkg_info -Q PREFIX xentools\* | sed -n 1p)

tab=$(printf "\t")
have_domUs=false
hostname=$(hostname)

TMPFILE=$(mktemp "${XEN_SYSCONFDIR}/xen/conserver.xen.XXXXXXXX")
CONSERVER_XEN="${XEN_SYSCONFDIR}/xen/conserver.xen"

###echo $0: dom0=${hostname}: rebuilding ${CONSERVER_XEN}

# xxx could/should there be an exit trap to clean up $TMPFILE???

echo "# DO NOT MODIFY -- cretated entirely by ${0}" > ${TMPFILE}

for domid in $(xenstore-list /local/domain) ; do
	if [ ${domid} = 0 ]; then
		# xenstored knows nothing about our own dom0 console
		continue
	fi
	have_domUs=true
	domnm=$(xenstore-read /local/domain/${domid}/name)
	domtty=$(xenstore-read /local/domain/${domid}/console/tty 2>/dev/null)
	domstty=$(xenstore-read /local/domain/${domid}/serial/0/tty 2>/dev/null)
	if [ -z "${domtty}" -a -z "${domstty}" ]; then
		echo ERROR: ${domnm} has no console or serial tty 1>&2
		echo "#console ${domnm} {}"
		continue;
	fi
	if [ -n "${domtty}" ]; then
		# if there is a serial tty, it should have the default (simple)
		# name, so append "-cons" to this one if domstty is set
		cat <<- _EOH_
			console ${domnm}${domstty:+-cons} {
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
done >> ${TMPFILE}

if ! ${have_domUs}; then
	# at least one entry must exist at all times
	#
	cat <<- _EOH_
		console dummy-${hostname} {
		${tab}type exec;
	}
	_EOH_
fi

rc=$?
if [ ${rc} -ne 0 ]; then
	echo $0: failed to generate new conserver.xen 1>&2
	rm ${TMPFILE}
	exit ${rc}
fi

if cmp ${TMPFILE} ${CONSERVER_XEN} >/dev/null 2>&1; then
	echo ${CONSERVER_XEN}: no change 1>&2
	rm ${TMPFILE}
	exit 0
fi

mv ${TMPFILE} ${CONSERVER_XEN}
if [ "${1}" = "reload" ]; then
	/etc/rc.d/conserver reload
fi
