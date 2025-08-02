#import "@preview/touying:0.6.1": *
#import "@preview/pinit:0.2.2": *
#import themes.simple: *

#show: simple-theme.with(aspect-ratio: "16-9")

#set footnote(numbering: "*")

#let my-outline(currentPart) = {
  let style(body, part: int) = {
    if part == currentPart {
      text(body, size: 1.5em, weight: "bold")
    } else {
      text(body, fill: black.transparentize(50%))
    }
  }

  [
    =

    #style(part: 1)[Treefmt]

    #style(part: 2)[Let's build a Neovim plugin]
  ]
}

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
    link("https://github.com/jfly/nix-autoformatting-talk/tree/" + rev)[#rev]
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

#my-outline(1)

== Does this look familiar?

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

#speaker-note[
  Who knows how many arguments you can pass to a command anyways?
  On my machine I could get up to 173,000.
]

== Treefmt - "The formatter multiplexer" #footnote[https://treefmt.com/]

Your formatters must implement the "Formatter Specification"
#footnote[https://treefmt.com/latest/reference/formatter-spec/]:

```<command> [options] [...<files>]```

For example: ```console nixfmt foo.nix bar.nix```

== Treefmt

Benefits:

#pause
- Consistent behavior across formatters
  - Walking of the filesystem
  - CI mode
  - Progress indicator

#pause
- Performance
  - Parallelism
  - Batching
  - Caching

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

== Under the hood

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

#my-outline(2)

== Design goals

- Run "the equivalent of" `nix fmt <filename>` on save
- Implementation should be able to work in big scary IDEs
- Do not assume `nix fmt` is running `treefmt` under the hood
  #footnote[https://github.com/NixOS/nix/pull/11613]

== `none-ls`

- `none-ls.nvim` is a community-maintained fork of `null-ls.nvim`
- Think of it as an LSP wrapper around various CLI tools
- Can we just add `nix fmt` as another CLI tool?

#pause
No, `nix fmt` is too slow.
#only("2-")[
  #footnote[Evaluation caching gets this closer to 2 seconds, but what if you're editing `flake.nix`?]
]
In `nixpkgs`:

#box[
  ```console
  $ time nix eval .#formatter.x86_64-linux
  «derivation /nix/store/pzidry16kalva72760...-treefmt.drv»
  ...
  Executed in 14.52 secs
  ```
]

== Caching

Once we've evaluated and built `nix fmt`
#only("2-")[#footnote[For a given project]],
don't do it again.

```console
$ nix build .#formatter.x86_64-linux --print-out-paths
/nix/store/qdw7fsx2q8gbkaiq6d1d5i5mcqzgb4d3-treefmt
```

#pause

#pause
`none-ls` has `dynamic_command` for this, but it needed some love.

#pad(y: 1em)[
  #grid(
    columns: (1fr, 1fr, 1fr),
    [#pause
      #rotate(15deg, screenshot(
        image("screenshots/none-ls-make-dynamic-command-async.png"),
      ))],
    [#pause #rotate(15deg, screenshot(
        image("screenshots/none-ls-run-dynamic-command-immediately.png"),
      ))],
    [#pause #rotate(15deg, screenshot(
        image("screenshots/none-ls-clear-cache.png"),
      ))],
  )
]

== Wait! That was a directory, not an executable

```console
$ nix build .#formatter.x86_64-linux --print-out-paths
/nix/store/qdw7fsx2q8gbkaiq6d1d5i5mcqzgb4d3-treefmt

$ ./result
bash: ./result: Is a directory

$ tree ./result
./result
└── bin
    └── treefmt
```

== `meta.mainProgram`

```nix
$ nix repl nixpkgs
nix-repl> pkgs = legacyPackages.x86_64-linux

nix-repl> pkgs.cowsay.meta.mainProgram
"cowsay"
```

#pause
```nix
nix-repl> lib.getExe pkgs.cowsay
"/nix/store/8iiw5zjxb34cw8886la8xl55b1fa9zgv-cowsay-3.8.4/bin/cowsay"
```

#pause
(This is oversimplified)

== Let's take a look at `nix` itself

The lookup lives in `nix/src/nix/fmt.cc` in Nix 2.28.4#footnote[https://github.com/NixOS/nix/blob/2.28.4/src/nix/fmt.cc#L51]:

#box[
  #show raw: it => {
    show regex("pin\d"): it => pin(it.text)
    it
  }

  #text(size: .75em)[
    ```cpp
    auto installable_ = parseInstallable(store, ".");
    auto & installable = InstallableValue::require(*installable_);
    auto app = installable.toApp(*evalState).resolve(evalStore, store);
    ...
    execProgramInStore(store, UseLookupPath::DontUse, pin1app.programpin2, programArgs);
    ```
  ]
]

#pause
#pinit-highlight("pin1", "pin2")
#pinit-point-from(("pin1", "pin2"))[We need this]

== Can we do this without a change to `nix`?

We need to do the equivalent of `lib.getExe` from `nixpkgs`.

Proof of concept:

```console
$ nix eval .#formatter --raw --apply 'formatters:
    let
      f = formatters.x86_64-linux;
    in
      "${f}/bin/${f.meta.mainProgram}"'
```
```
/nix/store/dx2rwv8flf90lygfi87ihkdyn2176h0w-treefmt/bin/treefmt
```

== Let's port that to Lua

#columns(2)[
  This ended up being 243 fairly tedious lines of async Nix-in-Lua.

  I did not enjoy writing it, and I'm sure nobody enjoyed reading it.

  #pause
  But, a `none-ls` maintainer actually merged this!

  #pause
  (Foreshadowing: another `none-ls` maintainer noticed the mess.)

  #colbreak()

  #meanwhile
  #text(size: .25em)[
    ```lua
    local eval_nix_formatter = [[
      let
        currentSystem = "]] .. nix_current_system .. [[";
        # Various functions vendored from nixpkgs lib (to avoid adding a
        # dependency on nixpkgs).
        lib = rec {
          getOutput = output: pkg:
            if ! pkg ? outputSpecified || ! pkg.outputSpecified
            then pkg.${output} or pkg.out or pkg
            else pkg;
          getBin = getOutput "bin";
          # Simplified by removing various type assertions.
          getExe' = x: y: "${getBin x}/bin/${y}";
          # getExe is simplified to assume meta.mainProgram is specified.
          getExe = x: getExe' x x.meta.mainProgram;
        };
      in
      formatterBySystem:
        if formatterBySystem ? ${currentSystem} then
          let
            formatter = formatterBySystem.${currentSystem};
            drv = formatter.drvPath;
            bin = lib.getExe formatter;
          in
            drv + "\n" + bin + "\n"
        else
          ""
    ]]

    ...

    local status, stdout_lines, stderr_lines = run_job({
        command = "nix",
        args = {
            "--extra-experimental-features",
            "nix-command flakes",
            "eval",
            ".#formatter",
            "--raw",
            "--apply",
            eval_nix_formatter,
        },
        cwd = root,
    })
    ```
  ]

  #pause
  #place(horizon)[
    #rotate(15deg)[#screenshot(
        image("screenshots/none-ls-add-nix-flake-fmt-builtin.png"),
      )]
  ]

  #pause
  #place(horizon)[
    #screenshot(
      image("screenshots/none-ls-wtf.png"),
    )
  ]
]

== NixVim #footnote[https://nix-community.github.io/nixvim/] is awesome

#columns(2)[
  #let nixvim = read("../nix/demo.nix")
  #text(size: 0.4em)[
    #raw(nixvim, lang: "nix")
  ]

  #pause
  #colbreak()
  ```console
  $ nix run github:jfly/nix-autoformatting-talk#demos/nixvim
  ```
]

== 2025-04-01 `nixpkgs` gets autoformatting

#align(center)[
  #screenshot(image("screenshots/nixpkgs-treewide-format.png"))
]

#pause
And the plugin doesn't work in `nixpkgs` 🤦

#pause
```console
$ nix eval .#formatter --apply 'fs: fs.x86_64-linux'
error: attribute 'x86_64-linux' missing
       at «string»:1:5:
            1| fs: fs.x86_64-linux
             |     ^
```

== Of _course_ there's a `formatting` package

#columns(2)[
  This is supposed to be an attrset, not a derivation:

  #text(size: 0.75em)[
    ```console
    $ nix eval .#formatter
    «derivation /nix/store/i30c97vx...-formatter-0.4.0.drv»
    ```
  ]

  #pause
  #colbreak()
  Remember, here's what this looks like in a simple project:

  #text(size: 0.75em)[
    ```console
    $ nix eval .#formatter
    { aarch64-darwin = «derivation /nix/store/z7rhz7r0...-treefmt.drv»; ... }
    ```
  ]
]

#pause
`nixpgks` has both of these flake outputs:

- `formatting.<system>`
- `legacyPackages.<system>.formatting`

== Fix it good

- I submit a fix to none-ls
  #footnote[https://github.com/nvimtools/none-ls.nvim/pull/272/commits/128c1310d9c089ba60eb49eac298f8025f945577],
  but I am now fed up with how difficult this is to implement
- So, I put together a PR to `NixOS/nix` #footnote[https://github.com/NixOS/nix/pull/13063] and attend a Nix team meeting

#pause
Nix 2.29.0 includes a new `nix formatter` subcommand. Notably:

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

== That's all Folks!

If you use `neovim`, consider using the `nix_flake_fmt` `none-ls.nvim` builtin I maintain.

If you use some other IDE, consider implementing a `nix_flake_fmt` plugin for
it! Feel free to reach out if you have any questions.

- #link("mailto:jeremyfleischman@gmail.com")
- `@jfly:matrix.org`
