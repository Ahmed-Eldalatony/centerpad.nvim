local v = vim.api

local center_buf = {}

-- function to toggle zen mode on
local turn_on = function(config)
  -- Get reference to current_buffer
  local main_win = v.nvim_get_current_win()
  local main_buffer = v.nvim_get_current_buf()

  -- get the user's current options for split directions
  local useropts = {
    splitbelow = vim.o.splitbelow,
    splitright = vim.o.splitright,
  }

  -- Only proceed if there are not too many windows open already
  if #v.nvim_tabpage_list_wins(0) > 2 or vim.g.center_buf_enabled then
    return
  end

  -- create scratch window to the left
  vim.o.splitright = false
  vim.cmd(string.format('%svnew', config.leftpad))
  local leftpad = v.nvim_get_current_buf()
  vim.opt_local.relativenumber = false
  v.nvim_buf_set_name(leftpad, 'leftpad')
  v.nvim_buf_set_option(leftpad, "buflisted", false)
  v.nvim_buf_set_option(leftpad, "buftype", "acwrite")
  v.nvim_buf_set_option(leftpad, "modifiable", false)
  v.nvim_set_current_win(main_win)

  -- create scratch window to the right
  vim.o.splitright = true
  vim.cmd(string.format('%svnew', config.rightpad))
  local rightpad = v.nvim_get_current_buf()
  vim.opt_local.relativenumber = false
  v.nvim_buf_set_name(rightpad, 'rightpad')
  v.nvim_buf_set_option(rightpad, "buflisted", false)
  v.nvim_buf_set_option(rightpad, "buftype", "acwrite")
  v.nvim_buf_set_option(rightpad, "modifiable", false)

  -- keep track of the current state of the plugin
  vim.g.center_buf_enabled = true

  -- reset the user's split opts
  vim.o.splitbelow = useropts.splitbelow
  vim.o.splitright = useropts.splitright

  v.nvim_set_current_win(main_win)
  v.nvim_set_current_buf(main_buffer)
end

-- function to toggle zen mode off
local turn_off = function(config)
  local curr_buf = v.nvim_get_current_buf()
  local curr_bufname = v.nvim_buf_get_name(curr_buf)

  if curr_bufname == 'leftpad' or curr_bufname == 'rightpad' then
    print('If you want to toggle off zen mode, switch focus out of a scratch buffer')
    return
  end

  local windows = v.nvim_tabpage_list_wins(0)
  for _, win in ipairs(windows) do
    local bufnr = v.nvim_win_get_buf(win)
    local cur_name = v.nvim_buf_get_name(bufnr)
    if cur_name:match('leftpad') or cur_name:match('rightpad') then
      v.nvim_buf_delete(bufnr, { force = true })
    end
  end

  vim.g.center_buf_enabled = false
end

-- User functions
center_buf.turn_off = function(config)
  if vim.g.center_buf_enabled == true then
    turn_off(config)
  end
end

center_buf.turn_on = function(config)
  config = config or { leftpad = 36, rightpad = 36 }
  if not vim.g.center_buf_enabled then
    turn_on(config)
  end
end

center_buf.toggle = function(config)
  config = config or { leftpad = 36, rightpad = 36 }
  if vim.g.center_buf_enabled == true then
    turn_off(config)
  else
    turn_on(config)
  end
end

center_buf.run_command = function(...)
  local args = { ... }
  if #args == 1 then
    center_buf.toggle { leftpad = args[1], rightpad = args[1] }
  elseif #args == 2 then
    center_buf.toggle { leftpad = args[1], rightpad = args[2] }
  else
    center_buf.toggle()
  end
end

-- Automatically enable on startup and buffer/window enter
vim.api.nvim_create_autocmd({ "VimEnter", "BufWinEnter" }, {
  callback = function()
    local ft = vim.bo.filetype
    local exclude = { "NvimTree", "TelescopePrompt", "help", "dashboard", "alpha" }

    for _, e in ipairs(exclude) do
      if ft == e then return end
    end

    if not vim.g.center_buf_enabled and #v.nvim_tabpage_list_wins(0) <= 2 then
      require('center_buf').turn_on()
    end
  end
})

return center_buf
