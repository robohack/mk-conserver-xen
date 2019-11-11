# mk-conserver-xen -- a conserver helper for Xen

Copyright (c) 2019 by Greg A. Woods <woods@planix.ca>

This work is licensed under the Creative Commons Attribution-ShareAlike
4.0 International License.

## Introduction

`mk-conserver-xen.sh` is an `rc.d` helper script to manage configuration
of `conserver` for all Xen domU instances.

## Installation

All of the following instructions are to be performed on the dom0 host.

First you will of course need to install `pkgsrc/comms/conserver8` (aka
[conserver](http://www.conserver.com/)).

Install the main script (`mk-conserver-xen.sh`) into
`/usr/pkg/etc/xen/scripts/mk-conserver-xen`.

Install the conserver helper (`conserver.sh`) into
`/etc/rc.conf.d/conserver` (on the dom0 host).

Install the xendomains helper (`xendomains.sh`) into
`/etc/rc.conf.d/xendomains` (on the dom0 host).

Then edit `/usr/pkg/etc/conserver.cf` to configure `conserver` as
desired, and to add the following section:

	#
	# Xen break into ddb
	#
	break 4 { string "+++++"; }
	
	# this "#include" line is not a comment!
	# (iff it is preceded by a blank line)
	
	#include /usr/pkg/etc/xen/conserver.xen

Finally edit `/etc/rc.d/xendomains` to add `conserver` (and `sshd`) to
the `REQUIRE:` line, so that it looks something like this:

	REQUIRE: xencommons conserver sshd

Now you can run `/etc/rc.d/conserver reload` after you manually start a
new domU (or shut one down).
