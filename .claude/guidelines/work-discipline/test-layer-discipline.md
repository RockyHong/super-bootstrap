# Test Layer Discipline — The Cheapest Rung That Can Go Red

A suite grows by addition and never by subtraction. Each change arrives
with a check written on whichever layer its author was already standing
on, and the rung that drives the whole assembled system is the one that
looks most convincing on arrival — so the expensive layer accumulates by
default, chosen once by whoever was closest and billed on every run
afterwards to everyone. Nothing in that loop prices the choice, and the
next reader meets the accumulation and extends it. What follows governs
which rung an assertion is written on and which checks a given change
runs; whether a check can discriminate pass from fail at all is a
separate concern, owned by
[`dispatch-brief-demands.md`](dispatch-brief-demands.md).

- **Write each assertion on the cheapest layer that can prove it** —
  walk up from the bottom rung and stop at the first one that can
  actually go red on the defect in question. A higher rung proving the
  same thing adds no proof and charges its full cost on every run from
  then on, so the assertion belongs where the failure first becomes
  visible, not where it is most visible.
- **Let a breakage class earn the expensive rung** — a feature does not
  earn one by existing. The top rung is bought for the failures a person
  meets but cannot attribute to a cause: wiring that exists only once
  the parts are assembled, ordering that appears only under a real run.
  Attribution is precisely what the cheap rung cannot hand back, and it
  is the whole of what the price buys.
- **Assert each fact exactly once** — judge overlap by whether two
  checks assert the same fact, not by whether they exercise the same
  object. Two checks reading one fact through different paths drift
  apart, and the suite then holds two answers to one question with
  nothing in it to say which answer is current. Two checks on one object
  asserting different facts are not overlap, and both stay.
- **Derive the set to run from what the change touches** — the set
  follows the change, not the preference of whoever is running it. An
  actor choosing its own set has no cheap way to know what it may safely
  leave out, so it falls back on the whole roster; deriving the set
  instead is what makes a run scale with the size of the change rather
  than with the size of the suite.
- **Carry proof already earned across by equivalence** — when a change
  lands an artifact a test already ran (a prototype, a scratch script, a
  patched trial), its check is that the landed artifact matches the
  persisted tested artifact, differences limited to the deltas the change
  lists. The expensive run is kept for what equivalence cannot show:
  each listed delta's behaviour, which counts as untested, and contracts
  that exist only at runtime. Absent a persisted tested artifact, the
  check falls back to execution.
  Re-running tested behaviour adds no proof the equivalence check lacks
  and pays the full price again. Equivalence needs the tested artifact
  itself, so whoever runs the test persists it then, in the form the
  checker reads — a runtime's own record of the run is shaped for the
  runtime, not for a checker, and may omit content. Whoever sets a
  change's checks — the actor, or the brief that dispatches it — names
  which are equivalence and which are execution.
