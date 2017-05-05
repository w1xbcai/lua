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

local g_step = 1
local g_stat = 101
local g_ver = 0x21
local g_adr = 0x01

function luaInit(verLen, ver, adrLen, adr)

end

local g_pollCmds = {}
function initPollCmds()
	g_pollCmds = {}
	table.insert(g_pollCmds, 1, l_gb.pack(nil, g_ver, g_adr, 0xD0, 0x50))
	-表25	查询定位信息命令信息
	table.insert(g_pollCmds, 2, l_gb.pack(nil, g_ver, g_adr, 0xD0, 0x90))
	--11.7 查询模块振动告警信息
	table.insert(g_pollCmds, 3, l_gb.pack(nil, g_ver, g_adr, 0xD0, 0x92))
	--表37	查询塔身监测信息命令信息
	table.insert(g_pollCmds, 4, l_gb.pack(nil, g_ver, g_adr, 0xD0, 0xA1))
	--表40	查询大气环境信息命令信息
	table.insert(g_pollCmds, 4, l_gb.pack(nil, g_ver, g_adr, 0xD0, 0xA2))
	--表43	查询气象信息命令信息
	table.insert(g_pollCmds, 4, l_gb.pack(nil, g_ver, g_adr, 0xD0, 0xA3))
end

function nextPack(onePack)
	if #g_pollCmds == 0 then
		initPollCmds()
	end
	if g_step >= #g_pollCmds + 1 then
		pack_new(onePack, 101, 0, 0, 0);
		g_step = 1
	else
		local pack = g_pollCmds[g_step]
		pack_new(onePack, g_stat, 24, 500, #pack);
		for i = 1, #pack do
			pack_addInfo(onePack, i, pack[i]);
		end
		g_step = g_step + 1
	end	
end

function getGbCheck(tab)
	local sum = 0
	for idx = 2, #tab - 5, 1 do
		sum = sum + (tab[idx] & 0xFF)
	end
	sum = sum & 0xffff
    sum = ~sum
    sum = sum & 0xffff
    sum = sum + 1
	return sum
end

local g_gb_min_len = 18
function checkGbPack(c_rs, pack)
	local packLen = #pack
	
	if packLen < g_gb_min_len then
		parse_setNextPos(c_rs, 0)
		parse_setNeedLen(c_rs, g_gb_min_len)
		return 102
	end
	
	if ((string.format("%02X", (pack[1]&0xFF)) ~= "7E")) then
		parse_setNextPos(c_rs, packLen)
		parse_setNeedLen(c_rs, g_gb_min_len)
		return 102
	end
	
	local infoLenBytes = l_base.asc_to_hexstr({pack[10],pack[11],pack[12],pack[13]})
	local infoLenCalc = ((infoLenBytes[1] & 0xF) << 8) | infoLenBytes[2]
	if infoLenCalc + g_gb_min_len > packLen then
		parse_setNextPos(c_rs, 0)
		parse_setNeedLen(c_rs, infoLenCalc + g_gb_min_len - packLen)
		return 103
	end

	if ((string.format("%02X", (pack[infoLenCalc + 18]&0xFF)) ~= "0D")) then
		parse_setNextPos(c_rs, packLen)
		parse_setNeedLen(c_rs, g_gb_min_len)
		return 102
	end
	
	local calcCheck = getGbCheck(pack)
	local readCheckByte = l_base.asc_to_hexstr({pack[packLen - 4],pack[packLen - 3],pack[packLen - 2],pack[packLen - 1]})
	local readCheck = ((readCheckByte[1]) << 8) | readCheckByte[2]
	
--	print("check:", calcCheck, readCheck)
	if calcCheck ~= readCheck then
		parse_setNextPos(c_rs, packLen)
		parse_setNeedLen(c_rs, g_gb_min_len)
		return 102
	end
	
	parse_setNextPos(c_rs, packLen)
	parse_setNeedLen(c_rs, 0)
	return 101
end

function parse(c_rs)
	local pack = parse_getPackInfo(c_rs)
	local checkrs = checkGbPack(c_rs, pack)
	parse_setStatus(c_rs, checkrs)
	if checkrs == 101  then
		table.remove(pack, 1)
		table.remove(pack, #pack)
		table.remove(pack, #pack)
		table.remove(pack, #pack)
		table.remove(pack, #pack)
		table.remove(pack, #pack)
		local packInfo = l_base.asc_to_hexstr(pack)
		if g_step == 2 then
			setVerAndAdr(c_rs, packInfo)
		elseif g_step == 3 then
			getSiteInfo(c_rs, packInfo)
		elseif g_step == 4 then
			checkShakeAlarm(c_rs, packInfo)
		elseif g_step == 5 then
			getTowerInfo(c_rs, packInfo)
		elseif g_step == 6 then
			getAirEnv(c_rs, packInfo)
		elseif g_step == 7 then
			getWeatherInfo(c_rs, packInfo)
		else
			parse_new(c_rs, 0)
		end
	end
	g_step = g_step + 1
end

function setVerAndAdr(c_rs, info)
	parse_new(c_rs, 0)
	g_ver = info[1]
	g_adr = info[2]
end

--[[
AGPS有效标识	37010001
经度	37111001
纬度	37112001
海拔	37113001
]]
function getSiteInfo(c_rs, info)
--	if #info ~= 21 then
--		parse_new(c_rs, 0)
--		return
--	end
	local ver = info[1]
	local adr = info[2]
	local cid1 = info[3]
	local cid2 = info[4]
	
	local offset = 7
	parse_new(c_rs, 4)
	parse_addRs(c_rs, 1, 37010001, info[offset], 1)
	offset = offset + 1
	
	local rs = l_base.fourBytesToInt({info[offset], info[offset+1], info[offset+2], info[offset+3]})
	rs = rs * 0.0001
	parse_addRs(c_rs, 2, 37111001, rs, 1)
	offset = offset + 4
	
	rs = l_base.fourBytesToInt({info[offset], info[offset+1], info[offset+2], info[offset+3]})
	rs = rs * 0.0001
	parse_addRs(c_rs, 3, 37112001, rs, 1)
	offset = offset + 4
	
	rs = l_base.twoBytesToInt({info[offset], info[offset+1]})
	parse_addRs(c_rs, 4, 37113001, rs, 1)
end

--[[
塔身振动幅度告警	37016001
塔身振动告警		37017001
]]
function checkShakeAlarm(c_rs, info)
--	if #info ~= 23 then
--		parse_new(c_rs, 0)
--		return
--	end
	local ver = info[1]
	local adr = info[2]
	local cid1 = info[3]
	local cid2 = info[4]
	
	local offset = 7
	parse_new(c_rs, 4)
	parse_addRs(c_rs, 1, 37016001, info[offset], 1)
	offset = offset + 1
	
	local rs = l_base.twoBytesToUint({info[offset], info[offset+1]})
	rs = rs * 0.1
	parse_addRs(c_rs, 2, 37017001, rs, 1)
	offset = offset + 2
	
end

--[[
塔身倾斜度告警	7015001
塔身振动幅度	7102001
塔身振动频率	7103001
]]
function getTowerInfo(c_rs, info)
--	if #info ~= 16 then
--		parse_new(c_rs, 0)
--		return
--	end
	local ver = info[1]
	local adr = info[2]
	local cid1 = info[3]
	local cid2 = info[4]
	
	local offset = 7
	parse_new(c_rs, 3)

	local rs = l_base.twoBytesToUint({info[offset], info[offset+1]})
	rs = rs * 0.1
	parse_addRs(c_rs, 1, 7015001, rs, 1)
	offset = offset + 2
	
	rs = l_base.twoBytesToUint({info[offset], info[offset+1]})
	rs = rs * 0.1
	parse_addRs(c_rs, 2, 7102001, rs, 1)
	offset = offset + 2
	
	rs = l_base.twoBytesToUint({info[offset], info[offset+1]})
	parse_addRs(c_rs, 3, 7103001, rs, 1)
	offset = offset + 2
end

--大气环境PM2.5	37104001
function getAirEnv(c_rs, info)
--	if #info ~= 14 then
--		parse_new(c_rs, 0)
--		return
--	end
	local ver = info[1]
	local adr = info[2]
	local cid1 = info[3]
	local cid2 = info[4]
	
	local offset = 7
	parse_new(c_rs, 1)

	local rs = l_base.fourBytesToUint({info[offset], info[offset+1], info[offset+2], info[offset+3]})
	rs = rs * 0.1
	parse_addRs(c_rs, 1, 37104001, rs, 1)
end

--[[
环境温度	7105001
湿度	 	7106001
风速		7107001
风向		7108001
]]
function getWeatherInfo(c_rs, info)
--	if #info ~= 18 then
--		parse_new(c_rs, 0)
--		return
--	end
	local ver = info[1]
	local adr = info[2]
	local cid1 = info[3]
	local cid2 = info[4]
	
	local offset = 7
	parse_new(c_rs, 4)

	local rs = l_base.twoBytesToInt({info[offset], info[offset+1]})
	rs = rs * 0.5
	parse_addRs(c_rs, 1, 7105001, rs, 1)
	offset = offset + 2
	
	rs = l_base.twoBytesToUint({info[offset], info[offset+1]})
	parse_addRs(c_rs, 2, 7106001, rs, 1)
	offset = offset + 2
	
	rs = l_base.twoBytesToUint({info[offset], info[offset+1]})
	parse_addRs(c_rs, 3, 7107001, rs, 1)
	offset = offset + 2
	
	rs = l_base.twoBytesToUint({info[offset], info[offset+1]})
	parse_addRs(c_rs, 4, 7108001, rs, 1)
	offset = offset + 2
end

--[[
DGPS有效标识	37014001
经度修正数	37115001
纬度修正数	37116001
海拔修正数		37117001
]]
function getModuleCfg(c_rs, info)
--	if #info ~= 25 then
--		parse_new(c_rs, 0)
--		return
--	end
	local ver = info[1]
	local adr = info[2]
	local cid1 = info[3]
	local cid2 = info[4]
	
	local offset = 10
	parse_new(c_rs, 4)
	parse_addRs(c_rs, 1, 37014001, 1, 1)
	
	local rs = l_base.fourBytesToInt({info[offset], info[offset+1], info[offset+2], info[offset+3]})
	rs = rs * 0.000001;
	parse_addRs(c_rs, 1, 37115001, 1, 1)
	offset = offset + 4
	
	rs = l_base.fourBytesToInt({info[offset], info[offset+1], info[offset+2], info[offset+3]})
	rs = rs * 0.000001;
	parse_addRs(c_rs, 2, 37116001, 1, 1)
	offset = offset + 4
	
	rs = l_base.fourBytesToUint({info[offset], info[offset+1], info[offset+2], info[offset+3]})
	rs = rs * 0.000001;
	parse_addRs(c_rs, 3, 37117001, 1, 1)
	offset = offset + 4
end
