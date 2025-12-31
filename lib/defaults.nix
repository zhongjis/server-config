{
  sops-nix,
  disko,
  ...
}: {
  mkNodeSpecialArgs = hostname: {
    user ? "nixos",
    isMaster ? false,
    master ? "",
    labels ? [],
  }: {
    custHostConfig = {
      hostName = hostname;
      hostUser = user;
      isK3sMaster = isMaster;
      masterAddr = master;
      nodeLabels = labels;
    };
  };

  mkK3sNode = hostName: {
    user ? "root",
    host,
    buildOnTarget ? false,
    tags ? [],
    system ? "x86_64-linux",
    hostModule,
  }: {
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

    nixpkgs.system = system;
  };
}
