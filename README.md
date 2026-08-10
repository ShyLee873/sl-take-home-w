# Waymark Junior Software Engineer — Take-Home Assessment

Welcome! This exercise gives you a chance to show us how you think and how you build. There are no trick questions and no single correct answer. We're interested in the decisions you make and how you reason about them.

**Time box:** Plan for roughly four hours. We're not timing you, but this is the scope we designed for. A focused, incomplete solution with a thoughtful README is more valuable to us than an exhaustive one with no explanation.

---

## The Scenario

Build a small Elixir application that processes work items asynchronously. The application should consume messages from a RabbitMQ queue, process each item using a GenServer-backed worker, and persist results to a PostgreSQL database.

**The domain is yours to choose.** Pick something that makes the data model feel real to you: a job queue, a notification dispatcher, an order processor, a sensor event pipeline. We've intentionally left this open because we're more interested in *how* you build it than *what* it does.

---

## Requirements

Your submission must include all of the following:

1. **A working Elixir OTP application**
   - Phoenix is not required. A plain Mix application is fine.
   - The application should start cleanly and process messages end-to-end.

2. **A RabbitMQ consumer backed by a GenServer worker**
   - Messages arrive on the `work-inbound` queue (see infrastructure below).
   - A GenServer (or pool of GenServers) should handle processing of each message.
   - Internally we use [Lapin](https://github.com/lbonn/lapin), but the choice is yours. [Broadway RabbitMQ](https://github.com/dashbitco/broadway_rabbitmq) and the [amqp](https://github.com/pma/amqp) library are both popular options.

3. **A PostgreSQL schema with at least one Ecto migration**
   - Define the entities your domain needs.
   - Schema should reflect real relational thinking: primary keys, foreign keys where appropriate, sensible column types.

4. **A Git repository with an incremental commit history**
   - Work in commits that tell the story of how you built the thing.

5. **A README in your repository**
   - How to run your application against the provided infrastructure.
   - The design decisions you made and why.
   - What you would do differently or build next with more time.

---

## A Note on AI Tooling

At Waymark, we think of software as a craft. AI tooling, used thoughtfully, is part of that craft. It can surface edge cases, suggest cleaner patterns, and push you toward better solutions. We're interested in whether you use your tools to produce work you're proud of, not just work you produced quickly.

You're welcome and encouraged to use whatever AI tools you reach for day-to-day. There are no restrictions.

The follow-up interview will include a walkthrough of your solution. You should be able to speak to every decision: why you structured things the way you did, which tools you used and why you chose them, and what trade-offs you considered. The goal is a conversation about craft, not a quiz.

---

## Getting Started

### Prerequisites

- [Elixir](https://elixir-lang.org/install.html) (latest stable)
- [Taskfile](https://taskfile.dev/installation/)
- [Docker](https://docs.docker.com/get-docker/)

### Bringing Up Infrastructure

From the root of this repository:

```
task init
```

This will start PostgreSQL and RabbitMQ in Docker and initialize the RabbitMQ vhost, user, exchange, and queue your application will connect to.

To tear everything down and start fresh:

```
task destroy
task init
```

To see all available tasks:

```
task -l
```

### Connection Details

**PostgreSQL**
- Host: `localhost`
- Port: `5433`
- User: `postgres`
- Password: `postgres`

**RabbitMQ**
- AMQP Port: `5672` (non-TLS)
- App credentials: user `app_user`, password `rabbitmq`
- Vhost: `homework`
- Exchange: `waymark` (direct)
- Queue: `work-inbound`
- Routing key: `inbound`

**RabbitMQ Management UI**
```
task rabbitmq:ui
```

### Test Data

You are responsible for publishing any test messages your application needs. The RabbitMQ management UI and `rabbitmqadmin` CLI (available inside the container) are both useful for this. You may also add a Taskfile task or Mix task to seed messages, whatever fits your workflow.

---

## Submission

Please send us:

1. A link to your Git repository (GitHub, GitLab, or similar).
2. Confirm your README covers how to run it, your design decisions, and next steps.

Do not deploy the project publicly. We'd prefer this exercise stays fresh for future candidates.

---

## FAQ

**What is the purpose of this exercise?**

We want to see how you approach building a small but real system. We'll use your submission as the starting point for a technical conversation during the interview, not as a pass/fail gate.

**Can I make assumptions?**

Yes. Where requirements are ambiguous, make a decision and document it in your README. You're welcome to reach out with questions too.

**Do I need to deploy it?**

No. Please don't — see above.

**Are there coding standards I need to follow?**

No strict standards. Write idiomatic Elixir as best you understand it, and show your own style. We're more interested in clarity and reasoning than adherence to any particular convention.

**What if I've never used RabbitMQ before?**

That's fine — we don't expect prior experience. The infrastructure is already configured for you. Internally we use [Lapin](https://github.com/lbonn/lapin), but you're free to use whatever library works for you. [Broadway RabbitMQ](https://github.com/dashbitco/broadway_rabbitmq) and the [amqp](https://github.com/pma/amqp) library are both popular options. The RabbitMQ management UI at `http://localhost:15672` is helpful for inspecting queues and publishing test messages manually.

**What if I've never used Elixir before?**

Also fine — the job description says no prior Elixir experience required, and we mean it. Show us how you learn and reason. A partial solution with a clear explanation of where you got stuck is genuinely useful to us.
