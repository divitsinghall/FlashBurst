# ⚡ FlashBurst: High-Concurrency Inventory Engine

> **A Shopify-style inventory protection system capable of handling 5,000+ concurrent checkout requests with zero overselling.**

### 🛑 The Problem: The "Lost Update"
In standard E-commerce applications (like standard Rails), checking out a hot item creates a race condition.
1. User A checks stock (sees 1).
2. User B checks stock (sees 1).
3. User A buys (stock -> 0).
4. User B buys (stock -> -1). **Overselling occurs.**

### ✅ The Solution: Redis Atomic Lua Scripting
FlashBurst solves this by moving the "source of truth" for inventory to **Redis** during the high-traffic window. It uses a **Lua script** to ensure that the *Check* and the *Decrement* happen in a single, atomic operation that no other request can interrupt.

---

## 🏗 Architecture

[Client] -> [GraphQL API] -> [InventoryService (Redis)] -> [Sidekiq Job] -> [PostgreSQL]

1.  **Gatekeeper:** `InventoryService` attempts to decrement inventory in Redis using Lua.
2.  **Atomic Lock:** If Redis returns `0`, the request is rejected immediately (4ms latency).
3.  **Async Persistence:** If Redis returns `1`, the stock is "reserved", and an `OrderCreationJob` is pushed to Sidekiq to update the persistent Postgres database.

## 🛠 Tech Stack
* **Language:** Ruby 3.x / Rails 8 (API Mode)
* **Concurrency:** Redis (Lua Scripting)
* **Queues:** Sidekiq
* **Database:** PostgreSQL
* **API:** GraphQL (graphql-ruby)

---

## 🚀 How to Verify the Fix

I have included two Rake tasks to demonstrate the difference between "Standard Rails" and "FlashBurst Architecture."

### 1. Simulate the Crash (The "Before")
Spawns 150 concurrent threads trying to buy 100 items using standard ActiveRecord `decrement!`.
```bash
bundle exec rake simulate:race