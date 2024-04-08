# Suma Analytics Tables

Suma's database includes analytics tables, which are denormalized from transactional data.

- Analytics models are like normal models, backed by actual tables and managed by migrations.
- In theory we could use views, but in practice, our domain model is sufficiently complex
  that it would require a large duplication of application logic into SQL queries.
- This is prohibitive for small orgs without dedicated analyists,
  so a trigger-based system that is part of the application leverages all the domain modeling work
  that has been done.

The analytics tables are all in the `analytics` schema,
and defaults to the same database as transactional data.
Set `ANALYTICS_DATABASE_URL` to choose a different database.

For every model event (`suma.member.created`, etc), we find all analytics models that depend on it,
and upsert the relevant rows. For example, when an order is created,
we upsert a row into `analytics.orders`, a row for each order item into `analytics.order_items`,
and upsert the `order_count` column of `analytics.members` for the member who placed the order.

See `Suma::Analytics` for code related to analytics.
See `suma/analytics/model.rb` for instructions on creating analytics models.
Run `make analytics-reimport` to truncate and recreate all analytics tables.
