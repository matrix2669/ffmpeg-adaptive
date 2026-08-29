# Release process

No tag or GitHub Release is created by repository bootstrap.

## Version rules

- Use Semantic Versioning in `VERSION`; prefix tags with `v`.
- Beta builds use `MAJOR.MINOR.PATCH-beta.N` on tested `dev` commits.
- Stable releases use `MAJOR.MINOR.PATCH` on `main`.
- Keep `VERSION`, the version in `ffmpeg-smart.sh`, the changelog section, tag,
  release title, artifact name, and checksum synchronized.
- Never move a published tag or replace a published artifact.

## Required release gates

1. Reconcile the current workspace standards.
2. Complete decision closure and resolve all contradictions.
3. Run `./scripts/validate.sh`.
4. Repeat applicable software, hardware, Docker/LXC, live-stream, `pipe:0`,
   cache migration, concurrency, and performance tests.
5. Re-run the current-tree provenance audit against the recorded unlicensed
   baseline and upstream source. Review exact and near-identical blocks,
   third-party notices, generated artifacts, and every file added since the
   last audit.
6. Verify the release tree contains only material the project may distribute
   under MIT and that `LICENSE` and `PROVENANCE.md` are accurate.
7. Build an installable archive from the exact release commit, excluding Git
   history and runtime state. Inspect its contents and calculate SHA-256.

## Beta release

After the gates pass, version and tag the exact tested `dev` commit. A beta may
be published as a GitHub prerelease only with explicit approval.

## Stable release

Promote the exact tested code to `main`, finalize the matching stable version,
repeat the gates, create the immutable stable tag, and publish a normal GitHub
Release with the inspected archive and checksum. GitHub's automatic source
archives do not replace the project-specific package.

Downstream plugin synchronization, registry changes, installation, and
deployment are separate approval and validation gates.
