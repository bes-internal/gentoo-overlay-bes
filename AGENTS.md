# AGENTS.md

Instructions for Claude (or any agent) doing routine maintenance on this
overlay.

## Version-bump maintenance

Periodically check each package's upstream for a newer version. When one
exists, create a new ebuild for it, verify it builds, and fix simple
version-related breakage before committing.

### Per-package upstream feed

| Package | Feed / listing | Notes |
|---|---|---|
| dev-perl/Mail-SPF | https://fastapi.metacpan.org/v1/release/Mail-SPF | CPAN distribution — check the `version`/`date` fields in the JSON. The GitHub mirror (fastmail/mail-spf) publishes no releases/tags, don't use it. |
| mail-mta/exim | https://code.exim.org/exim/exim/tags.rss | RSS of git tags `exim-<version>`: take the highest one that isn't `-RC*`. Fetch it with plain `curl`, no User-Agent header: a browser-like one (`-A Mozilla`) gets a 404 from this server. Fallback if it's down: the release tarball listing https://downloads.exim.org/exim4/ (highest `exim-<version>.tar.xz`; `fixes/` has point releases, `test/` RCs to skip), which has been unreachable at times. Security fixes ship as ordinary point releases (e.g. `4.100.1` fixed four security issues), so there's no separate CVE feed to check. |
| dev-util/diffr | https://github.com/mookid/diffr/releases.atom | GitHub Atom releases feed; tags are `v<version>`. |
| sys-cluster/csync2 | https://github.com/LINBIT/csync2/releases.atom | GitHub Atom releases feed; tags are `csync2-<version>`. Releases are rare (2.0 is the latest); our security patches come from open upstream PRs (#49, #50), so also check whether those got merged and released, and drop the matching patch once they have. |
| sys-apps/busybox | `::gentoo` tree | Busybox's `X.Y.0` "unstable" releases usually land in stock without keywords (`KEYWORDS` commented out), so they're skipped by the rule below until stock keywords them. |
| www-apps/gitea | https://github.com/go-gitea/gitea/releases.atom | GitHub Atom releases feed; tags are `v<version>`, skip `-dev`/`-rc` tags. After `1.27.x` upstream switched to major-only numbering (`v28.0.0`, `v28.1.0`, ...); Portage orders `28.x` above `1.27.x`. Base new versions on stock's ebuild. Since 28.x the Go module path is `gitea.dev` (the `-X ...modules/setting.*` ldflags must use it) and SQLite is built in via the pure-Go driver, with USE=sqlite selecting the cgo `sqlite_mattn` driver. |
| www-apps/gitea-runner-bin | https://gitea.com/gitea/runner/releases.rss | Gitea instances expose `<releases-url>.rss` |
| www-nginx/ngx-ja4 | https://github.com/bes-internal/ja4-nginx-module/releases.atom | Our own module repo; GitHub Atom releases feed, tags are `v<version>`. |

A row whose feed is the `::gentoo` tree follows stock Gentoo's versions
instead of upstream's, rather than fetching any release feed. The version
to follow is the highest one stock keywords at all, testing (`~amd64`) or
stable (`amd64`), per `eix -e <package>` or the ebuilds under
`$(portageq get_repo_path / gentoo)/<category>/<package>/`. Ignore
versions without keywords (`**` in eix), masked ones, and live `9999`.
Bump only when that version is newer than ours, and base the new ebuild on
stock's ebuild for that version with this overlay's customization
re-applied on top, rather than copying our older ebuild forward.

A package stays in this table even when its directory has been removed
from the overlay (e.g. because stock caught up): keep checking its feed,
and when upstream is ahead of what's in the overlay again, add an ebuild
for the new version without asking — based on stock's ebuild when stock
carries the package.

General rule for a package not yet in this table: if upstream is on
GitHub, its feed is `<homepage>/releases.atom`; if upstream is on a Gitea
or Forgejo instance (Forgejo is Gitea-compatible), it's
`<releases-url>.rss`; if it's a CPAN Perl distribution
(`dev-perl/*`, sourced via `perl-module.eclass`), use
`https://fastapi.metacpan.org/v1/release/<Distribution-Name>` and read
the `version`/`date` fields — don't assume a GitHub mirror of a CPAN
module publishes releases, check first. Add the new row here when you
add the package.

### Procedure per package

Do the expensive work only when something changed. A package whose
upstream has no newer version and whose stock fingerprint is unchanged
(see "Pulling fixes from ::gentoo") needs nothing further: no builds, no
patch-apply tests, no stock diffs. Report it as up to date.

1. Fetch the feed/listing above and find the highest non-prerelease
   version (skip `-rc`, `beta`, `alpha` tags unless the package's row in
   the table above says it deliberately tracks them).
2. Compare it against the highest version already in the overlay
   (`ls <category>/<package>/*.ebuild`).
3. No newer version -> skip, nothing to do.
4. Newer version found:
   - `cp <old-highest>.ebuild <category>/<package>/<package>-<newver>[-r1].ebuild`
     (`-r1` per the rules in "Ebuild revision suffix (-rN)" below). Keep
     the old ebuild(s) in place at this point; pruning happens afterwards,
     per "Retention: newest major keeps two, older majors keep one" below.
   - Edit only what the version bump actually requires (SRC_URI, `S=`,
     pinned crate/dependency versions, etc). Don't restructure anything
     that isn't broken.
   - Regenerate the Manifest: `ebuild <new>.ebuild manifest` (needs
     network access to fetch the new distfile).
5. Test the build with Portage (`ebuild <new>.ebuild clean compile` to
   build through `src_compile` without touching the live system, or
   `ebuild <new>.ebuild clean install` to also run `src_install` into
   the image dir — still not merged into the live system). This needs
   `ebuild`/`emerge`, i.e. an actual Gentoo environment with this repo
   registered as a Portage repo. If the environment this is running in
   has that (`command -v ebuild`), just run it here; otherwise run it
   over ssh on a Gentoo host that does, against that host's checkout of
   this same repo.
6. If the build fails on something simple and clearly version-related
   (a renamed Makefile variable, a patch that's now upstreamed and no
   longer applies, a moved config option, etc.), fix it directly in the
   new ebuild — it hasn't been committed yet, so the fix doesn't add a
   revision. If the failure is non-trivial (new
   dependencies, real incompatibility, needs an actual new patch), stop
   and report it — don't guess at a real fix. If you later come back and
   change an already-committed version's ebuild (e.g. add a patch after
   the fact, as opposed to fixing it before the first commit), see
   "Ebuild revision suffix (-rN)" below.
7. Once it builds cleanly, prune per the retention rule below, then
   `git add` the new ebuild + Manifest and commit.

### Ebuild header

Whenever you create or change an ebuild, or add or change a file under
`files/` that carries a copyright header (init/conf.d scripts and the
like), its copyright range must end at the current year, e.g.
`# Copyright 2016-2026 Gentoo Authors`. Keep the start year the source
file already has (stock's, or ours).

### Retention: newest major keeps two, older majors keep one

Keep at most the two highest ebuilds in the newest major-version line of
a package (major = the first component of the version: `3.x` and `4.x`
are separate lines), and only the single highest ebuild in each older
major line once a newer major exists. Example: with `3.5.0`, `4.0.0` and
`4.0.1` present, keep `3.5.0`, `4.0.0` and `4.0.1`; a later `4.1.0`
would drop `4.0.0`. After a bump, delete the ones beyond that limit,
regenerate the Manifest so the removed versions' `DIST` entries are gone,
and include the deletion in the same commit as the bump. Different
`-rN` of one upstream version count as separate ebuilds. Any package
already over the limit can be trimmed the same way during a routine pass.

### Ebuild revision suffix (-rN)

Gentoo version syntax is `<upstream-version>[-rN]`. The `-rN` suffix is
never part of upstream's own version — it belongs exclusively to the
ebuild maintainer (here: this overlay) as a revision counter for the
*same* upstream version. Suffixes like `_alpha`, `_beta`, `_pN`, `_rcN`
etc. are part of upstream's version string instead, when upstream uses
them — never invent one of those ourselves either.

- A brand-new ebuild for a version never published in this overlay
  before, for a package that has **no equivalent in `::gentoo`** (stock
  doesn't carry the package at all), does not need `-rN` — there's
  nothing to disambiguate from, so the first ebuild is the implicit
  `-r0`.
- A brand-new ebuild for a version never published in this overlay
  before, for a package that **also exists (or plausibly could exist)
  in `::gentoo`**, and that carries any overlay-specific customization
  (an added/changed patch, a USE-flag delta, altered `src_*` logic)
  relative to what a stock ebuild of that version would look like,
  gets `-r1` from day one — even though it's the first appearance of
  that version in this overlay. Don't wait for a real collision with a
  future stock ebuild of the same version: the point of the suffix is
  that this ebuild's content is never assumed identical to whatever
  `::gentoo` might publish under the same version string. A version
  bump that is a pure, uncustomized copy of upstream's release (rare in
  this overlay, since packages here exist specifically *because* of
  customization) can stay at implicit `-r0`.
- Add (or increment) `-rN` when you modify an **already published**
  ebuild for the *same* upstream version without a new upstream release
  behind it — e.g. adding/removing/changing a patch, altering `src_*`
  logic, or fixing a USE-flag/dependency bug in the ebuild itself.
  `git mv` the file to bump it (`-r1` the first time such a change is
  made, `-r2` the next, etc.) rather than silently editing the existing
  filename in place.
- Package and category names may contain `A-Za-z0-9+-._` but must not
  end in a hyphen followed by a digit, to avoid being misread as a
  version.

### Pulling fixes from ::gentoo

For every package in this overlay, check what stock has fixed since our
ebuild was last compared, and carry it over. Don't redo this on every
pass: `stock-state.txt` at the repo root records a fingerprint of each
package's stock directory as of the last comparison, for every package we
maintain. A package stock doesn't carry is recorded as `-`; when stock
gains it the fingerprint changes and the package is checked like any
other (a stock copy may make ours a duplicate, per "When a package no
longer needs to live in this overlay").

0. Compute the current fingerprint of stock's `<category>/<package>`
   (command in the header of `stock-state.txt`; `-` if the directory
   doesn't exist). If it equals the recorded
   one, stock hasn't changed: skip the whole check below, including
   diffing and patch-applies. Otherwise do steps 1-4, then store the new
   fingerprint in `stock-state.txt` (in the same commit, or in its own
   `<category>/<package>: record stock state` commit when nothing needed
   porting). A package missing from `stock-state.txt` is checked once and
   added; add a line for every new package with its fingerprint or `-`. Also check when you touch the package for another reason
   (a bump, a patch change).

1. Diff our highest ebuild and its `files/` against stock's ebuild for
   the same version (or the nearest one) and stock's `files/`.
2. Sort every difference into two groups. One is this overlay's own
   customization (see the package's README "Atoms" line): keep it. The
   other is work stock has done that we don't have yet: bug fixes, new
   or updated patches, dependency fixes, `Bug:`/`#NNNNNN` references,
   dropped obsolete patches, `pkg_*` fixes. Port that into our ebuild.
3. Judge each stock change on its merits rather than copying blindly.
   Stock can also lose something that still matters (e.g. a
   `REQUIRED_USE` constraint dropped during a rewrite): if our ebuild
   still needs it, keep it and say why in the commit message. Purely
   cosmetic churn (comment wording, copyright year) needn't be ported on
   its own.
4. Porting into an already-published ebuild is a revision bump per the
   `-rN` rules below. Build-test as in the bump procedure, then commit as
   `<category>/<package>: sync fixes from ::gentoo`, listing the ported
   bug numbers in the body.

### When a package no longer needs to live in this overlay

Some packages here exist only because this overlay had a newer version
than the main `::gentoo` tree at the time. Once stock Gentoo catches up,
check whether the overlay ebuild is still pulling its weight:

1. Check what the main `::gentoo` tree provides now (`eix -e <package>`
   on the Gentoo host lists all known versions tagged by repo). A
   `~arch`-only (testing/unstable) stock ebuild still counts as
   coverage here — this overlay doesn't need to duplicate a version
   stock already carries at any stability level.
2. Diff this overlay's ebuild against the corresponding stock Gentoo
   ebuild (same or nearest version) — look at `files/` (any patches
   added here that stock doesn't carry), `IUSE`/`USE`-conditional logic,
   and the `src_*` functions.
3. If the overlay ebuild is functionally identical to stock — i.e. the
   only difference is the version string, with no added patches and no
   changed USE flags/dependencies/build logic — and stock Gentoo's
   version is equal to or newer than this overlay's, remove the whole
   package directory (`git rm -r <category>/<package>`). It's pure
   duplication at that point. Also remove its line from README.md's
   "Atoms" section, and delete any now-empty directory left behind. Keep
   its row in the feed table, so a later upstream release brings it back.
4. If the overlay ebuild carries real customization (extra patches,
   different USE flags, changed dependencies, altered `src_*` logic),
   keep it even if its version is now behind what stock Gentoo ships —
   the customization is still the reason it's here. Prefer rebasing
   that customization onto the newer version over deleting it.

### Keeping README's "Atoms" descriptions accurate

Each package in README.md's "Atoms" section is a top-level bullet with a
nested list of everything it changes or adds relative to `::gentoo`: one
sub-bullet per patch (mark security fixes), USE flag, keyword or logic
delta, and "newer upstream release than `::gentoo`" when that's part of
the reason. Packages stock doesn't carry are marked "(not in `::gentoo`)"
and still list what they ship. Don't just repeat the package name. Whenever you touch a package (a
bump, a patch, or a routine full pass), check that its line still
describes reality:

- Diff against the corresponding stock Gentoo ebuild (same or nearest
  version, e.g. via `portageq get_repo_path / gentoo` on a Gentoo host),
  the same way as in "When a package no longer needs to live in this
  overlay" above, to see what actually differs from stock right now.
- If the existing entry is still accurate, leave it alone — don't rewrite
  text that's already correct just to reword it.
- If it's stale (e.g. describes a version gap that's since closed, or a
  patch that's since been dropped) or missing, update it to describe the
  current reason for the customization.
- Never replace an existing accurate description with a generic
  placeholder, and never drop an entry for a package that's still in the
  overlay.

### Commit convention

One commit per package bump:

```
<category>/<package>: bump to <newver>
```

A prune-only commit (retention trim with no new version) uses
`<category>/<package>: prune old versions`.

This is a personal single-maintainer overlay — commit straight to
`master` and push directly, no PRs.

### Constraints

- Keep README.md's "Atoms" section in sync with what's actually in the
  overlay: add a line when a package is added, remove its line when a
  package is removed. A version bump alone doesn't need a README
  change.
- Only remove older ebuild versions as the retention rule above
  prescribes (beyond the two latest in the newest major line and the one
latest in each older major line); never more.
- Don't change `KEYWORDS` on the new ebuild beyond what the old one had
  unless the bump is deliberately also a stabilization — that's a
  separate decision, not a routine version bump.
- Keep unrelated cleanups out of a bump commit.
