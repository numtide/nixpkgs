{ config, lib, pkgs, ... }:

with lib;
let
  top = config.services.kubernetes;
  cfg = top.flannel;

  # we want flannel to use kubernetes itself as configuration backend, not direct etcd
  storageBackend = "kubernetes";

  # needed for flannel to pass options to docker
  mkDockerOpts =
    pkgs.runCommand "mk-docker-opts"
      {
        buildInputs = [ pkgs.makeWrapper ];
      } ''
      mkdir -p $out

      # bashInteractive needed for `compgen`
      makeWrapper ${pkgs.bashInteractive}/bin/bash $out/mk-docker-opts --add-flags "${pkgs.kubernetes}/bin/mk-docker-opts.sh"
    '';
in
{
  ###### interface
  options.services.kubernetes.flannel = {
    enable = mkEnableOption "enable flannel networking";
  };

  ###### implementation
  config = mkIf cfg.enable {
    services.flannel = {

      enable = mkDefault true;
      network = mkDefault top.clusterCidr;
      inherit storageBackend;
      nodeName = config.services.kubernetes.kubelet.hostname;
    };

    services.kubernetes.kubelet = {
      networkPlugin = mkDefault "cni";
      cni.config = mkDefault [{
        name = "mynet";
        type = "flannel";
        cniVersion = "0.3.1";
        delegate = {
          isDefaultGateway = true;
          bridge = "docker0";
        };
      }];
    };

    systemd.services.mk-docker-opts = {
      description = "Pre-Docker Actions";
      path = with pkgs; [ gawk gnugrep ];
      script = ''
        ${mkDockerOpts}/mk-docker-opts -d /run/flannel/docker
        systemctl restart docker
      '';
      serviceConfig.Type = "oneshot";
    };

    systemd.paths.flannel-subnet-env = {
      wantedBy = [ "flannel.service" ];
      pathConfig = {
        PathModified = "/run/flannel/subnet.env";
        Unit = "mk-docker-opts.service";
      };
    };

    systemd.services.docker = {
      environment.DOCKER_OPTS = "-b none";
      serviceConfig.EnvironmentFile = "-/run/flannel/docker";
    };

    # read environment variables generated by mk-docker-opts
    virtualisation.docker.extraOptions = "$DOCKER_OPTS";

    networking = {
      firewall.allowedUDPPorts = [
        8285 # flannel udp
        8472 # flannel vxlan
      ];
      dhcpcd.denyInterfaces = [ "docker*" "flannel*" ];
    };

    services.kubernetes.pki.certs = {
      flannelClient = top.lib.mkCert {
        name = "flannel-client";
        CN = "flannel-client";
        action = "systemctl restart flannel.service";
      };
    };

    # give flannel som kubernetes rbac permissions if applicable
    services.kubernetes.addonManager.bootstrapAddons = mkIf ((storageBackend == "kubernetes") && (elem "RBAC" top.apiserver.authorizationMode)) {

      flannel-cr = {
        apiVersion = "rbac.authorization.k8s.io/v1beta1";
        kind = "ClusterRole";
        metadata = { name = "flannel"; };
        rules = [{
          apiGroups = [ "" ];
          resources = [ "pods" ];
          verbs = [ "get" ];
        }
          {
            apiGroups = [ "" ];
            resources = [ "nodes" ];
            verbs = [ "list" "watch" ];
          }
          {
            apiGroups = [ "" ];
            resources = [ "nodes/status" ];
            verbs = [ "patch" ];
          }];
      };

      flannel-crb = {
        apiVersion = "rbac.authorization.k8s.io/v1beta1";
        kind = "ClusterRoleBinding";
        metadata = { name = "flannel"; };
        roleRef = {
          apiGroup = "rbac.authorization.k8s.io";
          kind = "ClusterRole";
          name = "flannel";
        };
        subjects = [{
          kind = "User";
          name = "flannel-client";
        }];
      };

    };
  };
}
