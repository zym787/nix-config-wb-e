# ============================================================
# modules/programs.nix —— 必备工具集
# ------------------------------------------------------------
# 用途：编辑器 / 浏览器 / 文件管理 / 截图 / 剪贴板 / 网络工具。
# 常见修改点：
#   1. neovim 的 LSP 服务器列表在下方 extraPackages 调整；
#   2. 想加软件直接往 environment.systemPackages 里加
# ============================================================
{ config, pkgs, myLib, ... }:

{
  options.my.programs.enable = myLib.mkEnable' "必备工具集";

  config = myLib.mkIfEnabled config.my.programs.enable {

    # ---- 系统级软件包（所有用户可用） ----
    environment.systemPackages = with pkgs; [
      # 网络与系统工具
      curl wget htop btop
      # 现代 CLI 三件套
      bat fd ripgrep
      # 截图（grim 截图 + slurp 框选）
      grim slurp
      # 剪贴板管理（clipman 配合 wl-clipboard / cliphist）
      clipman wl-clipboard cliphist
      # 文件管理器
      xfce.thunar
      # 其他常用
      eza unzip p7zip
    ];

    # ---- Firefox / Neovim 系统级声明（programs 键合并书写） ----
    programs = {
      # Firefox（Wayland 原生构建）
      firefox = {
        enable = true;
        package = pkgs.firefox-wayland; # 已启用 Wayland 后端的官方包
      };

      # Neovim 系统级启用；插件与 LSP 细节见下方 home-manager 段
      neovim = {
        enable = true;
        defaultEditor = true;
        viAlias = true;
        vimAlias = true;
      };
    };

    home-manager.sharedModules = [
      ({ pkgs, ... }: {
        programs.neovim = {
          enable = true;
          # 预装插件（nixpkgs 托管版本，免网络下载、可复现）
          plugins = with pkgs.vimPlugins; [
            nvim-lspconfig          # LSP 客户端配置
            nvim-treesitter.withAllGrammars  # 全语言语法高亮
            nvim-tree-lua           # 文件树（<leader>e 开关）
            telescope-nvim          # 模糊查找
            lualine-nvim            # 状态栏
          ];
          # LSP 服务端（语言服务器二进制）
          extraPackages = with pkgs; [
            nil                     # Nix LSP
            lua-language-server
            pyright
            typescript-language-server  # nodePackages 已被 nixpkgs 移除，用顶层包名
          ];
          # 内置 Lua 配置：启用上述插件的合理默认
          extraLuaConfig = ''
            -- 基础设置
            vim.opt.number = true
            vim.opt.relativenumber = true
            vim.g.mapleader = " "

            -- 文件树
            require("nvim-tree").setup {}
            vim.keymap.set("n", "<leader>e", ":NvimTreeToggle<CR>")

            -- 模糊查找
            local builtin = require("telescope.builtin")
            vim.keymap.set("n", "<leader>ff", builtin.find_files)
            vim.keymap.set("n", "<leader>fg", builtin.live_grep)

            -- LSP：按需启用语言服务器
            local lsp = require("lspconfig")
            lsp.nil_ls.setup {}
            lsp.lua_ls.setup {}
            lsp.pyright.setup {}

            -- Treesitter 高亮
            require("nvim-treesitter.configs").setup {
              highlight = { enable = true },
            }
          '';
        };
      })
    ];
  };
}
