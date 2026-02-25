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
        
        # Configuration for the different architectures
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
          version = "7.5.0";

          src = pkgs.fetchurl {
            inherit (selected) url sha256;
          };

          nativeBuildInputs = [ pkgs.autoPatchelfHook ];
          buildInputs = [ 
            pkgs.stdenv.cc.cc.lib 
            pkgs.libusb1 
            pkgs.glib
            pkgs.zlib
          ];

          # We expect the tarball to contain the /opt/pylon contents directly
          installPhase = ''
            mkdir -p $out
            cp -r * $out/
            chmod -R +w $out/bin $out/lib64 2>/dev/null || true
          '';
        };
      }
    );
}
