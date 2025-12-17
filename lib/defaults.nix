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

  mkHive = hostName: {
    user ? "root",
    host,
    buildOnTarget ? false,
    tags ? [],
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
  in {
    deployment = {
      targetHost = host;
      targetPort = 22;
      targetUser = user;
      buildOnTarget = buildOnTarget;
      tags = tags;
    };

    imports = [
      sops-nix.nixosModules.sops
      disko.nixosModules.disko
      hostModule
    ];

    _module.args = {
      inherit custHostConfig;
    };

    nixpkgs.system = system;
  };
}
