{
  sops-nix,
  disko,
  ...
}: {
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

    imports =
      [
        sops-nix.nixosModules.sops
        disko.nixosModules.disko
        (hostModule {inherit hostName;})
      ]
      ++ extraModules;
  };
}
