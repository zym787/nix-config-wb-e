# ============================================================
# modules/security.nix —— 安全基线配置
# ------------------------------------------------------------
# 用途：日志持久化、umask、root 登录限制、本地 DNS 解析。
# 常见修改点：
#   1. unbound 上游 DNS 在 forward-zone 中修改；
#   2. umask 022（宽松）/ 027（组不可读）/ 077（完全私有）
# ============================================================
{ config, pkgs, lib, myLib, ... }:

{
  options.my.security.enable = myLib.mkEnable' "安全基线";

  config = myLib.mkIfEnabled config.my.security.enable {

    # ---- journald 日志持久化（默认重启即丢，此处落盘） ----
    services = {
      journald.extraConfig = ''
        Storage=persistent
        SystemMaxUse=500M
      '';

      # ---- SSH 默认关闭；需要时打开且保持下列加固项 ----
      openssh = {
        enable = false;
        settings = {
          PermitRootLogin = "no";
          PasswordAuthentication = false;
        };
      };

      # ---- unbound：本地递归 DNS 解析（隐私 + 抗劫持） ----
      unbound = {
        enable = true;
        settings = {
          server = {
            interface = [ "127.0.0.1" "::1" ];
            do-tcp = true;
            # DNSSEC 校验
            auto-trust-anchor-file = [ "/var/lib/unbound/root.key" ];
            # 常见修改点：上游改为 DoT（如 1.1.1.1@853#cloudflare-dns.com）
            qname-minimisation = true;
          };
          forward-zone = [{
            name = ".";
            forward-addr = [ "223.5.5.5" "119.29.29.29" ]; # 阿里/腾讯公共 DNS，按地区替换
          }];
        };
      };

      # 与 unbound 冲突，关闭 systemd-resolved
      resolved.enable = false;
    };

    # ---- 默认 umask：新建文件 750/640，组外不可读 ----
    # 通过 /etc/login.defs 的 UMASK 设置（nixpkgs 无对应高层选项，
    # 故直接管理该文件；常见修改点：需要共享文件时改回 "022"）
    environment.etc."login.defs".text = ''
      UMASK 027
    '';

    # ---- 禁用 root 密码登录（保留 sudo 提权路径） ----
    users.users.root.hashedPassword = "!"; # "!" 表示锁定密码登录
    security.sudo.wheelNeedsPassword = true;

    # ---- 网络：unbound 接管 DNS + 防火墙 ----
    networking = {
      nameservers = [ "127.0.0.1" "::1" ];
      networkmanager.dns = "none"; # 由 unbound 接管，不用 DHCP 下发的 DNS
      resolvconf.enable = false;
      firewall.enable = true;
    };
  };
}
