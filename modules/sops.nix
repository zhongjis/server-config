{
  pkgs,
  lib,
  ...
}: {
  environment.systemPackages = with pkgs; [
    sops
  ];

  sops = {
    age.keyFile = lib.mkDefault "/home/zshen/.config/sops/age/keys.txt";
    validateSopsFiles = true;
  };
}
