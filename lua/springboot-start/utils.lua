local M = {}
M.ttype = "Rel"
M.para = "Parameter"
M.id = "Id"
M.url = 'https://start.spring.io'
M.cache_funcs = {}

local function get_file_modification_time(file_path)
  local stat = vim.loop.fs_stat(file_path)
  if stat then
    return stat.mtime.sec
  end
  return nil
end

M.notify = function(msg)
  print(msg)
end

M.check_cache_update = function(cache_file_path, update_interval, update_callback)
  local current_time = os.time()
  local last_modification_time = get_file_modification_time(cache_file_path)
  -- 使用vim.schedule_wrap将更新缓存的操作封装为异步任务
  local update_async = vim.schedule_wrap(update_callback)
  if not last_modification_time then
    M.notify("curtime: " .. current_time .. " lasttime: nil")
  else
    M.notify("curtime: " .. current_time .. " lasttime: " .. last_modification_time)
  end

  if not last_modification_time then
    update_async()
    return
  end

  local time_difference = current_time - last_modification_time

  if time_difference >= update_interval then
    update_async()
  else
    local remaining_time = update_interval - time_difference
    M.notify("Cache will be updated in " .. remaining_time .. " seconds.")
  end
end


M.raw_fetch = function()
  local res = vim.fn.system("curl -s " .. M.url)
  local lines = vim.split(res, '\n')
  local content_pattern = "%|(.*%|)"
  local table_sep_pattern = "%+%-.*%-%+"
  local table_limit = 3
  local table_limit_count = 0
  local tables = {}
  local ress = {}
  for _, line in ipairs(lines) do
    local content_match = line:gmatch(content_pattern)
    local sep_match = string.match(line, table_sep_pattern)
    if sep_match ~= nil then
      table_limit_count = table_limit_count + 1
      if table_limit_count == table_limit then
        table.insert(tables, ress)
        ress = {}
        table_limit_count = 0
        goto continue
      end
    end
    for content in content_match do
      if not string.match(content, "^%s*%|") and string.match(content, "%w") then
        table.insert(ress, content)
      end
    end
    ::continue::
  end
  return tables
end

M.gcol = function(l)
  local head_words = {}
  for head_word in l:gmatch("%s*([^|]+)%s*|") do
    table.insert(head_words, head_word:match("^%s*(.-)%s*$"))
  end
  return head_words
end

M.isIn = function(v, t)
  for _, value in ipairs(t) do
    if value == v then
      return true
    end
  end
  return false
end

M.format_data = function()
  local matches = M.raw_fetch()
  local result, tmpl, tmps, hws = {}, {}, {}, {}
  for _, match in ipairs(matches) do
    for j, line in ipairs(match) do
      if j == 1 then
        hws = M.gcol(line)
        goto continue
      end
      local data = M.gcol(line)
      for k, _ in ipairs(hws) do
        tmps[hws[k]] = data[k] or ""
      end
      table.insert(tmpl, tmps)
      tmps = {}
      ::continue::
    end
    -- 为每一个表添加key
    if M.isIn(M.ttype, hws) then
      result[M.ttype] = tmpl
    end
    if M.isIn(M.para, hws) then
      result[M.para] = tmpl
    end
    if M.isIn(M.id, hws) then
      result[M.id] = tmpl
    end
    tmpl = {}
  end
  return result
end

-- cache things
M.read_cache = function(file_name)
  local cached_file = vim.fn.stdpath('cache') .. '/' .. file_name
  local data = {}
  local file = io.open(cached_file, 'r')
  if file then
    local content = file:read('*all')
    file:close()
    data = vim.fn.json_decode(content) or {}
  end
  return data
end

M.write_cache = function(data, file_name)
  local cached_file = vim.fn.stdpath('cache') .. '/' .. file_name
  local file = io.open(cached_file, 'w')
  if file then
    file:write(vim.fn.json_encode(data))
    file:close()
  end
end

M.highlight = function(name, msg)
  local cmd = "echohl " .. name .. " | echo '" .. msg .. "' | echohl None"
  vim.cmd(cmd)
end

M.remove_cache = function (file_name)
  os.remove(file_name)
end

M.register_init_or_update_cache_func = function(cache_func)
  table.insert(M.cache_funcs, cache_func)
end

-- if item is in table do nothing else insert item into table
M.insert_or = function (tbl, item)
  for _, value in ipairs(tbl) do
    if vim.deep_equal(value, item) then
      return
    end
  end
  table.insert(tbl, item)
end

return M
