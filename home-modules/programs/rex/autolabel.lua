-- Automatic labels, herdr-style. Run with `rex do --all <this file>
-- state=<file>`: rex.on never fires from init.lua.
--
-- Agent panes: a pane still labelled `shell` gets the name of the agent that
-- comes to its foreground (`claude`, then `claude-2`, … within a session), so
-- "talk to claude in session X" resolves. It goes back to `shell` when the
-- agent exits. Panes labelled by hand are left alone.
--
-- Sessions: each is named after the directory of its first pane, the top-left
-- pane of the first tab, and follows that pane as it changes directory.
-- Only a session still on its server-chosen label (`lunar-savanna`) or on a
-- label this script set is renamed. Once a session is named by hand it is
-- pinned (`false` in the state file) and never renamed again. The state file
-- maps session ID to the label this script set, so that survives restarts.
-- shortcut: a hand-picked word-dash-word name given while this script is not
-- running looks server-chosen and gets renamed; rename it again to pin it.
local terminal = "com.superlogical.terminal"
local state_file = assert(rex.args.state, "usage: rex do --all autolabel.lua state=FILE")
local default_label = "shell" -- what a new terminal pane is labelled
local agents = { claude = true, codex = true } -- foreground process names

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

-- A label this script gives an agent pane: `claude`, `claude-2`, …
local function is_agent_label(label)
  return agents[label:match("^(.-)%-%d+$") or label] == true
end

local function label_agent(sid, bid, fg)
  local view = rex.session.view{ session_id = sid }
  if view == nil then return end
  local label, taken = nil, {}
  for _, w in ipairs(view.windows) do
    for _, l in ipairs(w.layers) do
      for _, b in ipairs(l.blocks or {}) do
        if b.block_id == bid then label = b.label else taken[b.label] = true end
      end
    end
  end
  if label == nil then return end

  local agent = fg ~= nil and fg.name or nil
  local want
  if agents[agent] then
    if label ~= default_label then return end
    want = agent
    local n = 1
    while taken[want] do
      n = n + 1
      want = agent .. "-" .. n
    end
  elseif is_agent_label(label) then
    want = default_label
  else
    return
  end
  local _, err = rex.session.set_block_label{ session_id = sid, block_id = bid, label = want }
  if err ~= nil then rex.log("warn", "set_block_label " .. bid .. ": " .. tostring(err)) end
end

rex.on("terminal.process_changed", function(ctx, ev)
  label_agent(ctx.session_id, ctx.block_id, ev.foreground)
end)

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
