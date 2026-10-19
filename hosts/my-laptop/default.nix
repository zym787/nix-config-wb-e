# ============================================================
# hosts/my-laptop/default.nix —— 主机专属配置入口
# ------------------------------------------------------------
# 用途：组装本台主机的全部模块（系统模块 + 硬件 + 用户配置）。
# 常见修改点：
#   1. networking.hostName 改为你的主机名；
#   2. users.users.<用户名> 与 home-manager.users.<用户名> 必须同名；
#   3. 新增模块时在 imports 中追加 ../../modules/xxx.nix
# ============================================================
{ config, pkgs, lib, myLib, ... }:

{
  imports = [
    ./hardware-configuration.nix   # 由 nixos-generate-config 生成，请勿手写
    ../../modules/hardware.nix
    ../../modules/desktop.nix      # niri + DankMaterialShell
    ../../modules/shell.nix        # foot + zsh
    ../../modules/programs.nix     # neovim / firefox / thunar / 截图等
    ../../modules/gaming.nix       # Steam + Epic + gamescope 游戏会话
    ../../modules/security.nix     # 安全基线
    ./home.nix                     # 本机用户的 home-manager 配置
  ];

  # ---- 模块总开关（一键切换桌面环境：改这里即可） ----
  # 注意：my.* 键需合并书写，避免属性集重复绑定（statix W20）
  my = {
    hardware.enable = true;
    desktop.niri = {
      enable = true;
      scale = 1.0; # 常见修改点：4K 屏建议 2.0，详见 modules/desktop.nix
    };
    shell.enable = true;
    programs.enable = true;
    gaming.enable = true;
    security.enable = true;
  };

  # ---- 主机基础信息 ----
  networking.hostName = "my-laptop"; # 常见修改点：改成你的主机名

  # ---- 系统状态版本：保持与首次安装的 NixOS 版本一致，勿随意升级 ----
  system.stateVersion = "26.11";

  # ---- 普通用户（root 已禁用密码登录，日常使用此账户） ----
  users.users.nixos = {
    isNormalUser = true;
    description = "NixOS 用户";                # 常见修改点：改成你的名字
    extraGroups = [ "wheel" "networkmanager" "video" "input" ];
    shell = pkgs.zsh;                          # 与 modules/shell.nix 协同
    initialPassword = "changeme";              # 首次登录后请立即用 passwd 修改
  };

  # ---- home-manager：用户级配置与系统级分离但协同 ----
  home-manager.users.nixos = import ./home.nix;

  # ---- Nix 自身设置 ----
  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    auto-optimise-store = true;      # 自动硬链接去重，节省磁盘
  };
  nixpkgs.config.allowUnfree = true; # Steam / 显卡驱动需要非自由软件
}
