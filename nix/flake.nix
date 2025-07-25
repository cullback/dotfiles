{
  description = "Example nix-darwin system flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin.url = "github:nix-darwin/nix-darwin/master";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = inputs@{ self, nix-darwin, nixpkgs }:
  let

    configuration = { pkgs, ... }: {
      environment.systemPackages =
      [ pkgs.helix
        pkgs.zellij
        pkgs.fish
        pkgs.gitui
        pkgs.fish
        pkgs.yazi
        pkgs.fzf
        pkgs.fd
        pkgs.sd
        pkgs.tree
        pkgs.bat
        pkgs.aider-chat

        # languages
        pkgs.cargo
        pkgs.rustc
        pkgs.rust-analyzer

        pkgs.python3
        pkgs.uv

        # gui apps
        pkgs.alacritty
        pkgs.iina
        pkgs.keepassxc
      ];

      fonts.packages = with pkgs; [
        nerd-fonts.fira-code
      ];

      users.knownUsers = [ "cullback" ];
      users.users.cullback.uid = 501;
      users.users.cullback.shell = pkgs.fish;

      programs.fish.enable = true;

      nix.enable = false;
      nix.settings.experimental-features = "nix-command flakes";
      system.configurationRevision = self.rev or self.dirtyRev or null;
      system.stateVersion = 6;
      nixpkgs.hostPlatform = "aarch64-darwin";
    };
  in
  {
    darwinConfigurations."cullbacks-MacBook-Air" = nix-darwin.lib.darwinSystem {
      modules = [ configuration ];
    };
  };
}

