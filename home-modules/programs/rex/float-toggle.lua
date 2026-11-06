-- Toggle a named floating pane in the current tab, herdr-popup style.
--
-- The pane is found by its block label. Missing: create it at 90% of the tab,
-- running `command` (a shell when absent) in the invoking pane's directory.
-- Visible: minimize it. Minimized: restore and focus it. Minimizing keeps the
-- program running, so a scratch shell keeps its jobs and scrollback.
rex.action{
  name = "float_toggle",
  title = "Toggle Floating Pane",
  description = "Show, hide or create a labeled floating pane in the current tab.",
  args = { label = "string", command = "array?" },
  run = function(ctx, args)
    local view, err = rex.session.view{}
    if err ~= nil then error(err, 0) end

    -- The tab holding the pane the action ran from, else the active tab.
    local win
    for _, w in ipairs(view.windows) do
      for _, l in ipairs(w.layers) do
        for _, b in ipairs(l.blocks or {}) do
          if b.block_id == ctx.block_id then win = w end
        end
      end
    end
    for _, w in ipairs(view.windows) do
      if win == nil and w.window_id == view.active_window_id then win = w end
    end
    if win == nil then error("float_toggle: no tab to act on", 0) end

    for _, l in ipairs(win.layers) do
      if l.kind ~= "tiled" then
        for _, b in ipairs(l.blocks or {}) do
          if b.label == args.label then
            local _, e
            if l.state == "minimized" then
              _, e = rex.session.set_layer_state{ layer_id = l.layer_id, state = "normal", focus = true }
            else
              _, e = rex.session.set_layer_state{ layer_id = l.layer_id, state = "minimized" }
            end
            if e ~= nil then error(e, 0) end
            return
          end
        end
      end
    end

    local options = { command = args.command }
    if ctx.block_id ~= nil then
      -- `process` reports a plain path; `pwd` is a file:// URL.
      local p = rex.block.call("com.superlogical.terminal", "process", { block_id = ctx.block_id })
      if p ~= nil and p.foreground ~= nil then options.cwd = p.foreground.cwd end
    end
    local _, e = rex.session.new_layer{
      window_id = win.window_id,
      bounds = { 0.05, 0.05, 0.9, 0.9 },
      focus = true,
      layout = { block = { flavor = "com.superlogical.terminal.shell", label = args.label, options = options } },
    }
    if e ~= nil then error(e, 0) end
  end,
}
