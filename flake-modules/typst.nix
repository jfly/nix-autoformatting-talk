{ inputs, ... }:
{
  perSystem =
    {
      config,
      self',
      pkgs,
      ...
    }:
    let
      typst = pkgs.typst.withPackages (ps: [
        ps.pinit
        ps.touying
      ]);
    in
    {
      treefmt.programs.typstyle.enable = true;

      devshells.default = {
        env = [
          {
            name = "TYPST_ROOT";
            eval = "$PRJ_ROOT";
          }
        ];
        packages = [
          typst
          pkgs.gnumake
        ];
      };

      packages.default = self'.packages.presentation;
      packages.presentation =
        pkgs.runCommandNoCC "nix-autoformatting.pdf"
          {
            nativeBuildInputs = config.devshells.default.packages;
            DIRTY_REV = inputs.self.dirtyRev or inputs.self.shortRev;
          }
          ''
            cd ${../.}
            make
          '';
      checks."packages/presentation" = self'.packages.presentation;
    };
}
