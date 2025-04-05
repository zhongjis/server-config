{
  modulesPath,
  lib,
  pkgs,
  hostName,
  ...
}: {
  imports =
    [
      (modulesPath + "/installer/scan/not-detected.nix")
      (modulesPath + "/profiles/qemu-guest.nix")
      (import ./disko-config.nix {device = "/dev/sda";})
    ]
    ++ lib.optional (builtins.pathExists ./hardware-configuration-${hostName}.nix) ./hardware-configuration-${hostName}.nix;

  boot.loader.grub = {
    # no need to set devices, disko will add all devices that have a EF02 partition to the list already
    # devices = [ ];
    efiSupport = true;
    efiInstallAsRemovable = true;
  };
  services.openssh.enable = true;

  networking.hostName = hostName;

  time.timeZone = "America/Denver";

  environment.systemPackages = map lib.lowPrio [
    pkgs.curl
    pkgs.gitMinimal
  ];

  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINDkA9QW9+SBK4dXpIj9nR9k49wuPdjlMwLvSacM9ExM zhongjie.x.shen@gmail.com"
  ];

  system.stateVersion = "24.05";
}
