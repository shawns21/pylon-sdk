{
  description = "Basler Pylon SDK for Nexus";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        
        pylonInfo = {
          "x86_64-linux" = {
            url = "https://github.com/shawns21/pylon-sdk/releases/download/v1.0.0/pylon-7.5.0.15658-linux-x86_64_debs.tar.gz";
            sha256 = "1xwa62g4j82m7cn028xyrz1kcscbj1rwdb0w24mbryy9xjja8cc8";
          };
          "aarch64-linux" = {
            url = "https://github.com/shawns21/pylon-sdk/releases/download/v1.0.0/pylon-7.5.0.15658-linux-aarch64_debs.tar.gz";
            sha256 = "1ar0imqfmrkip75sqxl7ghr65v8wr0sxj6cifwr9wr5kwf2lbm4q";
          };
        };

        selected = pylonInfo.${system} or (throw "Unsupported system: ${system}");
      in
      {
        packages.default = pkgs.stdenv.mkDerivation {
          pname = "pylon-sdk";
          version = "7.5.0.15658";

          src = pkgs.fetchurl {
            inherit (selected) url sha256;
          };

          # autoPatchelfHook fixes the "Library not found" errors
          # dpkg is required to extract the .deb files inside the tarball
          nativeBuildInputs = [ 
            pkgs.autoPatchelfHook 
            pkgs.dpkg 
          ];

          # Dependencies found in the Basler binaries
          buildInputs = [ 
            pkgs.stdenv.cc.cc.lib 
            pkgs.libusb1 
            pkgs.glib
            pkgs.zlib
            pkgs.libxml2
          ];

          # Manual unpack because the tarball contains multiple .deb files
          unpackPhase = ''
            mkdir -p source
            tar -C source -xvf $src
            cd source
            
            echo "Extracting Debian packages..."
            for f in *.deb; do
              # We use --extract and pipe to dev/null to ignore the permission errors
              # that happen with the CodeMeter setuid binaries.
              dpkg-deb -x "$f" . || true
            done
          '';
	  installPhase = ''
            mkdir -p $out
            if [ -d "./opt/pylon" ]; then
              cp -r ./opt/pylon/* $out/
            else
              cp -r * $out/
            fi
            
            # Remove any existing broken symlinks or high-privilege bits 
            # that might interfere with the Nix store
            chmod -R u+w $out
          '';
          meta = {
            description = "Basler Pylon SDK";
            homepage = "https://www.baslerweb.com";
            license = pkgs.lib.licenses.unfree;
          };
        };
      }
    );
}
