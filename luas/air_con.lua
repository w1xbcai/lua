-- 科龙-特种空调通讯协议（CON-KS V3.0）.doc
local l_gb = require "gbModule"
local l_base = require "baseModule"
--[[ ]]
local c_so = require "cExtend"

local parse_addRs = c_so.parse_addRs
local pack_new = c_so.pack_new
local pack_addInfo = c_so.pack_addInfo
local parse_setNextPos = c_so.parse_setNextPos
local parse_setNeedLen = c_so.parse_setNeedLen
local parse_getPackInfo = c_so.parse_getPackInfo
local parse_new = c_so.parse_new
local parse_setStatus = c_so.parse_setStatus
local floatToBytes = c_so.floatToBytes

   
local g_ver = 0x21
local g_adr = 0x01

function luaInit(verLen, ver, adrLen, adr)
	if adrLen < 1 then
		return
	end
	if type(adr) == "string" then
		g_adr = tonumber(adr)
	else
		g_adr = adr 
	end 
end

function getCmd()
local rs = 
	{
		-- step1, 
		{
			pack = l_gb.pack(nil, g_ver, g_adr, 0x60, 0x50),
			parse = 
				{

				},
			delay = 500,
			needLen = 18,
		},
		{
			pack = l_gb.pack(nil, g_ver, g_adr, 0x60, 0x44),
			parse = 
				{
					{"BYTE", "J6"},
					{"SET", "U8", "lg_alarm_vol = rs"},
					{"SET", "U8", "lg_alarm_vol = lg_alarm_vol + rs"},
					{"SET", "U8", "lg_alarm_vol = lg_alarm_vol + rs"},
					{"BYTE", "NU", 15003001, "lg_alarm_vol > 0"},
					
					{"SET", "U8", "lg_alarm_cur = rs"},
					{"SET", "U8", "lg_alarm_cur = lg_alarm_cur + rs"},
					{"SET", "U8", "lg_alarm_cur = lg_alarm_cur + rs"},
					{"BYTE", "NU", 15002001, "lg_alarm_cur > 0"},
					
					{"SET", "U8", "lg_alarm_vol = lg_alarm_vol + rs"},
					{"SET", "U8", "lg_alarm_vol = lg_alarm_vol + rs"},
					{"SET", "U8", "lg_alarm_vol = lg_alarm_vol + rs"},
					{"SET", "U8", "lg_alarm_vol = lg_alarm_vol + rs"},
					{"SET", "U8", "lg_alarm_vol = lg_alarm_vol + rs"},
					{"BYTE", "NU", 15001001, "lg_alarm_vol + lg_alarm_cur > 0"},
					{"BYTE", "J21"},
				},
			delay = 500,
			needLen = 24,
		},
		-- step2, 
		{
			pack = l_gb.pack(nil, g_ver, g_adr, 0x60, 0x42),
			parse = 
				{
					{"BYTE", "J6"},
					{"BYTE", "U16", 15104001, "rs * 0.01"},
				--	{"BYTE", "U16", 15104002, "rs * 0.01"},
				--	{"BYTE", "U16", 15104003, "rs * 0.01"},
					{"BYTE", "J4"},
					
					{"BYTE", "U16", 15101001, "rs * 0.01"},
				--	{"BYTE", "U16", 15101002, "rs * 0.01"},
				--	{"BYTE", "U16", 15101003, "rs * 0.01"},
					{"BYTE", "J4"},
					{"BYTE", "J2"},
					
					{"BYTE", "U16", 15102001, "rs * 0.01"},
					{"BYTE", "J15"},
				},
			delay = 500,
			needLen = 30,
		},
	}
	return rs
end

local g_cmd = getCmd()

local g_step = 1
function nextPack(onePack)
	local allStep = #g_cmd
	if g_step >= allStep + 1 then
		pack_new(onePack, 101, 0, 0, 0);
		g_step = 1
	else
		local pack = g_cmd[g_step]
--		print("---->", g_step, #g_cmd, pack.needLen, pack.delay)
		pack_new(onePack, 101, pack.needLen, pack.delay, #pack.pack);
		for i = 1, #pack.pack do
			pack_addInfo(onePack, i, pack.pack[i]);
		end
		g_step = g_step + 1
		
	end
end

function parse(c_rs)
	local pack = parse_getPackInfo(c_rs)
	
	local nextPos, needLen = l_gb.checkPack(pack)
	parse_setNextPos(c_rs, nextPos)
	parse_setNeedLen(c_rs, needLen)
	if needLen ~= 0 then
		parse_setStatus(c_rs, 102)
		return
	else
		parse_setStatus(c_rs, 101)
	end
	table.remove(pack, 1)
	table.remove(pack, #pack)
	table.remove(pack, #pack)
	table.remove(pack, #pack)
	table.remove(pack, #pack)
	table.remove(pack, #pack)
	local packInfo = l_base.asc_to_hexstr(pack)
	l_base.printHexArr(packInfo, "Rx:")
	
	if g_step == 2 then
		-- init adr ver
		g_ver = packInfo[1]
		g_adr = packInfo[2]
		g_cmd = getCmd()
	else
		g_cmd = getCmd()
		local parseRs = {}
		l_base.parseScript(g_cmd[g_step - 1].parse, packInfo, parseRs)
		if #packInfo == 0 then
			parse_new(c_rs, #parseRs)
			for idx = 1, #parseRs do
				if parseRs[idx][2] == -99999999 then
					parse_addRs(c_rs, idx, parseRs[idx][1], parseRs[idx][2], 1)
				else
					parse_addRs(c_rs, idx, parseRs[idx][1], parseRs[idx][2], 0)
				end
			end
		else
			parse_setNeedLen(c_rs, 0)
			parse_setStatus(c_rs, 102)
			parse_new(c_rs, 0)
		end
	end
end

local g_setCmd
function setWpack(c_set)
--	g_setCmd = {}
	local count = set_getArgsCount(c_set)
	for idx = 1, count do
		local cmd =  set_getOneArgByIdx(c_set, idx)
		l_base.printStr("===================== AIR_CON CMD SET:[" .. cmd[1] .. "]=" .. cmd[2] .. "=====================")
		if(cmd[1] == 15202001) then
			table.insert(g_setCmd, getOpenAirCmd())
		elseif(cmd[1] == 15202001) then
			table.insert(g_setCmd, getCloseAirCmd())
		elseif(cmd[1] == 15301001) then
			table.insert(g_setCmd, getSetAirTempCmd(cmd[2]))
		else
			l_base.printStr("=====================UNKOWN AIR_CON CMD SET:[" .. cmd[1] .. "]=" .. cmd[2] .. "=====================")
		end
	end
end

local next_parse_formula 
function nextWpack(onePack)
	local cmd = table.remove(g_setCmd, 1)
	if cmd ~= nil then
		pack_new(onePack, 101, cmd.needLen, cmd.delay, #cmd.pack);
		for i = 1, #cmd.pack do
			pack_addInfo(onePack, i, cmd.pack[i]);
		end
		next_parse_formula = cmd.parse
	else
		pack_new(onePack, 100, 0, 0, 0);
	end
end

function parseW(c_rs)
	local pack = parse_getPackInfo(c_rs)

	local nextPos, needLen = l_gb.checkPack(pack)
	parse_setNextPos(c_rs, nextPos)
	parse_setNeedLen(c_rs, needLen)
	if needLen ~= 0 then
		parse_setStatus(c_rs, 102)
		return
	else
		parse_setStatus(c_rs, 101)
	end
	table.remove(pack, 1)
	table.remove(pack, #pack)
	table.remove(pack, #pack)
	table.remove(pack, #pack)
	table.remove(pack, #pack)
	table.remove(pack, #pack)
	local packInfo = l_base.asc_to_hexstr(pack)
	local parseRs = {}
	l_base.parseScript(next_parse_formula, packInfo, parseRs)
	if #packInfo == 0 then
		parse_new(c_rs, #parseRs)
		for idx = 1, #parseRs do
			parse_addRs(c_rs, idx, parseRs[idx][1], parseRs[idx][2], 0)
		end
	else
		parse_setNeedLen(c_rs, 0)
		parse_setStatus(c_rs, 102)
		parse_new(c_rs, 0)
	end
end

--开机 15201001
function getOpenAirCmd()
	local rs = 
	{
		pack = l_gb.pack({0x10}, g_ver, g_adr, 0x60, 0x45),
		parse = 
			{
				{"BYTE", "J3"},
				{"BYTE", "U8", 15201001, "rs == 0"},
				{"BYTE", "J2"},
			},
		delay = 500,
		needLen = 18,
	}
	return rs
end

--关机 15202001
function getCloseAirCmd()
	local rs = 
	{
		pack = l_gb.pack({0x1F}, g_ver, g_adr, 0x60, 0x45),
		parse = 
			{
				{"BYTE", "J3"},
				{"BYTE", "U8", 15201001, "rs == 0"},
				{"BYTE", "J2"},
			},
		delay = 500,
		needLen = 18,
	}
	return rs
end

--设置温度 18 -> 32 15301001
function getSetAirTempCmd(value)
	local a,b,c,d = floatToBytes(rs)
	local rs = 
	{
		pack = l_gb.pack({0x86, a, b, c, d}, g_ver, g_adr, 0x60, 0x49),
		parse = 
			{
				{"BYTE", "J3"},
				{"BYTE", "U8", 15201001, "rs == 0"},
				{"BYTE", "J2"},
			},
		delay = 500,
		needLen = 18,
	}
	return rs
end

