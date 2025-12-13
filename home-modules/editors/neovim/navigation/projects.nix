# project.nvim configuration
# Project management with Telescope integration
{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.programs.neovim-ide;
in
{
  config = mkIf cfg.enable {
    # Add project.nvim plugin
    programs.nvf.settings.vim.extraPlugins = {
      project-nvim = {
        package = pkgs.vimPlugins.project-nvim;
      };
    };

    # Setup project.nvim after plugins are loaded
    programs.neovim-ide.luaConfigPost."50-project-setup" = ''
      require('project').setup({
        -- Use LSP for project root detection (in addition to patterns)
        use_lsp = true,

        -- Patterns to detect project root
        patterns = {
          ".git",
          "_darcs",
          ".hg",
          ".bzr",
          ".svn",
          "Makefile",
          "package.json",
          "flake.nix",
          "Cargo.toml",
          "go.mod",
          "pyproject.toml",
          "setup.py",
        },

        -- Don't change directory automatically (we handle it manually for tabs)
        manual_mode = false,

        -- When changing directories, update neo-tree root
        silent_chdir = false,

        -- Scope for cd (global, tab, win)
        scope_chdir = "tab",
      })

      -- Load Telescope extension
      require('telescope').load_extension('projects')

      -- Auto-discover projects from conventional directories
      local function discover_projects()
        local home = vim.fn.expand('~')
        local base_dirs = {
          home .. '/src/github.com',
          home .. '/src/gitlab.com',
          home .. '/src/bitbucket.org',
        }

        local History = require('project.utils.history')
        local discovered = 0

        -- Helper to add project to session_projects without changing cwd
        local function add_project(path)
          if vim.tbl_isempty(History.session_projects) then
            History.session_projects = { path }
          elseif not vim.tbl_contains(History.session_projects, path) then
            table.insert(History.session_projects, path)
          else
            return false
          end
          return true
        end

        for _, base_dir in ipairs(base_dirs) do
          if vim.fn.isdirectory(base_dir) == 1 then
            -- Scan org directories
            local orgs = vim.fn.glob(base_dir .. '/*', false, true)
            for _, org_path in ipairs(orgs) do
              if vim.fn.isdirectory(org_path) == 1 then
                -- Scan project directories within each org
                local projects = vim.fn.glob(org_path .. '/*', false, true)
                for _, project_path in ipairs(projects) do
                  if vim.fn.isdirectory(project_path) == 1 then
                    -- Check if it looks like a project (has .git or other markers)
                    local is_project = vim.fn.isdirectory(project_path .. '/.git') == 1
                      or vim.fn.filereadable(project_path .. '/flake.nix') == 1
                      or vim.fn.filereadable(project_path .. '/package.json') == 1
                      or vim.fn.filereadable(project_path .. '/Cargo.toml') == 1
                      or vim.fn.filereadable(project_path .. '/go.mod') == 1

                    if is_project and add_project(project_path) then
                      discovered = discovered + 1
                    end
                  end
                end
              end
            end
          end
        end

        if discovered > 0 then
          vim.notify('Discovered ' .. discovered .. ' projects', vim.log.levels.DEBUG)
        end
      end

      -- Run discovery on startup (deferred to not slow down init)
      vim.defer_fn(discover_projects, 100)
    '';

    # Project keymaps and tab integration
    programs.neovim-ide.luaConfigPost."55-projects" = ''
      -- Helper: Get project name from path
      local function get_project_name(path)
        return vim.fn.fnamemodify(path, ':t')
      end

      -- Helper: Extract org from path (e.g., ~/src/github.com/ORG/project -> ORG)
      local function get_project_org(path)
        -- Match patterns like /src/github.com/ORG/project or /src/gitlab.com/ORG/project
        local org = path:match('/src/[^/]+/([^/]+)/[^/]+$')
        return org or 'other'
      end

      -- Helper: Open project in current context
      local function open_project(project_path)
        -- Change to project directory (tab-scoped due to project.nvim config)
        vim.cmd('tcd ' .. vim.fn.fnameescape(project_path))

        -- Update neo-tree root if it's open
        local ok, _ = pcall(function()
          require('neo-tree.command').execute({ action = 'focus', dir = project_path })
        end)

        -- If neo-tree wasn't open, just notify
        if not ok then
          vim.notify('Switched to: ' .. get_project_name(project_path), vim.log.levels.INFO)
        end
      end

      -- Helper: Open project in new tab
      local function open_project_in_new_tab(project_path)
        -- Create new tab
        vim.cmd('tabnew')

        -- Name the tab after the project
        local project_name = get_project_name(project_path)
        vim.fn.settabvar(vim.fn.tabpagenr(), 'tab_name', project_name)

        -- Open the project
        open_project(project_path)
      end

      -- Helper: Build grouped and sorted project list
      local function get_grouped_projects()
        local History = require('project.utils.history')
        local projects = History.get_recent_projects() or {}

        -- Group projects by org
        local by_org = {}
        for _, path in ipairs(projects) do
          local org = get_project_org(path)
          if not by_org[org] then
            by_org[org] = {}
          end
          table.insert(by_org[org], path)
        end

        -- Sort orgs by number of projects (descending)
        local org_list = {}
        for org, paths in pairs(by_org) do
          table.insert(org_list, { org = org, paths = paths, count = #paths })
        end
        table.sort(org_list, function(a, b)
          return a.count > b.count
        end)

        -- Build flat list with org headers
        local results = {}
        for _, org_data in ipairs(org_list) do
          -- Sort projects within org alphabetically
          table.sort(org_data.paths)
          local first_in_org = true
          for _, path in ipairs(org_data.paths) do
            table.insert(results, {
              path = path,
              org = org_data.org,
              show_org = first_in_org,
              name = get_project_name(path),
              display = org_data.org .. '/' .. get_project_name(path),
            })
            first_in_org = false
          end
        end

        return results
      end

      -- Custom Telescope picker for projects grouped by org
      local function projects_picker(opts)
        opts = opts or {}
        local on_select = opts.on_select or open_project

        local pickers = require('telescope.pickers')
        local finders = require('telescope.finders')
        local conf = require('telescope.config').values
        local actions = require('telescope.actions')
        local action_state = require('telescope.actions.state')
        local entry_display = require('telescope.pickers.entry_display')

        local results = get_grouped_projects()

        local org_width = 20

        -- Find index of current project to pre-select it
        -- Match if cwd is the project root or a subdirectory of it
        local cwd = vim.fn.getcwd()
        local default_selection = 1
        local best_match_len = 0
        for i, entry in ipairs(results) do
          -- Check if cwd starts with this project path
          if cwd:find(entry.path, 1, true) == 1 then
            -- Prefer longer matches (more specific project)
            if #entry.path > best_match_len then
              best_match_len = #entry.path
              default_selection = i
            end
          end
        end

        pickers.new({
          selection_caret = "> ",
        }, {
          prompt_title = 'Projects',
          default_selection_index = default_selection,
          finder = finders.new_table({
            results = results,
            entry_maker = function(entry)
              local org_display = entry.show_org and entry.org or ""
              local padding = string.rep(" ", org_width - #org_display)

              return {
                value = entry.path,
                ordinal = entry.display,
                org = entry.org,
                show_org = entry.show_org,
                name = entry.name,
                org_display = org_display,
                padding = padding,
                display = function(e)
                  local text = e.org_display .. e.padding .. e.name
                  if e.show_org then
                    return text, { { { 0, #e.org }, "Type" } }
                  else
                    return text
                  end
                end,
              }
            end,
          }),
          sorter = conf.generic_sorter({}),
          attach_mappings = function(prompt_bufnr, map)
            actions.select_default:replace(function()
              actions.close(prompt_bufnr)
              local selection = action_state.get_selected_entry()
              if selection then
                on_select(selection.value)
              end
            end)
            return true
          end,
        }):find()
      end

      -- Telescope picker for projects (current tab)
      vim.keymap.set('n', '<leader>fp', function()
        projects_picker({ on_select = open_project })
      end, { desc = 'Find projects' })

      -- Telescope picker for projects (new tab)
      vim.keymap.set('n', '<leader>fP', function()
        projects_picker({ on_select = open_project_in_new_tab })
      end, { desc = 'Find projects (new tab)' })

      -- Project-scoped buffer picker
      local function project_buffers_picker()
        local pickers = require('telescope.pickers')
        local finders = require('telescope.finders')
        local conf = require('telescope.config').values
        local actions = require('telescope.actions')
        local action_state = require('telescope.actions.state')

        local cwd = vim.fn.getcwd()
        local buffers = {}

        for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
          if vim.api.nvim_buf_is_loaded(bufnr) then
            local bufname = vim.api.nvim_buf_get_name(bufnr)
            -- Filter to buffers within current project
            if bufname ~= "" and bufname:find(cwd, 1, true) == 1 then
              local relative_path = bufname:sub(#cwd + 2) -- +2 for trailing slash
              local modified = vim.api.nvim_buf_get_option(bufnr, 'modified')
              table.insert(buffers, {
                bufnr = bufnr,
                name = relative_path,
                modified = modified,
              })
            end
          end
        end

        -- Sort by most recently used
        table.sort(buffers, function(a, b)
          return vim.fn.getbufinfo(a.bufnr)[1].lastused > vim.fn.getbufinfo(b.bufnr)[1].lastused
        end)

        pickers.new({
          selection_caret = "> ",
        }, {
          prompt_title = 'Buffers (' .. get_project_name(cwd) .. ')',
          finder = finders.new_table({
            results = buffers,
            entry_maker = function(entry)
              local display = entry.name
              if entry.modified then
                display = display .. " [+]"
              end
              return {
                value = entry.bufnr,
                display = display,
                ordinal = entry.name,
              }
            end,
          }),
          sorter = conf.generic_sorter({}),
          attach_mappings = function(prompt_bufnr, map)
            actions.select_default:replace(function()
              actions.close(prompt_bufnr)
              local selection = action_state.get_selected_entry()
              if selection then
                vim.api.nvim_set_current_buf(selection.value)
              end
            end)
            -- Delete buffer with <C-d>
            map('i', '<C-d>', function()
              local selection = action_state.get_selected_entry()
              if selection then
                vim.api.nvim_buf_delete(selection.value, { force = false })
                -- Refresh picker
                actions.close(prompt_bufnr)
                project_buffers_picker()
              end
            end)
            return true
          end,
        }):find()
      end

      vim.keymap.set('n', '<leader>,', project_buffers_picker, { desc = 'Switch buffer (project)' })
      vim.keymap.set('n', '<leader>fb', project_buffers_picker, { desc = 'Find buffers (project)' })

      -- Command to manually add current directory as a project
      vim.api.nvim_create_user_command('ProjectAdd', function()
        local project = require('project')
        local cwd = vim.fn.getcwd()
        -- This will add to history
        project.set_pwd(cwd, 'manual')
        vim.notify('Added project: ' .. cwd, vim.log.levels.INFO)
      end, { desc = 'Add current directory as a project' })

      -- Helper: Find project root for a given path
      local function find_project_root(path)
        local History = require('project.utils.history')
        local projects = History.get_recent_projects() or {}
        local best_match = nil
        local best_match_len = 0
        for _, project_path in ipairs(projects) do
          if path:find(project_path, 1, true) == 1 then
            if #project_path > best_match_len then
              best_match = project_path
              best_match_len = #project_path
            end
          end
        end
        return best_match
      end

      -- Helper: Auto-name current tab based on project
      local function auto_name_tab()
        local tab_name = vim.fn.gettabvar(vim.fn.tabpagenr(), 'tab_name', "")
        -- Only auto-name if tab doesn't already have a custom name
        if tab_name == "" then
          local cwd = vim.fn.getcwd()
          local project_root = find_project_root(cwd)
          if project_root then
            vim.fn.settabvar(vim.fn.tabpagenr(), 'tab_name', get_project_name(project_root))
          else
            -- Fallback to cwd basename
            vim.fn.settabvar(vim.fn.tabpagenr(), 'tab_name', get_project_name(cwd))
          end
        end
      end

      -- Auto-name tab when entering a project directory
      vim.api.nvim_create_autocmd('DirChanged', {
        group = vim.api.nvim_create_augroup('ProjectTabName', { clear = true }),
        callback = function(args)
          -- Only for tab-local directory changes
          if args.match == 'tabpage' then
            auto_name_tab()
          end
        end,
      })

      -- Auto-name first tab on startup (after projects are discovered)
      vim.defer_fn(function()
        auto_name_tab()
      end, 200)
    '';
  };
}
