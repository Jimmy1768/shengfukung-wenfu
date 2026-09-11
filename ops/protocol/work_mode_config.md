# Work Mode Config

How work is done here, independent of which agent is doing it. Nothing in this
file is about Claude Code. If a rule only makes sense because of a particular
tool, it belongs in a `claude_` file instead — that prefix is the boundary.

What applies to one repository and not another is in `repo_context.md`.

## Committing

**Commit with an explicit pathspec. Never `git add -A`.** `git commit` takes
the whole index rather than the paths you had in mind, so a file staged by
someone else rides into your commit under a message describing something else.
Check with `git diff --cached` before committing that the index holds your
paths and nothing else.

Commit your own work. Do not commit someone else's, and do not wait on them to
commit yours.

**The pathspec has two holes, and both appear only when a file enters or leaves
the tree rather than changing in place.**

- **A rename needs both paths named.** `git mv` stages a deletion and an
  addition; naming only the new path commits the addition and leaves the
  deletion staged, so both files sit in `HEAD` together.
- **A new file needs `git add <path>` first.** `git commit <pathspec>` cannot
  name a file git does not know about — it fails with *pathspec did not match
  any file(s) known to git*.

Hitting either under time pressure is what makes `git add -A` look like the way
out, which is the thing this rule exists to prevent.

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

**Not yours to touch and safe to leave are two different findings.** Declining
to act settles the first and says nothing about the second, but a report that
gives only the decline reads as though it settled both. When you leave
something alone, say what it is as well as why you left it — and if you have
not looked closely enough to say, report that instead of implying it is
ordinary.

**State read at two moments is not one observation.** Reporting a commit read
at the start of a turn alongside a digest read at the end presents as fact
something that was never true at either moment. When you report what a
repository or another session holds, read it in one pass, and say when you read
it.

**A negative result from a query you constructed is evidence about the query
first.** A grep that returns nothing has told you the pattern did not match, not
that the thing is absent — it may be wrapped across a line, spelled differently,
or two lines from where you looked. A listing you capped at four has told you
about the cap. Before reporting an absence, change the query and look again.

**A check that cannot fail is not evidence.** That query is the narrow case;
this is the class. **The test is what result would have contradicted it** — if
nothing could have, you have a statement rather than a measurement, and a check
with nothing to disagree with is unfalsifiable rather than correct. Two
instances: `grep … | sed … && echo FOUND` always prints FOUND, because a
pipeline's exit status is the last command's and `sed` returns zero whatever it
read; and a digest you supplied and got back matches by construction, telling
you the file has not changed since you hashed it rather than that it is the
file the sender meant. Neither was built so it could come out the other way.
Where a constructed check does contradict a passing suite, suspect the check.

**A digest confirms stability and a description confirms identity.** Compute
the digest from your own copy, and read the sender's description of what
changed against the diff. Only the pair is worth anything: one repository
caught a real mismatch on the digest alone, where the description was accurate
and could not have caught it, and two caught defects on the description alone,
where the digests matched cleanly. Neither half has a better record than the
other.

**A summary displaces the evidence it stands on.** A script printed `applies
cleanly` on the same screen as `error: patch does not apply`, and `passwordless
sudo available` directly beneath `sudo: a password is required`. The true
answer was one line up both times. This is not that summaries are wrong — it is
that they are read last and remembered first, so a confident one survives the
output contradicting it. **A correct check has the same property:** `all 58
assets resolved 200` displaces the 58 lines above it whether or not it could
have failed.

It goes one step further where the reader is a person: a reported check
displaces the evidence beside it, and a reported conclusion displaces the
check. *Verified three ways*, where the three were one query run three times,
reaches a decision intact because nothing in the sentence shows the difference.
Print the value you computed beside the value you expected, rather than
`match`.

Phases in a plan doc are organization, not gates. An accepted plan is accepted
whole.
