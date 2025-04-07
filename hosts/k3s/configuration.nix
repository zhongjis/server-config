custHostConfig: {
  modulesPath,
  lib,
  pkgs,
  config,
  inputs,
  ...
}: let
  sopsFile = ../../secrets/homelab.yaml;
in {
  imports =
    [
      (modulesPath + "/installer/scan/not-detected.nix")
      (modulesPath + "/profiles/qemu-guest.nix")
      (import ./disko-config.nix {device = "/dev/sda";})

      ../../modules
    ]
    ++ lib.optional (builtins.pathExists ./hardware-configuration-${custHostConfig.hostName}.nix) ./hardware-configuration-${custHostConfig.hostName}.nix;

  boot.loader.grub = {
    # no need to set devices, disko will add all devices that have a EF02 partition to the list already
    # devices = [ ];
    efiSupport = true;
    efiInstallAsRemovable = true;
  };
  services.openssh.enable = true;

  networking.hostName = custHostConfig.hostName;

  time.timeZone = "America/Denver";

  environment.systemPackages = map lib.lowPrio [
    pkgs.curl
    pkgs.gitMinimal
  ];

  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINDkA9QW9+SBK4dXpIj9nR9k49wuPdjlMwLvSacM9ExM zhongjie.x.shen@gmail.com"
  ];

  users.users."${custHostConfig.hostUser}" = {
    isNormalUser = true;
    extraGroups = ["wheel"]; # Enable ‘sudo’ for the user.
    packages = with pkgs; [
      tree
    ];
    # Created using mkpasswd
    shell = pkgs.zsh;
    # hashedPasswordFile = config.sops.secrets.server_password_sha256.path;
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINDkA9QW9+SBK4dXpIj9nR9k49wuPdjlMwLvSacM9ExM zhongjie.x.shen@gmail.com"
    ];
  };
  programs.zsh.enable = true;

  system.stateVersion = "24.05";
}
