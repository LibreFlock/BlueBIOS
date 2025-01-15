::sof::

local blue = blue ---@diagnostic disable-line: undefined-global
local trigger1, trigger2

local component = component or require("component") ---@diagnostic disable-line: undefined-global
local computer = computer or require("computer") ---@diagnostic disable-line: undefined-global

-- known issues:
-- shell on no drive
-- screen tear on tier 1 gpus in lua shell

local gpu = component.proxy(component.list("gpu")())
local res_x, res_y = gpu.getResolution()

function blue.fn.shell()
    local function centrize(message)
        gpu.fill(1, 1, res_x, res_y, " ")
        return gpu.set(math.ceil(res_x/2-#message/2), math.ceil(res_y/2),  message)
    end

    _G.buffer = {}

    function _G.print(text)
        for _ in string.gmatch(tostring(text), "[^\r\n]+") do
            if #tostring(text) > res_x then
                for i=1,math.ceil(#tostring(text)/res_x) do
                    buffer[#buffer+1] = string.sub(tostring(text), (i == 1 and 1) or res_x*(i-1), res_x*i-1)
                end
            else
                buffer[#buffer+1] = tostring(text)
            end
        end
    end

    function _G.help()
        print("exit Exits the shell")
        print("help() Access list of predefined functions")
        print("clear() Clears the current screen buffer")
        print("print(text: str) Print a string")
        print("To modify the buffer, the buffer dictionary exists.")
        print("Typically to add a new value in the shell's buffer, you need to modify buffer[#buffer+1].")
        print("The print function supports wrap around text.")
        print("Blue's predefined dictionary")
        print("'blue' is the global dictionary for blue's functions and variables.")
        print("Variables: 'blue.vb.init', 'blue.vb.boot_label', 'blue.vb.boot_drive'")
        print("Functions: 'blue.fn.shell'")
    end

    function _G.clear()
        _G.buffer = nil
    end

    buffer[1] = "You are currently in a recovery shell in BIOS."
    buffer[2] = "Enter 'help()' for a list of functions." .. res_y
    buffer[#buffer+1] = "bootloader> "
    local shift = false
    local caps_lock = false
    local command = ""
    local command_entered = true
    local lgpu = false

    centrize("")

    ::render::

    if type(buffer) ~= "table" then
        _G.buffer = {}
        buffer[1] = "bootloader> "
    end

    if gpu.getDepth() < 1 then
        lgpu = true
    end

    for i=1,res_y do
        if buffer[#buffer-i+1] then
            if i == 1 and gpu.getDepth() > 1 then
                if command_entered then
                    centrize("")
                end
                local f_buffer = buffer[#buffer-i+1]
                if not lgpu then
                    gpu.fill(#f_buffer+1, res_y, res_y-#f_buffer-1, 1, " ")
                    gpu.setForeground(0xaec5d4)
                    gpu.set(1, res_y, f_buffer)
                    gpu.setForeground(0x9cc3db)
                    gpu.setBackground(0xaec5d4)
                    gpu.set(#f_buffer+1, res_y, " ")
                    gpu.setBackground(0x003150)
                else
                    gpu.setBackground(0x000000)
                    gpu.setForeground(0xFFFFFF)
                    gpu.fill(#f_buffer+1, res_y, res_y-#f_buffer-1, 1, " ")
                    gpu.set(#f_buffer+1, res_y, " ")
                    gpu.setBackground(0xFFFFFF)
                    gpu.set(1, res_y, f_buffer)
                    gpu.setBackground(0x000000)
                end
            elseif command_entered then
                gpu.set(1, res_y-i+1, buffer[#buffer-i+1])
            end
        end
    end

    if command_entered then
        command_entered = false
    end

    local event, _, char, code = computer.pullSignal()
    if not char then
        if event == "key_down" then
            if code == 42 or code == 54 then
                shift = true
            elseif code == 58 then
                caps_lock = not caps_lock
            end
        elseif event == "key_up" then
            if code == 42 or code == 54 then
                shift = false
            end
        end
    else
        if event == "key_down" then
            if code == 28 then
                if command == "exit" then
                    return
                elseif command == "reboot" then
                    computer.shutdown(1)
                elseif command == "shutdown" then
                    computer.shutdown()
                end
                result, reason = pcall(load(command))
                command_entered = true
                if reason then
                    local wraparound = false
                    for _ in string.gmatch(reason, "[^\r\n]+") do
                        if #reason > res_x then
                            wraparound = true
                            for i=1,math.ceil(#reason/res_x) do
                                buffer[#buffer+1] = string.sub(reason, (i == 1 and 1) or res_x * (i-1), res_x*i)
                            end
                        else
                            buffer[#buffer+1] = reason
                        end
                    end
                    if wraparound then
                        centrize("")
                    end
                end
                if type(buffer) ~= "table" then
                    _G.buffer = {}
                end
                buffer[#buffer+1] = "bootloader> "
                command = ""
                goto render
            elseif code == 14 then
                if #buffer[#buffer] > 12 then
                    command = string.sub(command, 1, #command-1)
                    buffer[#buffer] = string.sub(buffer[#buffer], 1, #buffer[#buffer]-1)
                end
                goto render
            elseif (char < 127 and char > 31) then
                local letter = string.char(char)
                if shift or caps_lock then
                    letter = string.upper(letter)
                end
                buffer[#buffer] = buffer[#buffer] .. letter
                command = command .. letter
            end
        elseif event == "clipboard" then
            buffer[#buffer] = buffer[#buffer] .. char
            command = command .. char
        end
    end

    goto render
end

local shift = false
local caps_lock = false

local function invert(boolean)
    if boolean then
        if gpu.getDepth() > 1 then
            gpu.setBackground(0x9cc3db)
            gpu.setForeground(0x003150)
        else
            gpu.setBackground(0xFFFFFF)
            gpu.setForeground(0x000000)
        end
    else
        if gpu.getDepth() > 1 then
            gpu.setBackground(0x003150)
            gpu.setForeground(0x9cc3db)
        else
            gpu.setBackground(0x000000)
            gpu.setForeground(0xFFFFFF)
        end
    end
end

invert(false)

local row_1 = { y = math.ceil(res_y/2) - 2, button_offset = 4, button_height = 1, opts = {}, optcount = 0 }
if gpu.getDepth() > 1 then
    _G.row_2 = { y = math.ceil(res_y/2) + 2, button_offset = 2, button_height = 0, opts = { "Power off", computer.getArchitecture(), "Internet boot", "Rename", "Format" }, optcount = 5 }
else
    _G.row_2 = { y = math.ceil(res_y/2) + 2, button_offset = 2, button_height = 0, opts = { "Halt", "Shell", "Netboot", "Rename", "Format" }, optcount = 5 }
end

local fdrive = component.list("filesystem")()
local boot_opts = {}
local selected_drive

row_1.opts = {}
if component.list("filesystem")() then
    for i in pairs(component.list("filesystem")) do
        local label = component.invoke(i, "getLabel")
        if label == "tmpfs" then
            goto continue
        end
        label = (label ~= nil and label) or string.sub(i, 1, 5)
        boot_opts[i] = 0
        for _, j in ipairs(component.invoke(i, "list", "/")) do
            if j == "init.lua" then
                boot_opts[i] = boot_opts[i] + 1
            elseif j == "OS.lua" then
                boot_opts[i] = boot_opts[i] + 2
            end
        end
        if not selected_drive then
            selected_drive = label
        end
        row_1.opts[i] = label
        row_1.optcount = row_1.optcount + 1
        ::continue::
    end
else
    blue.fn.shell()
    computer.shutdown(1)
end

local selected_row = row_1
local selected_button = 1

::render::

if component.list("filesystem")() ~= fdrive then
    goto sof
end

gpu.fill(1, 1, res_x, res_y, " ")

if selected_button < 1 then
    selected_button = selected_row.optcount
elseif selected_button > selected_row.optcount then
    selected_button = 1
end

local button_count = 0

local function render_row(row)
    local render_string = ""
    local opt_renders = {}
    local opt_render
    for _, j in pairs(row.opts) do
        button_count = button_count + 1
        opt_render = string.rep(" ", row.button_offset) .. j .. string.rep(" ", row.button_offset)
        opt_renders[#opt_renders+1] = opt_render
        render_string = render_string .. opt_render
    end
    button_count = 0
    return render_string, opt_renders
end

local row_1_string, row_1_opts = render_row(row_1)
local row_2_string, row_2_opts = render_row(row_2)

if selected_row == row_1 then
    local count = 0
    for i, j in pairs(row_1.opts) do
        count = count + 1
        local test_1 = (j == string.match(row_1_opts[selected_button], "^%s*(.-)%s*$"))
        local test_2 = count == selected_button
        if test_1 and test_2 then
            selected_drive = i
            break
        end
    end
end

gpu.set(math.ceil(res_x/2)-math.ceil(#row_1_string/2), row_1.y, row_1_string)
gpu.set(math.ceil(res_x/2)-math.ceil(#row_2_string/2), row_2.y, row_2_string)

if gpu.getDepth() > 1 then
    gpu.set(math.ceil(res_x/2)-math.ceil(75/2), res_y, "Use ← ↑ → ↓ to move cursor; Enter to confirm option; CTRL+ALT+C to shutdown")
else
    gpu.set(math.ceil(res_x/2)-math.ceil(26/2), res_y, "Use ← ↑ → ↓ to move cursor")
end

if selected_row == row_1 then
    _G.button_string = row_1_opts[selected_button] or row_1_opts[#row_1_opts]
    _G.full_string = row_1_string
    _G.determined_x = math.ceil(res_x/2)-math.ceil(#row_1_string/2)
    _G.determined_y = row_1.y
    _G.row_opts = row_1_opts
else
    _G.button_string = row_2_opts[selected_button] or row_2_opts[#row_2_opts]
    _G.full_string = row_2_string
    _G.determined_x = math.ceil(res_x/2)-math.ceil(#row_2_string/2)
    _G.determined_y = row_2.y
    _G.row_opts = row_2_opts
end

local pos1 = 0

for i, j in ipairs(row_opts) do
    if j == button_string and i == selected_button then
        pos1 = pos1 + 1
        break
    else
        pos1 = pos1 + #j
    end
end

invert(true)
gpu.set(determined_x+pos1-1, determined_y, button_string)
if selected_row.button_height > 0 then
    for i=1,selected_row.button_height do
        local text = string.rep(" ", #button_string)
        gpu.set(determined_x+pos1-1, determined_y-i, text)
        gpu.set(determined_x+pos1-1, determined_y+i, text)
    end
end
invert(false)

repeat
    local event, _, _, code = computer.pullSignal()
    if event == "key_down" then
        if code == 200 then
            selected_row = row_1
        elseif code == 208 then
            selected_row = row_2
        elseif code == 203 then
            selected_button = selected_button - 1
        elseif code == 205 then
            selected_button = selected_button + 1
        elseif code == 42 or code == 54 then
            shift = true
        elseif code == 58 then
            caps_lock = not caps_lock
        elseif code == 29 or code == 157 then
            trigger1 = true
        elseif code == 56 or code == 184 then
            trigger2 = true
        elseif code == 46 then
            if trigger1 and trigger2 then
                computer.shutdown()
            end
        elseif code == 28 then
            if selected_row == row_1 then
                local exists = pcall(component.invoke, selected_drive, "getLabel")
                if not exists then
                    goto sof
                end
                local text = "Booting..."
                gpu.setForeground(0xcccccc)
                gpu.fill(1, math.ceil(res_y/2)+5, res_x, 1, " ")
                gpu.set(math.ceil(res_x/2)-math.ceil(#text/2), math.ceil(res_y/2)+5, text)
                if blue.vb.boot_drive == selected_drive then
                    invert(false)
                    break
                end
                local drive = component.proxy(selected_drive)
                local label = drive.getLabel()
                local function initialize_file(file)
                    local handle = drive.open(file)
                    if handle then
                        local data = ""
                        ::parse::
                        local chunk = drive.read(handle, math.huge)
                        if chunk then
                            data = data .. chunk
                            goto parse
                        end
                        drive.close(handle)
                        return data
                    end
                end
                if not label then
                    label = "N/A"
                end
                local boot = false
                if boot_opts[selected_drive] == 1 then
                    blue.vb.init = initialize_file("/init.lua")
                    boot = true
                elseif boot_opts[selected_drive] > 1 then
                    blue.vb.init = initialize_file("/OS.lua")
                    boot = true
                elseif boot_opts[selected_drive] == 0 then
                    text = "Unable to boot; missing boot files"
                    gpu.fill(1, math.ceil(res_y/2)+5, res_x, 1, " ")
                    gpu.set(math.ceil(res_x/2)-math.ceil(#text/2), math.ceil(res_y/2)+5, text)
                    invert(false)
                    boot = false
                    computer.pullSignal()computer.pullSignal()
                end
                if boot then
                    blue.vb.boot_label = label
                    blue.vb.boot_drive = selected_drive
                    computer.setBootAddress(selected_drive)
                    invert(false)
                    break
                end
            else
                if selected_button == 1 then
                    computer.shutdown()
                elseif selected_button == 2 then
                    blue.fn.shell()
                elseif selected_button == 3 then
                    gpu.setForeground(0xcccccc)
                    if component.list("internet")() then
                        local internet = component.proxy(component.list("internet")())
                        local text = "URL: "
                        gpu.fill(1, math.ceil(res_y/2)+5, res_x, 1, " ")
                        repeat
                            gpu.set(math.ceil(res_x/2)-math.ceil(#text/2), math.ceil(res_y/2)+5, text)
                            local event, _, char, code = computer.pullSignal()
                            if event == "key_down" then
                                if code == 42 or code == 54 then
                                    shift = true
                                elseif code == 58 then
                                    caps_lock = not caps_lock
                                elseif code == 14 then
                                    if #text > 5 then
                                        text = string.sub(text, 1, #text-1)
                                        gpu.fill(1, math.ceil(res_y/2)+5, res_x, 1, " ")
                                    end
                                elseif (char > 31 and char < 127) then
                                    if shift or caps_lock then
                                        text = text .. string.upper(string.char(char))
                                    else
                                        text = text .. string.char(char)
                                    end
                                elseif code == 28 then
                                    gpu.fill(1, math.ceil(res_y/2)+5, res_x, 1, " ")
                                    gpu.set(math.ceil(res_x/2)-7, math.ceil(res_y/2)+5, "Downloading...")
                                    local request = internet.request(string.sub(text, 6, #text))
                                    if request then
                                        local data = ""
                                        ::parserequest::
                                        local chunk = request.read()
                                        if chunk then
                                            data = data .. chunk
                                            goto parserequest
                                        end
                                        if data and data ~= "" then
                                            local state, reason = pcall(function() return load(data)() end)
                                            if state then
                                                goto sof
                                            else
                                                gpu.fill(1, math.ceil(res_y/2)+5, res_x, 1, " ")
                                                gpu.set(math.ceil(res_x/2)-math.ceil(#reason/2), math.ceil(res_y/2)+5, reason)
                                                computer.pullSignal()computer.pullSignal()
                                                break
                                            end
                                        else
                                            gpu.fill(1, math.ceil(res_y/2)+5, res_x, 1, " ")
                                            text = "An error occured."
                                            gpu.set(math.ceil(res_x/2)-math.ceil(#text/2), math.ceil(res_y/2)+5, text)
                                        end
                                    else
                                        gpu.fill(1, math.ceil(res_y/2)+5, res_x, 1, " ")
                                        text = "An error occured."
                                        gpu.set(math.ceil(res_x/2)-math.ceil(#text/2), math.ceil(res_y/2)+5, text)
                                        computer.pullSignal()computer.pullSignal()
                                        break
                                    end
                                end
                            elseif event == "key_up" then
                                if code == 42 or code == 54 then
                                    shift = false
                                end
                            elseif event == "clipboard" then
                                text = text .. char
                            end
                        until false
                        invert(false)
                    else
                        gpu.fill(1, math.ceil(res_y/2)+5, res_x, 1, " ")
                        local text = "This feature requires an internet card to run."
                        gpu.set(math.ceil(res_x/2)-math.ceil(#text/2), math.ceil(res_y/2)+5, text)
                        computer.pullSignal()computer.pullSignal()
                    end
                    invert(false)
                elseif selected_button == 4 then
                    local text = "New label: "
                    gpu.fill(1, math.ceil(res_y/2)+5, res_x, 1, " ")
                    repeat
                        gpu.setForeground(0xcccccc)
                        gpu.set(math.ceil(res_x/2)-math.ceil(#text/2), math.ceil(res_y/2)+5, text)
                        local event, _, char, code = computer.pullSignal()
                        if event == "key_down" then
                            if code == 42 or code == 54 then
                                shift = true
                            elseif code == 58 then
                                caps_lock = not caps_lock
                            elseif code == 14 then
                                if #text > 11 then
                                    text = string.sub(text, 1, #text-1)
                                    gpu.fill(1, math.ceil(res_y/2)+5, res_x, 1, " ")
                                end
                            elseif (char > 31 and char < 127) then
                                if shift or caps_lock then
                                    text = text .. string.upper(string.char(char))
                                else
                                    text = text .. string.char(char)
                                end
                            elseif code == 28 then
                                local label = string.sub(text, 12, #text)
                                local result, reason
                                if label == "" then
                                    result, reason = pcall(component.invoke, selected_drive, "setLabel", nil)
                                else
                                    result, reason = pcall(component.invoke, selected_drive, "setLabel", label)
                                end
                                if not result then
                                    gpu.fill(1, math.ceil(res_y/2)+5, res_x, 1, " ")
                                    text = "An error has occured: " .. reason
                                    gpu.set(math.ceil(res_x/2)-math.ceil(#text/2), math.ceil(res_y/2)+5, text)
                                    computer.pullSignal()computer.pullSignal()
                                    invert(false)
                                    break
                                else
                                    invert(false)
                                    break
                                end
                            end
                        elseif event == "key_up" then
                            if code == 42 or code == 54 then
                                shift = false
                            end
                        elseif event == "clipboard" then
                            text = text .. char
                        end
                    until false
                    goto sof
                elseif selected_button == 5 then
                    gpu.fill(1, math.ceil(res_y/2)+5, res_x, 1, " ")
                    gpu.setForeground(0xcccccc)
                    local label = component.invoke(selected_drive, "getLabel")
                    local text = "Format " .. (label ~= nil and label or "N/A") .. " (" .. selected_drive .. ")? (Y/N)"
                    gpu.set(math.ceil(res_x/2)-math.ceil(#text/2), math.ceil(res_y/2)+5, text)
                    repeat
                        local event, _, char = computer.pullSignal()
                        if event == "key_down" then
                            if string.char(char) == "y" then
                                gpu.fill(1, math.ceil(res_y/2)+5, res_x, 1, " ")
                                text = "Formatting..."
                                local remove_time = computer.uptime()
                                gpu.set(math.ceil(res_x/2)-math.ceil(#text/2), math.ceil(res_y/2)+5, text)
                                local fs = component.proxy(selected_drive)
                                local function format(path)
                                    for _, i in ipairs(fs.list(path ~= nil and path or "/")) do
                                        if string.match(i, "/$") ~= nil then
                                            format("/" .. (path ~= nil and path or "") .. i)
                                        else
                                            fs.remove("/" .. (path ~= nil and path or "") .. i)
                                        end
                                    end
                                end
                                fs.setLabel(nil)
                                format()
                                if remove_time == computer.uptime() then
                                    text = "Formatted in less than a second"
                                else
                                    text = "Formatted in " .. computer.uptime()-remove_time .. " seconds"
                                end
                                gpu.set(math.ceil(res_x/2)-math.ceil(#text/2), math.ceil(res_y/2)+5, text)
                                computer.pullSignal()computer.pullSignal()
                                break
                            else
                                break
                            end
                        end
                    until false
                    goto sof
                end
            end
        end
    elseif event == "key_up" then
        if code == 42 or code == 54 then
            shift = false
        elseif code == 29 or code == 157 then
            trigger1 = false
        elseif code == 56 or code == 184 then
            trigger2 = false
        end
    end
    goto render
until false
