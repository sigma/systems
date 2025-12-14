# Patch wezterm with PR #6821 to expose swap_active_with_id on MuxTab
# https://github.com/wezterm/wezterm/pull/6821
final: prev: {
  wezterm = prev.wezterm.overrideAttrs (oldAttrs: {
    patches = (oldAttrs.patches or [ ]) ++ [
      # lua-api-crates/mux: expose swap_active_with_index
      (final.fetchpatch {
        url = "https://github.com/wezterm/wezterm/commit/3595b420b0594a23ab5f147a00700d960cf3ebcd.patch";
        hash = "sha256-r3RDz1CSI+xTUUohWYJdYwj6IWT7HPdTrwZegMv1/SE=";
      })
      # lua-api-crates/mux: change swap_active_with_index to use pane ids
      (final.fetchpatch {
        url = "https://github.com/wezterm/wezterm/commit/9758db633d94e1eef2771592eaca5c901d75c125.patch";
        hash = "sha256-sCJrx5dg/DHfrg4Onk0AQWG5lttisAGO05esaXKz2pc=";
      })
    ];
  });
}
