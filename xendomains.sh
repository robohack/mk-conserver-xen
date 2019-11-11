#!/bin/sh
#
#	/etc/rc.conf.d/xendomains -- rc.d helper for xendomains
#

start_postcmd=xendomains_postcmd

xendomains_postcmd() {
	/usr/pkg/etc/xen/scripts/mk-conserver-xen reload
}
