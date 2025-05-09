defmodule Gitlabor.Features.GitlabMrTest do
  use ExUnit.Case, async: false

  use Wallaby.Feature

  import Wallaby.Query

  require Logger

  @vault_token_path "~/.vault-token"

  # Erlang Term Storage Table
  @table_name :screenshot_state_table
  @counter_key :global_screenshot_count

  defp ets_setup do
    if :ets.whereis(@table_name) == :undefined do
      :ets.new(@table_name, [
        :set,
        :public,
        :named_table,
        write_concurrency: true,
        read_concurrency: true
      ])

      :ets.insert(@table_name, {@counter_key, 0})
    end

    :ok
  end

  defp screenshot_increment do
    :ets.update_counter(@table_name, @counter_key, {2, 1, 0})
    :ets.update_counter(@table_name, @counter_key, {2, 1})
  rescue
    ArgumentError ->
      ets_setup()
      :ets.update_counter(@table_name, @counter_key, {2, 1})
  end

  defp screenshot_counter_value do
    case :ets.lookup(@table_name, @counter_key) do
      [{@counter_key, val}] ->
        val

      [] ->
        ets_setup()
        0
    end
  end

  defp _screenshot_ets_cleanup do
    :ets.delete(@table_name)
  end

  # This reads the local vault token from the users home directory. This requires
  # that the token has actually been initialized, and doesn't provide much value
  # if the token is stale.
  defp read_vault_token do
    # Expand the path (replace ~ with the actual home directory)
    path = Path.expand(@vault_token_path)

    case File.read(path) do
      {:ok, binary_content} ->
        token = String.trim(binary_content)
        {:ok, token}

      {:error, reason} ->
        IO.inspect({:error, "Failed to read vault token at #{path}: #{inspect(reason)}"},
          label: "Vault Read Error"
        )

        {:error, reason}
    end
  end

  # This queries the Vault V1 API for the GitLab bot's password.
  defp vault_read_bot_password(token) do
    client =
      Tesla.client([
        {Tesla.Middleware.BaseUrl, System.get_env("VAULT_ADDR")},
        Tesla.Middleware.JSON
      ])

    Tesla.request!(client, [
      {:url, "/v1/kv/data/platform-vault-secrets/gitlab-t01/gitlabor-pw"},
      {:method, :get},
      {:headers, [{"X-Vault-Token", token}]}
    ])
    |> get_in([
      Access.key!(:body),
      Access.key!("data"),
      Access.key!("data"),
      Access.key!("value")
    ])
  end

  setup %{session: session} do
    Logger.info("Running test setup", session: session)
    Logger.info("Reading GITLAB_TEST_USERNAME", session: session)
    gitlab_user = System.get_env("GITLAB_TEST_USERNAME")

    Logger.info("Reading vault token", session: session)
    {:ok, token} = read_vault_token()
    Logger.info("Using token to get password", session: session, user: gitlab_user)
    gitlab_pass = vault_read_bot_password(token)
    Logger.info("gitlab_pass set", session: session)

    Logger.info("Reading GITLAB_TEST_PROJECT_PATH", session: session)
    project_path = System.get_env("GITLAB_TEST_PROJECT_PATH")

    Logger.info("Reading GITLAB_TEST_TARGET_BRANCH", session: session)
    target_branch = System.get_env("GITLAB_TEST_TARGET_BRANCH", "main")

    source_branch = "gitlabor-test-#{UUID.uuid4()}"
    Logger.info("Generated source_branch", session: session, branch: source_branch)

    if is_nil(gitlab_user) or String.length(gitlab_user) == 0 or
         is_nil(gitlab_pass) or String.length(gitlab_pass) == 0 do
      flunk("""
      GitLab test credentials not configured correctly in config or env vars.
      Checked :gitlabor, :gitlab_credentials.
      Ensure GITLAB_TEST_USERNAME and GITLAB_TEST_PASSWORD env vars are set.
      """)
    end

    if is_nil(project_path) or String.length(project_path) == 0 or
         is_nil(target_branch) or String.length(target_branch) == 0 do
      flunk("""
      GitLab test target details not configured correctly in config or env vars.
      Checked :gitlabor, :gitlab_test_target.
      Ensure GITLAB_TEST_PROJECT_PATH, GITLAB_TEST_SOURCE_BRANCH,
      and GITLAB_TEST_TARGET_BRANCH env vars are set.
      """)
    end

    {:ok,
     session: session,
     gitlab_user: gitlab_user,
     gitlab_pass: gitlab_pass,
     project_path: project_path,
     source_branch: source_branch,
     target_branch: target_branch}
  end

  defp sleep(session, duration_ms) do
    Logger.info("Sleeping for #{duration_ms}ms", session: session, duration_ms: duration_ms)
    Process.sleep(duration_ms)
    session
  end

  # Since `tap` can't be expected to not modify state (for some reason...), we'll
  # just roll our own!
  #
  # This currently doesn't support overloading the logger with metadata... which
  # is tolerable.
  defp logtee(session, logger, message) do
    logger.(message)
    message = "#{screenshot_counter_value()}_#{message |> String.replace(" ", "_")}"
    session |> take_screenshot([{:name, message}])
    screenshot_increment()
    session
  end

  feature "GitLab Merge Request creation check", %{
    session: session,
    gitlab_user: user,
    gitlab_pass: pass,
    project_path: proj_path,
    source_branch: src_branch,
    target_branch: _tgt_branch
  } do
    ets_setup()

    session
    |> logtee(&Logger.info(&1), "Start \"GitLab Merge Request creation check\" test")

    # --- Login ---
    |> logtee(&Logger.info(&1), "Visit /users/sign_in")
    |> visit("/users/sign_in")
    |> logtee(&Logger.info(&1), "Check page has a GitLab title")
    |> assert_has(css("h1", text: "GitLab"))
    |> logtee(&Logger.info(&1), "Open Standard Login (i.e. not LDAP)")
    |> click(css("#gl_tab_nav__tab_2"))
    |> logtee(&Logger.info(&1), "Write username")
    |> fill_in(css("#user_login"), with: user)
    |> logtee(&Logger.info(&1), "Write password")
    |> fill_in(css("#user_password"), with: pass)
    |> logtee(&Logger.info(&1), "Click Login button")
    |> click(css("button.gl-button:nth-child(6)"))
    |> logtee(&Logger.info(&1), "Assert we're logged in (can see our user avatar)")
    |> assert_has(css("img.gl-avatar"))

    # --- Create Test Branch
    |> logtee(&Logger.info(&1), "Visit /#{proj_path}/-/branches/new")
    |> visit("/#{proj_path}/-/branches/new")
    |> logtee(&Logger.info(&1), "Write Branch Name")
    |> fill_in(css("#branch_name"), with: src_branch)
    |> logtee(&Logger.info(&1), "Click Branch Create Button")
    |> click(css("button.gl-button:nth-child(4)"))

    # --- Create Test MR (Select Branch)
    |> logtee(&Logger.info(&1), "Visit /#{proj_path}/-/merge_requests/new")
    |> visit("/#{proj_path}/-/merge_requests/new")
    |> logtee(&Logger.info(&1), "Select the branch dropdown")
    |> click(css("#dropdown-toggle-btn-44"))
    |> logtee(&Logger.info(&1), "Can we search our branch in the dropdown?")
    |> find(
      css(
        "#base-dropdown-47 > div:nth-child(2) > div:nth-child(2) > div:nth-child(1) > input:nth-child(2)"
      ),
      &Element.fill_in(&1, with: src_branch)
    )
    |> sleep(2000)
    |> logtee(&Logger.info(&1), "We found it, send enter to select it")
    |> send_keys([:enter])

    # --- Create MR (Confirm Selection)
    |> logtee(&Logger.info(&1), "Confirm we're creating a new PR")
    |> click(css("button.btn-confirm"))
    |> sleep(2000)
    |> logtee(&Logger.info(&1), "We're now on a page with a h1 that says \"New merge request\"")
    |> assert_has(css("h1", text: "New merge request"))
    |> logtee(&Logger.info(&1), "Click new MR button")
    |> click(css("button.btn-confirm:nth-child(1)"))
    |> sleep(2000)
    |> assert_has(css("h2", text: "Activity"))

    # --- We've made a MR ---
    |> logtee(&Logger.info(&1), "We've made an MR 🎉")
  end
end
