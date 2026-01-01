{
  description = "Nix package for wfinfo-ng";

  inputs = {
    # Nixpkgs is the core dependency
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
    
    # I want to use flake.lock to lock it to specific version.
    wfinfo-ng = {
      url = "path:/home/joonas/Documents/wfinfo-ng";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, wfinfo-ng }:
    let
      # Define system architectures (e.g., standard Linux)
      supportedSystems = [ "x86_64-linux" "aarch64-linux" ];
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
      
      # Import Nixpkgs for each system (this is the outer mapping)
      pkgs = forAllSystems (system: import nixpkgs {
        inherit system;
        config.allowUnfree = true; # Allow unfree packages, just in case
      });

    in {
      # The 'packages' output contains the package derivation
      packages = forAllSystems (system:

        let 
          # pkgsForSystem is the single-system package set we MUST use locally
          pkgsForSystem = pkgs.${system}; 
          

        in
        {
          wfinfo-ng = pkgsForSystem.rustPlatform.buildRustPackage { 
            pname = "wfinfo-ng";
            version = "unstable-2024-09-30";

            doCheck = false;
            RUST_BACKTRACE = "1";

            src = wfinfo-ng; 

              cargoLock = {
                lockFile = "${wfinfo-ng}/Cargo.lock";
              };


            # Build-time dependencies
            nativeBuildInputs = [
              pkgsForSystem.cmake
              pkgsForSystem.pkg-config
              pkgsForSystem.rustPlatform.bindgenHook
              pkgsForSystem.curl
              pkgsForSystem.jq
            ];

            # Runtime/shared library dependencies
            buildInputs =  [
              pkgsForSystem.lxrandr
              pkgsForSystem.tesseract 
              pkgsForSystem.curl
              pkgsForSystem.jq
              pkgsForSystem.xorg.libX11
              pkgsForSystem.xorg.libXi
              pkgsForSystem.xorg.libXtst
              pkgsForSystem.leptonica
              pkgsForSystem.fontconfig
              pkgsForSystem.dbus
            ];
            
            meta = {
              description = "A Linux compatible version of WFinfo to analyze relic reward screens";
              homepage = "https://github.com/juiveli/wfinfo-ng";
              license = pkgsForSystem.lib.licenses.gpl3; # Use licenses.gpl3, not lib.gpl3
              platforms = pkgsForSystem.lib.platforms.linux;
            };

          };

          # Alias for simple building: nix build .
          default = self.packages.${system}.wfinfo-ng;
        }
      );
    };
}
