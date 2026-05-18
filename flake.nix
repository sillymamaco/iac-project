{
  description = "Run Ripes Continuous AppImage with Wayland file-dialog fixes";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };
        
        ripes-appimage = pkgs.appimageTools.wrapType2 {
          pname = "ripes";
          version = "continuous";
          src = pkgs.fetchurl {
            url = "https://github.com/mortbopet/Ripes/releases/download/continuous/Ripes-v2.2.6-83-g14c54fc-linux-x86_64.AppImage";
           hash = "sha256-LT3FQliSW+U8ib48SvPTdaF05JN5Mb0p0TEy2+MtIL0="; 
          };
          extraPkgs = pkgs: with pkgs; [ gsettings-desktop-schemas ];
        };
      in
      {
        packages.default = pkgs.stdenv.mkDerivation {
          pname = "ripes-wrapped";
          version = "continuous";
          dontUnpack = true;
          nativeBuildInputs = [ pkgs.makeWrapper ];
          installPhase = ''
            mkdir -p $out/bin
            makeWrapper ${ripes-appimage}/bin/ripes $out/bin/ripes \
              --set QT_QPA_PLATFORM "wayland;xcb" \
              --prefix XDG_DATA_DIRS : "${pkgs.gsettings-desktop-schemas}/share" \
              --set QT_DONT_USE_NATIVE_DIALOG 1
          '';
        };

        apps.default = {
          type = "app";
          program = "${self.packages.${system}.default}/bin/ripes";
        };
      }
    );
}
