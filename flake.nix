{
  description = "fastnix - Fast & Minimal NixOS (sowm + suckless stack)";

  inputs = {
    # Pin nixpkgs. Dùng nixos-unstable để có package mới nhất cho nnn/dmenu/pipewire.
    # Nếu muốn ổn định hơn, đổi thành "github:NixOS/nixpkgs/nixos-24.11".
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    zen-browser.url = "github:0xc000022070/zen-browser-flake";
    zen-browser.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, zen-browser, ... }@inputs:
    let
      system = "x86_64-linux";
    in
    {
      nixosConfigurations.fastnix = nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = { inherit inputs; };
        modules = [
          ./configuration.nix
          ./hardware-configuration.nix
        ];
      };
    };
}
