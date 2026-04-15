-- RTT view implementation for nvim-dap-view integration
-- This implementation follows the same pattern as dapui/rtt.lua for consistency

local consoles = require('dap-cortex-debug.consoles')
local rtt_utils = require('dap-cortex-debug.rtt')

local tmp_buf

--- Get RTT buffer for nvim-dap-view
---@return integer bufnr # Buffer number
local function get_buffer()
    local channel = rtt_utils.find_rtt_channel()
    if not channel then
        if not tmp_buf or not vim.api.nvim_buf_is_valid(tmp_buf) then
            tmp_buf = vim.api.nvim_create_buf(false, true)
            vim.api.nvim_buf_set_lines(tmp_buf, 0, -1, false, {
                'RTT: No active RTT channels',
                'Start a debugging session with RTT configured to see output here.',
            })
        end
        return tmp_buf
    end
    local term = consoles.rtt_term(channel)
    return term.buf
end

--- Show RTT view - ensure buffer is properly displayed
local function show()
    local channel = rtt_utils.find_rtt_channel()
    if channel then
        local term = consoles.rtt_term(channel)
        if term then
            term:scroll()
        end
    end
end

return {
    get_buffer = get_buffer,
    show = show,
}
