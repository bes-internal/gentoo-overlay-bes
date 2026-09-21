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
- sys-cluster/csync2: not packaged in the main ::gentoo tree
- dev-util/diffr: Diff tool with colorized word-level highlighting inside changed lines, not packaged in the main ::gentoo tree
- dev-perl/Mail-SPF: newer CPAN release than what's in the main ::gentoo tree
- www-apps/gitea-runner-bin: not packaged in the main ::gentoo tree
- www-nginx/ngx-ja4: JA4 TLS fingerprinting module for NGINX, not packaged in the main ::gentoo tree
- mail-mta/exim + use experimental_spf/dmarc 
