# ============================================================
# hardware-configuration.nix —— 硬件扫描结果（占位模板）
# ------------------------------------------------------------
# 用途：记录磁盘分区、文件系统、内核模块等硬件相关信息。
# 重要：本文件是模板！请在目标机器上运行
#   sudo nixos-generate-config --root /mnt
# 并用生成的 /mnt/etc/nixos/hardware-configuration.nix 覆盖本文件。
# ============================================================
{ config, lib, pkgs, modulesPath, ... }:

{
  imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];

  # ---- 引导加载器（UEFI + systemd-boot，现代笔记本推荐） ----
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # ---- 内核模块：按 nixos-generate-config 的输出填写 ----
  boot.initrd.availableKernelModules = [ "xhci_pci" "nvme" "usb_storage" "sd_mod" ];
  boot.kernelModules = [ "kvm-intel" ]; # AMD CPU 改为 "kvm-amd"

  # ---- 文件系统（以下为示例，务必替换为真实 UUID） ----
  fileSystems."/" = {
    device = "/dev/disk/by-uuid/00000000-0000-0000-0000-000000000000";
    fsType = "ext4";
  };
  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/0000-0000";
    fsType = "vfat";
  };
  swapDevices = [ ];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
}
