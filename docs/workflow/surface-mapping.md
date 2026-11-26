# Surface mapping

**A product is one platform with many surfaces. A feature is never "just the backend" or "just the app."** Before planning or writing code for any change, map every surface it touches across every app and every backend module. Then plan.

The most common defect we've had is not a bug inside one app. It's a missing app: one surface gets updated and its siblings are forgotten.

- A backend field the admin panel never shows.
- A user-app dialog with no admin mirror.
- A new table that the data-wipe tool doesn't know about.
- A changed flow that the QA guide still describes the old way.

## The surfaces

Write your project's list into `AGENTS.md` as a table. Include the surfaces that are easy to forget:

| Surface | What usually ripples |
|---|---|
| Each user-facing app | Screens, strings in every language, right-to-left layout, empty and error states |
| The admin or operator panel | Mirrors of every user-facing shape; ops-only tools |
| The owning backend module | Schema, validation, the function itself |
| **Every other module that reads the changed field** | Shared resolvers, uniqueness checks, indexes, search, scheduled jobs, exports, notifications |
| Data lifecycle tools | The data wipe, retention, seed data, import scripts. A wipe "must account for every table" only if someone updates it. |
| Generated code | API types and clients. Regenerate and commit them; CI checks they're fresh. |
| Messaging and AI | Conversation state, templates, routing, tool definitions |
| Integrations and config | Auth providers, third-party APIs, env vars, and the [side-effect gate](/delivery/environments) for any new outbound send |
| Docs | API reference, flows, engineering pages, **QA test cases** |

## The process

This is mandatory, and it happens **before the plan**, not after.

1. **Send one research sub-agent per surface** that might be affected, in parallel. Don't rely on the surface named in the request. The point is to catch the app or module you'd otherwise forget.
2. **Write a surface map** with a row for every surface, including the honest "no change" rows, so the coverage is visible:

   | Surface | Affected? | Evidence (`file:line`) | What's needed |
   |---|---|---|---|
   | User app | yes | `app/lib/orders/order_screen.dart:88` | Show the new total |
   | Admin panel | yes | `panel/src/orders/OrderRow.tsx:41` | Same field, same format |
   | API: orders module | yes | `api/src/orders/orders.service.ts:120` | Compute and return `totalFils` |
   | API: other readers | yes | `api/src/reports/monthly.ts:57` | Reads the old `total` |
   | Scheduled jobs | no | searched `api/src/jobs/` | |
   | Data wipe | no | no new table | |
   | Generated types | yes | `panel/src/api/generated.ts` | Regenerate |
   | Docs | yes | `docs/api/orders.md`, `docs/qa/test-cases/orders.md` | New field; ORD-014 expected result |
   | Integrations / env | no | no outbound send | |

3. **Only then plan or build.** Every affected surface is in scope for the same change, or explicitly deferred with the user's agreement. Never drop one silently.

## Per-app instructions vs. the whole platform

Nested `CLAUDE.md` files often say "only change files in this app". That conflicts with surface mapping. State the precedence in the root file: *the surface map decides the scope; a nested file's scope rule applies only to work that the map says is app-local.*
