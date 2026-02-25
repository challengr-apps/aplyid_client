import Config

if config_env() == :prod do
  config :aplyid,
    environments: [
      production: [
        base_url: "https://app.aplyid.com",
        api_key: System.get_env("APLYID_API_KEY"),
        api_secret: System.get_env("APLYID_API_SECRET")
      ]
    ]
end
