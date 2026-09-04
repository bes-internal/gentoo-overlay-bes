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

### Commit convention

One commit per package bump:

```
<category>/<package>: bump to <newver>
```

This is a personal single-maintainer overlay — commit straight to
`master` and push directly, no PRs.

### Constraints

- Never remove an older ebuild version as part of a routine bump.
- Don't change `KEYWORDS` on the new ebuild beyond what the old one had
  unless the bump is deliberately also a stabilization — that's a
  separate decision, not a routine version bump.
- Keep unrelated cleanups out of a bump commit.
