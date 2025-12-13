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

      -- Telescope picker for projects (current tab)
      vim.keymap.set('n', '<leader>fp', function()
        require('telescope').extensions.projects.projects({
          attach_mappings = function(prompt_bufnr, map)
            local actions = require('telescope.actions')
            local action_state = require('telescope.actions.state')

            actions.select_default:replace(function()
              actions.close(prompt_bufnr)
              local selection = action_state.get_selected_entry()
              if selection then
                open_project(selection.value)
              end
            end)

            return true
          end,
        })
      end, { desc = 'Find projects' })

      -- Telescope picker for projects (new tab)
      vim.keymap.set('n', '<leader>fP', function()
        require('telescope').extensions.projects.projects({
          attach_mappings = function(prompt_bufnr, map)
            local actions = require('telescope.actions')
            local action_state = require('telescope.actions.state')

            actions.select_default:replace(function()
              actions.close(prompt_bufnr)
              local selection = action_state.get_selected_entry()
              if selection then
                open_project_in_new_tab(selection.value)
              end
            end)

            return true
          end,
        })
      end, { desc = 'Find projects (new tab)' })

      -- Command to manually add current directory as a project
      vim.api.nvim_create_user_command('ProjectAdd', function()
        local project = require('project')
        local cwd = vim.fn.getcwd()
        -- This will add to history
        project.set_pwd(cwd, 'manual')
        vim.notify('Added project: ' .. cwd, vim.log.levels.INFO)
      end, { desc = 'Add current directory as a project' })

      -- Auto-name tab when entering a project directory
      vim.api.nvim_create_autocmd('DirChanged', {
        group = vim.api.nvim_create_augroup('ProjectTabName', { clear = true }),
        callback = function(args)
          -- Only for tab-local directory changes
          if args.match == 'tabpage' then
            local tab_name = vim.fn.gettabvar(vim.fn.tabpagenr(), 'tab_name', "")
            -- Only auto-name if tab doesn't already have a custom name
            if tab_name == "" then
              local project_name = get_project_name(vim.fn.getcwd())
              vim.fn.settabvar(vim.fn.tabpagenr(), 'tab_name', project_name)
            end
          end
        end,
      })
    '';
  };
}
