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

local g_step = 1
local g_adr = 1
local g_stat = 101

local g_CT = 1
local g_PT = 1

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

function modbusPack(tab)
	local check = l_base.getCrc_A001(tab, 1, #tab)
	l_base.tableadd(tab, (check >> 8) & 0xFF) 
	l_base.tableadd(tab, (check & 0xFF))
	return tab
end

local g_pollCmds = {}
local g_needLen = {}
function initPollCmds()
	g_pollCmds = {}
	g_needLen = {}
	local cmd1 = {g_adr, 0x03, 0x03, 0x00, 0x00, 0x0A}
	local cmd2 = {g_adr, 0x03, 0x00, 0x00, 0x00, 0x29}
	table.insert(g_pollCmds, 1, modbusPack(cmd1))
	table.insert(g_pollCmds, 2, modbusPack(cmd2))
	g_needLen = {25, 87}
end

function nextPack(c_onePack)
	if #g_pollCmds == 0 then
		initPollCmds(g_adr)
	end
	if g_step >= #g_pollCmds + 1 then
		pack_new(c_onePack, 101, 23, 12, 0);
		g_step = 1
	else
		local pack = g_pollCmds[g_step]
		-- 41 = 3 + 0x29 * 2 + 2
		pack_new(c_onePack, g_stat, g_needLen[g_step], 500, #pack);
		for i = 1, #pack do
			pack_addInfo(c_onePack, i, pack[i]);
		end
		g_step = g_step + 1
	end
end

local modbusMinResLen = 5
function checkModbusReadPack(c_rs, info, g_adr)
	local len = #info
	if len < modbusMinResLen or info[1] ~= g_adr or info[2] ~= 0x03 then
		parse_setNextPos(c_rs, len)
		parse_setNeedLen(c_rs, modbusMinResLen)
		return 102
	end
	local needLen = (info[3] & 0xFF)
--	print("needLen" .. needLen)
	if needLen + 5 > len then
		parse_setNextPos(c_rs, 0)
		parse_setNeedLen(c_rs, needLen + 5 - len)
		return 103
	end
	local crc = l_base.getCrc_A001(info, 1, #info - 2)
	local calc = (info[len - 1] & 0xFF) << 8
	calc = calc  + (info[len]&0xFF)
--	print("crc: " .. crc .. "  calc: " .. calc)
	if crc ~= calc then
		parse_setNextPos(c_rs, len)
		parse_setNeedLen(c_rs, modbusMinResLen)
		return 102
	end
	parse_setNextPos(c_rs, len)
	parse_setNeedLen(c_rs, 0)
	return 101
end

function parse(c_rs)
	local info = parse_getPackInfo(c_rs)
	--printArr(info)
	local checkrs = checkModbusReadPack(c_rs, info, g_adr)
	parse_setStatus(c_rs, checkrs)
	--print("check " .. checkrs)
	if checkrs == 101 then
		if g_step == 2 then
			parseCtPt(c_rs, info)
		elseif g_step == 3 then
			parseAi(c_rs, info)
		else
			parse_new(c_rs, 0)
		end
	end
end

--01 03 14 00 01 00 00 00 01 00 00 00 03 00 01 00 00 00 01 00 00 00 01 A1 4F
function parseCtPt(c_rs, tab)
	if #tab ~= 25 then
		parse_new(c_rs, 0)
		return
	end
	g_PT = ((tab[18] & 0xFF) << 8) | (tab[19] & 0xFF)
	g_CT = ((tab[22] & 0xFF) << 8) | (tab[23] & 0xFF)
--	print("gPT: " .. g_PT .. " g_CT: " .. g_CT)
	parse_new(c_rs, 0)
end

--[[
线电压Uab	6101001 线电压Ubc	6102001 线电压Uca	6103001
A相电压Ua		6104001 B相电压Ub		6105001 C相电压Uc		6106001
A相电流Ia		6107001 B相电流Ib		6108001 C相电流Ic		6109001
零序电流Io	6110001
A相有功功率Pa	6111001 B相有功功率Pb	6112001 C相有功功率Pc	6113001
A相无功功率Qa	6114001 B相无功功率Qb	6115001 C相无功功率Qc	6116001
功率因数PF	6117001 频率F		6118001
正向有功电能	6119001
正向无功电能	6120001
]]
--01 03 52 58 27 9A 54 1D D2 B8 0A 01 A6 26 5B 00 2B 03 5D 5F 0C 9A F3 0F B7 B8 0A 00 ED 25 FB 00 20 01 E9 56 D5 9C 93 16 D3 B8 0A 01 3E 26 57 00 2F 02 89 00 00 5A 01 16 C7 B8 0A 03 D1 26 2E 00 7A 07 CF 00 00 5D 5A 00 20 00 00 00 00 C0 41 00 04 F4 19 00 03 23 F4 
function parseAi(c_rs, pack)
	if #pack ~= 87 then
		parse_new(c_rs, 0)
		return
	end
	local codes = {6101001, 6104001, 6107001, 6111001, 6114001, 
				   6102001, 6105001, 6108001, 6112001, 6115001,
				   6103001, 6106001, 6109001, 6113001, 6116001,
				   6110001, 6118001, 6117001}
	local offset = 4
	-- some ammeter 从0309中读出的CT值要乘以10，再做作为CT来用
	g_CT = g_CT * 10
	local V_formula	= g_PT * 0.01
	local I_formula = g_CT * 0.0001
	local HZ_formula = 0.00106813
	local PF_formula = 0.0001
	local WQ_formula = g_PT * g_CT * 0.4
	local S_formula = g_PT * g_CT * 0.2
	local wh_formula = g_PT * g_CT
	local rate = {V_formula, V_formula, I_formula, WQ_formula, WQ_formula,
				  V_formula, V_formula, I_formula, WQ_formula, WQ_formula,
				  V_formula, V_formula, I_formula, WQ_formula, WQ_formula,
				  I_formula, HZ_formula, PF_formula}
	parse_new(c_rs, 18)
	for i = 1, 18 do 
		local rs
		if (i==4 or i==5 or i==9 or i ==10 or i==14 or i==15 or i==18) then
			rs = ((pack[offset]) << 8) | (pack[offset + 1] & 0xFF)	
		else
			rs = ((pack[offset] & 0xFF) << 8) | (pack[offset + 1] & 0xFF)
		end	 
		rs = rs * rate[i]
		parse_addRs(c_rs, i, codes[i], rs, 1)
		
		offset = offset + 2
		if (i == 3 or i == 4 or i == 5 or i == 8 or i == 9 or i == 10
			or i == 13 or i == 14 or i == 15 or i == 17) then
			offset = offset + 2
		end
		if (i == 16) then
			offset = offset + 4
		end
	end
end

function printArr(cmd)
	local dd = ""
	for j = 1, #cmd do
		dd = dd .. string.format("%02X", (cmd[j]&0xFF)) .. " "
	end
	print(dd)
end

