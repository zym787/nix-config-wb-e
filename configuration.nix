# ============================================================
# configuration.nix —— 传统（非 flake）构建入口
# ------------------------------------------------------------
# 用途：兼容 `nixos-rebuild` 的传统 channel 方式。
#   使用 flake 时本文件不会被读取（flake.nix 才是入口）；
#   不使用 flake 时，请确保 channel 中已添加 home-manager：
#     sudo nix-channel --add https://github.com/nix-community/home-manager/archive/master.tar.gz home-manager
#     sudo nix-channel --update
#   然后：sudo nixos-rebuild switch
# 常见修改点：一般无需改动，主机差异化配置放在 ./hosts/<主机名>/
# ============================================================
{ lib, ... }:

let
  myLib = import ./lib { inherit lib; };
in
{
  imports = [
    # 非 flake 方式下的 home-manager 模块（通过 channel 提供）
    <home-manager/nixos>
    # 主机专属配置（按需改成你的主机目录）
    ./hosts/my-laptop
  ];

  # 向所有子模块传递 myLib（与 flake 入口的 specialArgs 对应）
  _module.args.myLib = myLib;

  # home-manager 键合并书写（statix W20）
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    extraSpecialArgs = { inherit myLib; inputs = { }; };
  };
}
