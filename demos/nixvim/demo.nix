{ nixvim, ... }:
nixvim.legacyPackages.makeNixvim {
  plugins = {
    lspconfig.enable = true;

    # Format on save.
    lsp-format = {
      enable = true;
      lspServersToEnable = "none";
    };

    # Configure none-ls's `nix_flake_fmt` builtin.
    none-ls = {
      enable = true;
      enableLspFormat = true;
      sources.formatting.nix_flake_fmt.enable = true;
    };

    # See notifications, including startup notifications.
    fidget.enable = true;
  };
}
