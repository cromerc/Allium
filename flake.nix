{
  inputs = {
    fenix = {
      url = "github:nix-community/fenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    flake-utils.url = "github:numtide/flake-utils";
    naersk = {
      url = "github:nix-community/naersk";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixpkgs.url = "nixpkgs/nixos-unstable";
  };

  outputs =
    {
      self,
      fenix,
      flake-utils,
      naersk,
      nixpkgs,
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        target = "armv7-unknown-linux-gnueabihf";
        crossPkgs = pkgs.pkgsCross.armv7l-hf-multiplatform;
        toolchain =
          with fenix.packages.${system};
          combine [
            minimal.cargo
            minimal.rustc
            targets.${target}.latest.rust-std
          ];
        naersk-lib = naersk.lib.${system}.override {
          cargo = toolchain;
          rustc = toolchain;
        };
      in
      {
        packages.default = naersk-lib.buildPackage {
          src = ./.;
          buildInputs = [
            pkgs.libclang
            crossPkgs.sqlite
          ];
          LIBCLANG_PATH = "${pkgs.llvmPackages.libclang.lib}/lib";
          CARGO_BUILD_TARGET = target;
          "CC_${target}" = "${crossPkgs.stdenv.cc}/bin/${crossPkgs.stdenv.cc.targetPrefix}cc";
          CARGO_TARGET_ARMV7_UNKNOWN_LINUX_GNUEABIHF_LINKER = "${crossPkgs.stdenv.cc}/bin/${crossPkgs.stdenv.cc.targetPrefix}cc";
        };
      }
    );
}
