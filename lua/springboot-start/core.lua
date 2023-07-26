local M = {}

local Input = require("nui.input")
local pickers = require('telescope.pickers')
local finders = require('telescope.finders')
local conf = require('telescope.config').values
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")
local utils = require('springboot-start.utils')
local list_cache_file = "spring-boot-cache.json"
local param_cache_file = "spring-boot-param-cache.json"
local selected_rel_and_deps = "spring-boot-selected-rel-and-deps.json"
local last_param_cache = "spring-boot-last-param-cache.json"
local whole_cmd = ""
local update_interval = 2592000 -- 一个月的秒数 (30天 * 24小时 * 60分钟 * 60秒)
local pdata, selected_rel, selected_deps, default_param, default_funs = {}, "gradle-project", {}, {}, {}
local default_sep = "AllDefault"
local param_limit = 150
local dep_limit = 4096
local default_dir = "."
M.options = {
  input = {
    position = {
      row = nil,
      col = nil,
    },
    size = {
      width = 25,
      height = 10,
    },
    border = {
      style = "single",
      text = {
        top = "[Dir]",
        top_align = "center",
      },
    },
    win_options = {
      winhighlight = "Normal:Normal,FloatBorder:Normal",
    },
  },
}
-- spring boot uri to download
-- template:
-- 	 curl -G https://start.spring.io/starter.tgz -d dependencies=web,data-jpa \
-- 		   -d type=gradle-project -d baseDir=my-dir | tar -xzvf -

local function process_param(chked_data)
  local project_param = {}
  for _, v in ipairs(chked_data) do
    local param = string.match(v[3], "%w*:(.*)")
    if param == "type" then
      goto continue
    end
    if param == "dependencies" then
      goto continue
    end
    local default_value = string.match(v[1], "%w*:(.*)")
    if param == "baseDir" then
      default_value = "my-dir"
    end
    project_param[param] = default_value
    ::continue::
  end
  return project_param
end

local function process(pre_data)
  pre_data = pre_data or {}
  local result = {}
  for _, v in pairs(pre_data) do
    local sreult = {}
    for k, vv in pairs(v) do
      utils.insert_or(sreult, k .. ":" .. vv)
    end
    table.sort(sreult)
    utils.insert_or(result, sreult)
  end
  return result
end

local function update_pdcache()
  local cache = utils.format_data()
  utils.write_cache(cache, list_cache_file)
  return cache
end

local function update_param_cache()
  if string.len(vim.inspect(pdata)) < dep_limit then
    update_pdcache()
  end
  local pre_data = pdata[utils.para]
  local cked_data = process(pre_data)
  local pparam = process_param(cked_data)
  utils.write_cache(pparam, param_cache_file)
  return pparam
end

local function update_selected_type_and_deps()
  local need_to_cache = { ["deps"] = {}, ["type"] = "", ["dir"] = "" }
  for _, v in ipairs(selected_deps) do
    utils.insert_or(need_to_cache["deps"], v)
  end
  need_to_cache["type"] = selected_rel
  need_to_cache["dir"] = default_dir
  utils.write_cache(need_to_cache, selected_rel_and_deps)
end

local function read_last_selected_cache()
  local srad = utils.read_cache(selected_rel_and_deps)
  default_param = utils.read_cache(last_param_cache)
  for k, v in pairs(srad) do
    if k == "type" then
      selected_rel = v
      goto continue
    end
    if k == "dir" then
      default_dir = v
      goto continue
    end
    for _, vv in pairs(v) do
      utils.insert_or(selected_deps, vv)
    end
    ::continue::
  end
end

local function write_last_selected_cache()
  update_selected_type_and_deps()
  utils.write_cache(default_param, last_param_cache)
end

local function update_cache()
  update_pdcache()
  update_param_cache()
  update_selected_type_and_deps()
end

-- register update cache functions

utils.register_init_or_update_cache_func(function()
  -- pdata cache
  if string.len(vim.inspect(pdata)) > dep_limit then
    return
  end
  local cache = utils.read_cache(list_cache_file)
  if string.len(vim.inspect(cache)) > dep_limit then
    pdata = cache
  else
    pdata = update_pdcache()
  end
end)

utils.register_init_or_update_cache_func(function()
  -- default_param cache
  if string.len(vim.inspect(default_param)) > param_limit then
    return
  end
  local param_cached = utils.read_cache(param_cache_file)
  if string.len(vim.inspect(param_cached)) > param_limit then
    default_param = param_cached
  else
    default_param = update_param_cache()
  end
end)

local function init_or_update_cache()
  for _, v in pairs(utils.cache_funcs) do
    v()
  end
end

-- modified_data should be a dict
local function alter_default_param(modified_data)
  for k, v in pairs(modified_data) do
    default_param[k] = v
  end
end

local function delete_selected_dep()
  local alter_dep = function(opts)
    opts = opts or {}
    pickers.new(opts, {
      prompt_title = 'Dependencies',
      finder = finders.new_table {
        results = selected_deps,
        entry_maker = function(entry)
          return {
            value = entry,
            display = entry,
            ordinal = entry,
          }
        end,
      },
      sorter = conf.generic_sorter(opts),
      attach_mappings = function(prompt_bufnr, map)
        actions.select_default:replace(function()
          local picker = action_state.get_current_picker(prompt_bufnr)
          actions.close(prompt_bufnr)
          -- 获取多选个数
          -- tab键多选
          local num_selections = #picker:get_multi_selection()
          if num_selections > 0 then
            local selections = picker:get_multi_selection()
            for _, selection in ipairs(selections) do
              -- selection排序之后，Id选项排在第二
              selected_deps = vim.tbl_filter(function(v)
                return v ~= selection.value
              end, selected_deps)
            end
          else
            local selection = action_state.get_selected_entry()
            selected_deps = vim.tbl_filter(function(v)
              return v ~= selection.value
            end, selected_deps)
            -- vim.api.nvim_put({ selection["value"][2] }, "", false, true)
          end
        end)
        return true
      end,
    }):find()
  end
  alter_dep(require('telescope.themes').get_dropdown {})
end

local function display_maker(tbl)
  local item = tbl.value
  return string.match(item[2], "%w*:(.*)") .. ": " .. string.match(item[1], "%w*:(.*)")
end

local function picker_finder(d, dm)
  return finders.new_table {
    results = d,
    entry_maker = function(entry)
      table.sort(entry)
      local ord = ""
      if entry == nil then
        return {
          value = entry,
          display = dm,
          ordinal = ord,
        }
      end
      -- means Rel
      if #entry == 2 or string.match(entry[2], "(%w*):.*") == utils.id then
        ord = string.match(entry[2], "%w*:(.*)")
      else
        ord = string.match(entry[3], "%w*:(.*)")
      end
      return {
        value = entry,
        display = dm,
        ordinal = ord,
      }
    end,
  }
end

-- can be selected
local function gettype(raw_data)
  raw_data = raw_data or {}
  local pre_data = raw_data[utils.ttype]
  local cked_data = process(pre_data)
  local tpy = function(opts)
    opts = opts or {}
    pickers.new(opts, {
      prompt_title = 'Rel',
      finder = picker_finder(cked_data, display_maker),
      sorter = conf.generic_sorter(opts),
      attach_mappings = function(prompt_bufnr, map)
        actions.select_default:replace(function()
          actions.close(prompt_bufnr)
          -- 获取多选个数
          -- tab键多选
          local selection = action_state.get_selected_entry()
          local raw_rel = string.match(selection["value"][2], "%w*:(.*)")
          selected_rel = string.match(raw_rel, "^([%w|%-]+)")
        end)
        return true
      end,
    }):find()
  end
  tpy(require('telescope.themes').get_dropdown {})
end

-- should be inputed
local function getparameters(raw_data)
  if not M.options.input.position.row then
    M.options.input.position.row = vim.fn.winheight(0) * 0.2
  end
  if not M.options.input.position.col then
    M.options.input.position.col = vim.fn.winwidth(0) * 0.4
  end
  if not M.options.input.border.text.top or M.options.input.border.text.top == "[Dir]" then
    M.options.input.border.text.top = "[Modify]"
  end
  local input = Input(M.options.input, {
    prompt = M.options.input.prompt or "> ",
    default_value = "default",
    on_close = function()
      utils.notify("Input Closed!")
    end,
    on_submit = function(value)
      local selection = action_state.get_selected_entry()
      local selected = string.match(selection["value"][3], "%w*:(.*)")
      if value == "default" or not value or value == "" then
        utils.notify("Input Submitted: " .. selected .. "=" .. default_param[selected])
        return
      end
      local moded = { [selected] = value }
      alter_default_param(moded)
      utils.notify("Input Submitted: " .. selected .. "=" .. value)
    end,
  })
  -- unmount input by pressing `<Esc>` in normal mode
  -- consistent with telescope.nvim
  input:map("n", "<Esc>", function()
    input:unmount()
  end, { noremap = true })
  raw_data = raw_data or {}
  local pre_data = raw_data[utils.para]
  local cked_data = process(pre_data)
  utils.insert_or(cked_data, { "Parameter:" .. default_sep, "Description:" .. default_sep, "DefaultValue:" .. default_sep })
  local par = function(opts)
    opts = opts or {}
    pickers.new(opts, {
      prompt_title = 'Rel',
      finder = picker_finder(cked_data, function(tbl)
        local item = tbl.value
        return string.match(item[3], "%w*:(.*)") ..
            ": " ..
            "(default)" .. string.match(item[1], "%w*:(.*)") .. " Description: " .. string.match(item[2], "%w*:(.*)")
      end),
      sorter = conf.generic_sorter(opts),
      attach_mappings = function(prompt_bufnr, map)
        actions.select_default:replace(function()
          -- actions.close(prompt_bufnr)
          local selection = action_state.get_selected_entry()
          if string.match(selection["value"][3], "%w*:(.*)") == default_sep then
            actions.close(prompt_bufnr)
            input:unmount()
          else
            input:mount()
          end
        end)
        return true
      end,
    }):find()
  end
  par(require('telescope.themes').get_dropdown {})
end

-- can be selected
local function getdependencies(raw_data)
  raw_data = raw_data or {}
  local pre_data = raw_data[utils.id]
  local cked_data = process(pre_data)
  local dep = function(opts)
    opts = opts or {}
    pickers.new(opts, {
      prompt_title = 'Dependencies',
      finder = picker_finder(cked_data, display_maker),
      sorter = conf.generic_sorter(opts),
      attach_mappings = function(prompt_bufnr, map)
        actions.select_default:replace(function()
          local picker = action_state.get_current_picker(prompt_bufnr)
          actions.close(prompt_bufnr)
          -- 获取多选个数
          -- tab键多选
          -- if selected one, num_selections is zero
          local num_selections = #picker:get_multi_selection()
          if num_selections > 0 then
            local selections = picker:get_multi_selection()
            for _, selection in ipairs(selections) do
              -- selection排序之后，Id选项排在第二
              utils.insert_or(selected_deps, string.match(selection.value[2], "%w*:(.*)"))
            end
          else
            local selection = action_state.get_selected_entry()
            utils.insert_or(selected_deps, string.match(selection.value[2], "%w*:(.*)"))
            -- vim.api.nvim_put({ selection["value"][2] }, "", false, true)
          end
        end)
        return true
      end,
    }):find()
  end
  dep(require('telescope.themes').get_dropdown {})
end

local function gen_command()
  local udep = "-d dependencies="
  for k, v in pairs(selected_deps) do
    if k == 1 then
      udep = udep .. v
      goto continue
    end
    udep = udep .. "," .. v
    ::continue::
  end
  local utype = "-d type="
  utype = utype .. selected_rel
  local upar = ""
  -- default_file_name = default_param["applicationName"] .. ".tgz" or default_file_name .. ".tgz"
  for k, v in pairs(default_param) do
    if string.match(v, "%s") then
      upar = upar .. "--data-urlencode " .. "'" .. k .. "=" .. v .. "' "
    else
      upar = upar .. "-d " .. k .. "=" .. v .. " "
    end
  end
  whole_cmd = "(cd " ..
      default_dir ..
      ";curl -sG " ..
      utils.url .. "/starter.tgz " .. udep .. " " .. utype .. " " .. upar .. " | tar -zxvf - 1>/dev/null)"
end

local function chose_dir()
  if not M.options.input.position.row then
    M.options.input.position.row = vim.fn.winheight(0) * 0.2
  end
  if not M.options.input.position.col then
    M.options.input.position.col = vim.fn.winwidth(0) * 0.4
  end
  if not M.options.input.border.text.top or M.options.input.border.text.top == "[Modify]" then
    M.options.input.border.text.top = "[Dir]"
  end
  local input = Input(M.options.input, {
    prompt = M.options.input.prompt or "> ",
    default_value = ".",
    on_close = function()
      utils.notify("Input Closed!")
    end,
    on_submit = function(value)
      local path = vim.fn.expand(value)
      default_dir = path or default_dir
      utils.notify("Input Submitted: " .. default_dir)
    end,
  })
  -- unmount input by pressing `<Esc>` in normal mode
  -- consistent with telescope.nvim
  input:map("n", "<Esc>", function()
    input:unmount()
  end, { noremap = true })
  input:mount()
end

--[[
-- export functions
--]]

M.init = function()
  init_or_update_cache()
  -- if string.len(vim.inspect(pdata)) < dep_limit then
  --   vim.cmd('highlight MyRedColor guifg=#FF0000')
  --   utils.highlight('MyRedColor', 'spring boot init failed')
  -- else
  --   vim.cmd('highlight MyGreenColor guifg=#00FF00')
  --   utils.highlight('MyGreenColor', 'spring boot project data has been fetched')
  -- end
end

M.getdep = function()
  M.init()
  getdependencies(pdata)
end

M.gettype = function()
  -- local raw_d = M.sp()
  M.init()
  gettype(pdata)
end

M.getpar = function()
  M.init()
  getparameters(pdata)
end

M.chose_dir = function()
  chose_dir()
end

local function format_show(title, data, format)
  data = data or {}
  utils.notify(title)
  for k, v in pairs(data) do
    utils.notify(string.format(format, k, v))
  end
end

M.show_dep = function()
  format_show("deps: ", selected_deps, "%5d. %s")
end

M.show_rel = function()
  format_show("rel: ", { selected_rel }, "%5d. %s")
end

M.show_par = function()
  if string.len(vim.inspect(default_param)) < param_limit then
    local param_cached = utils.read_cache(param_cache_file)
    default_param = param_cached
  end
  utils.notify("par: ")
  for k, v in pairs(default_param) do
    utils.notify(string.format("%s", k .. "=" .. v))
  end
end

M.show_selected = function()
  format_show("rel: ", { selected_rel }, "%5d. %s")
  format_show("deps: ", selected_deps, "%5d. %s")
  M.show_par()
  format_show("dir: ", { default_dir }, "%5d. %s")
end

M.show_last_selected = function()
  local srad = utils.read_cache(selected_rel_and_deps)
  local last_param = utils.read_cache(last_param_cache)
  local sr, dd, sd = "", "", {}
  for k, v in pairs(srad) do
    if k == "type" then
      sr = v
      goto continue
    end
    if k == "dir" then
      dd = v
      goto continue
    end
    for _, vv in pairs(v) do
      utils.insert_or(sd, vv)
    end
    ::continue::
  end
  format_show("rel: ", { sr }, "%5d. %s")
  format_show("deps: ", sd, "%5d. %s")
  format_show("par: ", last_param, "%s=%s")
  format_show("dir: ", { dd }, "%5d. %s")
end

M.create_project = function()
  M.init()
  gen_command()
  local res = vim.fn.system(whole_cmd)
  if res == "" then
    vim.cmd('highlight MyGreenColor guifg=#00FF00')
    utils.highlight('MyGreenColor', 'spring boot project has been initialized')
    write_last_selected_cache()
  else
    vim.cmd('highlight MyRedColor guifg=#FF0000')
    utils.highlight('MyRedColor', 'spring boot init failed')
  end
end

M.create_last_selected_project = function()
  read_last_selected_cache()
  gen_command()
  local res = vim.fn.system(whole_cmd)
  if res == "" then
    vim.cmd('highlight MyGreenColor guifg=#00FF00')
    utils.highlight('MyGreenColor', 'spring boot project has been initialized')
    write_last_selected_cache()
  else
    vim.cmd('highlight MyRedColor guifg=#FF0000')
    utils.highlight('MyRedColor', 'spring boot init failed')
  end
end

M.delete_selected_dep = function()
  delete_selected_dep()
end

-- read the last parameters, but do not create a project,
-- so as to modify some parameters later.
M.get_last_selected = function()
  read_last_selected_cache()
  M.show_selected()
end

M.menu = function(opts)
  M.init()
  default_funs["getdep"] = M.getdep
  default_funs["gettype"] = M.gettype
  default_funs["getpar"] = M.getpar
  default_funs["chose_dir"] = M.chose_dir
  default_funs["show_dep"] = M.show_dep
  default_funs["show_rel"] = M.show_rel
  default_funs["show_par"] = M.show_par
  default_funs["show_selected"] = M.show_selected
  default_funs["create_project"] = M.create_project
  -- default_funs["init"] = M.init
  default_funs["remove_cache"] = M.remove_cache
  default_funs["update_cache"] = M.update_cache
  default_funs["show_last_selected"] = M.show_last_selected
  default_funs["create_last_selected_project"] = M.create_last_selected_project
  default_funs["delete_dep"] = M.delete_selected_dep
  default_funs["display_cache_dir"] = M.display_cache_file_location
  default_funs["get_last_selected"] = M.get_last_selected
  opts = opts or {}
  pickers.new(opts, {
    prompt_title = "Functions",
    finder = finders.new_table({
      results = {
        -- { "init",               "Initialize basic data and default parameters of Spring project" },
        { "getdep",             "Choose dependencies" },
        { "gettype",            "Choose project type" },
        { "getpar",             "Alter default project parameters" },
        { "chose_dir",          "chose project directory" },
        { "show_dep",           "Show selected dependencies" },
        { "show_rel",           "Show selected project type" },
        { "show_par",           "Show selected project parameters" },
        { "show_selected",      "Show all selected" },
        { "create_project",     "Create project" },
        { "remove_cache",       "Remove cache files" },
        { "update_cache",       "Update cache" },
        { "show_last_selected", "Show last selected" },
        { "create_last",        "Create project using last selected" },
        { "delete_dep",         "Alter selected deps" },
        { "display_cache_dir",  "Show cache folder location" },
        { "get_last_selected",  "Get last selected" }
      },
      entry_maker = function(entry)
        return {
          value = entry,
          display = entry[1] .. ": " .. entry[2],
          ordinal = entry[1],
        }
      end,
    }),
    sorter = conf.generic_sorter(opts),
    attach_mappings = function(prompt_bufnr, map)
      actions.select_default:replace(function()
        local selection = action_state.get_selected_entry()
        actions.close(prompt_bufnr)
        default_funs[selection.value[1]]()
      end)
      return true
    end,
  }):find()
end

M.test_dir = function()
  -- local script = debug.getinfo(1, "S").source:sub(2)
  -- local folder_path = script:match("(.*/)"):sub(1, -2)
  local script_path = debug.getinfo(1, "S").source:sub(2)        -- 去掉路径前缀的 '@' 字符
  local current_folder = vim.fn.fnamemodify(script_path, ":h")   -- 获取当前文件夹路径
  local parent_folder = vim.fn.fnamemodify(current_folder, ":h") -- 获取上一级文件夹路径
  utils.notify(parent_folder)
end

M.setup = function(opts)
  M.options = vim.tbl_deep_extend("force", M.options, opts or {})
end

M.remove_cache = function()
  local std_cache_path = vim.fn.stdpath('cache') .. '/'
  utils.remove_cache(std_cache_path .. list_cache_file)
  utils.remove_cache(std_cache_path .. param_cache_file)
  utils.remove_cache(std_cache_path .. last_param_cache)
  utils.remove_cache(std_cache_path .. selected_rel_and_deps)
end

M.display_cache_file_location = function()
  utils.notify("cache file location: " .. vim.fn.stdpath('cache') .. '/')
end

M.update_cache = function()
  update_cache()
end

return M
