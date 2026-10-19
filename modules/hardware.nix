# ============================================================
# modules/hardware.nix —— 硬件相关通用配置
# ------------------------------------------------------------
# 用途：显卡、蓝牙、电源管理、音频等硬件层开关。
# 常见修改点：
#   1. NVIDIA 用户取消 nvidia 段落注释，并把 videoDrivers 改为 "nvidia"；
#   2. 打印机支持按需启用 services.printing
# ============================================================
{ config, lib, myLib, ... }:

{
  options.my.hardware = {
    enable = myLib.mkEnable' "硬件通用配置";
    nvidia = lib.mkEnableOption "NVIDIA 闭源驱动（Wayland/niri 下需额外内核参数）";
  };

  config = myLib.mkIfEnabled config.my.hardware.enable (lib.mkMerge [
    {
      # ---- 图形栈与蓝牙（hardware 键合并，避免重复绑定） ----
      hardware = {
        # 默认使用开源驱动（Intel/AMD 开箱即用）
        graphics = {
          enable = true;
          enable32Bit = true; # Steam/游戏需要 32 位驱动库
        };
        bluetooth.enable = true;
      };

      # ---- 音频 / 蓝牙托盘 / 电源管理（services 键合并） ----
      services = {
        pipewire = {
          enable = true;
          alsa.enable = true;
          alsa.support32Bit = true;
          pulse.enable = true; # 兼容 PulseAudio 客户端
        };
        blueman.enable = true;                 # 蓝牙托盘管理工具
        power-profiles-daemon.enable = true;   # 笔记本续航优化
      };
      security.rtkit.enable = true; # PipeWire 实时调度需要

      # ---- 网络 ----
      networking.networkmanager.enable = true;
    }

    # ---- NVIDIA 可选段落：nvidia = true 时生效 ----
    (lib.mkIf config.my.hardware.nvidia {
      services.xserver.videoDrivers = [ "nvidia" ];
      hardware.nvidia = {
        modesetting.enable = true;          # Wayland 必需
        open = true;                        # Turing 及以上推荐开源内核模块
        nvidiaSettings = true;
        package = config.boot.kernelPackages.nvidiaPackages.stable;
      };
      boot.kernelParams = [ "nvidia-drm.fbdev=1" ];
    })
  ]);
}
