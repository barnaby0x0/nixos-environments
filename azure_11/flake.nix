{
  description = "PowerShell environment with Terraform 1.11.0";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          config.allowUnfree = true;
        };

        # Terraform 1.11.0 binaire précompilé
        terraform_1_11_0 = pkgs.stdenv.mkDerivation rec {
          pname = "terraform";
          version = "1.11.0";
          
          src = pkgs.fetchurl {
            url = "https://releases.hashicorp.com/terraform/${version}/terraform_${version}_linux_amd64.zip";
            hash = "sha256-Bp5TH9RlG5tRCtvX4n3WSLiNZtXzaaIFmq27S6rq0cE=";
          };
          
          nativeBuildInputs = [ pkgs.unzip ];
          
          dontUnpack = true;
          
          installPhase = ''
            mkdir -p $out/bin
            unzip -j $src terraform -d $out/bin
            chmod +x $out/bin/terraform
          '';
          
          meta = with pkgs.lib; {
            description = "Tool for building, changing, and versioning infrastructure";
            homepage = "https://www.terraform.io/";
            license = licenses.mpl20;
            maintainers = with maintainers; [ ];
            mainProgram = "terraform";
            platforms = [ "x86_64-linux" ];
          };
        };
        
      in
      {
        devShells.default = pkgs.mkShell {
          name = "azure-powershell-terraform-1.11.0";

          buildInputs = with pkgs; [
            powershell
            terraform_1_11_0
            azure-cli
            azure-storage-azcopy
            kubectl
            helm
            git
            jq
            yq
            curl
            wget
          ];

          shellHook = ''
            echo "🔷 Environment avec Terraform 1.11.0"
            echo "Terraform version: $(terraform --version | head -n1)"
            echo "Expected: Terraform v1.11.0"
          '';
        };
      }
    );
}
