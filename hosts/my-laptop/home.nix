# ============================================================
# hosts/my-laptop/home.nix —— 用户级配置（home-manager）
# ------------------------------------------------------------
# 用途：管理用户家目录下的程序配置，与系统配置分离但协同生效。
#   独立使用：home-manager switch --flake .#nixos@my-laptop
#   随系统使用：nixos-rebuild 时自动应用
# 常见修改点：username / homeDirectory 必须与系统用户一致
# ============================================================
{ pkgs, ... }:

{
  # home 键合并书写，避免属性集重复绑定（statix W20）
  home = {
    username = "nixos";
    homeDirectory = "/home/nixos";
    stateVersion = "26.11"; # 与首次启用 home-manager 的版本一致，勿随意改
  };

  # ---- niri 的用户级补充设置（快捷键主体在 modules/desktop.nix） ----
  # DPI 缩放由系统模块 my.desktop.niri.scale 统一控制
  home.sessionVariables = {
    NIXOS_OZONE_WL = "1";        # 让 Electron/Chromium 应用走 Wayland
    MOZ_ENABLE_WAYLAND = "1";    # Firefox Wayland 模式
    XDG_SESSION_TYPE = "wayland";
  };

  # ---- 用户级软件包（系统级在 modules/programs.nix，二者互补） ----
  home.packages = with pkgs; [
    wl-clipboard  # wl-copy / wl-paste，clipman 依赖
    libnotify     # notify-send 桌面通知
    nerd-fonts.jetbrains-mono # 终端/编辑器图标字体
  ];

  # ---- 用户级 programs 配置（programs 键合并书写） ----
  programs = {
    # 允许 home-manager 管理自身
    home-manager.enable = true;

    # git 用户配置（按需修改）
    git = {
      enable = true;
      settings.user = {
        name = "Your Name";         # 常见修改点
        email = "you@example.com";  # 常见修改点
      };
    };
  };

  # ---- clipman 剪贴板守护进程（配合 foot/niri 快捷键） ----
  services.cliphist.enable = true; # clipman 的数据源：wl-clipboard 历史服务

  # （git 配置已并入上方 programs 块）

  # ---- XDG 用户目录与默认应用 ----
  xdg = {
    enable = true;
    mimeApps.defaultApplications = {
      "text/html" = [ "firefox.desktop" ];
      "x-scheme-handler/http" = [ "firefox.desktop" ];
      "x-scheme-handler/https" = [ "firefox.desktop" ];
      "inode/directory" = [ "thunar.desktop" ];
    };
  };
}
