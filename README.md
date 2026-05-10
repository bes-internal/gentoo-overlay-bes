# gentoo-overlay-bes

personal portage overlay

## Installing

add the overlay to gentoo:

```
$ emerge app-eselect/eselect-repository
$ eselect repository enable bes
```

update:

```
$ emaint sync -r bes
```

## Atoms

- sys-apps/busybox: extra use flag for all suppressed commands in base gentoo (beep, inetd, ipcalc, inotifyd, rfkill, ...)
- sys-cluster/csync2

