#
# N.B.:  the first non-comment line should source Xen's hotplugpaths.sh
#
#. /etc/xen/scripts/hotplugpaths.sh
#
#	/etc/rc.conf.d/xendomains -- rc.d config segment for xendomains
#				     conserver support
#
start_postcmd=xendomains_postcmd

xendomains_postcmd() {
	${XEN_SCRIPT_DIR}/mk-conserver-xen reload
}
