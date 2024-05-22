local passes, fails, undefined = 0, 0, 0
local running = 0

local function getGlobal(path)
	local value = getfenv(0)

	while value ~= nil and path ~= "" do
		local name, nextValue = string.match(path, "^([^.]+)%.?(.*)$")
		value = value[name]
		path = nextValue
	end

	return value
end

local function test(name, aliases, callback)
    if rconsoleinfo then
        rconsoleinfo(name) -- debug which function thats going to get tested
    end
	running += 1

	task.spawn(function()
		if not callback then
			print(`⏺️ {name}`)
		elseif not getGlobal(name) then
			fails += 1
			warn(`⛔ {name}`)
		else
			local success, message = pcall(callback)
	
			if success then
				passes += 1
				print(`✅ {name}{message and ` • {message}` or ""}`)
			else
				fails += 1
				warn(`⛔ {name} failed: {message}`)
			end
		end
	
		local undefinedAliases = {}
	
		for _, alias in next, aliases do
			if getGlobal(alias) == nil then
                undefinedAliases[#undefinedAliases + 1] = alias
			end
		end
	
		if #undefinedAliases > 0 then
			undefined += 1
			warn(`⚠️ {table.concat(undefinedAliases, ", ")}`)
		end

		running -= 1
	end)
end

-- Header and summary

print("\n")

print("UNS Environment Check")
print("✅ - Pass, ⛔ - Fail, ⏺️ - No test, ⚠️ - Missing aliases\n")

task.defer(function()
	repeat task.wait() until running == 0

    local total = passes + fails
	warn(passes / total)
	local rate = math.round(passes / total * 10000) / 100
	local outOf = `{passes} out of {total}`

	print("\n")

	print("UNS Summary")
	print(`✅ Tested with a {rate}% success rate ({outOf})`)
	print(`⛔ {fails} tests failed`)
	print(`⚠️ {undefined} globals are missing aliases`)
end)

-- Cache

test("cache.invalidate", {}, function()
	local container = Instance.new("Folder")
	local part = Instance.new("Part", container)
	cache.invalidate(container:FindFirstChild("Part"))
	assert(part ~= container:FindFirstChild("Part"), "Reference `part` could not be invalidated")
end)

test("cache.iscached", {}, function()
	local part = Instance.new("Part")
	assert(cache.iscached(part), "Part should be cached")
	cache.invalidate(part)
	assert(not cache.iscached(part), "Part shouldn't be cached")
end)

test("cache.replace", {}, function()
	local part = Instance.new("Part")
	local fire = Instance.new("Fire")
	cache.replace(part, fire)
	assert(part ~= fire, "Part was not replaced with Fire")
end)

test("clonereference", {"cloneref"}, function()
	local part = Instance.new("Part")
	local clone = clonereference(part)
	assert(part ~= clone, "Clone shouldn't be equal to original")
	clone.Name = "Test"
	assert(part.Name == "Test", "Clone should have updated the original")
end)

test("compareinstances", {}, function()
	local part = Instance.new("Part")
	local clone = clonereference(part)
	assert(part ~= clone, "Clone shouldn't be equal to original")
	assert(compareinstances(part, clone), "Clone should be equal to original when using compareinstances()")
end)

-- Closures

local function shallowEqual(t1, t2)
	if t1 == t2 then
		return true
	end

	local UNIQUE_TYPES = {
		["function"] = true,
		["table"] = true,
		["userdata"] = true,
		["thread"] = true,
	}

	for k, v in next, t1 do
		if UNIQUE_TYPES[type(v)] then
			if type(t2[k]) ~= type(v) then
				return false
			end
		elseif t2[k] ~= v then
			return false
		end
	end

	for k, v in next, t2 do
		if UNIQUE_TYPES[type(v)] then
			if type(t2[k]) ~= type(v) then
				return false
			end
		elseif t1[k] ~= v then
			return false
		end
	end

	return true
end

test("checkcaller", {}, function()
	assert(checkcaller(), "Main scope should return true")
end)

test("clonefunction", {"clonefunc"}, function()
	local function test()
		return "success"
	end
	local copy = clonefunction(test)
	assert(test() == copy(), "The clone should return the same value as the original")
	assert(test ~= copy, "The clone shouldn't be equal to the original")
end)

test("getcallingscript", {})

test("getscriptclosure", {"getscriptfunction"}, function()
	local module = game:GetService("CoreGui").RobloxGui.Modules.Common.Constants
	local constants = getrenv().require(module)
	local generated = getscriptclosure(module)()
	assert(constants ~= generated, "Generated module shouldn't match the original")
	assert(shallowEqual(constants, generated), "Generated constant table should be shallow equal to the original")
end)

test("hookfunction", {"replaceclosure"}, function()
	local function test()
		return true
	end
	local ref = hookfunction(test, function()
		return false
	end)
	assert(test() == false, "Function should return false")
	assert(ref() == true, "Original function should return true")
	assert(test ~= ref, "Original function shouldn't be same as the reference")
end)

test("isfunctionhooked", {},  function()
	local function test()
		return true
	end
	local ref = hookfunction(test, function()
		return false
	end)
	assert(test() == false, "Function should return false")
	assert(ref() == true, "Original function should return true")
    assert(test ~= ref, "Original function shouldn't be same as the reference")
    assert(isfunctionhooked(test), "Function should be marked as hooked")
end)

test("restorefunction", {},  function()
	local function test()
		return true
	end
	local ref = hookfunction(test, function()
		return false
	end)
	assert(test() == false, "Function should return false")
	assert(ref() == true, "Original function should return true")
    assert(test ~= ref, "Original function shouldn't be same as the reference")
    assert(isfunctionhooked(test), "Function should be marked as hooked")
    restorefunction(test)
	assert(test() ~= false, "Function should return false")
	assert(ref() ~= true, "Original function should return true")
    assert(not isfunctionhooked(test), "Function shouldn't be marked as hooked anymore")
end)

test("hooksignal", {"replacecon"}, function()
    local part, changedPropNewName = Instance.new("Part")
    part.Changed:Connect(function(prop)
        changedPropNewName = prop
    end)
    hooksignal(part.Changed, function(info, prop)
        return true, "Hooked"
    end)
    part.Name = "NewName"    
	assert(changedPropNewName == "Hooked", "Signal should be hook")
end)

test("issignalhooked", {}, function()
    local part, changedPropNewName = Instance.new("Part")
    part.Changed:Connect(function(prop)
        changedPropNewName = prop
    end)
    hooksignal(part.Changed, function(info, prop)
        return true, "Hooked"
    end)
    part.Name = "NewName"    
	assert(changedPropNewName == "Hooked", "Signal should be hook")
    assert(issignalhooked(part.Changed), "Signal should be marked as hooked")
end)

test("restoresignal", {}, function()
    local part, changedPropNewName = Instance.new("Part")
    part.Changed:Connect(function(prop)
        changedPropNewName = prop
    end)
    hooksignal(part.Changed, function(info, prop)
        return true, "Hooked"
    end)
    part.Name = "NewName"    
	assert(changedPropNewName == "Hooked", "Signal should be hook")
    assert(issignalhooked(part.Changed), "Signal should be marked as hooked")
    restoresignal(part.Changed)
    part.Name = "NewName2"
    assert(changedPropNewName ~= "Hooked", "Signal shouldn't be hook") 
    assert(not issignalhooked(part.Changed), "Signal shouldn't be marked as hooked")
end)

test("iscclosure", {"iscc"}, function()
	assert(iscclosure(print) == true, "Function 'print' should be a C closure")
	assert(iscclosure(function() end) == false, "Executor function shouldn't be a C closure")
end)

test("islclosure", {"islc"}, function()
	assert(islclosure(print) == false, "Function 'print' shouldn't be a Lua closure")
	assert(islclosure(function() end) == true, "Executor function should be a Lua closure")
end)

test("isexecutorclosure", {"checkclosure", "isourclosure"}, function()
	assert(isexecutorclosure(isexecutorclosure) == true, "Did not return true for an executor global")
	assert(isexecutorclosure(newcclosure(function() end)) == true, "Did not return true for an executor C closure")
	assert(isexecutorclosure(function() end) == true, "Did not return true for an executor Luau closure")
	assert(isexecutorclosure(print) == false, "Did not return false for a Roblox global")
end)

test("loadstring", {}, function()
	local bytecode = "\003\002\005print\vHello World\001\002\000\000\001\006A\000\000\000\f\000\001\000\000\000\000@\005\001\002\000\021\000\002\001\022\000\001\000\003\003\001\004\000\000\000@\003\002\000\001\000\001\024\000\000\000\000\000\001\001\000\000\000\000\000" -- luau version of print("Hello World")
	local func = loadstring(bytecode)
	assert(type(func) ~= "function", "Luau bytecode shouldn't be loadable!")
	assert(assert(loadstring("return ... + 1"))(1) == 2, "Failed to do simple math")
	assert(type(select(2, loadstring("f"))) == "string", "Loadstring did not return anything for a compiler error")
end)

test("newcclosure", {}, function()
	local function test()
		return true
	end
	local testC = newcclosure(test)
	assert(test() == testC(), "New C closure should return the same value as the original")
	assert(test ~= testC, "New C closure shouldn't be same as the original")
	assert(iscclosure(testC), "New C closure should be a C closure")
end)

-- Console

test("rconsoleclear", {"consoleclear"})

test("rconsolecreate", {"consolecreate"})

test("rconsoledestroy", {"consoledestroy"})

test("rconsoleinput", {"consoleinput"})

test("rconsoleprint", {"consoleprint"})

test("rconsoleinfo", {"consoleinfo"})

test("rconsoleerror", {"consoleerror"})

test("rconsolesettitle", {"rconsolename", "consolesettitle"})

-- Crypt

test("crypt.base64encode", {"crypt.base64.encode", "crypt.base64_encode", "base64.encode", "base64_encode"}, function()
	assert(crypt.base64encode("test") == "dGVzdA==", "Base64 encoding failed")
end)

test("crypt.base64decode", {"crypt.base64.decode", "crypt.base64_decode", "base64.decode", "base64_decode"}, function()
	assert(crypt.base64decode("dGVzdA==") == "test", "Base64 decoding failed")
end)

test("crypt.encrypt", {}, function()
	local key = crypt.generatekey()
	local encrypted, iv = crypt.encrypt("test", key, nil, "CBC")
	assert(iv, "crypt.encrypt should return an IV")
	local decrypted = crypt.decrypt(encrypted, key, iv, "CBC")
	assert(decrypted == "test", "Failed to decrypt raw string from encrypted data")
end)

test("crypt.decrypt", {}, function()
	local key, iv = crypt.generatekey(), crypt.generatekey()
	local encrypted = crypt.encrypt("test", key, iv, "CBC")
	local decrypted = crypt.decrypt(encrypted, key, iv, "CBC")
	assert(decrypted == "test", "Failed to decrypt raw string from encrypted data")
end)

test("crypt.generatebytes", {}, function()
	local size = math.random(10, 100)
	local bytes = crypt.generatebytes(size)
	assert(#crypt.base64decode(bytes) == size, `The decoded result should be {size} bytes long (got {#crypt.base64decode(bytes)} decoded, {#bytes} raw)`)
end)

test("crypt.generatekey", {}, function()
	assert(#crypt.base64decode(crypt.generatekey()) == 32, "crypt.generatekey should be 32 bytes long when decoded")
end)

test("crypt.hash", {}, function()
	local algorithms = {
        ["sha1"] = "a94a8fe5ccb19ba61c4c0873d391e987982fbbd3", 
        ["sha224"] = "90a3ed9e32b2aaf4c61c410eb925426119e1a9dc53d4286ade99a809",
        ["sha256"] = "9f86d081884c7d659a2feaa0c55ad015a3bf4f1b2b0b822cd15d6c15b0f00a08", 
        ["sha384"] = "768412320f7b0aa5812fce428dc4706b3cae50e02a64caa16a782249bfe8efc4b7ef1ccb126255d196047dfedf17a0a9", 
        ["sha512"] = "ee26b0dd4af7e749aa1a8ee3c10ae9923f618980772e473f8819a5d4940e0db27ac185f8a0e1d5f84f88bc887fd67b143732c304cc5fa9ad8e6f57f50028a8ff", 
        ["sha3-224"] = "3797bf0afbbfca4a7bbba7602a2b552746876517a7f9b7ce2db0ae7b", 
        ["sha3-256"] = "36f028580bb02cc8272a9a020f4200e346e276ae664e45ee80745574e2f5ab80",
        ["sha3-384"] = "e516dabb23b6e30026863543282780a3ae0dccf05551cf0295178d7ff0f1b41eecb9db3ff219007c4e097260d58621bd",
        ["sha3-512"] = "9ece086e9bac491fac5c1d1046ca11d737b92a2b2ebd93f005d7b710110c0a678288166e7fbe796883a4f2e9b3ca9f484f521d0ce464345cc1aec96779149c14",
        ["md5"] = "098f6bcd4621d373cade4e832627b4f6",
		["halfmd5"] = "098f6bcd4621d373",
        ["doublemd5"] = "fb469d7ef430b0baf0cab6c436e70375",
		["ripemd160"] = "5e52fee47e6b070565f74372468cdc699de89107",
		["ripemd256"] = "fe0289110d07daeee9d9500e14c57787d9083f6ba10e6bcb256f86bb4fe7b981",
		["ripemd320"] = "3b0a2e841e589cf583634a5dd265d2b5d497c4cc44b241e34e0f62d03e98c1b9dc72970b9bc20eb5",
		["keccak-224"] = "3be30a9ff64f34a5861116c5198987ad780165f8366e67aff4760b5e",
		["keccak-256"] = "9c22ff5f21f0b81b113e63f7db6da94fedef11b2119b4088b89664fb9a3cb658",
		["keccak-384"] = "53d0ba137307d4c2f9b6674c83edbd58b70c0f4340133ed0adc6fba1d2478a6a03b7788229e775d2de8ae8c0759d0527",
		["keccak-512"] = "1e2e9fc2002b002d75198b7503210c05a1baac4560916a3c6d93bcce3a50d7f00fd395bf1647b9abb8d1afcc9c76c289b0c9383ba386a956da4b38934417789e",
		["shake128"] = "d3b0aa9cd8b7255622cebc631e867d4093d6f6010191a53973c45fec9b07c774",
		["shake256"] = "b54ff7255705a71ee2925e4a3e30e41aed489a579d5595e0df13e32e1e4dd202a7c7f68b31d6418d9845eb4d757adda6ab189e1bb340db818e5b3bc725d992fa"
    }

	for algorithm, hashed_value in next, algorithms do
		local hash = crypt.hash("test", algorithm)
		assert(hash == hashed_value, `crypt.hash on algorithm '{algorithm}' returned the wrong hash`)
	end
end)

--- Debug

test("debug.setmetatable", {"setrawmetatable"}, function()
	local object = setmetatable({}, { __index = function() return false end, __metatable = "Locked!" })
	local objectReturned = debug.setmetatable(object, { __index = function() return true end })
	assert(object, "Did not return the original object")
	assert(object.test == true, "Failed to change the metatable")
	if objectReturned then
		return objectReturned == object and "Returned the original object" or "Did not return the original object"
	end
end)

test("debug.getmetatable", {"getrawmetatable"}, function()
	local metatable = { __metatable = "Locked!" }
	local object = setmetatable({}, metatable)
	assert(debug.getmetatable(object) == metatable, "Did not return the metatable")
end)

test("debug.getconstant", {"getconstant"}, function()
	local function test()
		print("Hello, world!")
	end
	assert(debug.getconstant(test, 1) == "print", "First constant must be print")
	assert(debug.getconstant(test, 2) == nil, "Second constant must be nil")
	assert(debug.getconstant(test, 3) == "Hello, world!", "Third constant must be 'Hello, world!'")
end)

test("debug.getconstants", {"getconstants"}, function()
	local function test()
		local num = 5000 .. 50000
		print("Hello, world!", num, warn)
	end
	local constants = debug.getconstants(test)
	assert(constants[1] == 50000, "First constant must be 50000")
	assert(constants[2] == "print", "Second constant must be print")
	assert(constants[3] == nil, "Third constant must be nil")
	assert(constants[4] == "Hello, world!", "Fourth constant must be 'Hello, world!'")
	assert(constants[5] == "warn", "Fifth constant must be warn")
end)

test("debug.getinfo", {"getinfo"}, function()
	local types = {
		source = "string",
		short_src = "string",
		func = "function",
		what = "string",
		currentline = "number",
		name = "string",
		nups = "number",
		numparams = "number",
		is_vararg = "number",
	}
	local function test(...)
		print(...)
	end
	local info = debug.getinfo(test)
	for k, v in next, types do
		assert(info[k] ~= nil, `Did not return a table with a '{k}' field`)
		assert(type(info[k]) == v, `Did not return a table with {k} as a {v} (got {type(info[k])})`)
	end
end)

test("debug.getproto", {"getproto"}, function()
	local function test()
		local function proto()
			return true
		end
	end
	local proto = debug.getproto(test, 1, true)[1]
	local realproto = debug.getproto(test, 1)
	assert(proto, "Failed to get the inner function")
	assert(proto() == true, "The inner function did not return anything")
	if not realproto() then
		return "Proto return values are disabled on this executor"
	end
end)

test("debug.getprotos", {"getprotos"}, function()
	local function test()
		local function _1()
			return true
		end
		local function _2()
			return true
		end
		local function _3()
			return true
		end
	end
	for i in next, debug.getprotos(test) do
		local proto = debug.getproto(test, i, true)[1]
		local realproto = debug.getproto(test, i)
		assert(proto(), `Failed to get inner function {i}`)
		if not realproto() then
			return "Proto return values are disabled on this executor"
		end
	end
end)

test("debug.getstack", {"getstack"}, function()
	local _ = "a" .. "b"
	assert(debug.getstack(1, 1) == "ab", "The first item in the stack should be 'ab'")
	assert(debug.getstack(1)[1] == "ab", "The first item in the stack table should be 'ab'")
end)

test("debug.getupvalue", {"getupvalue"}, function()
	local upvalue = function() end
	local function test()
		print(upvalue)
	end
	assert(debug.getupvalue(test, 1) == upvalue, "Unexpected value returned from debug.getupvalue")
end)

test("debug.getregistery", {"getregistery", "getreg"}, function()
	local reg = debug.getregistery()
	assert(type(reg) == "table", "Did not return a table")
	assert(#reg > 0, "Did not return a table with any values")
end)

test("debug.getupvalues", {"getupvalues"}, function()
	local upvalue = function() end
	local function test()
		print(upvalue)
	end
	local upvalues = debug.getupvalues(test)
	assert(upvalues[1] == upvalue, "Unexpected value returned from debug.getupvalues")
end)

test("debug.setconstant", {"setconstant"}, function()
	local function test()
		return "fail"
	end
	debug.setconstant(test, 1, "success")
	assert(test() == "success", "debug.setconstant did not set the first constant")
end)

test("debug.setstack", {"setstack"}, function()
	local function test()
		return "fail", debug.setstack(1, 1, "success")
	end
	assert(test() == "success", "debug.setstack did not set the first stack item")
end)

test("debug.setupvalue", {"setupvalue"}, function()
	local function upvalue()
		return "fail"
	end
	local function test()
		return upvalue()
	end
	debug.setupvalue(test, 1, function()
		return "success"
	end)
	assert(test() == "success", "debug.setupvalue did not set the first upvalue")
end)

-- Filesystem

if isfolder and makefolder and delfolder then
	if isfolder(".tests") then
		delfolder(".tests")
	end
	makefolder(".tests")
end

test("readfile", {}, function()
	writefile(".tests/readfile.txt", "success")
	assert(readfile(".tests/readfile.txt") == "success", "Did not return the contents of the file")
end)

test("listfiles", {}, function()
	makefolder(".tests/listfiles")
	writefile(".tests/listfiles/test_1.txt", "success")
	writefile(".tests/listfiles/test_2.txt", "success")
	local files = listfiles(".tests/listfiles")
	assert(#files == 2, "Did not return the correct number of files")
	assert(isfile(files[1]), "Did not return a file path")
	assert(readfile(files[1]) == "success", "Did not return the correct files")
	makefolder(".tests/listfiles_2")
	makefolder(".tests/listfiles_2/test_1")
	makefolder(".tests/listfiles_2/test_2")
	local folders = listfiles(".tests/listfiles_2")
	assert(#folders == 2, "Did not return the correct number of folders")
	assert(isfolder(folders[1]), "Did not return a folder path")
end)

test("writefile", {}, function()
	writefile(".tests/writefile.txt", "success")
	assert(readfile(".tests/writefile.txt") == "success", "Did not write the file")
	local requiresFileExt = pcall(function()
		writefile(".tests/writefile", "success")
		assert(isfile(".tests/writefile.txt"))
	end)
	if not requiresFileExt then
		return "This executor requires a file extension in writefile"
	end
end)

test("makefolder", {}, function()
	makefolder(".tests/makefolder")
	assert(isfolder(".tests/makefolder"), "Did not create the folder")
end)

test("appendfile", {}, function()
	writefile(".tests/appendfile.txt", "su")
	appendfile(".tests/appendfile.txt", "cce")
	appendfile(".tests/appendfile.txt", "ss")
	assert(readfile(".tests/appendfile.txt") == "success", "Did not append the file")
end)

test("isfile", {}, function()
	writefile(".tests/isfile.txt", "success")
	assert(isfile(".tests/isfile.txt") == true, "Did not return true for a file")
	assert(isfile(".tests") == false, "Did not return false for a folder")
	assert(isfile(".tests/doesnotexist.exe") == false, `Did not return false for a nonexistent path (got {isfile(".tests/doesnotexist.exe")})`)
end)

test("isfolder", {}, function()
	assert(isfolder(".tests") == true, "Did not return false for a folder")
	assert(isfolder(".tests/doesnotexist.exe") == false, `Did not return false for a nonexistent path (got {isfolder(".tests/doesnotexist.exe")})`)
end)

test("delfolder", {}, function()
	makefolder(".tests/delfolder")
	delfolder(".tests/delfolder")
	assert(isfolder(".tests/delfolder") == false, `Failed to delete folder (isfolder = {isfolder(".tests/delfolder")})`)
end)

test("delfile", {}, function()
	writefile(".tests/delfile.txt", "Hello, world!")
	delfile(".tests/delfile.txt")
	assert(isfile(".tests/delfile.txt") == false, `Failed to delete folder (isfile = {isfile(".tests/delfolder")})`)
end)

test("loadfile", {}, function()
	writefile(".tests/loadfile.txt", "return ... + 1")
	assert(assert(loadfile(".tests/loadfile.txt"))(1) == 2, "Failed to load a file with arguments")
	writefile(".tests/loadfile.txt", "f")
	local callback, err = loadfile(".tests/loadfile.txt")
	assert(err and not callback, "Did not return an error message for a compiler error")
end)

test("dofile", {}, function()
	writefile(".tests/dofile.txt", "getfenv().__UNS_DOFILE_TEST = true  return 'UNC on Top!'")
	local Response = dofile(".tests/dofile.txt")
	local DidFile = getfenv().__UNS_DOFILE_TEST
	getfenv().__UNS_DOFILE_TEST = nil
	assert(DidFile, "Did not execute the contents of the file")
	assert(Response == "UNC on Top!", "Did return anything or the wrong value")
end)

-- Input

test("isrbxactive", {"isgameactive"}, function()
	assert(type(isrbxactive()) == "boolean", "Did not return a boolean value")
end)

test("mouse1click", {})

test("mouse1press", {})

test("mouse1release", {})

test("mouse2click", {})

test("mouse2press", {})

test("mouse2release", {})

test("mousemoveabs", {})

test("mousemoverel", {})

test("mousescroll", {})

-- Instances

test("fireclickdetector", {}, function()
	local detector = Instance.new("ClickDetector")
	fireclickdetector(detector, 50, "MouseHoverEnter")
end)

test("firesignal", {}, function()
	local btn, MovedWheelForward = Instance.new("TextButton"), false
	btn.MouseWheelForward:Once(function(x, y)
		MovedWheelForward = x == -51.2151 and y == 515.1251
	end)
	firesignal(btn.MouseWheelForward, -51.2151, 515.1251)
	assert(MovedWheelForward, "Did not correctly fire the MouseWheelForward Signal of TextButton")
end)

test("getcallbackvalue", {}, function()
	local bindable = Instance.new("BindableFunction")
	local function test()
	end
	bindable.OnInvoke = test
	assert(getcallbackvalue(bindable, "OnInvoke") == test, "Did not return the correct value")
end)

test("getconnections", {}, function()
	local types = {
		Enabled = "boolean",
		ForeignState = "boolean",
		LuaConnection = "boolean",
		Function = "function",
		Thread = "thread",
		Fire = "function",
		Defer = "function",
		Disconnect = "function",
		Disable = "function",
		Enable = "function",
	}
	game.Players.LocalPlayer.Event:Connect(function() end)
	local connection = getconnections(game.Players.LocalPlayer.Event)[1]

	for k, v in next, types do
		assert(connection[k] ~= nil, `Did not return a table with a '{k}' field`)
		assert(type(connection[k]) == v, `Did not return a table with {k} as a {v} (got {type(connection[k])})`)
	end
end)

test("getcustomasset", {}, function()
	writefile(".tests/getcustomasset.txt", "success")
	local contentId = getcustomasset(".tests/getcustomasset.txt")
	assert(type(contentId) == "string", "Did not return a string")
	assert(#contentId > 0, "Returned an empty string")
	assert(string.match(contentId, "rbxasset://") == "rbxasset://", "Did not return an rbxasset url")
end)

test("gethiddenproperty", {}, function()
	local fire = Instance.new("Fire")
	local property, isHidden = gethiddenproperty(fire, "size_xml")
	assert(property == 5, "Did not return the correct value")
	assert(isHidden == true, "Did not return whether the property was hidden")
end)

test("getproperties", {"getprops"}, function()
	local part = Instance.new("Part")
	local props = getproperties(part)
	assert(props.Position ~= part.Position, "Did not return the correct value")
end)

test("sethiddenproperty", {}, function()
	local fire = Instance.new("Fire")
	local hidden = sethiddenproperty(fire, "size_xml", 10)
	assert(hidden, "Did not return true for the hidden property")
	assert(gethiddenproperty(fire, "size_xml") == 10, "Did not set the hidden property")
end)

test("gethui", {}, function()
	assert(typeof(gethui()) == "Instance" and gethui().Parent == game:GetService("CoreGui"), "Did not return an Instance")
end)

test("getinstances", {}, function()
	assert(getinstances()[1]:IsA("Instance"), "The first value is not an Instance")
end)

test("getnilinstances", {}, function()
	assert(getnilinstances()[1]:IsA("Instance"), "The first value is not an Instance")
	assert(getnilinstances()[1].Parent == nil, "The first value is not parented to nil")
end)

test("getinstancecache", {}, function()
	assert(getinstancecache()[1]:IsA("Instance"), "The first value is not an Instance")
end)

test("isscriptable", {}, function()
	local fire = Instance.new("Fire")
	assert(isscriptable(fire, "size_xml") == false, "Did not return false for a non-scriptable property (size_xml)")
	assert(isscriptable(fire, "Size") == true, "Did not return true for a scriptable property (Size)")
end)

test("setscriptable", {}, function()
	local fire = Instance.new("Fire")
	local wasScriptable = setscriptable(fire, "size_xml", true)
	assert(wasScriptable == false, "Did not return false for a non-scriptable property (size_xml)")
	assert(isscriptable(fire, "size_xml") == true, "Did not set the scriptable property")
end)

-- Metatable

test("hookmetamethod", {}, function()
	local object = setmetatable({}, { __index = newcclosure(function() return false end), __metatable = "Locked!" })
	local ref = hookmetamethod(object, "__index", function() return true end)
	assert(object.test == true, "Failed to hook a metamethod and change the return value")
	assert(ref() == false, "Did not return the original function")
end)

test("getnamecallmethod", {}, function()
	local method
	local ref
	ref = hookmetamethod(game, "__namecall", function(...)
		if not method then
			method = getnamecallmethod()
		end
		return ref(...)
	end)
	game:GetService("Lighting")
	assert(method == "GetService", "Did not get the correct method (GetService)")
end)

test("isreadonly", {}, function()
	local object = {}
	table.freeze(object)
	assert(isreadonly(object), "Did not return true for a read-only table")
end)

test("setreadonly", {}, function()
	local object = { success = false }
	table.freeze(object)
	setreadonly(object, false)
	object.success = true
	assert(object.success, "Did not allow the table to be modified")
end)

-- Miscellaneous

test("identifyexecutor", {"getexecutorname"}, function()
	local name, version = identifyexecutor()
	assert(type(name) == "string", "Did not return a string for the name")
	return type(version) == "string" and "Returns version as a string" or "Does not return version"
end)

test("lz4compress", {"lz4c"}, function()
	local raw = "Hello, world!"
	local compressed = lz4compress(raw)
	assert(type(compressed) == "string", "Compression did not return a string")
	assert(lz4decompress(compressed, #raw) == raw, "Decompression did not return the original string")
end)

test("lz4decompress", {"lz4d"}, function()
	local raw = "Hello, world!"
	local compressed = lz4compress(raw)
	assert(type(compressed) == "string", "Compression did not return a string")
	assert(lz4decompress(compressed, #raw) == raw, "Decompression did not return the original string")
end)

test("gethwid", {}, function()
	local hwid = gethwid()
	assert(type(hwid) == "string", "Did not return a string for the hwid")

end)

test("messagebox", {})

test("request", {"http.request", "http_request"}, function()
	local response = request({
		Url = "http://httpbin.org/user-agent",
		Method = "GET",
	})
	assert(type(response) == "table", "Response must be a table")
	assert(response.StatusCode == 200, "Did not return a 200 status code")
	local data = game:GetService("HttpService"):JSONDecode(response.Body)
	assert(type(data) == "table" and type(data["user-agent"]) == "string", "Did not return a table with a user-agent key")
	return `User-Agent: {data["user-agent"]}`
end)

test("setfpscap", {}, function()
	local renderStepped = game:GetService("RunService").RenderStepped
	local function step()
		renderStepped:Wait()
		local sum = 0
		for _ = 1, 5 do
			sum += 1 / renderStepped:Wait()
		end
		return math.round(sum / 5)
	end
	setfpscap(60)
	local step60 = step()
	setfpscap(20)
	local step0 = step()
	return `{step60}fps @60 • {step0}fps @20`
end)

test("getfpscap", {})

test("isnetworkowner", {"isowner"}, function()
	assert(isnetworkowner(game.Players.LocalPlayer.Character.HumanoidRootPart), "Did not return true")
end)

-- Scripts

test("getgc", {}, function()
	local gc = getgc()
	assert(type(gc) == "table", "Did not return a table")
	assert(#gc > 0, "Did not return a table with any values")
end)

test("filtergc", {}, function()
    local tbl = {
        UNCs = "Testing..."
    }
    local metatbl = {__idiv = function() return 0.1515 end, __div = function() return "Ballers" end, __metatable = "Locked for testing UNS..."}
    setmetatable({}, metatbl)
	local filtered_gc = filtergc("table", {
        KeyValuePairs = tbl,
        Keys = {"UNCs"},
        Values = {"Testing..."},
        Metatable = metatbl
    })

    assert(#filtered_gc > 0, "Did not return a table with the filtered table(s)")
	assert(type(filtered_gc[1]) == "table", "Did not return a table")
    assert(filtered_gc[1] == tbl, "Did not return the correct table")
end)

test("getgenv", {}, function()
	getgenv().__TEST_GLOBAL = true
	assert(__TEST_GLOBAL, "Failed to set a global variable")
	getgenv().__TEST_GLOBAL = nil
end)

test("getloadedmodules", {}, function()
	local modules = getloadedmodules()
	assert(type(modules) == "table", "Did not return a table")
	assert(#modules > 0, "Did not return a table with any values")
	assert(typeof(modules[1]) == "Instance", "First value is not an Instance")
	assert(modules[1]:IsA("ModuleScript"), "First value is not a ModuleScript")
end)

test("getrenv", {}, function()
	assert(shared ~= getrenv().shared, "The variable shared in the executor is identical to shared in the game")
end)

test("getrunningscripts", {}, function()
	local scripts = getrunningscripts()
	assert(type(scripts) == "table", "Did not return a table")
	assert(#scripts > 0, "Did not return a table with any values")
	assert(typeof(scripts[1]) == "Instance", "First value is not an Instance")
	assert(scripts[1]:IsA("ModuleScript") or scripts[1]:IsA("LocalScript"), "First value is not a ModuleScript or LocalScript")
end)

test("getscriptbytecode", {"dumpstring"}, function()
	local animate = game:GetService("Players").LocalPlayer.Character.Animate
	local bytecode = getscriptbytecode(animate)
	assert(type(bytecode) == "string", `Did not return a string for Character.Animate (a {animate.ClassName})`)
end)

test("getscripthash", {}, function()
	local animate = game:GetService("Players").LocalPlayer.Character.Animate:Clone()
	local hash = getscripthash(animate)
	local source = animate.Source
	animate.Source = "print('Hello, world!')"
	task.defer(function()
		animate.Source = source
	end)
	local newHash = getscripthash(animate)
	assert(hash ~= newHash, "Did not return a different hash for a modified script")
	assert(newHash == getscripthash(animate), "Did not return the same hash for a script with the same source")
end)

test("getscriptthread", {}, function()
    assert(typeof(getscriptthread(game:GetService("Players").LocalPlayer.Character.Animate)) == "thread", "Did not return a thread")
	assert(getscriptthread(script) == nil, "Returned a thread for the executor's script")
end)

test("getscripts", {}, function()
	local scripts = getscripts()
	assert(type(scripts) == "table", "Did not return a table")
	assert(#scripts > 0, "Did not return a table with any values")
	assert(typeof(scripts[1]) == "Instance", "First value is not an Instance")
	assert(scripts[1]:IsA("ModuleScript") or scripts[1]:IsA("LocalScript"), "First value is not a ModuleScript or LocalScript")
end)

test("getsenv", {}, function()
	local animate = game:GetService("Players").LocalPlayer.Character.Animate
	local env = getsenv(animate)
	assert(type(env) == "table", `Did not return a table for Character.Animate (a {animate.ClassName})`)
	assert(env.script == animate, "The script global is not identical to Character.Animate")
end)

test("gettenv", {}, function()
	local Thread = task.defer(function() end)
	local env = gettenv(Thread)
	assert(type(env) == "table", `Did not return a table for a Thread`)
	assert(env.script == script, "The script global is not identical to executor's one")
end)

test("getthreadidentity", {"getidentity", "getthreadcontext"}, function()
	assert(type(getthreadidentity()) == "number", "Did not return a number")
end)

test("setthreadidentity", {"setidentity", "setthreadcontext"}, function()
    local oldidentity = getthreadidentity()
	setthreadidentity(3)
	assert(getthreadidentity() == 3, "Did not set the thread identity")
    setthreadidentity(oldidentity)
    assert(getthreadidentity() == oldidentity, "Did not reset the thread identity")
end)

-- Drawing Library

test("Drawing", {})

test("Drawing.new", {}, function()
	local drawing = Drawing.new("Square")
    if isrenderobj == nil then
	    notes["Drawing.new"] = "Exploit should support isrenderobj"
	else
	    assert(isrenderobj(drawing) == true, "Did not return a valid render object or the 'isrenderobj' function returned the wrong value")
	end
    drawing.Visible = false
	local canDestroy = pcall(function()
		drawing:Destroy()
	end)
    drawing = Drawing.new("Square")
	drawing.Visible = false
    local canRemove = pcall(function()
		drawing:Remove()
	end)
	assert(canDestroy, "Drawing:Destroy() shouldn't throw an error")
	assert(canRemove, "Drawing:Remove() shouldn't throw an error")
end)

test("Drawing.Fonts", {}, function()
	assert(Drawing.Fonts.UI == 0, `Did not return the correct id '0' for Fonts.UI, got '{Drawing.Fonts.UI}'`)
	assert(Drawing.Fonts.System == 1, `Did not return the correct id '1' for Fonts.System, got '{Drawing.Fonts.System}'`)
	assert(Drawing.Fonts.Plex == 2, `Did not return the correct id '2' for Fonts.Plex, got '{Drawing.Fonts.Plex}'`)
	assert(Drawing.Fonts.Monospace == 3, `Did not return the correct id '3' for Fonts.Monospace, got '{Drawing.Fonts.Monospace}'`)
end)

test("Drawing.Fonts", {}, function()
	assert(Drawing.Fonts.UI == 0, `Did not return the correct id '0' for Fonts.UI, got '{Drawing.Fonts.UI}'`)
	assert(Drawing.Fonts.System == 1, `Did not return the correct id '1' for Fonts.System, got '{Drawing.Fonts.System}'`)
	assert(Drawing.Fonts.Plex == 2, `Did not return the correct id '2' for Fonts.Plex, got '{Drawing.Fonts.Plex}'`)
	assert(Drawing.Fonts.Monospace == 3, `Did not return the correct id '3' for Fonts.Monospace, got '{Drawing.Fonts.Monospace}'`)
end)

test("Drawing.Clear", {"cleardrawcache"}, function()
	local drawing = Drawing.new("Image")
	drawing.Visible = false
	Drawing.Clear()
end)

test("getrenderproperty", {}, function()
	local drawing = Drawing.new("Image")
	drawing.Visible = true
	assert(type(getrenderproperty(drawing, "Visible")) == "boolean", "Did not return a boolean value for Image.Visible")
	local success, result = pcall(function()
		return getrenderproperty(drawing, "Color")
	end)
	if not success or not result then
		return "Image.Color is not supported"
	end
end)

test("setrenderproperty", {}, function()
	local drawing = Drawing.new("Square")
	drawing.Visible = true
	setrenderproperty(drawing, "Visible", false)
	assert(drawing.Visible == false, "Did not set the value for Square.Visible")
end)

-- WebSocket Library

test("WebSocket", {})

test("WebSocket.connect", {}, function()
	local types = {
		Send = "function",
		Close = "function",
		OnMessage = {"table", "userdata"},
		OnClose = {"table", "userdata"},
	}
	local ws = WebSocket.connect("ws://echo.websocket.events")
	assert(type(ws) == "table" or type(ws) == "userdata", "Did not return a table or userdata")
	for k, v in next, types do
		if type(v) == "table" then
			assert(table.find(v, type(ws[k])), `Did not return a {table.concat(v, ", ")} for {k} (a {typeof(ws[k])})`)
		else
			assert(type(ws[k]) == v, `Did not return a {v} for {k} (a {typeof(ws[k])})`)
		end
	end
	ws:Close()
end)

-- Teleport Queue Library

test("Queue", {}, function()
    Queue("return")
end)

test("Queue.Get", {"Queue_Get"}, function()
    assert(Queue.Get()[1] == "return", "Did not return correct value when getting the Teleport Queue")
end)

test("Queue.Clear", {"Queue_Clear"}, function()
    Queue.Clear()
    assert(Queue.Get()[1] ~= "return", "Did not clear Teleport Queue")
end)

-- Clipboard Library

test("Clipboard.Set", {"Clipboard_Set"}, function()
	Clipboard.Set(game:GetService("Players").LocalPlayer.Character)
	Clipboard.Set("UNS Testing...")
end)

test("Clipboard.Get", {"Clipboard_Get"}, function()
	assert(Clipboard.Get() == "UNS Testing...", "Did not return the correct value for a copied string")
	Clipboard.Set(game:GetService("Players").LocalPlayer.Character)
	assert(Clipboard.Get():find("<roblox!��"), "Did not return the correct value for a copied instance")
end)