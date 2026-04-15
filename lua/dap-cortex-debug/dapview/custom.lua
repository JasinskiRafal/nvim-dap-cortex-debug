-- Custom DAP View for nvim-dap-cortex-debug
-- Integrates with nvim-dap-view to provide a custom debugging view
-- that can display "hello" or output from rbonsai program

local M = {}

---@class CustomViewConfig
---@field label string
---@field keymap string
---@field action fun(): nil
---@field buffer fun(): number

---Create the custom view configuration for nvim-dap-view
---@return CustomViewConfig
function M.create_custom_view()
    local bufnr = nil
    local ns_id = vim.api.nvim_create_namespace('dap_cortex_debug_custom_view')
    
    return {
        label = "Custom Debug",
        keymap = "C",
        action = function()
            -- This function is called when the view is activated
            if not bufnr or not vim.api.nvim_buf_is_valid(bufnr) then
                bufnr = M.create_buffer()
            end
            
            -- Update the buffer content
            M.update_buffer_content(bufnr, ns_id)
            
            -- Jump to the view
            local ok, dap_view = pcall(require, 'dap-view')
            if ok then
                dap_view.show_view('custom_debug')
            end
        end,
        buffer = function()
            if not bufnr or not vim.api.nvim_buf_is_valid(bufnr) then
                bufnr = M.create_buffer()
            end
            return bufnr
        end,
    }
end

---Create a new buffer for the custom view
---@return number bufnr
function M.create_buffer()
    local buf = vim.api.nvim_create_buf(false, true)
    
    -- Set buffer options
    vim.api.nvim_buf_set_option(buf, 'filetype', 'dap-custom-view')
    vim.api.nvim_buf_set_option(buf, 'buftype', 'nofile')
    vim.api.nvim_buf_set_option(buf, 'bufhidden', 'hide')
    vim.api.nvim_buf_set_option(buf, 'swapfile', false)
    vim.api.nvim_buf_set_option(buf, 'buflisted', false)
    
    -- Set buffer name
    vim.api.nvim_buf_set_name(buf, 'dap-cortex-debug://custom-view')
    
    return buf
end

---Update the buffer content with either "hello" or rbonsai output
---@param bufnr number
---@param ns_id number
function M.update_buffer_content(bufnr, ns_id)
    -- Clear existing content
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, {})
    
    -- Add header
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, {
        "=== Custom DAP View ===",
        "",
    })
    
    -- Check if rbonsai is available
    local rbonsai_available = vim.fn.executable('rbonsai') == 1
    
    if rbonsai_available then
        -- Try to get rbonsai output
        local success, output = pcall(function()
            return M.get_rbonsai_output()
        end)
        
        if success and output and output ~= "" then
            vim.api.nvim_buf_set_lines(bufnr, -1, -1, false, {
                "=== rbonsai output ===",
                "",
            })
            
            -- Split output by lines and add to buffer
            for _, line in ipairs(vim.split(output, '\n')) do
                if line ~= "" then
                    vim.api.nvim_buf_set_lines(bufnr, -1, -1, false, {line})
                end
            end
        else
            vim.api.nvim_buf_set_lines(bufnr, -1, -1, false, {
                "Hello from nvim-dap-cortex-debug custom view!",
                "",
                "rbonsai is installed but could not retrieve output",
            })
        end
    else
        vim.api.nvim_buf_set_lines(bufnr, -1, -1, false, {
            "Hello from nvim-dap-cortex-debug custom view!",
            "",
            "rbonsai is not installed or not in PATH",
        })
    end
    
    -- Add some helpful information
    vim.api.nvim_buf_set_lines(bufnr, -1, -1, false, {
        "",
        "=== Info ===",
        "This is a custom DAP view integrated with nvim-dap-cortex-debug.",
        "It demonstrates how to extend debugging functionality.",
    })
    
    -- Add syntax highlighting
    M.apply_syntax_highlighting(bufnr, ns_id)
end

---Get output from rbonsai program
---@return string|nil
function M.get_rbonsai_output()
    local job = require('plenary.job'):new({
        command = 'rbonsai',
        args = {'--help'}, -- Use --help to get some output, can be changed
        cwd = vim.loop.cwd(),
    })
    
    local result, return_val = job:sync()
    
    if return_val == 0 and result and #result > 0 then
        return table.concat(result, '\n')
    else
        return nil
    end
end

---Apply syntax highlighting to the buffer
---@param bufnr number
---@param ns_id number
function M.apply_syntax_highlighting(bufnr, ns_id)
    -- Clear existing highlights
    vim.api.nvim_buf_clear_namespace(bufnr, ns_id, 0, -1)
    
    -- Highlight headers
    local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
    for i, line in ipairs(lines) do
        if line:match("^===.*===$") then
            vim.api.nvim_buf_add_highlight(bufnr, ns_id, 'Title', i - 1, 0, -1)
        elseif line:match("^Hello") then
            vim.api.nvim_buf_add_highlight(bufnr, ns_id, 'String', i - 1, 0, -1)
        end
    end
end

---Register the custom view with nvim-dap-view
function M.register_view()
    local ok, dap_view = pcall(require, 'dap-view')
    if not ok then
        vim.notify("nvim-dap-view not found. Custom view registration skipped.", vim.log.levels.WARN)
        return false
    end
    
    -- Check if register_view function exists
    if not dap_view.register_view then
        vim.notify("nvim-dap-view version doesn't support custom views.", vim.log.levels.WARN)
        return false
    end
    
    -- Create and register our custom view
    local custom_view = M.create_custom_view()
    dap_view.register_view('custom_debug', custom_view)
    
    vim.notify("Registered custom_debug view with nvim-dap-view", vim.log.levels.INFO)
    return true
end

return M