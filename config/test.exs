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
  repo: Aplyid.TestRepo,
  base_url: "http://localhost:4000"

config :aplyid, Aplyid.TestRepo,
  username: "throng",
  password: "gray-goop1!",
  hostname: "127.0.0.1",
  database: "aplyid_test",
  pool: Ecto.Adapters.SQL.Sandbox
