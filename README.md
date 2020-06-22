# wine-builder
my personal wine-builder "system" for use on puppylinux or puppy derivates {puplets}.

Due to my latest updates this should actually build on any system, regardless if it is a puppylinux based distro or not (not 100% sure tho, needs testing).

current working wine-staging commit: 7b5a0e5a94f3b203adc367e7cc0ef4d33be13c9c

usage:
```bash
./build.sh [options]
``` 

```
options list:
--only-repos            : Only pull git repos and download tar packages.
--patch-stop            : Only get to patch wine {for testing purposes}.
--no-build-gstreamer    : Don't build gstreamer, meant for proper distros
                          with package managers.
--without-gstreamer     : Disable gstreamer support entirely.
--threads=x             : Number of compiling threads.
--dest=/path/to/dest    : DESTDIR like argument.
--last-working          : Use the last working commit (manually updated) 
--latest                : Overrides the safe last_working_commit file
--no-libusb             : Skip building libusb
--h --help -h           : Show this help and exit.
```

