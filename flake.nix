{
  description = "A Nix flake for running Gitlabor Elixir tests";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    {
      nixpkgs,
      flake-utils,
      ...
    }@inputs:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs { inherit system; };

        elixirVersion = pkgs.beamPackages.elixir_1_18;

        mixNixDeps = import ./mix_deps.nix {
          lib = pkgs.lib;
          beamPackages = pkgs.beamPackages;
        };

        projectSrc = pkgs.lib.cleanSource ./.;

        gitlaborPkg = pkgs.beamPackages.buildMix {
          name = "gitlabor";
          version = "0.1.0";
          src = projectSrc;

          beamDeps = with mixNixDeps; [
            wallaby
            tesla
            uuid
            jason
            mint
          ];
        };

      in
      {
        packages.default = gitlaborPkg;

        devShells.default = pkgs.mkShell {
          packages = [
            elixirVersion
            pkgs.mix2nix
            pkgs.chromedriver
          ];

          VAULT_ADDR = "https://vault-a.dbccloud.dk:8200";

          GITLAB_BASE_URL = "https://gitlab-test.dbc.dk";
          GITLAB_TEST_USERNAME = "gitlabor";
          GITLAB_TEST_PROJECT_PATH = "fully-automated-luxury-gitlab-testing/means-of-testing";
          GITLAB_TEST_TARGET_BRANCH = "main";

          shellHook = ''
            export MIX_ENV=test
            echo ""
            echo "Gitlabor test development shell loaded."
            echo ""
            echo "MIX_ENV is set to 'test'."
            echo ""
            echo "Make sure to run 'mix deps.get' if you change dependencies."
            echo ""
            echo "To regenerate mix_deps.nix: mix2nix > mix_deps.nix"
            echo ""
            echo "Required environment variables for tests:"
            echo "  GITLAB_BASE_URL, GITLAB_TEST_USERNAME, VAULT_ADDR"
            echo "  (VAULT_TOKEN will be read from ~/.vault-token by the test)"
            echo "  GITLAB_TEST_PROJECT_PATH, GITLAB_TEST_TARGET_BRANCH"
            echo ""
          '';
        };

        apps.default = {
          type = "app";
          program = pkgs.lib.getExe (
            pkgs.writeShellApplication {
              name = "run-gitlabor-tests";

              runtimeInputs = [
                elixirVersion
                pkgs.chromedriver
              ];

              text = ''
                set -euo pipefail

                echo "--- Preparing to run Gitlabor tests via Nix Flake ---"

                export MIX_ENV=test
                echo "[INFO] MIX_ENV set to '$MIX_ENV'"

                ELIXIR_APP_WITH_DEPS_PATH="${gitlaborPkg}"

                export ERL_LIBS="''${ELIXIR_APP_WITH_DEPS_PATH}/lib"

                echo "[INFO] ERL_LIBS set to '$ERL_LIBS'"
                echo "[INFO] Using Elixir from: $(command -v elixir)"
                echo "[INFO] Using Mix from: $(command -v mix)"
                echo "[INFO] Using ChromeDriver from: $(command -v chromedriver)"
                echo "[INFO] Current directory: $PWD"

                echo "[INFO] Ensuring local project compilation (if needed)..."

                if ! mix compile --force --no-deps-check; then
                  echo "[ERROR] mix compile failed!"
                  exit 1
                fi

                echo "[INFO] Starting Wallaby tests (mix test)..."

                if ! mix test "$@"; then
                    echo "[ERROR] mix test failed!"
                    exit 1
                fi

                echo "--- Gitlabor tests finished successfully ---"
              '';
            }
          );
        };
      }
    );
}
