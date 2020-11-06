import ./make-test-python.nix ({ pkgs, lib, ... }:
  let
    accessKey = "BKIKJAA5BMMU2RHO6IBB";
    secretKey = "V7f1CwQqAcwo80UEIJEjc5gVQUSSx5ohQ9GSrr12";
    nixCacheURL = "s3://test-bucket?region=us-east-1&endpoint=localhost:9000&scheme=http";
  in
  {
    name = "nar-serve";
    meta.maintainers = [ lib.maintainers.rizary ];
    nodes =
      {
        server = { pkgs, ... }: {
          services.minio = {
            enable = true;
            inherit accessKey secretKey;
          };
          services.nar-serve = {
            enable = true;
            nixCacheURL = nixCacheURL;
          };
          environment.systemPackages = [
            pkgs.minio-client
            pkgs.hello
            pkgs.curl
          ];

          # TODO: handle AWS credentials better. These are not necessary when
          #       running on AWS as they can be sources from the EC2 instance
          #       IAM Role.
          systemd.services.nar-serve.environment = {
            AWS_ACCESS_KEY_ID = accessKey;
            AWS_SECRET_KEY = secretKey;
          };

          networking.firewall.allowedTCPPorts = [ 8383 ];

          # Minio requires at least 1GiB of free disk space to run.
          virtualisation.diskSize = 2 * 1024;
        };
      };
    testScript = ''
      start_all()

      server.wait_for_unit("minio.service")
      server.wait_for_open_port(9000)

      # Create a test bucket on the server
      server.succeed(
          "mc config host add minio http://localhost:9000 ${accessKey} ${secretKey} --api s3v4"
      )
      server.succeed("mc mb minio/test-bucket")
      assert "test-bucket" in server.succeed("mc ls minio")

      # Add a derivation to the cache
      server.succeed(
          "AWS_ACCESS_KEY_ID=${accessKey} AWS_SECRET_ACCESS_KEY=${secretKey} nix copy --to '${nixCacheURL}' ${pkgs.hello}"
      )
      drvName = os.path.basename("${pkgs.hello}")
      drvHash = drvName.split("-")[0]

      # Check that nar-serve can return the content of the derivation
      server.wait_for_unit("nar-serve.service")
      server.succeed(
          "curl -o hello -f http://localhost:8383/nix/store/{}/bin/hello".format(drvHash)
      )
    '';
  }
)
