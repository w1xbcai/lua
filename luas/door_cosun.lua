--	高新兴-BASS-260-R门禁监控系统通讯协议（V2.0）-20140416.doc
--9600 数据格式：1起始位，8数据位，1停止位，校验方式：无校验；

local l_gb = require "gbModule"
local l_base = require "baseModule"
--[[  ]]
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
local timeDescToTimeT = c_so.timeDescToTimeT

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
			pack = l_gb.pack({0xF2, 0xE0}, g_ver, g_adr, 0x80, 0x4A),
			parse = 
				{

				},
			delay = 500,
			needLen = 24,
		},
		-- step2, 
		{
			pack = l_gb.pack({0xF4, 0x7F}, g_ver, g_adr, 0x80, 0x4A),
			parse = 
				{
					{"BYTE", "J7"},
					{"BYTE", "J48"},
					{"BYTE", "U8", 17102001, "rs > 0"},
					{"BYTE", "J5"},
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
	
	
	
	if g_step == 2 then
	--F1 E0 20 16 02 25 01 17 48 50
		if #packInfo == 16 then	
			local secFrom1970 = string.format("%02X", packInfo[9]) .. string.format("%02X", packInfo[10]) .. "-" 
			secFrom1970 = secFrom1970 .. string.format("%02X", packInfo[11]) .. "-"
			secFrom1970 = secFrom1970 .. string.format("%02X", packInfo[12]) .. " "
			secFrom1970 = secFrom1970 .. string.format("%02X", packInfo[13]) .. ":"
			secFrom1970 = secFrom1970 .. string.format("%02X", packInfo[14]) .. ":"
			secFrom1970 = secFrom1970 .. string.format("%02X", packInfo[15])
	--		print("time", secFrom1970)
			local devTimeSec = timeDescToTimeT(secFrom1970)
			parse_new(c_rs, 1)
			parse_addRs(c_rs, 1, 17103001, devTimeSec, 0)
			return
		end
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
		end
		return
	end
	parse_setNeedLen(c_rs, 0)
	parse_setStatus(c_rs, 102)
	parse_new(c_rs, 0)
end

local g_setCmd
function setWpack(c_set)
--	g_setCmd = {}
	local count = set_getArgsCount(c_set)
	for idx = 1, count do
		local cmd =  set_getOneArgByIdx(c_set, idx)
		l_base.printStr("===================== DOOR_COSUN CMD SET:[" .. cmd[1] .. "]=" .. cmd[2] .. "=====================")
		if(cmd[1] == 17201001) then
			table.insert(g_setCmd, getOpenDoorCmd())
		elseif(cmd[1] == 17202001) then
			table.insert(g_setCmd, getSyncTimeCmd(cmd[2]))
		else
			l_base.printStr("=====================UNKOWN DOOR_COSUN CMD SET:[" .. cmd[1] .. "]=" .. cmd[2] .. "=====================")
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

--远程开门		17201001
function getOpenDoorCmd()
	local va = value
	local rs = 
	{
		pack = l_gb.pack({0xF1, 0xED, 0x01}, g_ver, g_adr, 0x80, 0x49),
		parse = 
			{
				{"BYTE", "J3"},
				{"BYTE", "U8", 17201001, "rs == 0"},
				{"BYTE", "J2"},
			},
		delay = 500,
		needLen = 18,
	}
	return rs
end

--时钟同步		17202001
function getSyncTimeCmd(value)
	local va = value
	local rs = 
	{
		pack = l_gb.pack({0x1F}, g_ver, g_adr, 0x64, 0x45),
		parse = 
			{
				{"BYTE", "J3"},
				{"BYTE", "U8", 17202001, "rs == 0"},
				{"BYTE", "J2"},
			},
		delay = 500,
		needLen = 18,
	}
	return rs
end