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

function format.raw.header(builds,dir)
	local f,err = io.open(path(dir,'header.txt'),'wb')
	if not f then return f,err end

	print("Writing raw/header.txt")

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

	return true
end

function format.raw.api(build,dir,latest)
	local name
	if latest then
		name = path(dir,'latest.rbxapi')
	else
		name = path(dir,build.PlayerHash .. '.rbxapi')
		if not fileempty(name) then return true end
	end

	print("Writing " .. name)

	local f,err = io.open(name,'wb')
	if not f then return f,err end

	local dump,err = FetchAPI(build.PlayerHash,build.StudioHash)
	if not dump then f:close() return dump,err end

	f:write(dump)
	f:flush()
	f:close()

	return true
end

function format.raw.rflmd(build,dir,latest)
	local name
	if latest then
		name = path(dir,'latest.xml')
	else
		name = path(dir,build.PlayerHash .. '.xml')
		if not fileempty(name) then return true end
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

	return true
end
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
		local s,err = dtypes.header(builds,fdir)
		if not s then
			print('Could not write header file: ' .. err)
		end
	end

	if dtypes.api then
		local dir = path(fdir,'api')
		local s,err = mkdir(dir)
		if not s then return s,err end

		local list = builds.List
		for i = 1,#list do
			local s,err = dtypes.api(list[i],dir)
			if not s then
				print('Could not write api file: ' .. err)
			end
		end
		-- latest
		local s,err = dtypes.api(list[#list],dir,true)
		if not s then
			print('Could not write api file: ' .. err)
		end
	end

	if dtypes.rflmd then
		local dir = path(fdir,'rflmd')
		local s,err = mkdir(dir)
		if not s then return s,err end

		local list = builds.List
		for i = 1,#list do
			local s,err = dtypes.rflmd(list[i],dir)
			if not s then
				print('Could not write rflmd file: ' .. err)
			end
		end
		local s,err = dtypes.rflmd(list[#list],dir,true)
		if not s then
			print('Could not write rflmd file: ' .. err)
		end
	end
end
