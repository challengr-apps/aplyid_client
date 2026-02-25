import Config

config :aplyid,
  environments: [
    uat: [
      base_url: "http://localhost",
      api_key: "test_api_key",
      api_secret: "test_api_secret"
    ],
    production: [
      base_url: "http://localhost",
      api_key: "test_prod_api_key",
      api_secret: "test_prod_api_secret"
    ]
  ]

config :aplyid, :mock_server,
  enabled: true,
  embedded: true,
  repo: Aplyid.TestRepo

config :aplyid, Aplyid.TestRepo,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  database: "aplyid_test",
  pool: Ecto.Adapters.SQL.Sandbox
