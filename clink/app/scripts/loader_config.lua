-- Copyright (c) 2024 Christopher Antos
-- License: http://opensource.org/licenses/MIT

local norm = "\x1b[m"
local italic = "\x1b[3m"
local underline = "\x1b[4m"
local bold = "\x1b[1m"
--local reverse = "\x1b[7m"
--local noreverse = "\x1b[27m"

--------------------------------------------------------------------------------
local function printerror(message)
    io.stderr:write(message)
    io.stderr:write("\n")
end

--------------------------------------------------------------------------------
local demo_colors =
{
    ["0"] = "",

    ["A"] = "color.arg",
    ["C"] = "color.cmd",
    ["D"] = "color.doskey",
    ["E"] = "color.executable",
    ["F"] = "color.flag",
    ["G"] = "color.message",
    ["H"] = "color.histexpand",
    ["I"] = "color.input",
    ["L"] = "color.selection",
    ["M"] = "color.argmatcher",
    ["P"] = "color.prompt",
    ["R"] = "color.comment_row",
    ["S"] = "color.suggestion",
    ["U"] = "color.unexpected",
    ["Z"] = "color.unrecognized",

    ["&"] = "color.cmdsep",
    [">"] = "color.cmdredir",
    ["?"] = "color.interact",

    ["d"] = "color.description",
    ["h"] = "hidden",
    ["i"] = "color.arginfo",
    ["l"] = "color.selected_completion",
    ["p"] = "color.common_match_prefix",
    ["r"] = "readonly",

    ["_"] = "cursor",
    ["\\"] = "dir",

    --color.filtered
    --color.horizscroll
    --color.modmark
    --color.popup
    --color.popup_desc
}

local demo_strings =
{
    "!I",
    "{PC:\\>}{Mclink} {Aset} {F--help}",
    "{PC:\\>}{Cecho} hello {>>file} {&&} {Enotepad} file",
    "{PC:\\>}{Dmyalias} This{_▂}{Sis an auto-suggestion}",
    "{PC:\\>}{Zxyzzy.exe} {&&} {Crem} {dAn unrecognized command}",
    "{PC:\\repo>}{Etype} {Lselected.txt}{_▂}",
    "!0",
    --"{h.git\\}  {\\src\\}  file.txt  {hhidden.txt}  {rreadonly.txt}  {lselected.txt}",
    "{\\src\\}  file.txt  {rreadonly.txt}  {lselected.txt}",
}

local function get_from_ini_or_settings(name, ini)
    return ini and ini[name] or settings.get(name) or ""
end

local function get_settings_color(name, ini)
    local color = get_from_ini_or_settings(name, ini)
    if color == "" then
        if name == "color.argmatcher" then
            color = get_from_ini_or_settings("color.executable", ini)
        elseif name == "color.popup" then
            local t = clink.getpopuplistcolors()
            color = t.items
        elseif name == "color.popup_desc" then
            local t = clink.getpopuplistcolors()
            color = t.desc
        elseif name == "color.selected" then
            color = "0;1;7"
        elseif name == "color.selection" then
            color = get_from_ini_or_settings("color.input", ini)
            if color == "" then
                color = "0"
            end
            color = color..";7"
        elseif name == "color.suggestion" then
            color = "0;90"
        end
    end
    color = color or ""
    if color:byte(1) ~= 27 then
        color = "\x1b["..color.."m"
    end
    return color
end

local function get_demo_color(c, ini)
    local color
    local name = demo_colors[c]
    if name then
        if name == "cursor" then
            color = "0;1"
        elseif name == "dir" then
            color = rl.getmatchcolor("foo", name)
        elseif name == "hidden" or name == "readonly" then
            color = rl.getmatchcolor("foo", "file,"..name) or ""
        else
            color = get_settings_color(name, ini)
        end
    end
    color = color or ""
    if color:byte(1) ~= 27 then
        color = "\x1b["..color.."m"
    end
    return color
end

local function demo_print(s, base_color)
    local t = {}
    local i = 1
    local n = #s
    table.insert(t, base_color)
    while i <= n do
        local c = s:sub(i, i)
        if c == "{" then
            i = i + 1
            c = s:sub(i, i)
            table.insert(t, get_demo_color(c))
        elseif c == "}" then
            table.insert(t, base_color)
        else
            table.insert(t, c)
        end
        i = i + 1
    end
    table.insert(t, norm)
    clink.print("  "..table.concat(t))
end

local function show_demo(title)
    if title then
        clink.print(norm..bold..italic..underline..title..norm)
    end

    local base_color = norm
    for _,s in ipairs(demo_strings) do
        if s:sub(1, 1) == "!" then
            base_color = get_demo_color(s:sub(2, 2))
        else
            demo_print(s, base_color)
        end
    end
end

--------------------------------------------------------------------------------
local function list_color_themes(args)
    local fullnames
    local samples
    for i = 1, #args do
        local arg = args[i]
        if arg == "-f" or arg == "--full" then
            fullnames = true
        elseif arg == "-s" or arg == "--samples" then
            samples = true
        elseif not arg or arg == "" or arg == "--help" or arg == "-h" or arg == "-?" then
-- TODO: help text.
        end
    end

    local sample_colors =
    {
        {"color.input", "In"},
        {"color.selection", "Se"},
        {"color.argmatcher", "Am"},
        {"color.cmd", "Cm"},
        {"color.doskey", "Do"},
        {"color.arg", "Ar"},
        {"color.flag", "Fl"},
        {"color.arginfo", "Ai"},
        {"color.description", "De"},
        {"color.executable", "Ex"},
        {"color.unrecognized", "Un"},
        {"color.suggestion", "Su"},
    }

    local themes, indexed = clink.getthemes()
    if themes then
        local maxlen
        if samples then
            maxlen = 1
            for _,name in ipairs(themes) do
                if fullnames then
                    name = indexed[clink.lower(name)] or name
                end
                maxlen = math.max(maxlen, console.cellcount(name))
            end
        end

        for _,name in ipairs(themes) do
            if fullnames then
                name = indexed[clink.lower(name)] or name
            end

            local s = {}
            table.insert(s, name)
            if samples then
                local ini = clink.readtheme(indexed[clink.lower(name)])
                if ini then
                    local has = {}
                    for _,e in ipairs(ini) do
                        has[e.name] = true
                    end

                    table.insert(s, string.rep(" ", maxlen + 4 - console.cellcount(name)))
                    for _,e in ipairs(sample_colors) do
                        if has[e[1]] then
                            table.insert(s, get_settings_color(e[1], ini))
                            table.insert(s, e[2])
                            table.insert(s, norm)
                        else
                            table.insert(s, "  ")
                        end
                    end
                end
            end

            clink.print(table.concat(s))
        end
    end
end

--------------------------------------------------------------------------------
local function load_color_theme(args)
    local file
    if type(args) == "table" then
-- TODO: a flag to reset colors first.
-- TODO: and a flag to reset ALL colors?
-- TODO: help text.
        file = args[1]
    else
        file = args
    end
    args = nil -- luacheck: no unused

    if not file then
        printerror("No theme specified.")
        return
    end

    file = file:gsub('"', '')

    local fullname = clink.getthemes(file)
    if not fullname then
        printerror("Theme '"..file.."' not found.")
        return
    end
    file = fullname

-- TODO: Automatically save the current theme first, to some kind of
-- "Previous.clinktheme" file, in case the load was an accident.
    local ini, message = clink.applytheme(file)
    if message then
        printerror(message)
        message = nil
    end
    if not ini then
        return
    end
    return ini, message
end

--------------------------------------------------------------------------------
local function write_color_theme(o, all, rules)
    o:write("[set]\n")

    local list = settings.list()
    for _,entry in ipairs(list) do
        if entry.match:find("^color%.") then
            if all or not entry.source then
                o:write(string.format("%s=%s\n", entry.match, settings.get(entry.match, true) or ""))
            end
        elseif rules and entry.match == "match.coloring_rules" then
            o:write(string.format("%s=%s\n", entry.match, settings.get(entry.match) or ""))
        end
    end
end

local function save_color_theme(args)
    local file
    local yes
    local all
    local rules
    for i = 1, #args do
        local arg = args[i]
        if arg == "-y" or arg == "--yes" then
            yes = true
        elseif arg == "-a" or arg == "--all" then
            all = true
        elseif arg == "-r" or arg == "--rules" then
            rules = true
        elseif not arg or arg == "" or arg == "--help" or arg == "-h" or arg == "-?" then
-- TODO: help text.
        elseif not file then
            file = arg
        end
    end

    if not file then
        printerror("No output file specified.")
        return
    end

    file = file:gsub('"', '')

    local ext = path.getextension(file)
    if not ext or ext:lower() ~= ".clinktheme" then
        file = file..".clinktheme"
    end

-- TODO: What should be the default location if no path is given?  Maybe the profile directory?
-- TODO: There will need to be a CLINK_THEMES_DIR variable, similar to CLINK_COMPLETIONS_DIR.

    if os.isfile(file) and not yes then
        printerror("File '"..file.."' already exists.")
        printerror("Add '--yes' flag to overwrite the file.")
        return
    end

    local o = io.open(file, "w")
    if not o then
        printerror("Unable to open '"..file.."' for write.")
        return
    end

    write_color_theme(o, all, rules)

    o:close()
    return true
end

--------------------------------------------------------------------------------
local function show_color_theme(args)
-- TODO: help text.
    local name = args[1]
    local file
    if name then
        name = name:gsub('"', '')
        file = clink.getthemes(name)
        if not file then
            printerror("Theme '"..name.."' not found.")
            return
        end
    end

    if file then
        local ini, message = clink.readtheme(file)
        if not ini then
            if message then
                print(message)
            end
            return
        end

        show_demo("Current Theme")

        print()

        -- Must temporarily load the theme in order for rl.getmatchcolor() to
        -- represent colors properly.
        settings._overlay(ini, true--[[in_memory_only]])
        show_demo(path.getbasename(file) or name)

        -- Skip reloading for performance, since this is running in the
        -- standalone exe.
        --settings.load()
    else
        show_demo()
    end
end

--------------------------------------------------------------------------------
local function print_color_theme(args)
    local file
    local all
    local nosamples
    for i = 1, #args do
        local arg = args[i]
        if arg == "-a" or arg == "--all" then
            all = true
        elseif arg == "-n" or arg == "--no-samples" then
            nosamples = true
        elseif not arg or arg == "" or arg == "--help" or arg == "-h" or arg == "-?" then
-- TODO: help text.
        else
            file = arg
        end
    end

    local ini, message
    if file then
        file = file:gsub('"', '')
        ini, message = clink.readtheme(file)
        if not ini then
            if message then
                printerror(message)
            end
            return
        end
    else
        ini = {}
        for _,e in ipairs(settings.list()) do
            if e.match:find("^color%.") then
                if all or not e.source then
                    table.insert(ini, {name=e.match, value=settings.get(e.match, true, false)})
                end
            elseif e.match == "match.coloring_rules" then
                table.insert(ini, {name=e.match, value=settings.get(e.match)})
            end
        end
    end

    local anyset
    local anyclear
    local maxlen = 1
    for _,t in ipairs(ini) do
        maxlen = math.max(maxlen, console.cellcount(t.name))
        if t.value then
            anyset = true
        elseif not t.value then
            anyclear = true
        end
    end

    if anyset then
        print("[set]")
        for _, t in ipairs(ini) do
            if t.value then
                local s = {}
                table.insert(s, t.name)
                if not nosamples then
                    table.insert(s, string.rep(" ", maxlen + 4 - console.cellcount(t.name)))
                    if t.name:find("^color%.") then
                        local color = get_settings_color(t.name, ini)
                        table.insert(s, color)
                        table.insert(s, "Sample")
                        table.insert(s, norm)
                    else
                        table.insert(s, "      ")
                    end
                    table.insert(s, "  ")
                end
                table.insert(s, "=")
                if not nosamples then
                    table.insert(s, "  ")
                end
                table.insert(s, t.value)
                clink.print(table.concat(s))
            end
        end
    end

    if anyclear then
        print("[clear]")
        for _, t in ipairs(ini) do
            if not t.value then
                print(t.name)
            end
        end
    end

    if message then
        print()
        printerror(message)
    end
end

--------------------------------------------------------------------------------
local function do_theme_command(args)
    local command = args[1]
    table.remove(args, 1)

    if command == "list" then
        list_color_themes(args)
    elseif command == "load" then
        load_color_theme(args)
    elseif command == "save" then
        save_color_theme(args)
    elseif command == "show" then
        show_color_theme(args)
    elseif command == "print" then
        print_color_theme(args)
    elseif command == "reset" then
        print("RESET COLORS IS NYI")
        -- TODO: This will require a Lua API -- but I think it already exists?
        -- TODO: Reset only built-in colors by default.
        -- TODO: Reset all color.* settings when --all is given.
        -- TODO: Reset match.coloring_rules when --rules is given.
        -- TODO: How to reset colors that aren't loaded yet?
        -- TODO: This is probably better as a flag to "load".
        -- Maybe `settings.clearcolors()`?
        --  1.  For effiency.  Otherwise each individual clear will
        --      read + write the entire settings file.
        --  2.  This is tricky because it requires directly reading the
        --      clink_settings file and removing "color." entries even
        --      if a corresponding setting hasn't been added yet.
        --      REVIEW:  The [clear] section of settings._overlay() should
        --      already handle that, if it can be told the settings that
        --      haven't been loaded yet.
    elseif not command or command == "" or command == "--help" or command == "-h" or command == "-?" then
        print("Usage:  clink config theme [command]")
        print()
        print("Commands:")
        print("  list              List color themes.")
        print("  load <theme>      Load a color theme.")
        print("  save <theme>      Save the current color theme.")
        print("  show [<theme>]    Show what the theme looks like.")
        print("  print [<theme>]   Print a color theme.")
    else
        printerror("Unrecognized 'clink config theme "..command.."' command.")
    end
end

--------------------------------------------------------------------------------
-- luacheck: globals config_loader
config_loader = config_loader or {}
function config_loader.do_config(args)
    local command = args[1]
    table.remove(args, 1)

    if command == "theme" then
        return do_theme_command(args)
    elseif not command or command == "" or command == "--help" or command == "-h" or command == "-?" then
        print("Usage:  clink config [command]")
        print()
        print("Commands:")
        print("  theme             Configure the color theme for Clink.")
    else
        printerror("Unrecognized 'clink config "..command.."' command.")
    end
end