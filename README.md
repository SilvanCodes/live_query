# LiveQuery

LiveQuery shall bring the power of GQL-Subscriptions to Phoenix via the combination of the PostgreSQL TRIGGER/NOTIFY/LISTEN features.

It enables to show the user fresh database state without manual wiring by passing down fresh query results to the UI once they are available.

## What options do I know of to build reactive UI in Phoenix?

Well, Phoenix.LiveView is reactive and re-renders when state on the socket changes.
But it lacks the information if data in the database has changed.

Phoenix.PubSub enables reacting to even global live state changes.
Still it is not connected to the database layer.

## What do we need to do?

We need to automatically listen to relevant topics in the correct places.

We need to setup TRIGGER/NOTIFY calls with appropriate topics ande messages.

## How do we do it?

### Sketch #1

We could build a dependency graph for all live queries in the application.
We could then hash each query to directly use the query hash at the notification topic.
We could then build the triggers with notifications to each query hash directly.

This would be a very static, upfront setup. It could not easily be changed after application startup.
This would leverage the build-in notification deduplication for transactions in postgres.

### Sketch #2

We could collect all tables that are part of live queries.
We could then setup triggers for updates on the topic of the table name via migrations.
That would be static setup.

If every live query would listen to notifications of every table it depends on it is possible that it receives several notifications after transactions are commited.
Either the cost for multiple queries occurs of which only the first is useful (is it costly when is is exactly the same query?) or debouncing/deduplication has to be handled by LiveQuery.


## MVP

MVP is to state tables a LiveView uses to fetch its data and receive notifications about changes once the data in taht tables was touched.

Create [TRIGGER](https://www.postgresql.org/docs/current/sql-createtrigger.html)/[NOTIFY](https://www.postgresql.org/docs/current/sql-notify.html) and according [trigger function](https://www.postgresql.org/docs/current/plpgsql-trigger.html) via [Ecto.Migration.execute/2](https://hexdocs.pm/ecto_sql/Ecto.Migration.html#execute/2)

Have a process manage all LISTEN via [Postgrex.Notifications.listen/2](https://hexdocs.pm/postgrex/Postgrex.Notifications.html#listen/3)

Distribute notifications from PostgreSQL via [Phoenix.PubSub.broadcast/3](https://hexdocs.pm/phoenix_pubsub/Phoenix.PubSub.html#broadcast/4)

PostgreSQL-Channel-Name is table name.
Phoenix.PubSub topic is table name.

Requires explicitly listing all tables relevant to a LiveView's data.

```elixir
use LiveQuery.Notifications, for: ["users", "posts"]
```

Create mix task to generate migration from listed tables.

Create `LiveQuery.Listener` module to handle subscriptions

- checks for existence of triggers, errors/warns otherwise
- monitors LiveViews to automatically issue unlisten
- publishes notifications via PubSub

### Architecture

Before runtime:
Mix task => Migration

At runtime:
                                          +--------------Elixir/Phoenix----------------------------------------------------------------+
                                          | LiveViews mount +=> ask to register LISTEN => warning/error when table listener not set up |
                                          |                 |                                                                          |
                                          |                 +=> subscribe to PubSub                                                    |
                                          |                                                                                            |
+--------------Database--------------+    |                                                                                            |
| tables change => TRIGGER => NOTIFY | => | LISTEN => (debounce) => PubSub => LiveViews get notification                               |
+------------------------------------+    +--------------------------------------------------------------------------------------------+

### Stuff

```shell
mix do live_query.gen.migration, ecto.migrate
```
aliased as
```shell
mix live_query.migrate
```

How to track when new tables are listed in any `tables` list?

How to rollback outdated triggers?

How to only create new triggers?

=> DELETE all old triggers in every migration

Possible solution: Never write out migrations, only generate and apply them at application startup.

Initial solution: Create all triggers for currently listed tables on every live_query.migrate call.

How to remind devs to run live_query.migrate when tables have changed?

=> when listen call is issued, check if DB contains corresponding trigger


```elixir
def handle_info({live_query: update}, socket) do
  # react to changes in database

  {:noreply, socket}
end
```

## Questions

What would it cost to blantly setup TRIGGER/NOTIFY for every database table?
=> disregarded

What is the cost of having many listeners for one NOTIFY call?
=> Postgrex.Notifications only sets up one LISTEN per channels, then broadcasts to any listening process


## What do we build on?

Postgrex.Notifications gives us one part of the puzzle. (LISTEN)


## FollowUp: LiveForm
