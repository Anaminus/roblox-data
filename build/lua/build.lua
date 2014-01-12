local outputs = {...}
if #outputs == 0 then
	print('Usage:\nlua build.lua [DIRECTORY]...\n')
	error('Must specify one or more directories.',0)
end

local lfs = require 'lfs'
local CompareVersions = require 'CompareVersions'
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

local function fileempty(filename)
	local size = lfs.attributes(filename,'size')
	return not size or size == 0
end

local function copy(an,bn)
	local a = io.open(an,'rb')
	local b = io.open(bn,'wb')
	b:write(a:read('*a'))
	b:flush()
	a:close()
	b:close()
end

local function mkdir(...)
	local s,err = lfs.mkdir(...)
	if not s and err ~= 'File exists' then
		return s,'Could not create directory `' .. fdir .. '`: ' .. err
	end
	return true
end


----------------------------------------------------------------
-- raw ---------------------------------------------------------
local rawformat = {}

-- Incrementally writes build information to a header file. If the build is
-- nil, then it writes initial information to the file instead.
function rawformat.header(header,versions,build)
	if build then
		header:write(
			build.Date,'\t',
			build.PlayerHash,'\t',
			build.StudioHash,'\t',
			build.PlayerVersion,'\n'
		)
	else
		header:write(
			'schema ',versions.Schema,'\n',
			versions.Domain,'\n',
			'Date\tPlayerHash\tStudioHash\tPlayerVersion\n'
		)
	end
	header:flush()
	return true
end

-- build info
-- output directory
-- whether to check if the file exists
-- whether file is the `latest` file
function rawformat.api(build,dir,check,latest)
	local name
	if latest then
		name = path('raw','api','latest.txt')
	else
		name = path('raw','api',build.PlayerHash .. '.txt')
		if check and not fileempty(path(dir,name)) then return name end
	end

	local f,err = io.open(path(dir,name),'wb')
	if not f then return f,err end

	local dump,err = FetchAPI(build.PlayerHash,build.StudioHash)
	if not dump then f:close() return dump,err end

	f:write(dump)
	f:flush()
	f:close()

	print('\twrote `' .. name .. '`')

	return name
end

function rawformat.rmd(build,dir,check,latest)
	local name
	if latest then
		name = path('raw','rmd','latest.xml')
	else
		name = path('raw','rmd',build.PlayerHash .. '.xml')
		if check and not fileempty(path(dir,name)) then return name end
	end

	local f,err = io.open(path(dir,name),'wb')
	if not f then return f,err end

	local s,err,bdir = FetchAPI(build.PlayerHash,build.StudioHash)
	if not s then f:close() return s,err end

	local rf,err = io.open(path(bdir,'ReflectionMetadata.xml'),'rb')
	if not rf then f:close() return rf,err end
	f:write(rf:read('*a'))
	rf:close()
	f:flush()
	f:close()

	print('\twrote `' .. name .. '`')

	return name
end
----------------------------------------------------------------
----------------------------------------------------------------

-- Each entry to `format` is a table. This table should contain functions that
-- format data for each type of data. Each function should accept two
-- arguments: One, the path to an existing file, which contains the raw data
-- to be converted, and two, the path of the file to output converted data to.
-- Types of data are `header`, `api`, and `rmd`.
local format = {}

----------------------------------------------------------------
-- json --------------------------------------------------------
format.json = {}
format.json.extension = 'json'

function format.json.header(raw,dest)
	local header,err = ParseVersions(raw)
	if not header then return header,err end

	local f,err = io.open(dest,'wb')
	if not f then return f,err end

	local json = require 'dkjson'
	f:write(json.encode(header))

	f:flush()
	f:close()

	return true
end

function format.json.api(raw,dest)
	local f,err = io.open(raw,'rb')
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

	local f,err = io.open(dest,'wb')
	if not f then return f,err end

	f:write(json.encode(dump))

	f:flush()
	f:close()

	return true
end

function format.json.rmd(raw,dest)
	require 'LuaXML'
	local rmd,err = xml.load(raw)
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
					Name = getprop(props,'Name','');
					Browsable = getprop(props,'Browsable',true);
					Preliminary = getprop(props,'Preliminary',false);
					Deprecated = getprop(props,'Deprecated',false);
					IsBackend = getprop(props,'IsBackend',false);
					Summary = getprop(props,'summary','');
					ExplorerOrder = getprop(props,'ExplorerOrder',0);
					ExplorerImageIndex = getprop(props,'ExplorerImageIndex',0);
					PreferredParent = getprop(props,'PreferredParent','');
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
											Name = getprop(props,'Name','');
											Browsable = getprop(props,'Browsable',true);
											Preliminary = getprop(props,'Preliminary',false);
											Deprecated = getprop(props,'Deprecated',false);
											IsBackend = getprop(props,'IsBackend',false);
											Summary = getprop(props,'summary','');
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

	local f,err = io.open(dest,'wb')
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

	return true
end
----------------------------------------------------------------
----------------------------------------------------------------

local function updateDataType(build,dtype,data,check,latest)
	local rawfile,err = rawformat[dtype](build,data,check,latest)
	if rawfile then
		for ftype,f in pairs(format) do
			local out
			if latest then
				out = path(ftype,dtype,'latest.' .. f.extension)
			else
				out = path(ftype,dtype,build.PlayerHash .. '.' .. f.extension)
			end
			if check and not fileempty(path(data,out)) then
				-- do not update file if it exists
				return
			end
			local s,err = f[dtype](path(data,rawfile),path(data,out))
			if s then
				print('\twrote `' .. out .. '`')
			else
				print('\tcould not write ' .. dtype .. ' file for ' .. ftype .. 'format: ' .. err)
			end
		end
	else
		print('\tcould not write raw ' .. dtype .. ' file: ' .. err)
	end
end

local function makedatadir(data,type)
	local dir = path(data,type)
	local s,err = mkdir(dir)
	if not s then return s,err end

	local s,err = mkdir(path(dir,'api'))
	if not s then return s, "`api` dir: " .. err end

	local s,err = mkdir(path(dir,'rmd'))
	if not s then return s, "`rmd` dir: " .. err end

	return dir
end

local versions,err = ParseVersions(path('../../versions'))
if not versions then error("could not parse versions file: " .. err) end

function buildEach()
	for i = 1,#outputs do
		local data = outputs[i]
		if not exists(data) then
			return nil,'directory `' .. data .. '` does not exist'
		end

		print('writing `' .. data .. '`')

		-- create directories
		local rawdir,err = makedatadir(data,'raw')
		if not rawdir then return rawdir,'could not create raw directory: ' .. err end

		for type,f in pairs(format) do
			local s,err = makedatadir(data,type)
			if not s then return s,'could not create directory for ' .. type .. ' format: ' .. err end
		end

		-- compare versions with current header
		local headerpath = path(data,'raw','header.txt')
		local updates do
			local header
			if exists(headerpath) then
				header,err = ParseVersions(headerpath)
				if err then
					print('could not parse header file: ' .. err)
					print('assuming empty header')
				end
			end
			if not header then
				header = {Schema=versions.Schema,Domain=versions.Domain,List={}}
			end
			updates = CompareVersions(header,versions)
		end

		-- start writing new raw header file
		local header,err = io.open(path(rawdir,'header.txt'),'wb')
		if not header then
			return nil,'could not open header file: ' .. err
		end
		rawformat.header(header,versions,nil)

		local date = 0
		local latest
		for i = 1,#updates do
			local state,build = updates[i][1],updates[i][2]
			if state == 0 or state == 1 then
				print((state==0 and 'verifying ' or 'updating ') .. build.PlayerHash)

				if build.Date > date then
					date = build.Date
					latest = build
				end

				updateDataType(build,'api',data,state==0)
				updateDataType(build,'rmd',data,state==0)

				rawformat.header(header,versions,build)
			elseif state == -1 then
				print('removing ' .. build.PlayerHash)

				os.remove(path(data,'raw','api',build.PlayerHash .. '.txt'))
				os.remove(path(data,'raw','rmd',build.PlayerHash .. '.xml'))

				for type,f in pairs(format) do
					os.remove(path(data,type,'api',build.PlayerHash .. '.' .. f.extension))
					os.remove(path(data,type,'rmd',build.PlayerHash .. '.' .. f.extension))
				end
			end
		end
		header:flush()
		header:close()
		print('updated raw header file')

		print('updating formatted header files')
		for type,f in pairs(format) do
			local s,err = f.header(headerpath,path(data,type,'header.' .. (f.extension or type)))
			if s then
				print('\twrote header for ' .. type .. ' format')
			else
				print('\tcould not write header for ' .. type .. ' format: ' .. err)
			end
		end

		if latest then
			print('updating latest files')
			updateDataType(latest,'api',data,false,true)
			updateDataType(latest,'rmd',data,false,true)
		end
	end
end

local s,err = buildEach()
if not s then error(err,0) end
