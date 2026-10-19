# ============================================================
# lib/default.nix —— 通用 Nix 函数库
# ------------------------------------------------------------
# 用途：集中存放可复用的工具函数，各模块通过 `myLib` 参数取用。
# 常见修改点：新增函数时在此追加属性即可，例如 myLib.myFunc = ...;
# ============================================================
{ lib }:

rec {
  # mkIfEnabled：把「开关 + 配置」二合一的便捷封装。
  # 用法示例：
  #   options.my.foo.enable = mkEnableOption "foo";
  #   config = myLib.mkIfEnabled config.my.foo.enable { services.foo.enable = true; };
  mkIfEnabled = cond: cfg: lib.mkIf cond cfg;

  # mkEnableOptionWithDefault：带默认描述的开关选项封装，减少样板代码
  mkEnable' = name: lib.mkEnableOption "启用 ${name} 模块";

  # withSystem：为指定系统架构绑定 pkgs，便于跨架构复用
  # 用法：myLib.withSystem "x86_64-linux" (pkgs: ...)
  withSystem = system: f: f (import <nixpkgs> { inherit system; });

  # listNixFiles：列出目录下所有 .nix 文件（default.nix 除外），
  # 用于「自动导入某目录所有模块」的场景
  listNixFiles = dir:
    let
      entries = builtins.readDir dir;
      isNix = name: type:
        type == "regular" && lib.hasSuffix ".nix" name && name != "default.nix";
    in
    map (name: dir + "/${name}")
      (builtins.attrNames (lib.filterAttrs isNix entries));
}
