local schema = {}

--[[ Version 1

returns BuildList

type BuildList struct {
	Schema int     // The version of this schema
	Domain string  // The URI domain where builds may be downloaded
	List   []Build // A list of player build info
}

type Build struct {
	Date          int
	PlayerHash    string
	StudioHash    string
	PlayerVersion Version
}

type Version [4]uint16

]]
schema[1] = function(content,i)
	local s,f,domain = content:find('^(.-)\n',i)
	if not domain then
		return nil,"invalid domain"
	end

	local list = {}
	local versions = {
		Schema = 1;
		Domain = domain;
		List = list;
	}

	for line in content:sub(f+1):gmatch('[^\n]+') do
		local date,phash,shash,v0,v1,v2,v3 = line:match('^(%d+)\t(version%-%x+)\t(version%-%x+)\t(%d+)%.(%d+)%.(%d+)%.(%d+)$')
		date = tonumber(date)
		if date then
			list[#list+1] = {
				Date = date;
				PlayerHash = phash;
				StudioHash = shash;
				PlayerVersion = {tonumber(v0),tonumber(v1),tonumber(v2),tonumber(v3)};
			}
		end
	end

	return versions
end

return function(versions)
	local f = io.open(versions,'rb')
	local content = f:read('*a'):gsub('\r\n','\n')
	f:close()

	local s,f,v = content:find('^schema (%d+)\n')
	v = tonumber(v)
	if not v then
		return nil,"malformed schema version"
	end
	if not schema[v] then
		return nil,"schema version " .. v .. " is not supported"
	end

	return schema[v](content,f+1)
end
