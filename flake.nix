{
  description = "GitLabor Flake, tuned for DBC usage.";

  inputs = {
    flake-parts.url = "github:hercules-ci/flake-parts";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs =
    inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "aarch64-darwin"
        "x86_64-darwin"
      ];
      perSystem =
        {
          pkgs,
          ...
        }:
        {
          packages = rec {
            default = worktime;
            worktime =
              with pkgs.beamPackages;
              mixRelease rec {
                name = "gitlabor";
                pname = name;
                version = "0.0.1-dev";
                src = ./.;
                removeCookie = false;
              };
          };

          devShells =
            let
              environment = {

                # Setup default vault address to get credentials from.
                VAULT_ADDR = "https://vault-a.dbccloud.dk:8200";

                # Setup various GitLab specific variables, specifying what repo/forge to test on.
                GITLAB_BASE_URL = "https://gitlab-test.dbc.dk";
                GITLAB_TEST_USERNAME = "gitlabor";
                GITLAB_TEST_PROJECT_PATH = "fully-automated-luxury-gitlab-testing/means-of-testing";
                GITLAB_TEST_TARGET_BRANCH = "main";
              };
              sharedPackages = with pkgs; [
                elixir_1_18
                mix2nix
              ];
            in
            rec {
              # NOTE: we default to using the system chromedriver, because its significantly more light-weight.
              default = systemChromedriver;

              # DevShell using the system installed chromedriver (since this is a rather heavy dependency).
              systemChromedriver = pkgs.mkShell (
                environment
                // {
                  package = sharedPackages;
                }
              );

              # DevShell including chromedriver.
              projectChromedriver = pkgs.mkShell (
                environment
                // {
                  package = sharedPackages ++ [ pkgs.chromedriver ];
                }
              );
            };
        };
    };
}
