--[[
  ReaScript Name: Export effect config
  Author: fitzgeraldkd
  Version: 1.00
  Link: https://github.com/fitzgeraldkd/reascripts
  About:
    TODO: Populate
  Changelog:
    # v1.00 (2025-05-05)
    - Initial release
]]

function get_fx_config(fx)

end

function get_track_config(track)

end

function get_project_config(project)
    local config = ''

    config = config + "test\n"
    config = config + "foo\n"

    return config
end

function run_script()
    local project = reaper.EnumProjects(-1)
    local config = get_project_config(project)
    file = io.open("fx_config.yaml", "w")
    file:write(config)
    file:close()
end

run_script()
