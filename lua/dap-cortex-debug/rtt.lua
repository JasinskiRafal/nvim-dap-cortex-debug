-- RTT utilities shared between dapui and dapview integrations

local M = {}

--- Find first open RTT channel by buffer name
---@return integer? channel # RTT channel number or nil if not found
function M.find_rtt_channel()
    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
        local name = vim.api.nvim_buf_get_name(buf)
        local channel = name:match([[cortex%-debug://rtt:([0-9]+)]])
        channel = vim.F.npcall(tonumber, channel)
        if channel then
            return channel
        end
    end
end

return M
