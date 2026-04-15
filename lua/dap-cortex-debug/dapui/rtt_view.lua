local consoles = require('dap-cortex-debug.consoles')
local rtt_utils = require('dap-cortex-debug.rtt')

local tmp_buf

---@type dapui.Element
return {
    render = function() end,
    buffer = function()
        local channel = rtt_utils.find_rtt_channel()
        if not channel then
            if not tmp_buf or not vim.api.nvim_buf_is_valid(tmp_buf) then
                tmp_buf = vim.api.nvim_create_buf(false, true)
            end
            return tmp_buf
        end
        local term = consoles.rtt_term(channel)
        return term.buf
    end,
    float_defaults = function()
        return { width = 80, height = 20, enter = true }
    end,
    on_rtt_connect = function(channel)
        -- Force dap-ui to reevaluate buffer() by changing the temporary buffer in our window
        if tmp_buf and vim.api.nvim_buf_is_valid(tmp_buf) then
            -- if our tmp buf is being displayed
            local win = vim.fn.bufwinid(tmp_buf)
            if vim.api.nvim_win_is_valid(win) then
                -- replace it with term buffer
                local term = consoles.rtt_term(channel)
                vim.api.nvim_win_set_buf(win, term.buf)
            end
        end
    end,
}
