--[[
  ReaScript Name: Sync subproject tempo markers
  Author: fitzgeraldkd
  Version: 1.00
  Link: https://github.com/fitzgeraldkd/reascripts
  About:
    TODO: Set about.
  Changelog:
    # v1.00 (TODO: Set date)
    - Initial release
]]


-------------------------
-- USER CONFIG ----------
-------------------------

local use_timepos = false
local round_beatpos_to_int = true


-------------------
-- UTILS ----------
-------------------

function get_is_array(t)
  local i = 0
  for _ in pairs(t) do
      i = i + 1
      if t[i] == nil then return false end
  end
  return true
end


function get_tempo_time_sig_markers(project)
  local tempo_time_sig_markers = {}
  local i = 0
  while true do
    exists, timepos, measurepos, beatpos, bpm, timesig_num, timesig_denom, linear_tempo = reaper.GetTempoTimeSigMarker(project, i)
    if not exists then break end
    table.insert(tempo_time_sig_markers, {
      timepos=timepos,
      measurepos=measurepos,
      beatpos=beatpos,
      bpm=bpm,
      timesig_num=timesig_num,
      timesig_denom=timesig_denom,
      linear_tempo=linear_tempo,
    })
    i = i + 1
  end
  return tempo_time_sig_markers
end


-- TODO: Strings may need to be wrapped in quotes.
function parse_table_to_yaml(data, prefix, skip_first_prefix)
  local results = ''
  if is_array(data) then
    for i, value in ipairs(data) do
      local parsed_value = value
      local suffix = '\n'
      local this_prefix = prefix
      if skip_first_prefix and i == 1 then this_prefix = '' end
      if type(value) == 'table' then
        parsed_value = parse_table_to_yaml(value, prefix..'  ', true)
        suffix = ''
      elseif type(value) == 'boolean' then
        if value then parsed_value = 'true' else parsed_value = 'false' end
      end
      results = results..this_prefix..'- '..parsed_value..suffix
    end
  else
    local is_first = true
    for key, value in pairs(data) do
      local parsed_value = value
      local suffix = '\n'
      local this_prefix = prefix
      if skip_first_prefix and is_first then this_prefix = '' end
      if type(value) == 'table' then
        local next_prefix = prefix..'  '
        if is_array(value) then next_prefix = prefix end
        parsed_value = '\n'..parse_table_to_yaml(value, next_prefix, false)
        suffix = ''
      elseif type(value) == 'boolean' then
        if value then parsed_value = 'true' else parsed_value = 'false' end
      end
      results = results..this_prefix..key..': '..parsed_value..suffix
      is_first = false
    end
  end
  return results
end


function write_yaml_to_file(yaml)

end


-------------------------
-- MAIN SCRIPT ----------
-------------------------

reaper.ClearConsole()
local project = reaper.EnumProjects(-1)
local tempo_time_sig_markers = get_tempo_time_sig_markers(project)
local data = {
  tempo_time_sig_markers=tempo_time_sig_markers,
}
local yaml = '---\n'..parse_table_to_yaml(data)
write_yaml_to_file(yaml)
