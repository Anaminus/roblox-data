local lfs = require 'lfs'
local ParseVersions = require 'ParseVersions'
local FetchAPI = require 'FetchAPI'
local LexAPI = require 'LexAPI'

local function path(...)
	local a = {...}
	local p = a[1] or ''
	for i = 2,#a do
		p = p .. '/' .. a[i]
	end
	p = p:gsub('[\\/]+','/')
	return p
end

local function exists(filename)
	return not not lfs.attributes(filename)
end

local function fileempty(file)
	if not exists(file) then return true end
	local f = io.open(file,'rb')
	if not f then return true end
	local size = f:seek('end')
	f:close()
	return size == 0
end

local function mkdir(...)
	local s,err = lfs.mkdir(...)
	if not s and err ~= 'File exists' then
		return s,'Could not create directory `' .. fdir .. '`: ' .. err
	end
	return true
end

local format = {}

----------------------------------------------------------------
-- raw ---------------------------------------------------------
format.raw = {}

function format.raw.header(builds,dir,rdir)
	local name = path(dir,'header.txt')
	local f,err = io.open(name,'wb')
	if not f then return f,err end

	print("Writing " .. name)

	f:write('schema ',builds.Schema,'\n')
	f:write(builds.Domain,'\n')
	local list = builds.List
	for i = 1,#list do
		local b = list[i]
		f:write(
			b.Date,'\t',
			b.PlayerHash,'\t',
			b.StudioHash,'\t',
			table.concat(b.PlayerVersion,'.'),'\n'
		)
	end

	f:flush()
	f:close()

	return name
end

function format.raw.api(build,dir,rdir,latest)
	local name
	if latest then
		name = path(dir,'latest.rbxapi')
	else
		name = path(dir,build.PlayerHash .. '.rbxapi')
		if not fileempty(name) then return name end
	end

	print("Writing " .. name)

	local f,err = io.open(name,'wb')
	if not f then return f,err end

	local dump,err = FetchAPI(build.PlayerHash,build.StudioHash)
	if not dump then f:close() return dump,err end

	f:write(dump)
	f:flush()
	f:close()

	return name
end

function format.raw.rflmd(build,dir,rdir,latest)
	local name
	if latest then
		name = path(dir,'latest.xml')
	else
		name = path(dir,build.PlayerHash .. '.xml')
		if not fileempty(name) then return name end
	end

	print("Writing " .. name)

	local f,err = io.open(name,'wb')
	if not f then return f,err end

	local s,err,bdir = FetchAPI(build.PlayerHash,build.StudioHash)
	if not s then f:close() return s,err end

	local rf,err = io.open(path(bdir,'ReflectionMetadata.xml'),'rb')
	if not rf then f:close() return rf,err end
	f:write(rf:read('*a'))
	rf:close()
	f:flush()
	f:close()

	return name
end
----------------------------------------------------------------
----------------------------------------------------------------


----------------------------------------------------------------
-- json --------------------------------------------------------
format.json = {}

function format.json.header(builds,dir,rdir)
	local name = path(dir,'header.json')
	local f,err = io.open(name,'wb')
	if not f then return f,err end

	print("Writing " .. name)

	local json = require 'dkjson'
	f:write(json.encode(builds))

	f:flush()
	f:close()

	return name
end
function format.json.api(build,dir,rdir,latest)
	local name
	if latest then
		name = path(dir,'latest.json')
	else
		name = path(dir,build.PlayerHash .. '.json')
		if not fileempty(name) then return name end
	end

	print("Writing " .. name)

	-- depend on raw format instead of build fetching
	local dumpfile,err = format.raw.api(build,rdir,rdir,latest)
	if not dumpfile then return dumpfile,err end

	local f,err = io.open(dumpfile,'rb')
	if not f then return f,err end
	local dump,err = LexAPI(f:read('*a'))
	f:close()
	if not dump then return dump,err end

	local json = require 'dkjson'

	for i = 1,#dump do
		local item = dump[i]

		-- convert `tags` to an array
		local tags = item.tags
		local t = setmetatable({},{__jsontype='array'})
		for k in pairs(tags) do
			t[#t+1] = k
		end
		table.sort(t)
		item.tags = t

		if item.type == 'Class' then
			-- superclass is nullable
			if item.Superclass == nil then
				item.Superclass = json.null
			end
		elseif item.type == 'Function' or item.type == 'YieldFunction' then
			local args = item.Arguments
			for i = 1,#args do
				-- default is nullable
				if args[i].Default == nil then
					args[i].Default = json.null
				end
			end
		end
		-- ensure argument tables are arrays
		if item.Arguments ~= nil then
			setmetatable(item.Arguments,{__jsontype='array'})
		end
	end

	local f,err = io.open(name,'wb')
	if not f then return f,err end

	f:write(json.encode(dump))

	f:flush()
	f:close()

	return name
end

function format.json.rflmd(build,dir,rdir,latest)
	local name
	if latest then
		name = path(dir,'latest.json')
	else
		name = path(dir,build.PlayerHash .. '.json')
		if not fileempty(name) then return name end
	end

	print("Writing " .. name)

	-- depend on raw format instead of build fetching
	local rmdfile,err = format.raw.rflmd(build,rdir,rdir,latest)
	if not rmdfile then return rmdfile,err end

	require 'LuaXML'
	local rmd,err = xml.load(rmdfile)
	if not rmd then return rmd,err end


	local function getprop(props,name,default)
		local prop = props:find(nil,'name',name)
		if prop and prop.name == name then
			if type(default) == 'number' then
				return tonumber(prop[1]) or 0
			elseif type(default) == 'bool' then
				return prop[1] == 'true'
			else
				return prop[1]
			end
		else
			return default
		end
	end

	local out = {}
	local classes = rmd[1]
	for i = 1,#classes do
		local tag = classes[i]
		if tag[0] == 'Item' and tag.class == 'ReflectionMetadataClass' then
			local props = tag:find('Properties')
			if props then
				local class = {
					Name = getprop(props,'Name',"");
					Browsable = getprop(props,'Browsable',true);
					Preliminary = getprop(props,'Preliminary',false);
					Deprecated = getprop(props,'Deprecated',false);
					IsBackend = getprop(props,'IsBackend',false);
					Summary = getprop(props,'summary',"");
					ExplorerOrder = getprop(props,'ExplorerOrder',0);
					ExplorerImageIndex = getprop(props,'ExplorerImageIndex',0);
					PreferredParent = getprop(props,'PreferredParent',"");
					Members = {};
				}
				local members = class.Members
				for i = 1,#tag do
					local subtag = tag[i]
					if subtag[0] == 'Item' then
						if subtag.class == 'ReflectionMetadataProperties'
						or subtag.class == 'ReflectionMetadataFunctions'
						or subtag.class == 'ReflectionMetadataYieldFunctions'
						or subtag.class == 'ReflectionMetadataEvents'
						or subtag.class == 'ReflectionMetadataCallbacks' then
							for i = 1,#subtag do
								local memtag = subtag[i]
								if memtag[0] == 'Item' and memtag.class == 'ReflectionMetadataMember' then
									local props = memtag:find('Properties')
									if props then
										local member = {
											Name = getprop(props,'Name',"");
											Browsable = getprop(props,'Browsable',true);
											Preliminary = getprop(props,'Preliminary',false);
											Deprecated = getprop(props,'Deprecated',false);
											IsBackend = getprop(props,'IsBackend',false);
											Summary = getprop(props,'summary',"");
										}
										members[#members+1] = member
									end
								end
							end
						end
					end
				end
				out[#out+1] = class
			end
		end
	end

	local f,err = io.open(name,'wb')
	if not f then return f,err end

	local json = require 'dkjson'
	f:write(json.encode(out,{keyorder={
		'Name';
		'Summary';
		'ExplorerOrder';
		'ExplorerImageIndex';
		'Browsable';
		'Deprecated';
		'Preliminary';
		'IsBackend';
		'PreferredParent';
		'Members';
	}}))

	f:flush()
	f:close()

	return name
end
--[[
]]
----------------------------------------------------------------
----------------------------------------------------------------

local data = path('../../data')
local builds,err = ParseVersions(path('../../versions'))
if not builds then error(err) end

for ftype,dtypes in pairs(format) do
	local fdir = path(data,ftype)
	local s,err = mkdir(fdir)
	if not s then return s,err end

	if dtypes.header then
		local s,err = dtypes.header(builds,fdir,path(data,'raw'))
		if not s then
			print('Could not write header file: ' .. err)
		end
	end

	if dtypes.api then
		local dir = path(fdir,'api')
		local rdir = path(data,'raw','api')
		local s,err = mkdir(dir)
		if not s then return s,err end

		local list = builds.List
		for i = 1,#list do
			local s,err = dtypes.api(list[i],dir,rdir)
			if not s then
				print('Could not write api file: ' .. err)
			end
		end
		-- latest
		local s,err = dtypes.api(list[#list],dir,rdir,true)
		if not s then
			print('Could not write api file: ' .. err)
		end
	end

	if dtypes.rflmd then
		local dir = path(fdir,'rflmd')
		local rdir = path(data,'raw','rflmd')
		local s,err = mkdir(dir)
		if not s then return s,err end

		local list = builds.List
		for i = 1,#list do
			local s,err = dtypes.rflmd(list[i],dir,rdir)
			if not s then
				print('Could not write rflmd file: ' .. err)
			end
		end
		local s,err = dtypes.rflmd(list[#list],dir,rdir,true)
		if not s then
			print('Could not write rflmd file: ' .. err)
		end
	end
end
