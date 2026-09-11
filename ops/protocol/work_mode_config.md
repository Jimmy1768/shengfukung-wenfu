# Work Mode Config

How work is done here, independent of which agent is doing it. Nothing in this
file is about Claude Code. If a rule only makes sense because of a particular
tool, it belongs in a `claude_` file instead — that prefix is the boundary.

What applies to one repository and not another is in `repo_context.md`.

## Committing

**Commit with an explicit pathspec. Never `git add -A`.** `git commit` takes
the whole index rather than the paths you had in mind, so a file staged by
someone else rides into your commit under a message describing something else.
Check the index before committing.

Commit your own work. Do not commit someone else's, and do not wait on them to
commit yours.

**When committing a rename, name both paths.** `git mv` stages a deletion and
an addition. A pathspec naming only the new path commits the addition and
leaves the deletion staged, so both files sit in `HEAD` together.

## Branches

Each task gets its own branch, cut from `main` at a named commit:
`git checkout -b <name> <base>`. Name the base explicitly.

**Work that turns out wrong is deleted, not reverted.** `git branch -D`. No
revert commit, no rollback, `main` never dirtied. That is the reason each task
gets a branch rather than committing to a long-lived one.

Green means merge. Green is not judgement: the task names exact check commands
and their expected exit codes.

Who may merge, and how work reaches production, depend on how the repository is
laid out. Both are in `repo_context.md`.

## Documents

- **Plan docs** record intent at planning time. They drift and are not
  maintained.
- **Reference docs** describe what is currently true, and are maintained.

A plan doc for work being built now rides on the branch with that
implementation. A plan for work not yet started belongs on `main`.

When an implementation merges, in that same merge: **distil** durable facts
into the reference doc first — precondition, not follow-up; **delete** the plan
doc; **name it in the merge commit**, which is how it is recovered.

**No archive directory.** Archived files are read by nobody and returned by
every grep, mixing what was true once with what is true now.

Fix dangling links when you delete. A prose mention that something was retired
is fine; a link to a file that no longer exists is not.

## Databases

Use the development database. Do not create one per task or per worktree — it
multiplies setup, leaves stale databases behind, and obscures which one a
failure came from.

A normal task does not touch production. If a task requires production access,
it is different work: say so and stop.

**Production is remote.** A production branch is checked out on its server, not
on this machine, and nothing is served locally. A local checkout sitting on a
production branch is serving nothing, so moving it costs nothing — the live
deployment is untouched either way.

## Before editing a contract-tested file

Some files are pinned by tests — an exact phrase asserted, or a digest in a
manifest. Search the **whole repository** for the filename first:

```
grep -rl "<filename>" . --exclude-dir=.git --exclude-dir=worktrees --exclude-dir=node_modules
```

Not just test directories. Digest pins live in manifests outside the test tree,
so a test-only search finds the spec and misses the manifest. Regenerate
digests last.

**A file that is copied into several repositories is pinned from all of them.**
Searching the repository you are standing in finds nothing, because the
assertion lives in one of the others. Search every repository that holds a copy
before editing one.

## Scope

Autonomy is granted for a **kind of work**, not a list of permitted actions.
Inside the delegated kind, proceed without asking. The question is not "is this
allowed?" but **"is this still the work that was asked for?"**

**An action you generated yourself needs the Director.** Two tests: did anyone
ask for this specific thing, or did I decide it was a good idea? Am I acting on
a conclusion I reached moments ago?

**A finding that implies work elsewhere is reported, never acted on.** The tell
is that nobody asked for the second thing.

**State read at two moments is not one observation.** Reporting a commit read
at the start of a turn alongside a digest read at the end presents as fact
something that was never true at either moment. When you report what a
repository or another session holds, read it in one pass, and say when you read
it.

Phases in a plan doc are organization, not gates. An accepted plan is accepted
whole.
