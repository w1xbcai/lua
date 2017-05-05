--	海特温控-机柜空调机柜热交换器接口协议20141010A.pdf

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

local g_ver = 0x20
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
		-- step1, 热交换器 开关输入状态
		{
			pack = l_gb.pack(nil, g_ver, g_adr, 0x64, 0x43),
			parse = 
				{
					{"BYTE", "J10"},
					{"BYTE", "U8", 25004001},
					{"BYTE", "J1"},
				},
			delay = 500,
			needLen = 24,
		},
		-- step2, 
		{
			pack = l_gb.pack(nil, g_ver, g_adr, 0x64, 0x44),
			parse = 
				{
					{"BYTE", "J7"},
					{"SET", "U8", "lg_heat_alarm = rs"},
					{"SET", "U8", "lg_heat_alarm = lg_heat_alarm + rs"},
					{"SET", "U8", "lg_heat_alarm = lg_heat_alarm + rs"},
					{"SET", "U8", "lg_heat_alarm = lg_heat_alarm + rs"},
					{"SET", "U8", "lg_heat_alarm = lg_heat_alarm + rs"},
					{"SET", "U8", "lg_heat_alarm = lg_heat_alarm + rs"},
					{"SET", "U8", "lg_heat_alarm = lg_heat_alarm + rs"},
					{"SET", "U8", "lg_heat_alarm = lg_heat_alarm + rs"},
					{"SET", "U8", "lg_heat_alarm = lg_heat_alarm + rs"},
					{"BYTE", "NU", 25002001, "lg_heat_alarm > 0"},
					{"BYTE", "J1"},
				},
			delay = 500,
			needLen = 30,
		},
		{
			pack = l_gb.pack(nil, g_ver, g_adr, 0x60, 0x42),
			parse = 
				{
					{"BYTE", "J7"},
					{"BYTE", "U16", 25103001, "rs * 0.01"},
					{"BYTE", "U16", 25101001, "rs * 0.01"},
					{"BYTE", "J4"},
				},
			delay = 500,
			needLen = 30,
		},
		{
			pack = l_gb.pack(nil, g_ver, g_adr, 0x60, 0x43),
			parse = 
				{
					{"BYTE", "J7"},
					{"BYTE", "U8", 25004001},
					{"BYTE", "J3"},
				},
			delay = 500,
			needLen = 30,
		},
		{
			pack = l_gb.pack(nil, g_ver, g_adr, 0x60, 0x44),
			parse = 
				{
					{"BYTE", "J7"},
					{"SET", "U8", "lg_air_alarm = rs"},
					{"SET", "U8", "lg_air_alarm = lg_air_alarm + rs"},
					{"SET", "U8", "lg_air_alarm = lg_air_alarm + rs"},
					{"SET", "U8", "lg_air_alarm = lg_air_alarm + rs"},
					{"SET", "U8", "lg_air_alarm = lg_air_alarm + rs"},
					{"SET", "U8", "lg_air_alarm = lg_air_alarm + rs"},
					{"SET", "U8", "lg_air_alarm = lg_air_alarm + rs"},
					{"BYTE", "NU", 25004001, "lg_air_alarm > 0"},
					{"BYTE", "J1"},
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
		pack_new(onePack, 101, pack.needLen, pack.delay, #pack.pack)
		for i = 1, #pack.pack do
			pack_addInfo(onePack, i, pack.pack[i])
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
	g_cmd = getCmd()
	local parseRs = {}
--	l_base.printHexArr(packInfo, "Rx2:")
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

local g_setCmd = {}
function setWpack(c_set)
--	g_setCmd = {}
	local count = set_getArgsCount(c_set)
	for idx = 1, count do
		local cmd =  set_getOneArgByIdx(c_set, idx)
		l_base.printStr("=====================HAYDEN_THERMAL CMD SET:[" .. cmd[1] .. "]=" .. cmd[2] .. "=====================")
		if(cmd[1] == 25301001) then
			table.insert(g_setCmd, setRunTempCmd(cmd[2]))
		else
			l_base.printStr("=====================UNKOWN HAYDEN_THERMAL CMD SET:[" .. cmd[1] .. "]=" .. cmd[2] .. "=====================")
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


--设备运行温度设置 25301001   22
function setRunTempCmd(value)
	local temp = value * 100
	local rs = 
	{
		pack = l_gb.pack({0x80, (temp >> 8) & 0xFF, tmep & 0xFF}, g_ver, g_adr, 0x60, 0x49),
		parse = 
			{
				{"BYTE", "J3"},
				{"BYTE", "U8", 25301001, "rs == 0"},
				{"BYTE", "J2"},
			},
		delay = 500,
		needLen = 18,
	}
	return rs
end

--开机 25201001
function setOpenThermalCmd(value)
	local rs = 
	{
		pack = l_gb.pack({0x10}, g_ver, g_adr, 0x64, 0x45),
		parse = 
			{
				{"BYTE", "J3"},
				{"BYTE", "U8", 25301001, "rs == 0"},
				{"BYTE", "J2"},
			},
		delay = 500,
		needLen = 18,
	}
	return rs
end

--关机 25201001
function setCloseThermalCmd(value)
	local temp = value * 100
	local rs = 
	{
		pack = l_gb.pack({0x1F}, g_ver, g_adr, 0x64, 0x45),
		parse = 
			{
				{"BYTE", "J3"},
				{"BYTE", "U8", 25201001, "rs == 0"},
				{"BYTE", "J2"},
			},
		delay = 500,
		needLen = 18,
	}
	return rs
end