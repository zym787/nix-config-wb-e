# ============================================================
# modules/desktop.nix —— niri + DankMaterialShell 桌面环境
# ------------------------------------------------------------
# 用途：一键启用 Wayland 滚动平铺桌面。
#   - niri：滚动平铺合成器（systemd session 集成）
#   - DankMaterialShell（DMS）：Material You 风格 shell，提供
#     顶栏 / 启动器 / 通知中心 / 锁屏
# 常见修改点：
#   1. 切换桌面：把 my.desktop.niri.enable 关掉、开别的模块即可；
#   2. DMS 版本 pin 在下方 dmsSrc，升级时改 rev 与 hash；
#   3. 首次构建 DMS 时先用 lib.fakeHash，构建报错会给出真实 hash，回填即可
# ============================================================
{ config, pkgs, lib, myLib, ... }:

let
  cfg = config.my.desktop.niri; # 系统级开关与缩放值，供下方引用
  # ---- DankMaterialShell 源码 pin（无 flake 输入，直接 fetch 到仓库内） ----
  dmsSrc = pkgs.fetchFromGitHub {
    owner = "AvengeMedia";
    repo = "DankMaterialShell";
    rev = "master";          # 建议改为具体 commit，保证可复现
    hash = lib.fakeHash;     # 首次构建后替换为报错中提示的 hash
  };

  # DMS 是基于 Quickshell 的 shell 配置集，安装到用户可发现的位置
  dms = pkgs.runCommand "dank-material-shell" { } ''
    mkdir -p $out/share/quickshell/dms
    cp -r ${dmsSrc}/. $out/share/quickshell/dms/
  '';
in
{
  options.my.desktop.niri = {
    enable = myLib.mkEnable' "niri + DankMaterialShell 桌面";
    scale = lib.mkOption {
      type = lib.types.float;
      default = 1.0;
      description = "全局缩放；此处控制 niri 的 DPI 缩放，请根据显示器实际 PPI 调整";
    };
  };

  config = myLib.mkIfEnabled cfg.enable {

    # ---- niri 合成器 ----
    programs.niri.enable = true; # nixpkgs 原生模块，含 session / portal / polkit

    # ---- 显示管理器：greetd + tuigreet 极简登录 ----
    services.greetd = {
      enable = true;
      settings.default_session = {
        command = "${pkgs.tuigreet}/bin/tuigreet --time --cmd niri-session";
        user = "greeter";
      };
    };

    # ---- DMS 运行依赖：quickshell 引擎 ----
    environment.systemPackages = [ pkgs.quickshell dms ];

    # ---- XDG portal（屏幕共享 / 截图权限） ----
    xdg.portal = {
      enable = true;
      extraPortals = [ pkgs.xdg-desktop-portal-gnome pkgs.xdg-desktop-portal-gtk ];
      config.niri.default = [ "gnome" "gtk" ];
    };

    # ---- niri 用户级配置：默认快捷键（KDL 格式，declarative 写入） ----
    # 说明：home-manager 上游无 programs.niri 模块（该模块在 niri-flake 中），
    # 为保持「零外部 flake 输入」，此处直接生成 ~/.config/niri/config.kdl。
    home-manager.sharedModules = [
      ({ pkgs, ... }: {
        xdg.configFile."niri/config.kdl".text = ''
          // niri 合成器配置（由 Nix 生成，手工改动会在下次 rebuild 时被覆盖）

          // 启动时拉起 DMS（Quickshell 加载 DMS 配置目录）与剪贴板历史
          spawn-at-startup "qs" "-c" "dms"
          spawn-at-startup "wl-paste" "--watch" "cliphist" "store"

          // 显示器输出：此处控制 niri 的 DPI 缩放，请根据显示器实际 PPI 调整
          // （由 my.desktop.niri.scale 选项注入）
          output "eDP-1" {
              scale ${toString cfg.scale}
          }

          input {
              keyboard {
                  xkb {
                      layout "us" // 常见修改点：键盘布局
                  }
              }
              touchpad {
                  tap
                  natural-scroll
              }
          }

          // ---- 默认快捷键（可自由修改） ----
          binds {
              // 启动器：Win+D 呼出 DMS spotlight 启动器
              Mod+D { spawn "qs" "-c" "dms" "ipc" "call" "spotlight" "toggle"; }
              // 终端：Win+Enter 启动 foot
              Mod+Return { spawn "foot"; }
              // 关闭窗口 / 概览 / 锁屏
              Mod+Q { close-window; }
              Mod+O { toggle-overview; }
              Mod+Shift+L { spawn "qs" "-c" "dms" "ipc" "call" "lock" "lock"; }
              // 焦点移动（vim 风格）
              Mod+H { focus-column-left; }
              Mod+L { focus-column-right; }
              Mod+J { focus-window-down; }
              Mod+K { focus-window-up; }
              // 截图：Print 全屏 / Shift+Print 框选（grim + slurp）
              Print { spawn "grim"; }
              Shift+Print { spawn "sh" "-c" "grim -g \"$(slurp)\" - | wl-copy"; }
              // 剪贴板历史：Win+V 调取 cliphist
              Mod+V { spawn "sh" "-c" "cliphist list | qs -c dms ipc call spotlight clipboard"; }
              // 音量/亮度媒体键
              XF86AudioRaiseVolume { spawn "wpctl" "set-volume" "@DEFAULT_AUDIO_SINK@" "5%+"; }
              XF86AudioLowerVolume { spawn "wpctl" "set-volume" "@DEFAULT_AUDIO_SINK@" "5%-"; }
              XF86MonBrightnessUp { spawn "brightnessctl" "s" "10%+"; }
              XF86MonBrightnessDown { spawn "brightnessctl" "s" "10%-"; }
          }
        '';

        # 亮度/截图等用户工具
        home.packages = with pkgs; [ brightnessctl wireplumber ];
      })
    ];

    # ---- 字体：中文字体 + 等宽字体 ----
    fonts.packages = with pkgs; [ noto-fonts noto-fonts-cjk-sans noto-fonts-color-emoji ];
  };
}
