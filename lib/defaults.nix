{
  sops-nix,
  disko,
  nixpkgs,
  ...
}: {
  mkNixOS = hostName: {
    user ? "nixos",
    system ? "x86_64-linux",
    hostModule,
  }: let
    custHostConfig = {
      hostName = hostName;
      hostUser = user;
    };
  in
    nixpkgs.lib.nixosSystem {
      system = system;
      specialArgs = {
        inherit hostName;
      };

      modules = [
        sops-nix.nixosModules.sops
        disko.nixosModules.disko
        (nixpkgs.lib.modules.importApply hostModule custHostConfig)
      ];
    };

  mkColmenaConfig = hostName: {
    user ? "nixos",
    host,
    buildOnTarget ? false,
    tags ? [],
    system ? "x86_64-linux",
    extraModules ? [],
    hostModule,
  }: let
    custHostConfig = {
      hostName = hostName;
      hostUser = user;
    };
  in {
    deployment = {
      targetHost = host;
      targetPort = 22;
      targetUser = user;
      buildOnTarget = buildOnTarget;
      tags = tags;
    };
    nixpkgs.system = system;

    imports =
      [
        sops-nix.nixosModules.sops
        disko.nixosModules.disko
        (nixpkgs.lib.modules.importApply hostModule custHostConfig)
      ]
      ++ extraModules;
  };
}
