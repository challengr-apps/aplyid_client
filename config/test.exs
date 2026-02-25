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
