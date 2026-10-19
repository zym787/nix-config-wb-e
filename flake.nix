{
  # ============================================================
  # flake.nix —— 项目入口（推荐使用方式）
  # ------------------------------------------------------------
  # 用途：声明 NixOS 系统配置与 home-manager 的集成方式。
  # 常见修改点：
  #   1. nixpkgs.url 可改为 "github:NixOS/nixpkgs/nixos-26.11" 锁定稳定版；
  #   2. 新增主机时，在 nixosConfigurations 下仿照 my-laptop 增加条目；
  #   3. 构建命令：sudo nixos-rebuild switch --flake .#my-laptop
  # ============================================================
  description = "初学者友好的 NixOS 配置：niri + DankMaterialShell + 游戏会话";

  inputs = {
    # 基础包集：默认跟随 unstable，获得最新的 niri / DankMaterialShell 支持
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    # home-manager：以 nixos-module 方式集成（用户配置与系统配置协同生效）
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs"; # 与系统共用同一份 nixpkgs，避免双重求值
    };
  };

  outputs = { nixpkgs, home-manager, ... }@inputs:
    let
      # 导入 ./lib 下的通用工具函数（mkIfEnabled 等）
      myLib = import ./lib { inherit (nixpkgs) lib; };

      # 目标架构：如需 ARM 设备改为 "aarch64-linux"
      system = "x86_64-linux";

      # withSystem 封装：为指定主机目录生成完整 nixosSystem 配置
      mkHost = hostDir: nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = { inherit inputs myLib; };
        modules = [
          hostDir                       # 主机专属配置（hardware + 个性化）
          home-manager.nixosModules.home-manager
          {
            # home-manager 与系统级配置共享 pkgs / specialArgs，保证一致
            # （键合并书写，避免 statix W20 重复键警告）
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              extraSpecialArgs = { inherit inputs myLib; };
            };
          }
        ];
      };
    in
    {
      nixosConfigurations = {
        # 主机名 = 目录名；新增主机：mkdir hosts/xxx 并在此加一行
        my-laptop = mkHost ./hosts/my-laptop;
      };
    };
}
