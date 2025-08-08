#import "@preview/touying:0.6.1": *
#import themes.simple: *

#show: simple-theme.with(aspect-ratio: "16-9")

#set footnote(numbering: "*")

#let screenshot(body) = {
  rect(
    body,
    stroke: gray,
    radius: 5pt,
    fill: white,
  )
}

= Autoformatting with Nix in Neovim

#align(bottom)[
  Nix Vegas, DEFCON 2025

  Jeremy Fleischman

  #let rev = sys.inputs.at("DIRTY_REV", default: none)
  #if rev != none {
    link("https://github.com/jfly/nix-autoformatting-talk/tree/" + rev)
  }
]

== About me

#grid(
  columns: (1fr, 2fr),
  align(center, [#box(
      image("me.jpg", width: 75%),
      radius: 10pt,
      clip: true,
    )
  ]),
  align(horizon)[
    - Jeremy Fleischman (`@jfly` on GitHub)
    - Speedcuber #box(baseline: 20%)[#image("cube.svg", height: 1em)]
      - #text(size: .75em)[2010 US National Champion 3x3x3 One-Handed]
    - Nix user since 2021
    - Currently enjoying a Nix-focused sabbatical
      - Treefmt maintainer
      - Member of the NixOS Infrastructure Team
      - Leader of the Nix Formatting Team
  ],
)

== Goals for this talk

1. If you're want your project consistently formatted in CI and local dev, use `treefmt`
2. If you're contributing to projects that use `nix`, use `none-ls.nvim`'s `nix_flake_fmt`, or build something like it
3. Contribute to Nix! It's fun and not scary.

= Treefmt Soapbox

#image("tree-fm-tea.svg", height: 75%)

== Why Treefmt?

From `immich-app/immich`
#footnote[https://github.com/immich-app/immich/blob/v1.137.3/mobile/makefile#L37-L39]:

```console
$ cat mobile/makefile
```
```Makefile
format:
# Ignore generated files manually until https://github.com/dart-lang/dart_style/issues/864 is resolved
	dart format --set-exit-if-changed $$(find lib -name '*.dart' -not \( -name 'generated_plugin_registrant.dart' -o -name '*.g.dart' -o -name '*.drift.dart' \))
```

== Treefmt - "The formatter multiplexer" #footnote[https://treefmt.com/]

Implement the Formatter Specification
#footnote[https://treefmt.com/latest/reference/formatter-spec/]:

```<command> [options] [...<files>]```

For example: ```console nixfmt foo.nix bar.nix```

#pause
We will walk the filesystem for you. Fast.

== Let's rewrite that earlier example

#text(size: 0.75em)[
  ```console
  $ cat mobile/makefile
  ```
  ```Makefile
  format:
  # Ignore generated files manually until https://github.com/dart-lang/dart_style/issues/864 is resolved
  	dart format --set-exit-if-changed $$(find lib -name '*.dart' -not \( -name 'generated_plugin_registrant.dart' -o -name '*.g.dart' -o -name '*.drift.dart' \))
  ```
]

#pause
#pad(y: .5em)[
  #text(size: 0.75em)[
    ```console
    $ cat treefmt.toml
    ```
    ```toml
    [formatter.dart]
    command = "dart"
    options = [ "format" ]
    includes = [ "*.dart" ]
    excludes = [ "generated_plugin_registrant.dart", "*.g.dart", "*.drift.dart" ]
    ```
  ]
]

== Et voilà!

#text(size: 0.75em)[
  ```console
  $ treefmt
  ...
  INFO formatter | editorconfig-checker[1]: 1024 file(s) processed in 4.440477439s
  INFO formatter | nixfmt: 1024 file(s) processed in 36.077195953s
  INFO formatter | editorconfig-checker[1]: 1024 file(s) processed in 2.663098081s
  traversed 49041 files
  emitted 44191 files for processing
  formatted 8432 files (0 changed) in 39.144s
  ```

  #pause
  ```
  $ treefmt
  INFO config: searching for tree root using tree-root-file: .git-blame-ignore-revs
  INFO config: tree root: /home/jeremy/src/github.com/NixOS/nixpkgs
  traversed 49041 files
  emitted 44191 files for processing
  formatted 0 files (0 changed) in 417ms
  ```
]

== That `treefmt.toml` made some assumptions...

#text(size: 0.75em)[
  ```toml
  [formatter.dart]
  command = "dart"
  options = [ "format" ]
  includes = [ "*.dart" ]
  excludes = [ "generated_plugin_registrant.dart", "*.g.dart", "*.drift.dart" ]
  ```
]

Where does `dart` come from? How about `treefmt` itself?

== `treefmt-nix`

#columns(2)[
  #text(size: 0.5em)[
    #only("1-2")[
      #let flake = read("../demos/treefmt-nix/flake.nix")
      ```nix
      $ cat flake.nix
      ```
      #raw(flake, lang: "nix")
      #colbreak()
    ]

    #pause
    #let formatting = read("../demos/treefmt-nix/formatting.nix")
    ```nix
    $ cat formatting.nix
    ```
    #raw(formatting, lang: "nix")

    #pause
    #only("4-")[
      ```console
      $ nix flake show
      ├───checks
      │   └───x86_64-linux
      │       └───treefmt: derivation 'treefmt-check'
      └───formatter
          └───x86_64-linux: package 'treefmt'
      ```
      #colbreak()
    ]

    #pause
    #only("5-")[
      ```console
      $ nix flake check && echo 'Success!'
      Success!
      ```
    ]

    #pause
    #only("6-")[
      ```console
      $ nix fmt
      traversed 10 files
      emitted 6 files for processing
      formatted 0 files (0 changed) in 16ms
      ```
    ]
  ]
]

== To summarize

#columns(2)[
  #text(size: 0.7em)[
    ```console
    $ cat mobile/makefile
    ```
    ```Makefile
    format:
    # Ignore generated files manually until https://github.com/dart-lang/dart_style/issues/864 is resolved
    	dart format --set-exit-if-changed $$(find lib -name '*.dart' -not \( -name 'generated_plugin_registrant.dart' -o -name '*.g.dart' -o -name '*.drift.dart' \))
    ```


    #pause
    #colbreak()
    #let formatting = read("../demos/treefmt-nix/formatting.nix")
    ```nix
    $ cat formatting.nix
    ```
    #raw(formatting, lang: "nix")
  ]
]

== Ain't nobody gonna remember to run that

There are 3 ways people try to automate this:

#pause
- `pre-commit` hooks
#pause
- Watching the filesystem (`fswatch`, etc.)
#pause
- Editor integration

#speaker-note[
  Editor integration is the gold standard, but getting it wrong is worse than nothing.
  Explain summer of nix experience, and dealing with PRs that are buried in unrelated formatting changes.
]

= Let's build a Neovim plugin

== Design

- Run `nix fmt <filename>` on save
#pause
- Performance matters, so we have to cache the entrypoint

#pause
In `nixpkgs`: #only("3-")[#footnote[Evaluation caching gets this closer to 2 seconds, but what if you're editing `flake.nix`?]]

#box[
  ```console
  $ time nix eval .#formatter.x86_64-linux
  «derivation /nix/store/pzidry16kalva72760...-treefmt.drv»
  ...
  Executed in 14.52 secs
  ```
]

== Some pain points

- Nix (< 2.29) doesn't expose the formatter entrypoint
  - I opted to work around this by shelling out to Nix from Lua
#pause
- `none-ls.nvim` is the natural place to put this, but, its support for `dynamic_command` needed some love
#pause
- Treefmt refused to format the (untracked) temp files `none-ls` creates
  - I ran into enough Treefmt bugs that I became a maintainer
#pause
- Neovim's support for trusting directories was buggy

#pause
12 PRs to none-ls.nvim, 2 PRs to treefmt, 1 PR to neovim

== This code does not spark joy

- `nix_flake_fmt` has landed in `none-ls.nvim`!
#pause
- I'm vaguely worried it's going to get kicked out of `none-ls.nvim`

#image("screenshots/none-ls-wtf.png")

== Can we make this easier?

The lookup lives in `nix/src/nix/fmt.cc` in Nix 2.28.4:

#box[
  #text(size: .75em)[
    ```cpp
    auto installable_ = parseInstallable(store, ".");
    auto & installable = InstallableValue::require(*installable_);
    auto app = installable.toApp(*evalState).resolve(evalStore, store);
    ...
    execProgramInStore(store, UseLookupPath::DontUse, app.program, programArgs);
    ```
  ]
]

== Contributing to nix

- So, I put together a PR to `NixOS/nix` #footnote[https://github.com/NixOS/nix/pull/13063] and attend a Nix team meeting

#pause
- After some very helpful back and forth, Nix 2.29.0 is released with a new `nix formatter` subcommand.

#pause
#text(size: 0.95em)[
  ```console
  $ nix formatter build
  /nix/store/cb9w44vkhk2x4adfxwgdkkf5gjmm856j-treefmt/bin/treefmt
  ```

  #pause
  ```console
  $ nix formatter run  # Equivalent to `nix fmt`.
  ```
]

== #text(style: "italic")[That's all Folks!]

If you use `neovim`, consider using the `nix_flake_fmt` `none-ls.nvim` builtin I maintain. #footnote[NixVim config here: https://github.com/jfly/nix-autoformatting-talk/blob/main/demos/nixvim/demo.nix]

Try it! #text(0.9em)[```console nix run github:jfly/nix-autoformatting-talk#demos/nixvim```]

If you use some other IDE, consider implementing a `nix_flake_fmt` plugin for
it! Feel free to reach out if you have any questions.

- #link("mailto:jeremyfleischman@gmail.com")
- `@jfly:matrix.org`

= Slides I cut for time

== `treefmt-nix`: under the hood

#text(size: 0.5em)[
  #columns(2)[
    ```console
    $ nix flake show
    └───formatter
        └───x86_64-linux: package 'treefmt'
    ```

    #pause
    ```console
    $ nix build .#formatter.x86_64-linux
    ```

    #pause
    ```console
    $ tree ./result
    ./result
    └── bin
        └── treefmt
    ```

    #pause
    ```console
    $ cat result/bin/treefmt
    ```
    ```bash
    #!/nix/store/gkwbw9nzbkbz298njbn3577zmrnglbbi-bash-5.3p0/bin/bash
    set -euo pipefail
    unset PRJ_ROOT
    exec /nix/store/pnl4n8xandadzdp0jlnbkq4smkldprzs-treefmt-2.3.1/bin/treefmt \
      --config-file=/nix/store/c2w5algs4in1ma6hwxzfp15zppx0i016-treefmt.toml \
      --tree-root-file=flake.nix \
      "$@"
    ```

    #pause
    #colbreak()
    ```console
    $ cat /nix/store/c2w5algs4in1ma6hwxzfp15zppx0i016-treefmt.toml
    ```
    ```toml
    [formatter.dart-format]
    command = "/nix/store/qvaf793algl2iis9fdpzgq00f3bjdywn-dart-3.8.1/bin/dart"
    excludes = ["generated_plugin_registrant.dart", "*.g.dart", "*.drift.dart"]
    includes = ["*.dart"]
    options = ["format"]

    [global]
    excludes = []
    on-unmatched = "warn"
    ```
  ]
]

== NixVim #footnote[https://nix-community.github.io/nixvim/] is awesome

#columns(2)[
  #let nixvim = read("../demos/nixvim/demo.nix")
  #text(size: 0.4em)[
    #raw(nixvim, lang: "nix")
  ]

  #pause
  #colbreak()
  ```console
  $ nix run github:jfly/nix-autoformatting-talk#demos/nixvim
  ```
]
