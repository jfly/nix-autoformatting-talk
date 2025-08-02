{
  perSystem =
    { inputs', ... }:
    {
      packages."demos/nixvim" = import ../demos/nixvim/demo.nix { nixvim = inputs'.nixvim; };
    };
}
