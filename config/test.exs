import Config

config :live_query, repo: LiveQuery.TestRepo

config :live_query, LiveQuery.TestEndpoint,
  secret_key_base: "kjoy3o1zeidquwy1398juxzldjlksahdk3",
  live_view: [signing_salt: "FwuDKzc6D9-jxgIG"]
