--美的-移动通信定制网络空调异步通信规则(版本号 V13 2015.01.14 )(JZ1,JH1SN系列 适用DCM4).pdf
--波特率： 600BPS 起始位： 1BIT （低电平）数据位： 8BIT 奇偶校验： 偶校验 结束位： 2BIT （高电平）

local l_midea = require "mideaModule"
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

local g_DestAdr = 0xA1

function luaInit(verLen, ver, adrLen, adr)
	if adrLen < 1 then
		return
	end
	if type(adr) == "string" then
		g_DestAdr = tonumber(adr)
	else
		g_DestAdr = adr 
	end 
end

function getCmd()
local rs = 
	{
		-- step1, 
		{
			pack = l_midea.pack({0xC2, 0,0,0,0,0,0,0,0}, g_DestAdr),
			parse = 
				{
					{"BYTE", "J6"},
					{"BYTE", "U8", 15102001},
					{"BYTE", "J2"},
					{"SET", "U8", "lg_air_alarm = rs"},
					{"SET", "U8", "lg_air_alarm = lg_air_alarm + rs"},
					{"SET", "U8", "lg_air_alarm = lg_air_alarm + rs"},
					{"BYTE", "NU", 15001001, "lg_air_alarm > 0"},
					{"BYTE", "J2"},
				},
			delay = 500,
			needLen = 14,
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
	local packInfo = parse_getPackInfo(c_rs)
	
	local nextPos, needLen = l_midea.checkPack(packInfo)
	parse_setNextPos(c_rs, nextPos)
	parse_setNeedLen(c_rs, needLen)
	if needLen ~= 0 then
		parse_setStatus(c_rs, 102)
		return
	else
		parse_setStatus(c_rs, 101)
	end
	
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
		pack_new(onePack, 101, 14, 500, #cmd);
		for i = 1, #cmd do
			pack_addInfo(onePack, i, cmd[i]);
		end
	else
		pack_new(onePack, 100, 0, 0, 0);
	end
end

function parseW()

end

--开机 15201001 A1 21 14 00 00 00 00 00
function openAir(value, rs)
	table.insert(rs, l_midea.pack({0xC4, 0xA1,0x21,0x14,0,0,0,0,0}, g_DestAdr))
end

--关机 15202001  A1 21 1B 00 81 00 00 00
function openAir(value, rs)
	table.insert(rs, l_midea.pack({0xC4, 0xA1,0x21,0x1B,0,0x81,0,0,0}, g_DestAdr))
end

--设置温度 18 -> 32
function openAir(value, rs)
	local tmp = tonumber(rs)
	table.insert(rs, l_midea.pack({0xC4, 0xA1,0x21,tmp,0,0,0,0,0}, g_DestAdr))
end

--制冷
function openAir(value, rs)
	local tmp = tonumber(rs)
	table.insert(rs, l_midea.pack({0xC4, 0xA1,0x21,tmp,0,0,0,0,0}, g_DestAdr))
end

--制热
function openAir(value, rs)
	local tmp = tonumber(rs)
	table.insert(rs,  l_midea.pack({0xC4, 0xA1,0x22,tmp,0,0,0,0,0}, g_DestAdr))

end

