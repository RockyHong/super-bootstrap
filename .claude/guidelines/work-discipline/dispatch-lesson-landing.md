# Dispatch Lesson Landing — A Lesson Lands at Its Home, Not in the Report

A dispatched worker that has to discover something — a retry that worked, a
workaround, a tool or vendor quirk — holds a lesson the next reader of that
surface needs. Where the lesson's home is one code site, workers already land
it: a comment at the workaround rides the diff. Where its home is a doc — the
lesson spans surfaces, or belongs to a gotchas list, a spec, a setup note —
workers write it into their report and stop. The report is a message: it dies
with the dispatch, and the next dispatch rediscovers the lesson from scratch.

- **Demand in the brief that each lesson land at its home inside the diff** —
  a comment at the code site it belongs to, a line in the doc that owns the
  surface when it spans more than one. Name the doc the lesson should land in
  when the brief already knows it; otherwise the worker picks the doc a later
  reader of that surface opens first. Have the brief ask the worker to list
  its discovered lessons under a fixed report heading.
- **Read the returned report for lessons before the commit** — any retry,
  workaround or quirk the report narrates that the diff does not carry, the
  gateway writes at its home in the same commit. A lesson whose home sits in
  another repo: surface it to the user as a one-line note naming the repo.

Family catalog: [`index.md`](index.md).
