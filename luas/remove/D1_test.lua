local l_gb = require "gbModule"
local l_base = require "baseModule"

--g_step current collect step, 0:not start
local g_step = 1
local g_stat = 101
local g_ver = 0x20
local g_adr = 0x00
local g_isdebug = true
local g_endian = 0

local g_pollCmds = {}
function initPollCmds(ver, adr)
	g_pollCmds = {}
	table.insert(g_pollCmds, 1, l_gb.pack(nil, ver, adr, 0x40, 0x50))
	table.insert(g_pollCmds, 2, l_gb.pack({0}, ver, adr,0x40, 0x41))

	table.insert(g_pollCmds, 3, l_gb.pack({0}, ver, adr,0x40, 0x43))
--[[
	table.insert(g_pollCmds, 4, l_gb.pack({0}, ver, adr,0x40, 0x44))
	table.insert(g_pollCmds, 5, l_gb.pack(nil, ver, adr,0x40, 0x46))
	
	table.insert(g_pollCmds, 6, l_gb.pack(nil, ver, adr,0x41, 0x41))
	table.insert(g_pollCmds, 7, l_gb.pack(nil, ver, adr,0x41, 0x43))
	table.insert(g_pollCmds, 8, l_gb.pack(nil, ver, adr,0x41, 0x44))
	
	table.insert(g_pollCmds, 9, l_gb.pack(nil, ver, adr,0x42, 0x41))
	table.insert(g_pollCmds, 10, l_gb.pack(nil, ver, adr,0x42, 0x44))
	table.insert(g_pollCmds, 11, l_gb.pack(nil, ver, adr,0x42, 0x46))
]]
end

function nextPack(onePack)
	if #g_pollCmds == 0 then
		initPollCmds(g_ver, g_adr)
	end

--	showDebug("get step: " .. g_step .. " table len: " .. #g_pollCmds)
	if g_step >= #g_pollCmds + 1 then
		csb_newPack(onePack, g_stat, 8, 500, 0);
		g_step = 1
	else
		local pack = g_pollCmds[g_step]
		csb_newPack(onePack, g_stat, 8, 500, #pack);
		for i = 1, #pack do
			csb_addPackInfo(onePack, i, pack[i]);
		end
	end
end

function parse(c_rs)
	local checkrs = l_gb.checkPack(c_rs)
	csb_setParseResult(c_rs, checkrs)
--	showDebug("current step : " .. g_step .. " checkRs " .. checkrs)
	if g_step <= #g_pollCmds then
		if checkrs == 101 or checkrs == 107 then
			if g_step == 1 then
				local a,b,c,d = cfb_getData(c_rs, 1, 4)
				local ver = l_base.twoasc_to_hex(a, b)
				local adr = l_base.twoasc_to_hex(c, d)
				initPollCmds(ver, adr)
		--		print("ver , adr " .. string.format("%02X",ver) .. ":" .. adr)
				csb_newParse(c_rs, 0)
			else
			
				local parseRs = {}
				if g_step == 2 then
					parseRs = parse_acai(c_rs)
				elseif g_step == 3 then
					parseRs = parse_rcai(c_rs)
				end

				local newCount = #parseRs
				csb_newParse(c_rs, newCount)
				for i = 1, newCount do
					local one = parseRs[i]
	--				showDebug("key: " .. one[1] .. " value: " .. one[2])
					if one[2] + 999999 == 0 then
						csb_addParseRs(c_rs, i, one[1], one[2], 1)
					else
						csb_addParseRs(c_rs, i, one[1], one[2], 0)
					end
				end
				
--			else
--				csb_newParse(c_rs, 0)
			end
			g_step = g_step + 1
		end
	else
		g_step = 2
	end
end

function parse_acai(c_rs)
	local parseRs = {}
	local offset = 15
	local acCount = cfb_ascParse(c_rs, "touint", offset, 1, g_endian)
--	showDebug("acCount: " .. acCount)
	offset = offset + 2
	local pos = 1;
	for i = 1, acCount do
		local vac = cfb_ascParse(c_rs, "tofloat", offset, 4, g_endian) offset = offset + 8
--		showDebug("va: " .. vac)
		table.insert(parseRs, pos, {6101000 + i, vac}) pos = pos + 1
		
		vac = cfb_ascParse(c_rs, "tofloat", offset, 4, g_endian) offset = offset + 8
--		showDebug("vb: " .. vac)
		table.insert(parseRs, pos, {6102000 + i, vac}) pos = pos + 1
		

		vac = cfb_ascParse(c_rs, "tofloat", offset, 4, g_endian) offset = offset + 8
--		showDebug("vc: " .. vac)
		
		table.insert(parseRs, pos, {6103000 + i, vac}) pos = pos + 1
				
		offset = offset + 8
		local usrCount = cfb_ascParse(c_rs, "touint", offset, 1, g_endian) offset = offset + 2
		offset = offset + (usrCount * 8)
	end
	for i = 1, 3 do
		local vai = cfb_ascParse(c_rs, "tofloat", offset, 4, g_endian) offset = offset + 8
--		showDebug("v ai " .. i .. ": " .. vai)
		table.insert(parseRs, pos, {6106001 + 1000*i, vai}) pos = pos + 1
	end
	return parseRs
end

function parse_rcai(c_rs)
	local parseRs = {}
	offset = 23
	local rcCount = cfb_ascParse(c_rs, "touint", offset, 1, g_endian) offset = offset + 2
	local pos = 1
	for i = 1,rcCount do
		local tmp = cfb_ascParse(c_rs, "tofloat", offset, 4, g_endian) offset = offset + 8
--		showDebug("rc cur: " .. tmp)
		table.insert(parseRs, pos, {6113000 + i, tmp}) pos = pos + 1
	
		offset = offset + 26
		
		tmp = cfb_ascParse(c_rs, "tofloat", offset, 4, g_endian) offset = offset + 32
--		showDebug("rc tmp: " .. tmp)
		table.insert(parseRs, pos, {6114000 + i, tmp}) pos = pos + 1
	end
	return parseRs
end


function isOnWork(num, type)
	if type == 1 then
		if num + 99999 == 0 then
			return nil
		end
	else 
	
	end
	return num
end

function showDebug(msg)
	if g_isdebug then
		print(msg)
	end
end

--设置控制命令参数
local ctl_args     --控制命令参数
function setWpack(args)
	local count = csb_getWvalueCount(args)
	print("count: " .. count)
	for i = 0, count do
		local tab = csb_getOneWvalueByIdx(args, i)
	end
	
	
end

--通过控制命令参数取得控制命令
function nextWpack(onePack)
	
end

initPollCmds(g_ver, g_adr)
print(#g_pollCmds)
--[[
local adrver = getVerAdr()
local ss = ""
for i = 1, #adrver do
	ss = ss .. string.format("%02X", adrver[i]) .. " "
end
print("adrver cmd: " .. ss)
initPollCmds(g_ver, g_adr)
for i = 1, #g_pollCmds do
	local dd = ""
	local cmd = g_pollCmds[i]
	for j = 1, #cmd do
		dd = dd .. string.format("%02X", cmd[j]) .. " "
	end
	print("adrver cmd: " .. dd)
end
]]

