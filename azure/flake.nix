{
  description = "PowerShell environment with Terraform";

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

        # Lire la configuration depuis un fichier
        configFile = ./terraform-version;
        configContent = if builtins.pathExists configFile then
          builtins.readFile configFile
        else
          "1.13.0:sha256-3o75BfhPJGddogKmln/dxAsrI8FfySpQB1cPRqn8wQQ=";

        # Parser le format "version:hash"
        parseConfig = content:
          let
            lines = builtins.filter (line: line != "") (builtins.split "\n" content);
            firstLine = builtins.elemAt lines 0;
            parts = builtins.split ":" firstLine;
          in
          if builtins.length parts >= 3 then {
            version = builtins.elemAt parts 0;
            hash = builtins.elemAt parts 2;
          } else {
            version = "1.13.0";
            hash = "sha256-3o75BfhPJGddogKmln/dxAsrI8FfySpQB1cPRqn8wQQ=";
          };

        config = parseConfig configContent;
        tfVersion = config.version;
        tfHash = config.hash;


        # Lire la configuration depuis un fichier
        # configFile = ./terraform-version;
        # tfVersion = if builtins.pathExists configFile then
        #   builtins.replaceStrings ["\n"] [""] (builtins.readFile configFile)
        # else
        #   "1.13.0";

        # Récupérer la version depuis l'environnement ou utiliser la valeur par défaut
        # tfVersion = let envValue = builtins.getEnv "TF_VERSION"; in
        #   if envValue != "" then envValue else "1.13.0";

        # Afficher la version dans les logs de construction
        terraform_custom = pkgs.stdenv.mkDerivation rec {
          pname = "terraform";
          version = tfVersion;
          
          src = pkgs.fetchurl {
            url = "https://releases.hashicorp.com/terraform/${version}/terraform_${version}_linux_amd64.zip";
            hash = tfHash;
          };
          
          nativeBuildInputs = [ pkgs.unzip ];
          
          dontUnpack = true;
          
          installPhase = ''
            echo "📦 Installation de Terraform version: ${version}"
            mkdir -p $out/bin
            unzip -j $src terraform -d $out/bin
            chmod +x $out/bin/terraform
            echo "✅ Terraform ${version} installé avec succès"
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
          name = "azure-powershell-terraform";

          buildInputs = with pkgs; [
            powershell
            terraform_custom
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
            echo "🔷 Environment avec Terraform"
            echo "Version demandée: ${tfVersion}"
            echo "Version installée: $(terraform --version | head -n1)"
          '';
        };
      }
    );
}
