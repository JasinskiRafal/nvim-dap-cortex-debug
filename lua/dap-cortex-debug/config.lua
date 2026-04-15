local M = {}
local utils = require('dap-cortex-debug.utils')

-- Use a function to always get a new table, even if some deep field is modified,
-- like `config.commands.save = ...`. Returning a "constant" still seems to allow
-- the LSP completion to work.
local function defaults()
    -- stylua: ignore
    return {
        debug = false,
        extension_path = nil,
        lib_extension = nil,
        node_path = 'node',
        -- Deprecated: Use rtt.framework instead
        dapui_rtt = nil,
        dapview_rtt = nil,
        dap_vscode_filetypes = { 'c', 'cpp' },
        rtt = {
            buftype = 'Terminal',
            framework = 'auto',
        },
    }
end

local config = defaults()

function M.setup(opts)
    local new_config = vim.tbl_deep_extend('force', {}, defaults(), opts or {})

    -- Warn about deprecated RTT configuration but ignore the old settings
    if new_config.dapui_rtt ~= nil or new_config.dapview_rtt ~= nil then
        utils.warn_once([[
🚨 Deprecated RTT configuration detected!
The `dapui_rtt` and `dapview_rtt` settings are no longer used.
Please update your configuration to use the new unified system:
  NEW: rtt = { framework = 'auto' | 'dapui' | 'dapview' | false }

Example migration:
  OLD: dapui_rtt = true, dapview_rtt = false
  NEW: rtt = { framework = 'auto' }  -- or 'dapui' or 'dapview'

The old settings will be ignored. Using 'auto' mode (default) will
automatically detect and use the first available framework (dapui → dapview).
        ]])
    end

    -- Do _not_ replace the table pointer with `config = ...` because this
    -- wouldn't change the tables that have already been `require`d by other
    -- modules. Instead, clear all the table keys and then re-add them.
    for _, key in ipairs(vim.tbl_keys(config)) do
        config[key] = nil
    end
    for key, val in pairs(new_config) do
        config[key] = val
    end
end

-- Return the config table (getting completion!) but fall back to module methods.
return setmetatable(config, { __index = M })
