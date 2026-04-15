-- Debug the setup process

-- Add the plugin to runtime path
vim.opt.runtimepath:append('.')

print("Debugging setup process...")

-- Test if we can load the custom view module directly
local success, custom_view = pcall(require, 'dap-cortex-debug.dapview.custom')
if success then
    print("✓ Successfully loaded custom view module")
else
    print(string.format("✗ Failed to load custom view module: %s", custom_view))
end

-- Mock the dap-view module
local mock_dap_view = {
    registered_views = {},
    register_view = function(self, name, view)
        self.registered_views[name] = view
        print(string.format("Mock: Registered view '%s'", name))
    end,
    show_view = function(self, name)
        print(string.format("Mock: Showing view '%s'", name))
    end
}

-- Mock require to return our mock dap-view
package.loaded['dap-view'] = mock_dap_view

-- Now test the setup step by step
print("\nTesting setup step by step...")

-- Load the main module
local dap_cortex_debug = require('dap-cortex-debug')
print("✓ Loaded dap-cortex-debug module")

-- Call setup manually to see what happens
print("Calling setup...")
dap_cortex_debug.setup({
    debug = false,
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

-- Check if view was registered
if mock_dap_view.registered_views['custom_debug'] then
    print("✓ Custom view registered during setup")
else
    print("✗ Custom view not registered during setup")
end

-- Check if user command was created
local commands = vim.api.nvim_get_commands({})
if commands['CortexDebugCustomView'] then
    print("✓ User command registered")
else
    print("✗ User command not registered")
end

print("\nDebug completed")