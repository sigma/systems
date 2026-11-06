-- Jump to the agent that needs you, herdr-style: focus the most urgent
-- blocked, failed or finished pane in any session and show its session in the
-- app. The pane the action ran from is skipped, so pressing it again moves on
-- to the next one. To pick one from a list instead, use the app's View
-- Activity picker (pane.view_activity).
--
-- A pane's state comes from the Program Status Protocol (OSC 7501). Claude
-- Code reports idle, working, done and blocked by itself; no hook is involved.
-- Wrapped in do … end so its locals stay out of the rest of init.lua.
do
  local terminal = "com.superlogical.terminal"
  local rank = { blocked = 1, error = 2, done = 3, working = 4, idle = 5 }

  -- Every pane reporting a state, across all sessions, most urgent first.
  local function panes()
    local out = {}
    local list = rex.call("session.list")
    for _, s in ipairs(list and list.sessions or {}) do
      -- A connection reads only sessions it is attached to. Attaching again
      -- is safe and returns the view.
      local att = rex.call("session.attach", { session_id = s.session_id })
      for _, w in ipairs(att and att.view and att.view.windows or {}) do
        for _, l in ipairs(w.layers) do
          for _, b in ipairs(l.blocks or {}) do
            if b.creator_name == terminal then
              local st = rex.call("block.method", {
                session_id = s.session_id,
                block_id = b.block_id,
                method = "program_status",
                args = {},
              })
              -- The pane's most urgent record: a worker can be blocked while
              -- the root record says working.
              local best
              for _, r in ipairs(st and st.records or {}) do
                if rank[r.state] ~= nil and (best == nil or rank[r.state] < rank[best]) then best = r.state end
              end
              if best ~= nil then
                out[#out + 1] = {
                  session_id = s.session_id,
                  session = s.label,
                  window_id = w.window_id,
                  block_id = b.block_id,
                  label = b.label,
                  state = best,
                }
              end
            end
          end
        end
      end
    end
    -- Stable within a rank, so repeated jumps visit panes in a fixed order.
    table.sort(out, function(a, b)
      if a.state ~= b.state then return rank[a.state] < rank[b.state] end
      if a.session ~= b.session then return a.session < b.session end
      return a.label < b.label
    end)
    return out
  end

  rex.action{
    name = "agent_jump",
    title = "Jump to Agent Needing Attention",
    description = "Focus the most urgent blocked, failed or finished agent pane in any session.",
    run = function(ctx)
      for _, a in ipairs(panes()) do
        if rank[a.state] > rank.done then return end
        if a.block_id ~= ctx.block_id then
          local _, err = rex.session.focus_block{ session_id = a.session_id, block_id = a.block_id }
          if err ~= nil then error(err, 0) end
          rex.client.queue("session.select", { session_id = a.session_id, window_id = a.window_id })
          return
        end
      end
    end,
  }
end
