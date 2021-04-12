{ system ? builtins.currentSystem }:
let
  pkgs = import ./. { inherit system; config = { }; overlays = [ ]; };
  treefmt = import ../../numtide/treefmt { inherit system; };
in
pkgs.mkShell {
  buildInputs = [
    pkgs.nixpkgs-fmt
    pkgs.shfmt
    treefmt.treefmt
  ];
}
