# Start ExUnit test runner
ExUnit.start()

# Start Wallaby supervision tree
{:ok, _} = Application.ensure_all_started(:wallaby)

Application.put_env(
  :wallaby,
  :base_url,
  System.get_env("GITLAB_BASE_URL", "https://gitlab.example.com")
)

Application.put_env(
  :wallaby,
  :screenshot_on_failure,
  true
)

Application.put_env(
  :wallaby,
  :max_wait_time,
  15_000
)

# DONT look at me like that! We're testing GitLab, not something that actual is
# expected to work... This is just how it is.  Radical Acceptance or something.
Application.put_env(:wallaby, :js_errors, false)
Application.put_env(:wallaby, :js_logger, false)
