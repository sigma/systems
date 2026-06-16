# Shared kanata config-text generator.
#
# Returns a function that builds a kanata .kbd config from a small set of
# feature flags. The defsrc always covers the full physical keyboard so
# adding a new remap is a one-line change in the matching deflayer slot.
#
# Currently only `platform = "macos"` is wired up; the API is shaped so a
# Linux backend can be slotted in without changing callers.
{ lib }:
let
  inherit (lib) optionalString concatMapStringsSep;

  mkDefcfg =
    {
      platform,
      devices,
      withChords,
    }:
    let
      deviceList = concatMapStringsSep "\n    " (d: ''"${d}"'') devices;
      includeKey =
        if platform == "macos" then "macos-dev-names-include" else "linux-dev-names-include";
      # defchordsv2 requires concurrent-tap-hold for tap-hold aliases
      # to keep working while chord-key buffering is in flight.
      chordsLine = optionalString withChords "\n  concurrent-tap-hold yes";
    in
    ''
      (defcfg
        process-unmapped-keys yes${chordsLine}
        ${includeKey} (
          ${deviceList}
        ))
    '';

  # Full ANSI MacBook layout. Every physical key is listed so future
  # remaps drop straight into the matching deflayer slot. `fn` is in
  # the bottom row — kanata 1.11+ does see Apple's fn key on macOS via
  # the Karabiner DriverKit grab.
  #
  # The pedal row is appended only when a pedal is configured; the
  # pedal hardware must be programmed to emit f20/f21/f22.
  defsrcMac =
    { withPedal }:
    ''
      (defsrc
        esc  f1   f2   f3   f4   f5   f6   f7   f8   f9   f10  f11  f12
        grv  1    2    3    4    5    6    7    8    9    0    -    =    bspc
        tab  q    w    e    r    t    y    u    i    o    p    [    ]    \
        caps a    s    d    f    g    h    j    k    l    ;    '    ret
        lsft z    x    c    v    b    n    m    ,    .    /    rsft
        fn   lctl lalt lmet                spc                rmet ralt
        left up   down right${optionalString withPedal "\n  f20  f21  f22"})
    '';

  # tap-hold-press: pressing any other key during the hold window
  # commits to the hold action immediately, sidestepping the
  # time-based race that plain `tap-hold` loses on fast typing
  # (`)i` instead of `I`, etc).
  mkAliases =
    {
      hyperFromLctl,
      capsEscCtrl,
      enterRctrl,
      shiftParens,
      mediaKeys,
      stockToggle,
      tapMs,
      holdMs,
    }:
    let
      t = "${toString tapMs} ${toString holdMs}";
      lines = lib.flatten [
        (lib.optional hyperFromLctl "hyp  (multi lctl lalt lmet)")
        (lib.optional capsEscCtrl "cap  (tap-hold-press ${t} esc lctl)")
        (lib.optional enterRctrl "ent  (tap-hold-press ${t} ret rctl)")
        (lib.optional shiftParens "lpar (tap-hold-press ${t} S-9 lsft)")
        (lib.optional shiftParens "rpar (tap-hold-press ${t} S-0 rsft)")
        # Holding fn flips the F-row from media keys back to plain
        # F1-F12 via the `fkeys` layer defined below.
        (lib.optional mediaKeys "fnl  (layer-while-held fkeys)")
        # Conditional permanent switch: from base, switch to stock;
        # from stock, switch back to base. `layer-toggle` is a name-
        # alias for layer-while-held in kanata and would only hold
        # the layer for the duration of Esc.
        (lib.optional stockToggle ''
          tgst (switch
            ((base-layer base))  (layer-switch stock) break
            ((base-layer stock)) (layer-switch base)  break)'')
        # Context-aware "do nothing" for unmapped slots in the fkeys
        # layer: block (XX) while operating from base, fall through
        # (_) while operating from stock so the guest still gets
        # natural typing on stray Fn+letter combos.
        (lib.optional stockToggle ''
          nop  (switch
            ((base-layer base))  XX break
            ((base-layer stock)) _  break)'')
      ];
    in
    if lines == [ ] then
      ""
    else
      ''
        (defalias
          ${lib.concatStringsSep "\n  " lines})
      '';

  # Apple's macOS F-row "media key" mapping. Kanata's Karabiner-DriverKit
  # virtual HID can emit these consumer/Apple-vendor codes directly.
  mediaRow = "brdn brup mctl sls dtn dnd prev pp next mute vold volu";

  deflayerMac =
    {
      withPedal,
      swapAltCmd,
      fnDndHack,
      hyperFromLctl,
      capsEscCtrl,
      enterRctrl,
      shiftParens,
      mediaKeys,
      pedal,
    }:
    let
      # F-row mapping. mediaKeys wins over fnDndHack — when both are
      # set, F6 is `dnd` directly (no F16 hack needed). The standalone
      # fnDndHack path keeps the F6→F16 behavior for hosts that don't
      # want full media-key remapping.
      fRow =
        if mediaKeys then
          mediaRow
        else if fnDndHack then
          "f1 f2 f3 f4 f5 f16 f7 f8 f9 f10 f11 f12"
        else
          "f1 f2 f3 f4 f5 f6 f7 f8 f9 f10 f11 f12";

      fn = if mediaKeys then "@fnl" else "fn";

      caps = if capsEscCtrl then "@cap" else "caps";
      ret = if enterRctrl then "@ent" else "ret";

      lsft = if shiftParens then "@lpar" else "lsft";
      rsft = if shiftParens then "@rpar" else "rsft";

      lctl = if hyperFromLctl then "@hyp" else "lctl";

      # macOS PC-style swap: physical option↔command on both sides.
      # HID-level option is `lalt`/`ralt`, command is `lmet`/`rmet`.
      lalt = if swapAltCmd then "lmet" else "lalt";
      lmet = if swapAltCmd then "lalt" else "lmet";
      ralt = if swapAltCmd then "rmet" else "ralt";
      rmet = if swapAltCmd then "ralt" else "rmet";

      # Pedal: left=dictation-trigger (F18, paired with macOS Keyboard
      # Settings → Dictation Shortcut = F18), right=return, middle=cmd-hold.
      pedalRow = optionalString withPedal "\n  ${pedal.left} ${pedal.right} ${pedal.middle}";
    in
    ''
      (deflayer base
        esc  ${fRow}
        grv  1  2  3  4  5  6  7  8  9  0  -  =  bspc
        tab  q  w  e  r  t  y  u  i  o  p  [  ]  \
        ${caps} a s d f g h j k l ; ' ${ret}
        ${lsft} z x c v b n m , . / ${rsft}
        ${fn} ${lctl} ${lalt} ${lmet} spc ${rmet} ${ralt}
        left up down right${pedalRow})
    '';

  # Holding fn switches the F-row back to plain F1-F12 and exposes
  # Apple's stock Fn shortcuts: Fn+Bspc=Forward Delete, Fn+Ret=Keypad
  # Enter, Fn+E=Character Viewer, Fn+A=Show/hide Dock, Fn+←=Home,
  # Fn+→=End, Fn+↑=PgUp, Fn+↓=PgDn.
  #
  # Unmapped slots:
  #   - Without stockToggle: `XX` (no output) so stray Fn+letter combos
  #     don't dribble through as the literal letter.
  #   - With stockToggle: `@nop`, a context-aware alias that evaluates
  #     to `XX` while base is the active layer and `_` (transparent)
  #     while stock is. Lets a guest type letters under Fn+key without
  #     having to maintain two parallel fkeys layers.
  #
  # When stockToggle is on, the top-left esc slot becomes the toggle
  # into / out of the `stock` layer.
  fkeysLayerMac =
    { withPedal, stockToggle }:
    let
      esc = if stockToggle then "@tgst" else "_";
      f = if stockToggle then "@nop" else "XX";
      pedalRow = optionalString withPedal "\n  ${f} ${f} ${f}";
    in
    ''
      (deflayer fkeys
        ${esc} f1 f2 f3 f4 f5 f6 f7 f8 f9 f10 f11 f12
        ${f} ${f} ${f} ${f} ${f} ${f} ${f} ${f} ${f} ${f} ${f} ${f} ${f} del
        ${f} ${f} ${f} C-M-spc ${f} ${f} ${f} ${f} ${f} ${f} ${f} ${f} ${f} ${f}
        ${f} M-A-d ${f} ${f} ${f} ${f} ${f} ${f} ${f} ${f} ${f} ${f} kprt
        ${f} ${f} ${f} ${f} ${f} ${f} ${f} ${f} ${f} ${f} ${f} ${f}
        ${f} ${f} ${f} ${f} ${f} ${f} ${f}
        home pgup pgdn end${pedalRow})
    '';

  # Pass-through "guest mode" layer — what the keyboard would do
  # without any kanata remaps. Reached via Fn+Esc from base; the same
  # combo from stock toggles back. `fn` explicitly triggers fkeys
  # since after `layer-switch stock` the base of the stack is stock,
  # so `_` here would fall through to defsrc (literal fn).
  stockLayerMac =
    { withPedal }:
    let
      pedalRow = optionalString withPedal "\n  f18 ret  lmet";
    in
    ''
      (deflayer stock
        esc  brdn brup mctl sls dtn dnd prev pp next mute vold volu
        grv  1  2  3  4  5  6  7  8  9  0  -  =  bspc
        tab  q  w  e  r  t  y  u  i  o  p  [  ]  \
        caps a s d f g h j k l ; ' ret
        lsft z x c v b n m , . / rsft
        @fnl lctl lalt lmet spc rmet ralt
        left up down right${pedalRow})
    '';

  # Bracket chords on the bottom row: zxc and ,./ → [ ] { } < >.
  # Tight default timeout (chordMs) so rolling-finger typing of "exc",
  # "...", etc. doesn't accidentally fire chords. When stockToggle is
  # on, chords are disabled inside the `stock` layer so guests get
  # plain z/x/c/,/./ behavior.
  mkChords =
    {
      bracketChords,
      chordMs,
      stockToggle,
    }:
    if !bracketChords then
      ""
    else
      let
        disabled = if stockToggle then "(stock)" else "()";
        line = keys: out: "(${keys}) ${out} ${toString chordMs} all-released ${disabled}";
      in
      ''
        (defchordsv2
          ${line "z x" "lbrc"}
          ${line "x c" "S-lbrc"}
          ${line "z c" "S-,"}
          ${line ", ." "S-rbrc"}
          ${line ". /" "rbrc"}
          ${line ", /" "S-."})
      '';
in
{
  mkConfig =
    {
      platform ? "macos",
      devices ? [ ],
      swapAltCmd ? false,
      fnDndHack ? false,
      hyperFromLctl ? false,
      capsEscCtrl ? false,
      enterRctrl ? false,
      shiftParens ? false,
      bracketChords ? false,
      # When true: F-row emits Apple media keys (brightness, mission
      # control, spotlight, dictation, DND, media transport, mute,
      # volume) and holding fn flips back to plain F1-F12. Obsoletes
      # `fnDndHack` since F6→dnd is direct in this mode.
      mediaKeys ? false,
      # When true: Fn+Esc toggles a `stock` layer that bypasses all
      # kanata remaps (no caps→Ctrl, no shift-parens, no chords, no
      # alt↔cmd swap). Requires mediaKeys to be on so the fkeys layer
      # exists to host the Fn+Esc binding.
      stockToggle ? false,
      # Tap-hold timing window (ms). tapMs: max press duration that
      # still counts as a tap. holdMs: time-based fallback for the
      # "press alone, no other key" case.
      tapMs ? 200,
      holdMs ? 200,
      # Maximum delay (ms) between successive chord-key presses for
      # the chord to register. Tighter = fewer accidental triggers
      # during normal typing.
      chordMs ? 80,
      # Pedal output keys (what kanata emits when each pedal is pressed).
      # null = no pedal configured. Default mapping assumes the kinesis
      # pedal has been reflashed to send f20/f21/f22 from left/right/middle.
      pedal ? null,
    }:
    assert lib.assertMsg (platform == "macos")
      "kanata config generator currently only supports platform = \"macos\"";
    assert lib.assertMsg (!stockToggle || mediaKeys)
      "kanata stockToggle requires mediaKeys (the Fn+Esc binding lives in the fkeys layer)";
    let
      withPedal = pedal != null;
      pedalCfg =
        if withPedal then
          {
            left = "f18";
            right = "ret";
            middle = "lmet";
          }
          // pedal
        else
          null;
    in
    lib.concatStringsSep "\n" (
      [
        ";; Generated by nix — edit modules/kanata/config.nix, not this file."
        (mkDefcfg {
          inherit platform devices;
          withChords = bracketChords;
        })
        (defsrcMac { inherit withPedal; })
        (mkAliases {
          inherit
            hyperFromLctl
            capsEscCtrl
            enterRctrl
            shiftParens
            mediaKeys
            stockToggle
            tapMs
            holdMs
            ;
        })
        (mkChords {
          inherit bracketChords chordMs stockToggle;
        })
        (deflayerMac {
          inherit
            withPedal
            swapAltCmd
            fnDndHack
            hyperFromLctl
            capsEscCtrl
            enterRctrl
            shiftParens
            mediaKeys
            ;
          pedal = pedalCfg;
        })
      ]
      ++ lib.optional mediaKeys (fkeysLayerMac { inherit withPedal stockToggle; })
      ++ lib.optional stockToggle (stockLayerMac { inherit withPedal; })
    );
}
