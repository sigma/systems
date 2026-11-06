-- Name each session after the directory of its first pane, herdr-style, and
-- follow that pane as it changes directory. The first pane is the top-left
-- pane of the first tab. Run with `rex do --all <this file> state=<file>`:
-- rex.on never fires from init.lua.
--
-- Only a session still on its server-chosen label (`lunar-savanna`) or on a
-- label this script set is renamed. Once a session is named by hand it is
-- pinned (`false` in the state file) and never renamed again. The state file
-- maps session ID to the label this script set, so that survives restarts.
-- shortcut: a hand-picked word-dash-word name given while this script is not
-- running looks server-chosen and gets renamed; rename it again to pin it.
local terminal = "com.superlogical.terminal"
local state_file = assert(rex.args.state, "usage: rex do --all session-autoname.lua state=FILE")

local ours = {}
do
  local f = io.open(state_file)
  if f ~= nil then
    local ok, t = pcall(rex.json.decode, f:read("*a"))
    f:close()
    if ok and type(t) == "table" then ours = t end
  end
end

local function save()
  local tmp = state_file .. ".tmp"
  local f = assert(io.open(tmp, "w"))
  f:write(rex.json.encode(ours))
  f:close()
  assert(os.rename(tmp, state_file))
end

local function first_block(layout)
  while layout.split ~= nil do layout = layout.split.before end
  return layout.block_id
end

local function sync(sid)
  local view = rex.session.view{ session_id = sid }
  if ours[sid] == false or view == nil or view.windows[1] == nil then return end
  if view.label ~= ours[sid] and not view.label:match("^%l+%-%l+$") then return end

  local tiled
  for _, l in ipairs(view.windows[1].layers) do
    if l.kind == "tiled" then tiled = l end
  end
  if tiled == nil or tiled.layout == nil then return end

  -- `process` reports a plain path; `pwd` is a file:// URL.
  local p = rex.block.call(terminal, "process", { block_id = first_block(tiled.layout) })
  local cwd = p ~= nil and p.foreground ~= nil and p.foreground.cwd or nil
  if cwd == nil then return end

  local name = cwd:match("([^/]+)/*$") or "/"
  if name == view.label then return end
  local _, err = rex.session.set_label{ session_id = sid, label = name }
  if err ~= nil then
    rex.log("warn", "set_label " .. sid .. ": " .. tostring(err))
    return
  end
  ours[sid] = name
  save()
end

-- Layout changes cover new, closed, moved and swapped panes; pwd_changed
-- covers a `cd` in a shell.
rex.on("session_view_changed", function(ctx) sync(ctx.session_id) end)
rex.on("terminal.pwd_changed", function(ctx) sync(ctx.session_id) end)
-- Our own set_label also lands here, after `ours` already holds its label.
rex.on("session_label_changed", function(ctx, ev)
  if ours[ctx.session_id] ~= ev.label and ours[ctx.session_id] ~= false then
    ours[ctx.session_id] = false
    save()
  end
end)
rex.on("session_destroyed", function(_, ev)
  if ours[ev.session_id] ~= nil then
    ours[ev.session_id] = nil
    save()
  end
end)
