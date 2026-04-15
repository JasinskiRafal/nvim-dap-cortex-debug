-- Debug the setup process with detailed output

-- Add the plugin to runtime path
vim.opt.runtimepath:append('.')

print("Debugging setup process with detailed output...")

-- Mock the dap-view module
local mock_dap_view = {
    registered_views = {},
    register_view = function(self, name, view)
        self.registered_views[name] = view
        print(string.format("Mock: Registered view '%s'", name))
        return true
    end,
    show_view = function(self, name)
        print(string.format("Mock: Showing view '%s'", name))
    end
}

-- Mock require to return our mock dap-view
package.loaded['dap-view'] = mock_dap_view

-- Also mock utils to see warnings
local mock_utils = {
    warn_once = function(msg)
        print(string.format("Mock utils.warn_once: %s", msg))
    end,
    error = function(msg, ...)
        print(string.format("Mock utils.error: %s", string.format(msg, ...)))
    end
}
package.loaded['dap-cortex-debug.utils'] = mock_utils

-- Load dependencies first
print("Loading dependencies...")
local dap = require('dap')
local config = require('dap-cortex-debug.config')
local listeners = require('dap-cortex-debug.listeners')
local adapter = require('dap-cortex-debug.adapter')
local memory = require('dap-cortex-debug.memory')
local requests = require('dap-cortex-debug.requests')

print("Dependencies loaded")

-- Now load the main module
print("Loading main module...")
local dap_cortex_debug = require('dap-cortex-debug')
print("Main module loaded")

-- Call setup with debug output
print("Calling setup with debug...")

-- Patch the setup function to add debug output
local original_setup = dap_cortex_debug.setup
function dap_cortex_debug.setup(opts)
    print("Setup function called with opts:", vim.inspect(opts))
    
    -- Call original setup
    local result = original_setup(opts)
    
    print("Setup function completed")
    return result
end

dap_cortex_debug.setup({
    debug = true,  -- Enable debug mode
    extension_path = nil,
    lib_extension = nil,
    node_path = 'node',
    dapui_rtt = false,
    dap_vscode_filetypes = { 'c', 'cpp' },
    rtt = {
        buftype = 'Terminal',
    },
})

print("Setup call completed")

-- Check results
print("\n=== Results ===")
if mock_dap_view.registered_views['custom_debug'] then
    print("✓ Custom view registered")
else
    print("✗ Custom view not registered")
end

local commands = vim.api.nvim_get_commands({})
if commands['CortexDebugCustomView'] then
    print("✓ User command registered")
else
    print("✗ User command not registered")
end

print("\nDebug completed")