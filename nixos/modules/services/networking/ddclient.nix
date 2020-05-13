{ config, pkgs, lib, ... }:
let
  cfg = config.services.ddclient;
  boolToStr = bool: if bool then "yes" else "no";
  dataDir = "/var/lib/ddclient";

  configText = ''
    # This file can be used as a template for configFile or is automatically generated by Nix options.
    cache=${dataDir}/ddclient.cache
    foreground=YES
    use=${cfg.use}
    login=${cfg.username}
    password=${cfg.password}
    protocol=${cfg.protocol}
    ${lib.optionalString (cfg.script != "") "script=${cfg.script}"}
    ${lib.optionalString (cfg.server != "") "server=${cfg.server}"}
    ${lib.optionalString (cfg.zone != "") "zone=${cfg.zone}"}
    ssl=${boolToStr cfg.ssl}
    wildcard=YES
    quiet=${boolToStr cfg.quiet}
    verbose=${boolToStr cfg.verbose}
    ${cfg.extraConfig}
    ${lib.concatStringsSep "," cfg.domains}
  '';

in
with lib;

{

  imports = [
    (
      mkChangedOptionModule [ "services" "ddclient" "domain" ] [ "services" "ddclient" "domains" ]
        (config:
          let value = getAttrFromPath [ "services" "ddclient" "domain" ] config;
          in if value != "" then [ value ] else [ ])
    )
    (mkRemovedOptionModule [ "services" "ddclient" "homeDir" ] "")
  ];

  ###### interface

  options = {

    services.ddclient = with lib.types; {

      enable = mkOption {
        default = false;
        type = bool;
        description = ''
          Whether to synchronise your machine's IP address with a dynamic DNS provider (e.g. dyndns.org).
        '';
      };

      domains = mkOption {
        default = [ "" ];
        type = listOf str;
        description = ''
          Domain name(s) to synchronize.
        '';
      };

      username = mkOption {
        default = "";
        type = str;
        description = ''
          User name.
        '';
      };

      password = mkOption {
        default = "";
        type = str;
        description = ''
          Password. WARNING: The password becomes world readable in the Nix store.
        '';
      };

      interval = mkOption {
        default = "10min";
        type = str;
        description = ''
          The interval at which to run the check and update.
          See <command>man 7 systemd.time</command> for the format.
        '';
      };

      configFile = mkOption {
        default = "/etc/ddclient.conf";
        type = path;
        description = ''
          Path to configuration file.
          When set to the default '/etc/ddclient.conf' it will be populated with the various other options in this module. When it is changed (for example: '/root/nixos/secrets/ddclient.conf') the file read directly to configure ddclient. This is a source of impurity.
          The purpose of this is to avoid placing secrets into the store.
        '';
        example = "/root/nixos/secrets/ddclient.conf";
      };

      protocol = mkOption {
        default = "dyndns2";
        type = str;
        description = ''
          Protocol to use with dynamic DNS provider (see https://sourceforge.net/p/ddclient/wiki/protocols).
        '';
      };

      server = mkOption {
        default = "";
        type = str;
        description = ''
          Server address.
        '';
      };

      ssl = mkOption {
        default = true;
        type = bool;
        description = ''
          Whether to use to use SSL/TLS to connect to dynamic DNS provider.
        '';
      };


      quiet = mkOption {
        default = false;
        type = bool;
        description = ''
          Print no messages for unnecessary updates.
        '';
      };

      script = mkOption {
        default = "";
        type = str;
        description = ''
          script as required by some providers.
        '';
      };

      use = mkOption {
        default = "web, web=checkip.dyndns.com/, web-skip='Current IP Address: '";
        type = str;
        description = ''
          Method to determine the IP address to send to the dynamic DNS provider.
        '';
      };

      verbose = mkOption {
        default = true;
        type = bool;
        description = ''
          Print verbose information.
        '';
      };

      zone = mkOption {
        default = "";
        type = str;
        description = ''
          zone as required by some providers.
        '';
      };

      extraConfig = mkOption {
        default = "";
        type = lines;
        description = ''
          Extra configuration. Contents will be added verbatim to the configuration file.
        '';
      };
    };
  };


  ###### implementation

  config = mkIf config.services.ddclient.enable {
    environment.etc."ddclient.conf" = {
      enable = cfg.configFile == "/etc/ddclient.conf";
      mode = "0600";
      text = configText;
    };

    systemd.services.ddclient = {
      description = "Dynamic DNS Client";
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];
      restartTriggers = [ config.environment.etc."ddclient.conf".source ];

      serviceConfig = rec {
        DynamicUser = true;
        RuntimeDirectory = StateDirectory;
        StateDirectory = builtins.baseNameOf dataDir;
        Type = "oneshot";
        ExecStartPre = "!${lib.getBin pkgs.coreutils}/bin/install -m666 ${cfg.configFile} /run/${RuntimeDirectory}/ddclient.conf";
        ExecStart = "${lib.getBin pkgs.ddclient}/bin/ddclient -file /run/${RuntimeDirectory}/ddclient.conf";
      };
    };

    systemd.timers.ddclient = {
      description = "Run ddclient";
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnBootSec = cfg.interval;
        OnUnitInactiveSec = cfg.interval;
      };
    };
  };
}
