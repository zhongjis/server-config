{pkgs, ...}: {
  # https://nixos.wiki/wiki/AMD_GPU
  # https://github.com/xerhaxs/nixos/blob/main/nixosModules/hardware/amdgpu.nix

  boot.initrd.kernelModules = ["amdgpu"];

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
    extraPackages = with pkgs; [
      vaapiVdpau

      rocmPackages.clr
      rocmPackages.clr.icd

      amdvlk
    ];
    extraPackages32 = with pkgs; [driversi686Linux.amdvlk];
  };

  environment.variables = {
    "VDPAU_DRIVER" = "radeonsi";
    "LIBVA_DRIVER_NAME" = "radeonsi";
  };
  # Most software has the HIP libraries hard-coded. Workaround:
  systemd.tmpfiles.rules = [
    "L+    /opt/rocm/hip   -    -    -     -    ${pkgs.rocmPackages.clr}"
  ];

  hardware.amdgpu = {
    opencl.enable = true; # FIXME: this one was broken
    initrd.enable = true;
    amdvlk = {
      enable = true;
      support32Bit.enable = true;
    };
  };

  # Tell Xorg to use the amd driver
  services.xserver = {
    enable = true;
    videoDrivers = ["amdgpu"];
  };

  environment.systemPackages = with pkgs; [
    nvtopPackages.amd
  ];
}
