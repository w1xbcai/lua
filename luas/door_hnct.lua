
--	河南传通电子-智能门禁通信协议V1.1（更新日期15年04月22日）.pdf
--通信参数：9600，N,8,1,NO

local l_hnct = require "hnctModule"
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

local pwd = 9999
local machineNum = 0

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
			pack = l_hnct.pack(nil, machineNum, 0, 1, 0, pwd),
			parse = 
				{
	
				},
			delay = 500,
			needLen = 73,
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

	local nextPos, needLen = l_hnct.checkPack(pack, pwd)
	parse_setNextPos(c_rs, nextPos)
	parse_setNeedLen(c_rs, needLen)
	
	if needLen ~= 0 then
		parse_setStatus(c_rs, 102)
		return
	else
		parse_setStatus(c_rs, 101)
	end
	
	if g_step == 2 then
	--F1 E0 20 16 02 25 01 17 48 50
		if #pack == 73 then	
			l_base.printHexArr(pack, "rx2:")
			local offset = 7
			local secFrom1970 = "20" .. tostring(pack[offset + 1]) .. "-"
			secFrom1970 = secFrom1970 .. tostring(pack[offset + 2]) .. "-"
			secFrom1970 = secFrom1970 .. tostring(pack[offset + 3]) .. " "
			secFrom1970 = secFrom1970 .. tostring(pack[offset + 5]) .. ":"
			secFrom1970 = secFrom1970 .. tostring(pack[offset + 6]) .. ":"
			secFrom1970 = secFrom1970 .. tostring(pack[offset + 7])
			print("time", secFrom1970)
			local devTimeSec = timeDescToTimeT(secFrom1970)
			parse_new(c_rs, 3)
			parse_addRs(c_rs, 1, 17103001, devTimeSec, 0)
			local doorContact = pack[offset + 8] & 0xFF
			parse_addRs(c_rs, 2, 17101001, doorContact, 0)
			local lockStat = pack[offset + 9] & 0xFF
			parse_addRs(c_rs, 3, 17102001, lockStat, 0)
			return
		end
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
		l_base.printStr("===================== DOOR_HNCT CMD SET:[" .. cmd[1] .. "]=" .. cmd[2] .. "=====================")
		if(cmd[1] == 17201001) then
			table.insert(g_setCmd, getOpenDoorCmd())
		elseif(cmd[1] == 17202001) then
			table.insert(g_setCmd, getSyncTimeCmd(cmd[2]))
		else
			l_base.printStr("=====================UNKOWN DOOR_HNCT CMD SET:[" .. cmd[1] .. "]=" .. cmd[2] .. "=====================")
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

function parseW()
	local packInfo = parse_getPackInfo(c_rs)

	local nextPos, needLen = l_hnct.checkPack(packInfo, pwd)
	parse_setNextPos(c_rs, nextPos)
	parse_setNeedLen(c_rs, needLen)
	
	if needLen ~= 0 then
		parse_setStatus(c_rs, 102)
		return
	else
		parse_setStatus(c_rs, 101)
	end
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
		pack = l_hnct.pack(nil, machineNum, 7, 0, 0, pwd),
		parse = 
			{
				{"BYTE", "J4"},
				{"BYTE", "U8", 17201001, "rs == 0xAA"},
				{"BYTE", "J68"},
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
		pack = l_hnct.pack({0xF1, 0xE0}, g_ver, g_adr, 0x80, 0x49),
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
