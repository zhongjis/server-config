{
  sops-nix,
  disko,
  nixpkgs,
  inputs,
  ...
}: {
  mkK3sNode = hostName: {
    user ? "nixos",
    system ? "x86_64-linux",
    hostModule,
    isMaster ? false,
    masterAddr ? "",
  }: let
    custHostConfig = {
      hostName = hostName;
      hostUser = user;
      isK3sMaster = isMaster;
      masterAddr = masterAddr;
    };
  in
    nixpkgs.lib.nixosSystem {
      system = system;
      specialArgs = {
        inherit inputs hostName custHostConfig;
      };

      modules = [
        sops-nix.nixosModules.sops
        disko.nixosModules.disko
        hostModule
      ];
    };

  # FIXME: not working
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
