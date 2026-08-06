-- Neo-tree customizations
-- Custom root name formatter showing [ORG] PROJECT

local M = {}

function M.setup(opts)
  opts = opts or {}

  -- Create a custom component for the root folder name with colored org
  local neo_tree_components = require('neo-tree.sources.common.components')
  local original_name = neo_tree_components.name

  neo_tree_components.name = function(config, node, state)
    local result = original_name(config, node, state)
    -- Check if this is the root node
    if node:get_depth() == 1 and node.type == 'directory' then
      -- Match ~/src/github.com/ORG/PROJECT or similar
      local org, project = node.path:match('.*/src/[^/]+/([^/]+)/([^/]+)$')
      if org and project then
        -- Return multiple highlight segments
        return {
          { text = "[", highlight = "NeoTreeDimText" },
          { text = org, highlight = "@constant" },
          { text = "] ", highlight = "NeoTreeDimText" },
          { text = project, highlight = "NeoTreeDirectoryName" },
        }
      else
        -- Fallback to just the directory name
        if type(result) == 'table' then
          result.text = vim.fn.fnamemodify(node.path, ':t')
        end
      end
    end
    return result
  end
end

return M
