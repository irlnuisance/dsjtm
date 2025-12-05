{
  description = "OCaml development environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        ocamlPackages = pkgs.ocaml-ng.ocamlPackages_5_2;
      in
      {
        devShells.default = pkgs.mkShell {
          buildInputs = with ocamlPackages; [
            ocaml
            dune_3
            findlib
            ocaml-lsp
            ocamlformat
            utop
            odoc
          ] ++ (with pkgs; [
            opam
            pkg-config
          ]);

          shellHook = ''
            echo "OCaml $(ocaml -version | head -1)"
            echo "Dune $(dune --version)"
          '';
        };
      }
    );
}
