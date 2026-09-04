# Phase 4 — Nested plans/courses + progress

## Goals

Deeply nested plan/course trees with progress, reorder, plan-scoped chats, and ancestor context/memory inheritance.

## Tasks

- [x] `PlanNode` tree UI (infinite nesting via `parentId`)
- [x] Progress `0..100`, status, order / reorder
- [x] Manual plan edit
- [x] Plan-scoped chats (`planNodeId`)
- [x] Inherit memory/context up the ancestor chain into merge order
- [x] “Open plan chat” entry from a node

## Acceptance criteria

- Multi-level course/plan tree works end-to-end.
- Plan-scoped chat receives inherited ancestor + plan context correctly.
