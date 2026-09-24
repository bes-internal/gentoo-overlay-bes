---
name: overlay-check
description: Full maintenance pass over this repo — check every tracked package's upstream for a new version, bump/build/test/patch or drop it per AGENTS.md, keep README and -rN revisions correct, then commit and push. Use when asked to "check versions", "update the ebuilds", "run the overlay check", or do a routine maintenance pass on this overlay.
---

# Overlay maintenance pass

This skill operates on whichever checkout of this repo it's invoked
in — don't hardcode a path or hostname anywhere below. If you need the
repo root explicitly, get it with `git rev-parse --show-toplevel`.

**Read `AGENTS.md` at the repo root first, every run** — it is the
source of truth for the tracked-package table, the bump procedure, the
`-rN` rule, the removal criteria, and the commit/README conventions.
This skill is only the driver loop; if it disagrees with AGENTS.md,
AGENTS.md wins.

## 0. Sync with remote

This repo gets worked on from more than one machine/installation, so the
local checkout can be behind before this run even starts:

1. `git status` — if there are uncommitted changes already here (e.g. an
   earlier unfinished run of this skill, or work in progress), stash them
   with `git stash push -u` rather than pulling over them; unstash after
   the pull below succeeds.
2. `git fetch origin`, then fast-forward: `git pull --ff-only origin
   master` (or whatever branch `git status` reports as current). If it's
   not a clean fast-forward (history has diverged), stop and report it —
   don't merge or rebase automatically on a single-maintainer repo, that's
   a human call.
3. Only proceed to step 1 once the checkout is confirmed current with
   `origin`.

## 1. Environment check

- `command -v ebuild` / `command -v eix` — if present, this environment
  can build and query Portage directly; do that.
- If not present, building has to happen on a Gentoo host that has
  this repo registered as a Portage repo. Look for one reachable over
  ssh (check `~/.ssh/config`, shell history, or ask the user once and
  remember the answer for next time) rather than guessing a hostname.
- Either way, don't assume any particular absolute path for the repo
  checkout on that host — `cd` to wherever its checkout actually is.

## 2. Per-package version check

For each row in AGENTS.md's "Per-package upstream feed" table:

1. Fetch the feed and find the highest non-prerelease version (skip
   `-rc`/`beta`/`alpha` unless the package deliberately tracks those).
   - GitHub `*/releases.atom`, Gitea `*/releases.rss`: fetch directly.
   - MetaCPAN (`fastapi.metacpan.org/v1/release/<Dist>`): if a plain
     web fetch gets blocked (e.g. HTTP 402), fall back to `curl` from
     wherever this skill is running, or from the Gentoo host if that's
     the only place with working outbound access.
2. Compare with the highest ebuild in the overlay:
   `ls <category>/<package>/*.ebuild`. `${PV}` excludes any `-rN`.
3. Equal or older upstream -> up to date, note it, next package.

## 3. Newer version found -> decide bump vs. drop vs. skip

Before creating anything, run AGENTS.md's "When a package no longer
needs to live in this overlay" check:

- `eix -e <package>` (wherever Portage is available, per step 1) —
  what does stock `::gentoo` provide now? A `~arch` stock ebuild counts
  as coverage.
- Diff the overlay ebuild against the stock one for the same/nearest
  version (the stock tree's ebuild dir — find it with
  `portageq get_repo_path / gentoo` if you don't already know it).
  Look at `files/`, `IUSE`/USE logic, `src_*`.
- **Identical to stock** (only the version string differs, no added
  patches, no USE/dep/logic changes) **and** stock has an equal-or-newer
  version -> `git rm -r <category>/<package>`, drop its README "Atoms"
  line, drop its row from the AGENTS.md table, delete the now-empty
  dir, commit. Done with this package.
- **Carries real customization** -> keep it; bump as below (rebase the
  customization onto the new version, don't drop it).
- Package not in the overlay at all, stock already covers the new
  version -> nothing to do. If stock is *behind* the new upstream
  release and there's a reason to carry it, that's a new-package
  addition — do it only if the user asked, or ask first.

## 4. Bump procedure

1. `cp <old-highest>.ebuild <cat>/<pkg>/<pkg>-<newver>[-r1].ebuild`
   (`-r1` if the package is customized per AGENTS.md; keep the old
   ebuild, never delete a version during a bump).
2. Edit only what the version requires — `SRC_URI`, `S=`, pinned
   crate/dep versions, `DIST_VERSION`/`DIST_AUTHOR` for perl. Don't
   restructure working logic.
3. `cd <cat>/<pkg> && ebuild <pkg>-<newver>.ebuild manifest` (wherever
   Portage is available, per step 1).
4. Build test the same way:
   `ebuild <pkg>-<newver>.ebuild clean install` (unpack + `src_install`
   into the image dir; never merges into the live system). A plain
   `clean compile` if install is slow and there's nothing install-side
   to check.
5. Build fails on something simple and clearly version-related (renamed
   Makefile var, upstreamed patch that no longer applies, moved config
   option) -> fix it in the new ebuild before its first commit; that
   doesn't add a revision. Non-trivial failure (new deps, real breakage,
   needs a real patch) -> stop on this package, report it, keep going
   with the others.
6. `git add` the new ebuild + Manifest, commit
   `<category>/<package>: bump to <newver>` (+ the standard
   `Co-Authored-By` trailer).

## 5. -rN discipline

The `-rN` rules live in AGENTS.md's "Ebuild revision suffix (-rN)"
section: which new ebuilds start at `-r1`, and when to `git mv` an
already-committed one to add or increment it. Apply them to every new or
changed ebuild in this pass, and name the file accordingly before running
`manifest` and the build test.

## 6. README + repo hygiene (also worth a spot check every run)

- README.md "Atoms" list must match the package dirs that actually
  exist — add a line for a new package, remove one for a dropped
  package. A plain version bump needs no README change.
- Each remaining "Atoms" line should still accurately describe *why*
  that package is customized (newer version than stock, an extra patch,
  an extra USE flag, ...) per AGENTS.md's "Keeping README's 'Atoms'
  descriptions accurate" — diff against stock (same as step 3) and
  update a stale/missing description, but leave an already-accurate one
  alone; never overwrite it with a generic placeholder.
- If a package carries a `files/` patch or a USE/logic delta from stock
  but its highest ebuild has no `-rN`, that's fine only if that ebuild
  has never been revised since first commit — otherwise flag it.
- No stray empty package directories.

## 7. Finish

- One commit per package action (bump / drop / rename), following the
  AGENTS.md commit convention, each ending with the `Co-Authored-By`
  trailer the harness specifies for this session.
- Push: `git push origin master`. If it fails on credentials, that's a
  local git/ssh/token setup issue on whatever machine this is running
  on — fix the local git remote/credential config for that machine,
  don't hardcode a key path or workaround here.
- Report a short summary: bumped / dropped / renamed / already-current /
  failed-and-needs-a-human.

Do the clean, unambiguous work unattended (plain version bumps,
pure-duplicate removals, obvious `-rN` renames). Stop and ask before:
adding a brand-new package, dropping a package that has any
customization, or committing a non-trivial build fix.
