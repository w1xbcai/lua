-- 格力-基站空调通信协议V3.1.5 .doc
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
			pack = l_gb.pack(nil, g_ver, g_adr, 0x60, 0x43),
			parse = 
				{
					{"BYTE", "J13"},
					{"BYTE", "U8", 15001001, "rs == 0x81"},
				},
			delay = 500,
			needLen = 24,
		},
		-- step2, 
		{
			pack = l_gb.pack(nil, g_ver, g_adr, 0x60, 0x44),
			parse = 
				{
					{"BYTE", "J6"},
					{"SET", "U8", "lg_ua = rs"},
					{"SET", "U8", "lg_ub = rs"},
					{"SET", "U8", "lg_uc = rs"},
					{"BYTE", "NU", 15003001, "lg_ua == 0x81 or lg_ub == 0x81 or lg_uc == 0x81"},
					{"SET", "U8", "lg_ia = rs"},
					{"SET", "U8", "lg_ib = rs"},
					{"SET", "U8", "lg_ic = rs"},
					{"BYTE", "NU", 15002001, "lg_ia == 0x81 or lg_ib == 0x81 or lg_ic == 0x81"},
					{"BYTE", "J5"},
					{"SET", "U8", "lg_usrCount = rs"},
					{"SL", "NU", "lg_usrCount"},
						{"BYTE", "J1"},
					{"EL"},
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

local g_setCmd
function setWpack(c_set)
	g_setCmd = {}
	local count = set_getArgsCount(c_set)
	for idx = 1, count do
		local cmd =  set_getOneArgByIdx(c_set, idx)
		getLowOutputVolCmd(cmd[2], g_setCmd)
		print("SETCMDLEN", #g_setCmd)
	end
	
--	g_setCmd = getEqualizingChargeCmd(1)
end

function nextWpack(onePack)
	local cmd = table.remove(g_setCmd, 1)
	if cmd ~= nil then
		pack_new(onePack, 101, 18, 500, #cmd);
		for i = 1, #cmd do
			pack_addInfo(onePack, i, cmd[i]);
		end
	else
		pack_new(onePack, 100, 0, 0, 0);
	end
end

function parseW()

end

--开机 15201001
function openAir(value, rs)
	table.insert(rs, l_gb.pack({0x10}, g_ver, g_adr, 0x60, 0x45))
end

--关机 15202001
function openAir(value, rs)
	table.insert(rs, l_gb.pack({0x1F}, g_ver, g_adr, 0x60, 0x45))
end

--设置温度 18 -> 32
function openAir(value, rs)
	local tmp = tonumber(rs)
	table.insert(rs, l_gb.pack({0x86, 0x00, tmp}, g_ver, g_adr, 0x60, 0x45))
end

--制冷
function openAir(value, rs)
	local tmp = tonumber(rs)
	table.insert(rs, l_gb.pack({0x86, 0x00, tmp}, g_ver, g_adr, 0x60, 0x45))
	table.insert(rs, l_gb.pack({0xC0, 0x00, 0x01}, g_ver, g_adr, 0x60, 0x45))
end

--制热
function openAir(value, rs)
	local tmp = tonumber(rs)
	table.insert(rs, l_gb.pack({0x86, 0x00, tmp}, g_ver, g_adr, 0x60, 0x45))
	table.insert(rs, l_gb.pack({0xC0, 0x00, 0x04}, g_ver, g_adr, 0x60, 0x45))
end

