{
  sops-nix,
  disko,
  nixpkgs,
  ...
}: {
  mkNixOS = hostName: {
    system ? "x86_64-linux",
    hostModule,
  }:
    nixpkgs.lib.nixosSystem {
      system = system;
      specialArgs = {
        inherit hostName;
      };

      modules = [
        sops-nix.nixosModules.sops
        disko.nixosModules.disko
        hostModule
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
  }: {
    deployment = {
      targetHost = host;
      targetPort = 22;
      targetUser = user;
      buildOnTarget = buildOnTarget;
      tags = tags;
    };
    nixpkgs.system = system;

    specialArgs = {
      hostName = hostName;
    };

    imports =
      [
        sops-nix.nixosModules.sops
        disko.nixosModules.disko
        (nixpkgs.lib.modules.importApply hostModule hostName)
      ]
      ++ extraModules;
  };
}
