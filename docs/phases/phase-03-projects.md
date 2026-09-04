# Phase 3 — Projects & chat organization

## Goals

Projects as first-class containers for chats, with project-level default model, memory, and custom context that affect replies.

## Tasks

- [x] Projects CRUD (name, description, default model)
- [x] Assign / move chats in and out of projects
- [x] Project-scoped `MemoryItem` + `ContextDoc`
- [x] Context merge includes project scope when chat is in a project
- [x] Sidebar / UI for project list and project detail

## Acceptance criteria

- User can **move a chat in/out of a project**.
- Project context/memory **affects replies** when the chat is project-scoped.
