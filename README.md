Open Network Loader
===================

The Open Network Loader is the first-stage boot environment.

The Open Network Loader's responsibility is to select
the appropriate Software Image file and associated persistant
storage files when booting the system.

The Open Network Loader can be used interactively to load
arbitrary image files over the network or setup to automatically
boot image files located on local persistent storage or delivered
from automatic-provisioning servers.

The Open Network Loader is based on Buildroot and BusyBox.
This decision was made initially based on system flash capacities.

With the introduction of ONIE as the standard installation environment
and large block devices available for the system software the need for
a small (8-16MB) Loader environment is no longer necessary.

The Open Network loader system will likely be transitioned to a small
debian-based system for easy of development, consistency, package
portability between the Loader and Open Network environments (which are
already Debian based), as well as reducing build time and complexity.

