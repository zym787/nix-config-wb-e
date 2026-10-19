# ============================================================
# modules/shell.nix —— 终端与 Shell：foot + zsh
# ------------------------------------------------------------
# 用途：提供开箱即用的终端体验。
#   zsh 含 oh-my-zsh + 自动补全 + 语法高亮 + 历史提示插件。
# 常见修改点：
#   1. foot 字体/透明度在 programs.foot.settings 中调整；
#   2. zsh 主题改 programs.zsh.ohMyZsh.theme（如 "agnoster"）
# ============================================================
{ config, pkgs, lib, myLib, ... }:

{
  options.my.shell.enable = myLib.mkEnable' "foot + zsh";

  config = myLib.mkIfEnabled config.my.shell.enable {
    # 系统级启用 zsh（登录 shell 需要，见 hosts 中 users.users.*.shell）
    programs.zsh.enable = true;

    home-manager.sharedModules = [
      ({ pkgs, ... }: {
        # ---- 终端与 Shell（programs 键合并书写） ----
        programs = {
          # foot：轻量 Wayland 原生终端
          foot = {
            enable = true;
            settings = {
              main = {
                font = "JetBrainsMono Nerd Font:size=12";
                dpi-aware = "yes";             # 跟随 niri 缩放，无需手动调
                pad = "8x8";                   # 内边距
              };
              colors.alpha = 0.95;             # 轻微透明（0.0~1.0）
              scrollback.lines = 10000;
            };
          };

          # zsh + oh-my-zsh + 常用插件
          zsh = {
            enable = true;
            enableCompletion = true;
            autosuggestion.enable = true;      # 灰色历史命令提示
            syntaxHighlighting.enable = true;  # 命令实时语法高亮

            oh-my-zsh = {
              enable = true;
              theme = "robbyrussell";          # 常见修改点：主题
              plugins = [ "git" "sudo" "extract" "colored-man-pages" ];
            };

            # 常用别名：现代命令替代传统命令
            shellAliases = {
              ls = "eza --icons";
              cat = "bat";
              grep = "rg";
              rebuild = "sudo nixos-rebuild switch --flake ~/nixos-config#my-laptop";
            };

            # 额外 zsh 初始化内容
            initContent = ''
              # 历史记录设置
              HISTSIZE=10000; SAVEHIST=10000
              setopt SHARE_HISTORY HIST_IGNORE_DUPS
            '';
          };
        };
      })
    ];
  };
}
