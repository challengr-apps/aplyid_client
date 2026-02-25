import Config

# Configure the APLYiD API client
#
# config :aplyid,
#   environments: [
#     uat: [
#       base_url: "https://integration.aplyid.com",
#       api_key: "your_uat_api_key",
#       api_secret: "your_uat_api_secret"
#     ],
#     production: [
#       base_url: "https://app.aplyid.com",
#       api_key: "your_prod_api_key",
#       api_secret: "your_prod_api_secret"
#     ]
#   ]

config :aplyid,
  environments: [
    uat: [
      base_url: "https://integration.aplyid.com",
      api_key: System.get_env("APLYID_UAT_API_KEY"),
      api_secret: System.get_env("APLYID_UAT_API_SECRET")
    ]
  ]

import_config "#{config_env()}.exs"
