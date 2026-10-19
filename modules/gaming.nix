# ============================================================
# modules/gaming.nix —— 游戏环境：Steam + Epic + gamescope 专用会话
# ------------------------------------------------------------
# 用途：提供完备游戏环境，并注册一个独立的「Gaming (gamescope)」
#   会话，登录界面可直接选择进入（Steam Big Picture 模式，参考
#   SteamNix 项目思路，但不依赖外部 flake 输入）。
# 组成：
#   - Steam（含 remote play、专用 32 位图形库）
#   - Epic：经 Heroic Games Launcher（开源第三方 Epic/GOG 启动器）
#   - gamescope：Valve 微合成器，提供分辨率缩放 / HDR / 帧率限制
#   - wine / proton 兼容层、MangoHud 性能悬浮层、gamemode 调度优化
# 常见修改点：
#   1. 会话分辨率在下方 gamescope-session 脚本的 -W/-H 参数修改；
#   2. 不需要 Heroic 可从 systemPackages 中删除
# ============================================================
{ config, pkgs, myLib, ... }:

let
  # 游戏会话脚本：gamescope 全屏包裹 Steam Big Picture
  # 常见修改点：-W/-H 为输出分辨率，-w/-h 为渲染分辨率（可更低以省性能）
  gamescope-session = pkgs.writeShellScriptBin "gamescope-session" ''
    exec ${pkgs.gamescope}/bin/gamescope \
      -W 2560 -H 1440 -w 2560 -h 1440 \
      -f -e --steam --adaptive-sync \
      -- steam -steamdeck -gamepadui
  '';
in
{
  options.my.gaming.enable = myLib.mkEnable' "游戏环境（Steam/Epic/gamescope 会话）";

  config = myLib.mkIfEnabled config.my.gaming.enable {

    # ---- Steam + gamemode（programs 键合并书写） ----
    programs = {
      steam = {
        enable = true;
        remotePlay.openFirewall = true;        # 远程同乐
        dedicatedServer.openFirewall = true;
        gamescopeSession.enable = true;        # 内置 gamescope 集成
        extraCompatPackages = [ pkgs.proton-ge-bin ]; # Proton-GE 兼容层
      };
      # 游戏时自动优化 CPU 调度/优先级
      gamemode.enable = true;
    };

    # ---- 会话注册与手柄 udev 规则（services 键合并书写） ----
    services = {
      # 登录界面可选「Steam (gamescope)」——SteamNix 核心思路：
      # 把游戏作为独立 Wayland 会话
      displayManager.sessionPackages = [
        # 注意：sessionPackages 要求「带 providedSessions 的 package」类型，
        # writeTextFile 不满足，需用 runCommand 并声明 passthru.providedSessions
        (pkgs.runCommand "gamescope-steam-session" {
          passthru.providedSessions = [ "steam-gamescope" ];
        } ''
          mkdir -p $out/share/wayland-sessions
          cat > $out/share/wayland-sessions/steam-gamescope.desktop <<'EOF'
          [Desktop Entry]
          Name=Steam (gamescope)
          Comment=Steam Big Picture 游戏专用会话
          Exec=${gamescope-session}/bin/gamescope-session
          Type=Application
          EOF
        '')
      ];

      # 手柄支持（Xbox/PS/Switch Pro）udev 规则
      udev.packages = [ pkgs.game-devices-udev-rules ];
    };

    # ---- 游戏相关软件包 ----
    environment.systemPackages = with pkgs; [
      gamescope-session   # 上面定义的会话脚本
      gamescope
      heroic              # Epic / GOG 开源启动器
      mangohud            # 性能悬浮层（游戏中按 Shift_R+F12）
      lutris              # 通用游戏管理器（可选）
      wineWowPackages.stagingFull  # Windows 兼容层
      winetricks
    ];

    # ---- 手柄蓝牙支持 ----
    hardware.xpadneo.enable = true;
  };
}
