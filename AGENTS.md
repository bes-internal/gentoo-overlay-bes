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
| www-apps/gitea | https://github.com/go-gitea/gitea/releases.atom | GitHub Atom releases feed |
| www-apps/gitea-runner-bin | https://gitea.com/gitea/runner/releases.rss | Gitea instances expose `<releases-url>.rss` |

General rule for a package not yet in this table: if upstream is on
GitHub, its feed is `<homepage>/releases.atom`; if upstream is on a Gitea
instance, it's `<releases-url>.rss`. Add the new row here when you add
the package.

### Procedure per package

1. Fetch the feed/listing above and find the highest non-prerelease
   version (skip `-rc`, `beta`, `alpha` tags unless the package
   intentionally tracks those, e.g. exim's `_rc`).
2. Compare it against the highest version already in the overlay
   (`ls <category>/<package>/*.ebuild`).
3. No newer version -> skip, nothing to do.
4. Newer version found:
   - `cp <old-highest>.ebuild <category>/<package>/<package>-<newver>.ebuild`.
     Keep the old ebuild(s) in place — never delete an existing version as
     part of a bump.
   - Edit only what the version bump actually requires (SRC_URI, `S=`,
     pinned crate/dependency versions, etc). Don't restructure anything
     that isn't broken.
   - Regenerate the Manifest: `ebuild <new>.ebuild manifest` (needs
     network access to fetch the new distfile).
5. Test the build. This must run on the actual Gentoo host, since
   Portage/emerge lives there, not in the agent's own environment:
   - `ebuild <new>.ebuild clean compile` to build through `src_compile`
     without touching the live system, or `ebuild <new>.ebuild clean
     install` to also run `src_install` into the image dir (still not
     merged into the live system).
6. If the build fails on something simple and clearly version-related
   (a renamed Makefile variable, a patch that's now upstreamed and no
   longer applies, a moved config option, etc.), fix it directly in the
   new ebuild. If the failure is non-trivial (new dependencies, real
   incompatibility, needs an actual new patch), stop and report it —
   don't guess at a real fix.
7. Once it builds cleanly, `git add` the new ebuild + Manifest and
   commit.

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
   "Atoms" section, and delete any now-empty directory left behind.
4. If the overlay ebuild carries real customization (extra patches,
   different USE flags, changed dependencies, altered `src_*` logic),
   keep it even if its version is now behind what stock Gentoo ships —
   the customization is still the reason it's here. Prefer rebasing
   that customization onto the newer version over deleting it.

### Commit convention

One commit per package bump:

```
<category>/<package>: bump to <newver>
```

This is a personal single-maintainer overlay — commit straight to
`master` and push directly, no PRs.

### Constraints

- Keep README.md's "Atoms" section in sync with what's actually in the
  overlay: add a line when a package is added, remove its line when a
  package is removed. A version bump alone doesn't need a README
  change.
- Never remove an older ebuild version as part of a routine bump.
- Don't change `KEYWORDS` on the new ebuild beyond what the old one had
  unless the bump is deliberately also a stabilization — that's a
  separate decision, not a routine version bump.
- Keep unrelated cleanups out of a bump commit.
