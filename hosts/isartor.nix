{ config, pkgs, ... }:

let
  secrets = (import ../secrets);
in

{
  imports = [
    ../modules/default.nix
    ../modules/gateway.nix
  ];

  hardware.enableAllFirmware = true;
  boot.initrd.availableKernelModules = [ "xhci_pci" "ehci_pci" "ahci" "uhci_hcd" "usbhid" "usb_storage" "sd_mod" "sr_mod" ];
  boot.kernelModules = [ "kvm-intel" ];
  boot.extraModulePackages = [ ];

  fileSystems."/" =
    { device = "/dev/disk/by-uuid/d0ca21c6-f0b7-46a2-8e48-572156dabd44";
      fsType = "btrfs";
    };

  nix.maxJobs = 4;

  boot.loader.grub.enable = true;
  boot.loader.grub.version = 2;
  boot.loader.grub.device = "/dev/sda";

  freifunk.gateway = {
    enable = true;
    externalInterface = "eno1";
    ip4Interface = "tun0";
    ip6Interface = "eno1";
    networkingLocalCommands = ''
      ip rule add from 195.30.94.49/32 lookup 5
      ip route replace default via 195.30.94.62 table 5
    '';
    graphite = secrets.stats.bpletza;
    segments = {
      ffmuc = {
        baseMacAddress = "80:00:03:23:42";
        bridgeInterface = {
          ip4 = [ { address = "10.80.32.13"; prefixLength = 19; } ];
          ip6 = [
            { address = "fdef:ffc0:4fff::13"; prefixLength = 64; }
            { address = "2001:608:a01:2::13"; prefixLength = 64; }
          ];
        };
        dhcpRanges = [ "10.80.34.0,10.80.43.255,255.255.224.0,1h" ];
        ra.prefixes = [ "2001:608:a01:2::/64" ];
        ra.rdnss = [ "2001:608:a01:2::13" ];
        fastdConfigs = let
          secret = secrets.fastd.gw03.secret;
          listenAddress = "195.30.94.49";
        in {
          backbone = {
            inherit secret listenAddress;
            listenPort = 9999;
            mtu = 1426;
          };
          mesh0 = {
            inherit secret listenAddress;
            listenPort = 10000;
            mtu = 1426;
          };
          mesh1 = {
            inherit secret listenAddress;
            listenPort = 10099;
            mtu = 1426;
          };
          mesh2 = {
            inherit secret listenAddress;
            listenPort = 10001;
            mtu = 1280;
          };
          mesh3 = {
            inherit secret listenAddress;
            listenPort = 10098;
            mtu = 1280;
          };
        };
        portBalancings = [
          { from = 10000; to = 10099; }
          { from = 10001; to = 10098; }
        ];
      };
      welcome = {
        baseMacAddress = "80:ff:02:23:42";
        bridgeInterface = {
          ip4 = [ { address = "10.80.64.12"; prefixLength = 19; } ];
          ip6 = [
            { address = "fdef:ffc0:4fff:1::12"; prefixLength = 64; }
            { address = "2001:608:a01:3::12"; prefixLength = 64; }
          ];
        };
        dhcpRanges = [ "10.80.68.0,10.80.90.255,255.255.224.0,1h" ];
        ra.prefixes = [ "2001:608:a01:3::/64" ];
        ra.rdnss = [ "2001:608:a01:3::12" ];
        fastdConfigs = let
          secret = secrets.fastd.gwf02.secret;
          listenAddress = "195.30.94.49";
        in {
          mesh0 = {
            inherit secret listenAddress;
            listenPort = 11000;
            mtu = 1426;
          };
          mesh1 = {
            inherit secret listenAddress;
            listenPort = 11099;
            mtu = 1426;
          };
          mesh2 = {
            inherit secret listenAddress;
            listenPort = 11001;
            mtu = 1280;
          };
          mesh3 = {
            inherit secret listenAddress;
            listenPort = 11098;
            mtu = 1280;
          };
        };
        portBalancings = [
          { from = 11000; to = 11099; }
          { from = 11001; to = 11098; }
        ];
      };
      umland = {
        baseMacAddress = "80:01:02:23:42";
        bridgeInterface = {
          ip4 = [ { address = "10.80.96.12"; prefixLength = 19; } ];
          ip6 = [
            { address = "fdef:ffc0:4fff:2::12"; prefixLength = 64; }
            { address = "2001:608:a01:4::12"; prefixLength = 64; }
          ];
        };
        dhcpRanges = [ "10.80.98.0,10.80.105.255,255.255.224.0,1h" ];
        ra.prefixes = [ "2001:608:a01:4::/64" ];
        ra.rdnss = [ "2001:608:a01:4::12" ];
        fastdConfigs = let
          secret = secrets.fastd.gwu02.secret;
          listenAddress = "195.30.94.49";
        in {
          mesh0 = {
            inherit secret listenAddress;
            listenPort = 10011;
            mtu = 1426;
          };
          mesh1 = {
            inherit secret listenAddress;
            listenPort = 10089;
            mtu = 1426;
          };
        };
        portBalancings = [
          { from = 10011; to = 10089; }
        ];
      };
     };
  };

  networking = {
    hostName = "isartor";
    interfaces.eno2 = {
      ip4 = [ { address = "195.30.94.27"; prefixLength = 29; } ];
      ip6 = [ { address = "2001:608:a01::2"; prefixLength = 64; } ];
    };
    interfaces.eno1 = {
      ip4 = [ { address = "195.30.94.49"; prefixLength = 28; } ];
      ip6 = [ { address = "2001:608:a01:1::2"; prefixLength = 64; } ];
    };
    defaultGateway = "195.30.94.30";
    defaultGateway6 = "2001:608:a01:1::1";
    firewall.extraCommands = ''
      ip46tables -I nixos-fw 3 -i eno2 -p tcp --dport 655 -j nixos-fw-accept
      ip46tables -I nixos-fw 3 -i eno2 -p udp --dport 655 -j nixos-fw-accept
      ip46tables -I FORWARD 1 -i eno1 -o br-ffmuc -j ACCEPT
      ip46tables -I FORWARD 1 -i br-ffmuc -o eno1 -j ACCEPT
      ip6tables -I nixos-fw 3 -i tinc.backbone -m pkttype --pkt-type multicast -j nixos-fw-accept
      ip46tables -I FORWARD 1 -i eno1 -o tinc.backbone -j ACCEPT
      ip46tables -I FORWARD 1 -i tinc.backbone -o eno1 -j ACCEPT
      ip46tables -I FORWARD 1 -i br0 -o tinc.backbone -j ACCEPT
      ip46tables -I FORWARD 1 -i tinc.backbone -o br0 -j ACCEPT
    '';
  };

   environment.systemPackages = with pkgs; [
     tinc_pre babeld
   ];

  services = {
    tinc.networks = {
      backbone = {
        package = pkgs.tinc_pre;
        interfaceType = "tap";
        listenAddress = "195.30.94.27";
        extraConfig = ''
          Mode = switch
          ExperimentalProtocol = yes
        '';
      };
    };
  };

  systemd.services = {
    babeld = let
      babeldConf = pkgs.writeText "babeld.conf" ''
        redistribute ip ::/0 le 0 proto 3 metric 128
        redistribute ip 2001:608:a01::/48 le 127 metric 128
        redistribute ip fdef:ffc0:4fff::/48 le 127 metric 128
        redistribute local deny
        redistribute deny
        in ip 0.0.0.0/32 le 0 deny
        in ip ::/128 le 0 deny
      '';
      in {
        description = "Babel routing daemon";
        wantedBy = [ "network.target" "multi-user.target" ];
        after = [ "tinc.backbone" ];
        serviceConfig = {
          ExecStart =
            "${pkgs.babeld}/bin/babeld -c ${babeldConf} tinc.backbone";
        };
      };
  };

  services.openvpn.servers = secrets.openvpn;

  users.extraUsers.root.password = secrets.rootPassword;
}

