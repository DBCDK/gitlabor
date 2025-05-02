import Config

config :wallaby,
  driver: Wallaby.Chrome,
  base_url: System.get_env("GITLAB_BASE_URL", "https://gitlab.example.com")

config :tesla, adapter: Tesla.Adapter.Mint
