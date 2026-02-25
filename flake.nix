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

          nativeBuildInputs = [ 
            pkgs.autoPatchelfHook 
            pkgs.dpkg 
          ];

          # These cover the Qt, X11, Wayland, and core SDK dependencies
          buildInputs = [ 
            pkgs.stdenv.cc.cc.lib 
            pkgs.libusb1 
            pkgs.glib
            pkgs.zlib
            pkgs.libxml2
            pkgs.libGL
            pkgs.libGLU
            pkgs.libxcb
            pkgs.xorg.libX11
            pkgs.xorg.libXrender
            pkgs.xorg.libXi
            pkgs.libxkbcommon
            pkgs.libdrm
            pkgs.libtiff
            pkgs.wayland
            pkgs.mesa
          ];

          unpackPhase = ''
            mkdir -p source
            tar -C source -xvf $src
            cd source
            
            echo "Extracting Debian packages..."
            for f in *.deb; do
              # || true ignores the SUID permission errors from CodeMeter
              dpkg-deb -x "$f" . || true
            done
          '';

          installPhase = ''
            mkdir -p $out
            
            # Move extracted contents from the standard deb path to the Nix store path
            if [ -d "./opt/pylon" ]; then
              cp -r ./opt/pylon/* $out/
            else
              cp -r * $out/
            fi

            # Fix for specific libtiff.so.5 requirement if only .so.6 is found
            mkdir -p $out/lib
            ln -s ${pkgs.libtiff}/lib/libtiff.so $out/lib/libtiff.so.5 || true
            
            # Ensure the store path is writable for the patching phase
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
