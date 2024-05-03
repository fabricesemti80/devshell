# # ? Source / inspiration / thanks:
# ? https://github.com/martinbaillie/vault-plugin-secrets-github
# ? https://github.com/numtide/devshell
{
  description = "developer shell for the Platform Engineer";

  inputs = {
    nixpkgs.url = github:NixOS/nixpkgs/nixos-unstable;
    flake-parts.url = github:hercules-ci/flake-parts;

    devshell = {
      url = github:numtide/devshell;
      inputs.nixpkgs.follows = "nixpkgs";
    };

    gomod2nix = {
      url = github:nix-community/gomod2nix;
      inputs.nixpkgs.follows = "nixpkgs";
    };

    gitignore = {
      url = github:hercules-ci/gitignore.nix;
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs@{ self
    , nixpkgs
    , flake-parts
    , devshell
    , gomod2nix
    , gitignore
    , ...
    }:
    flake-parts.lib.mkFlake { inherit inputs; } ({
      systems = [
        "x86_64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
        "aarch64-linux"
      ];

      perSystem = { config, pkgs, system, ... }:
        let
          name = "platforms-dev-shell";
          package = "github.com/martinbaillie/${name}";
          rev = self.rev or "dirty";
          ver = if self ? "dirtyRev" then self.dirtyShortRev else self.shortRev;
          date = self.lastModifiedDate or "19700101";
          go = pkgs.go_1_22;
        in
        rec
        {
          _module.args.pkgs = import nixpkgs {
            inherit system;
            config.allowUnfree = true; # BSL2... Hashicorp...
            config.permittedInsecurePackages = [
                "python311Packages.kerberos"
                "python311Packages.pywinrm"
              ];
            overlays = [ devshell.overlays.default gomod2nix.overlays.default ];
          };

          devShells.default = pkgs.devshell.mkShell rec {
            inherit name;

            env = [                
                { 
                  # non-secret ENV VARS go here -->
                    name = "VAULT_ADDR"; value = "https://vault.sportingsolutions.com"; 
                }
            ];

            packages = with pkgs; [
                
                bashInteractive
                ansible  # IT automation
                aws-azure-login # Terraform uses this to allow access to state files
                awscli2 # Terraform uses this to allow access to state files
                ansible-lint # Linter for Ansible
                google-cloud-sdk # Required for accesing Vault
                glibcLocales  # Ansible  needs this [source: https://github.com/NixOS/nixpkgs/issues/223151]
                gomplate
                go-task # Task runner
                htop # System process viewer
                jq # Utility to display JSON files 
                nodejs # Needed for aws-azure-login
                packer # Template building automation
                pre-commit # Code valudation upon commit
                sshpass # For those rare cases when SSH is used with password 
                terraform # Infrastructure deployment automation
                terragrunt # Wrapper for Terraform
                tree # Utility to quickly view folder structure
                tmux # Terminal multiplexer
                whois # DNS lookup
                xorriso # Packer needs this in order to build VMWare VM images
                vault-bin # CLI for accessing our Vault #! --> NOT the one without '-bin' [forget about that one! seriously!]              
            ];

            commands = with pkgs; let prjRoot = "cd $PRJ_ROOT;"; in
            [
              # {
              #   inherit name;
              #   command = "nix run";
              #   help = "build and run the project binary";
              # }
              {
                name = "Time";
                command = "date";
                help = "print the time";
              }
              {
                name = "MakeExample";
                command = "./sanitize_envrc.sh";
                help = "take the current .envrc in this folder and generate a version with the secrets removed [for version control]";
              }        
            ];
          };
        };
    });
}