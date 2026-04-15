-- RTT view implementation for nvim-dap-view integration
local consoles = require('dap-cortex-debug.consoles')
local utils = require('dap-cortex-debug.utils')

local M = {}

--- Find all RTT terminal buffers
---@return table<integer, integer> # Map of channel -> buffer number
local function find_rtt_buffers()
    local rtt_buffers = {}
    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
        local name = vim.api.nvim_buf_get_name(buf)
        local channel = name:match([[cortex%-debug://rtt:([0-9]+)]])
        channel = vim.F.npcall(tonumber, channel)
        if channel then
            rtt_buffers[channel] = buf
        end
    end
    return rtt_buffers
end

--- Get the first available RTT buffer, or create a temporary one
---@return integer bufnr # Buffer number
function M.get_buffer()
    local rtt_buffers = find_rtt_buffers()

    -- Return first RTT buffer if available
    if not vim.tbl_isempty(rtt_buffers) then
        -- Return the first channel's buffer (sorted by channel number)
        local channels = vim.tbl_keys(rtt_buffers)
        table.sort(channels)
        return rtt_buffers[channels[1]]
    end

    -- Create temporary buffer if no RTT channels are active
    local tmp_buf = vim.api.nvim_create_buf(false, true)
    local temp_name = 'cortex-debug://rtt-temp'
    -- Try to set unique name if buffer with this name already exists
    local counter = 1
    while true do
        local success, err = pcall(function()
            vim.api.nvim_buf_set_name(tmp_buf, counter == 1 and temp_name or temp_name .. '-' .. counter)
        end)
        if success then
            break
        end
        counter = counter + 1
    end
    vim.api.nvim_buf_set_lines(tmp_buf, 0, -1, false, {
        'RTT: No active RTT channels',
        'Start a debugging session with RTT configured to see output here.',
    })

    return tmp_buf
end

--- Show RTT view in nvim-dap-view window
function M.show()
    if not utils.is_buf_valid(M.get_buffer()) then
        return
    end

    local rtt_buf = M.get_buffer()

    -- Check if this is a temporary buffer
    local is_temp = vim.api.nvim_buf_get_name(rtt_buf):find('rtt%-temp') ~= nil

    if not is_temp then
        -- For real RTT buffers, ensure proper terminal settings
        local term = consoles.rtt_term(M.get_rtt_channel_from_buffer(rtt_buf))
        if term then
            term:scroll()
        end
    end
end

--- Get RTT channel from buffer name
---@param bufnr integer
---@return integer? channel
function M.get_rtt_channel_from_buffer(bufnr)
    local name = vim.api.nvim_buf_get_name(bufnr)
    local channel = name:match([[cortex%-debug://rtt:([0-9]+)]])
    return vim.F.npcall(tonumber, channel)
end

--- Check if buffer is valid
---@param bufnr integer
---@return boolean
function M.is_buf_valid(bufnr)
    return vim.api.nvim_buf_is_valid(bufnr) and vim.api.nvim_buf_is_loaded(bufnr)
end

return M

