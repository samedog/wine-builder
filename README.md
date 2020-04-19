# wine-builder
my personal wine-builder "system" for use on puppylinux or puppy derivates {puplets}.

Due to my latest updates this should actually build on any system, regardless if it is a puppylinux based distro or not (not 100% sure tho, needs testing).

current tested wine-staging commit: 029c249e789fd8b05d8c1eeda48deb8810bbb751

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
--latest			        	: Overrides the safe last_working_commit file
--no-libusb             : Skip building libusb
--h --help -h           : Show this help and exit.
```

asdasd
