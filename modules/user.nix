{
  custHostConfig,
  pkgs,
  config,
  ...
}: let
  sopsFile = ../../secrets/homelab.yaml;
in {
  sops.secrets = {
    server_password_sha256 = {
      inherit sopsFile;
      neededForUsers = true;
    };
  };

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
    hashedPasswordFile = config.sops.secrets.server_password_sha256.path;
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINDkA9QW9+SBK4dXpIj9nR9k49wuPdjlMwLvSacM9ExM zhongjie.x.shen@gmail.com"
    ];
  };
  programs.zsh.enable = true;
}
