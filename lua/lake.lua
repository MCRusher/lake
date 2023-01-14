require "lfs" --optional, but needed for incremental builds
require "jit" --optional, improves results of guessOS

lake = {steps = {}}

lake.version = "1.1" --generally you could just check if a function is nil before using it though

--guess OS by checking for system environment variables
--can optionally specify a guess to check against
function lake.guessOS(guess)
    local answer
    if jit then
        answer = jit.os --leverage luajit's builtin os flag instead of making a wild guess
    elseif os.getenv("WINDIR") ~= nil then
        answer = "Windows"
    elseif os.getenv("HOME") ~= nil then
        answer = "Linux"
    else
        answer = "Other"
    end
    
    if guess == nil then
        return answer
    else
        return answer == guess
    end
end

function lake.nativeBinaryName(name)
    return name .. (lake.guessOS("Windows") and ".exe" or "")
end

function lake.nativeDLLName(name)
    return name .. (lake.guessOS("Windows") and ".dll" or ".so")
end

--adds flags to global state, sets first step if first arg is not a flag
function lake.parseArgs(...)
    local args = {...}
    if args[1] == "--help" then
        print("Lake version " .. lake.version .. [[

Usage: lake [-f:<filename>] [<step-name>] [<VAR>=<value> ...]
Options:
 (-f:<lakefile>) specify the name of the buildscript, defaults to "make.lua" if unspecified
 (<step-name>) specify the main step to be performed, defaults to the first step, will always be executed even if up-to-date
 (<VAR>=<value>) set/override variables of the buildscript, ex: CC=clang
]])
        os.exit()
    end
    local file = "make.lua" --default name
    for f in string.gmatch(args[1] or "", "^-f:(.+)") do
        file = f
        table.remove(args, 1)
    end
    if not string.find(args[1] or "","=") then
        lake.firstStep = args[1]
        table.remove(args, 1)
    end
    for _,str in ipairs(args) do
        --should only ever be one, but this allows non-matches to be ignored
        for key, val in str:gmatch("(.+)=(.+)") do
            _G[key] = val
            break --don't handle any malformed args
        end
    end
    return file
end

function lake.rm(...)
    for _,file_or_dir in ipairs({...}) do
        if lake.exists(file_or_dir) then
            if lfs and lfs.attributes(file_or_dir,"mode") == "directory" then
                --lfs.rmdir refuses to remove hidden directories
                if lake.guessOS("Windows") then
                    lake.execute("rmdir /s /q \"{}\"", file_or_dir)
                else
                    lake.execute("rm -rf \"{}\"", file_or_dir)
                end
            else
                lake.printf("os.remove \"{}\"", file_or_dir)
                print(os.remove(file_or_dir))
            end
        end
    end
end

function lake.step(name, prereqs, step)
    if lake.firstStep == nil then
        lake.firstStep = name
    end
    lake.steps[name] = {
        prereqs = prereqs,
        step = step
    }
end

function lake.phonyStep(name, prereqs, step)
    if lake.firstStep == nil then
        lake.firstStep = name
    end
    lake.steps[name] = {
        prereqs = prereqs,
        step = step,
        phony = true
    }
end

--top level step always performed, prereqs performed if their prereqs or any of their prereqs' prereqs have a newer time than them
function lake.doStep(name)
    name = name or lake.firstStep
    if name == nil then error("No steps exist") end
    if lake.steps[name] == nil then error("Step '" .. name .. "' does not exist") end
    local stepinfo = lake.steps[name]
    --perform all prerequisite steps first
    for _,step_name in ipairs(stepinfo.prereqs) do
        --not an error for a prereq, indicates a source dependency (like a .c file, etc.)
        if lake.steps[step_name] ~= nil then
            if lake.steps[step_name].phony --phony prereqs are always performed
            or not lake.exists(step_name) --non-phony ungenerated prereqs must built
            or lake.prereqsChangedAfter(step_name) then --prereqs at any level under a step being newer than an upper level need rebuilt
                lake.doStep(step_name)
            else
                print("step output '" .. step_name .. "' exists with older prereq timestamps, skipping step")
            end
        end
    end
    if type(stepinfo.step) == "string" then
        lake.execute(stepinfo.step)
    elseif type(stepinfo.step) == "function" then
        stepinfo.step(name, stepinfo.prereqs)
    elseif stepinfo.phony and stepinfo.step == nil then
        --do nothing
    else error("step must either be a function or an executable string") end
    if (not stepinfo.phony) and (lfs.attributes(name) == nil) then
        error("Step failed, output '" .. name .. "' does not exist")
    end
end

function lake.prereqsChangedAfter(step_name)
    if not lfs then return true end --can't use LFS to check for timestamps so just assume changed (no incremental)
    for _,prereq_name in pairs(lake.steps[step_name].prereqs) do
        if lfs.attributes(prereq_name,"modification") > lfs.attributes(step_name,"modification") then
            return true
        elseif lake.steps[prereq_name] ~= nil then
            if lake.prereqsChangedAfter(prereq_name) then
                return true
            end
        end
    end
    return false
end

--multi-mode, rust-style formatted string function
function lake.format(str, ...)
    local args = {...}
    --mode 1: indexed position, multiple use of each
    if not str:find("{}") then
        local function fmt(cap)
            return args[tonumber(cap)]
        end
        --parens discard second value from gsub
        return (str:gsub("{(%d+)}", fmt))
    --mode 2: same position, single use of each
    else
        local counter = 0
        local function fmt()
            counter = counter + 1
            return args[counter]
        end
        return (str:gsub("{}", fmt))
    end
end

function lake.execute(str, ...)
    local cmd = lake.format(str, ...)
    print(cmd)
    return os.execute(cmd)
end

function lake.exists(file)
    if lfs then --With LFS, should be more reliable than opening the file
        return lfs.attributes(file) ~= nil
    end
    local handle = io.open(file)
    if not handle then
        return false
    else
        io.close(handle)
        return true
    end
end

function lake.input(prompt)
    io.write(prompt)
    return io.read()
end

function lake.inputValidFile(prompt)
    while true do 
        local path = lake.input(prompt)
        if lfs.attributes(path, "mode") == "file" then
            return path
        else
            print("invalid path given, try again")
        end
    end
end

function lake.inputValidDir(prompt)
    while true do 
        local path = lake.input(prompt)
        if lfs.attributes(path, "mode") == "directory" then
            return path
        else
            print("invalid path given, try again")
        end
    end
end

function lake.sprint(...)
    local str = ""
    for _,val in {...} do
        str = str .. " " .. val
    end
    return str
end

function lake.printf(str, ...)
    print(lake.format(str, ...))
end

function lake.shortNames()
    for name,val in pairs(lake) do
        _G[name] = val
    end
end

function lake.copyFile(src, dest)
    lake.printf("lake.copy \"{}\" => \"{}\"", src, dest)
    local infile = assert(io.open(src, "rb"))
    local outfile = assert(io.open(dest, "wb"))
    local data = assert(infile:read("*a"))
    infile:close()
    assert(outfile:write(data))
    outfile:close()
end

function lake.copy(srcs, dests)
    assert(#srcs == #dests)
    for i = 1, #srcs do
        lake.copyFile(srcs[i], dests[i])
    end
end

function lake.path(base, ...)
    local p = base
    for _,part in ipairs({...}) do
        if p:sub(#p) ~= "/" then
            p = p .. "/"
        end
        if part:sub(1,1) == "/" then
            part = part:sub(2)
        end
        p = p .. part
    end
    return p
end

function lake.copyTo(src_dir, dest_dir, ...)
    local files = {...}
    
    local srcs = {}
    local dests = {}
    for i = 1, #files do
        table.insert(srcs, lake.path(src_dir, files[i]))
        table.insert(dests, lake.path(dest_dir, files[i]))
    end
    lake.copy(srcs, dests)
end

function lake.mkdir(path)
    if lfs then
        print("lfs.mkdir \"" .. path .. "\"")
        lfs.mkdir(path)
    else
        lake.execute("mkdir \"{}\"", path)
    end
end

--includes rpath only if not on windows (rpath doesn't work on Windows)
function lake.rpath(path)
    return lake.guessOS("Windows") and "" or "-Wl,-R\"" .. path .. "\""
end

function lake.split(str, sep)
    local sep = sep or " "
    local t = {}
    for s in str:gmatch("([^ ]+)") do
        table.insert(t, s)
    end
    return t
end

function lake.bake(cmd, ...)
    local baked = lake.format(cmd, ...):gsub("{.}", "{}")
    return function(...)
        return lake.format(baked, ...)
    end
end

lake.cat = table.concat

return lake
