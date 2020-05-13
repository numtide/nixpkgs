{ config, lib, pkgs, ... }:

with lib;
let
  cfg = config.services.minio;
in
{
  meta.maintainers = [ maintainers.bachp ];

  options.services.minio = {
    enable = mkEnableOption "Minio Object Storage";

    listenAddress = mkOption {
      default = ":9000";
      type = types.str;
      description = "Listen on a specific IP address and port.";
    };

    dataDir = mkOption {
      default = "/var/lib/minio/data";
      type = types.path;
      description = "The data directory, for storing the objects.";
    };

    configDir = mkOption {
      default = "/var/lib/minio/config";
      type = types.path;
      description = "The config directory, for the access keys and other settings.";
    };

    accessKey = mkOption {
      default = "";
      type = types.str;
      description = ''
        Access key of 5 to 20 characters in length that clients use to access the server.
        This overrides the access key that is generated by minio on first startup and stored inside the
        <literal>configDir</literal> directory.
      '';
    };

    secretKey = mkOption {
      default = "";
      type = types.str;
      description = ''
        Specify the Secret key of 8 to 40 characters in length that clients use to access the server.
        This overrides the secret key that is generated by minio on first startup and stored inside the
        <literal>configDir</literal> directory.
      '';
    };

    region = mkOption {
      default = "us-east-1";
      type = types.str;
      description = ''
        The physical location of the server. By default it is set to us-east-1, which is same as AWS S3's and Minio's default region.
      '';
    };

    browser = mkOption {
      default = true;
      type = types.bool;
      description = "Enable or disable access to web UI.";
    };

    package = mkOption {
      default = pkgs.minio;
      defaultText = "pkgs.minio";
      type = types.package;
      description = "Minio package to use.";
    };
  };

  config = mkIf cfg.enable {
    systemd.tmpfiles.rules = [
      "d '${cfg.configDir}' - minio minio - -"
      "d '${cfg.dataDir}' - minio minio - -"
    ];

    systemd.services.minio = {
      description = "Minio Object Storage";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        ExecStart = "${cfg.package}/bin/minio server --json --address ${cfg.listenAddress} --config-dir=${cfg.configDir} ${cfg.dataDir}";
        Type = "simple";
        User = "minio";
        Group = "minio";
        LimitNOFILE = 65536;
      };
      environment = {
        MINIO_REGION = "${cfg.region}";
        MINIO_BROWSER = "${if cfg.browser then "on" else "off"}";
      } // optionalAttrs (cfg.accessKey != "") {
        MINIO_ACCESS_KEY = "${cfg.accessKey}";
      } // optionalAttrs (cfg.secretKey != "") {
        MINIO_SECRET_KEY = "${cfg.secretKey}";
      };
    };

    users.users.minio = {
      group = "minio";
      uid = config.ids.uids.minio;
    };

    users.groups.minio.gid = config.ids.uids.minio;
  };
}
