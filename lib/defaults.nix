{
  sops-nix,
  disko,
  ...
}: {
  mkColmenaConfig = {
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
        sops-nix
        disko.nixosModules.disko
        hostModule
      ]
      ++ extraModules;
  };
}
