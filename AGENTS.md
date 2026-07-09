# Musical Instrument App - Agent Handoff

## Collaboration Rules

- The user prefers step-by-step guidance.
- Do not edit files unless the user explicitly asks you to edit files.
- When the user asks for code but does not explicitly allow edits, write code snippets in chat only.
- Before making code changes, inspect the relevant files first and explain what you are about to change.
- Keep changes scoped. Do not refactor unrelated modules.
- Use TypeScript/Express/PostgreSQL/Prisma patterns already present in the backend.
- Prefer `rg`/`rg --files` for searching.
- Run `npm run build` in `backend` after backend changes when feasible.

## Current Direction

The original idea was a mobile app for musical instruments that could use YouTube/MP4 and transform songs into instrument versions. That direction was paused because it introduces high cost and complexity:

- audio processing
- music transcription
- MIDI generation
- media storage
- YouTube/bopyright policy risk
- cloud costs

The product is pivoting to a lower-cost idea:

## New Product: Music Practice Tracker

Goal:

Help users learning musical instruments manage practice sessions, track progress, keep streaks, follow goals, and unlock premium learning content through VIP.

Core idea:

- No AI required.
- No YouTube processing.
- No heavy media storage.
- No audio conversion worker for MVP.
- Keep costs close to free.

## Stack

- Mobile: Flutter
- Backend: Node.js + Express + TypeScript
- Database: PostgreSQL
- ORM: Prisma
- Admin: backend admin APIs first, admin dashboard UI later

## Existing Backend Concepts To Keep

Keep and evolve:

- `users`
- `instruments`
- `vip_plans`
- `subscriptions`
- `payments`
- `chat_messages`
- auth/JWT
- admin middleware and admin APIs
- rule-based support chatbot

Likely pause/remove from the new MVP:

- `media_items`
- `processing_jobs`
- `generated_tracks`
- `youtube`
- upload/storage work
- audio processing work

Do not delete these immediately unless the user explicitly asks. Treat them as paused/legacy modules until the new schema is settled.

## VIP Business Rule

VIP is one entitlement that unlocks premium app features.

Fixed billing plans:

- `VIP_MONTHLY`: 30 days
- `VIP_YEARLY`: 365 days

Both plans unlock the same VIP entitlement. The difference is duration and price.

Admin may edit display/pricing fields:

- `name`
- `description`
- `price`
- `currency`
- `features`
- `status`

Admin should not edit:

- `code`
- `duration_days`

## Suggested New MVP Features

User-facing:

- register/login
- select instruments being practiced
- start/end practice timer
- create practice session notes
- view practice history
- view daily/weekly/monthly totals
- create practice goals
- track streaks
- browse free lessons/chords/scales
- unlock premium lessons/chords/scales with VIP
- ask rule-based support chatbot

Admin-facing:

- dashboard
- users
- instruments
- VIP plans
- payments
- subscriptions
- lessons/chords/scales management

## Proposed New Tables

Add later after design is confirmed:

- `practice_sessions`
- `practice_goals`
- `lesson_categories`
- `lessons`
- `user_lesson_progress`
- `chords`
- `scales`

Draft meanings:

- `practice_sessions`: one completed or active user practice session
- `practice_goals`: user goals such as 30 minutes/day or 5 days/week
- `lesson_categories`: groups such as Beginner Guitar, Piano Basics, Rhythm
- `lessons`: learning content, free or VIP
- `user_lesson_progress`: completed/in-progress lesson tracking
- `chords`: chord library
- `scales`: scale library

## Recommended Next Step

Do not continue audio processing/storage work.

Next planning step:

Design the database schema for Music Practice Tracker while reusing existing `users`, `instruments`, `vip_plans`, `subscriptions`, `payments`, and `chat_messages`.

Then implement backend modules in this order:

1. `practice_sessions`
2. `practice_goals`
3. `lessons`
4. `user_lesson_progress`
5. admin lesson/chord/scale management
6. Flutter MVP screens

## Notes For Future Agents

- The user may be low on quota and may move between coding agents.
- Be concise but preserve context.
- If the user asks "what are we building?", answer: a Music Practice Tracker for instrument learners.
- If the user asks to resume old YouTube/audio-conversion work, mention the cost/legal/complexity risks and confirm before proceeding.
- The user cares about keeping development cost free or near-free.
