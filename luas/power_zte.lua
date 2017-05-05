--中兴-ZXDU68T601(V5.0R01M01)YDT-1363通讯协议(铁塔).doc

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
		-- step1, get ver adr
		{
			pack = l_gb.pack(nil, g_ver, g_adr, 0x40, 0x50),
			parse = 
				{
				},
			delay = 500,
			needLen = 18,
		},
		-- -- step2, get time
		{
			pack = l_gb.pack(nil, g_ver, g_adr, 0x40, 0x4D),
			parse = 
				{
				},
			delay = 500,
			needLen = 24,
		 },
		-- step2, ac_ai
		{
			pack = l_gb.pack({0xFF}, g_ver, g_adr, 0x40, 0x42),
			parse = 
				{
					{"BYTE", "J7"},
					{"SET", "U8", "lg_acCount = rs"},
					{"SL", "NU", "lg_acCount"},
						{"SET", "U8", "lg_acInputCount = rs"},
						{"SL", "NU", "lg_acInputCount"},
							{"BYTE", "U16", 6101001, "rs * 0.01"},
							{"BYTE", "U16", 6102001, "rs * 0.01"},
							{"BYTE", "U16", 6103001, "rs * 0.01"},
							{"BYTE", "U16", 6110001, "rs * 0.01"},
							{"BYTE", "J1"},
						{"EL"},
						{"BYTE", "U16", 6107001, "rs * 0.01"},
						{"BYTE", "U16", 6108001, "rs * 0.01"},
						{"BYTE", "U16", 6109001, "rs * 0.01"},
					{"EL"},
				},
			delay = 500,
			needLen = 30,
		},
		--step3, ac_alarm
		{
			pack = l_gb.pack({0xFF}, g_ver, g_adr, 0x40, 0x44),
			parse = 
				{
					{"BYTE", "J7"},
					{"SET", "U8", "lg_acCount = rs"},
					{"SL", "NU", "lg_acCount"},
						{"BYTE", "J7"},
						{"BYTE", "U8", 6022001, "rs == 0xE1"},
						{"BYTE", "J7"},
					{"EL"},
				},
			delay = 500,
			needLen = 30,
		},
		--step4, rc_ai
		{
			pack = l_gb.pack(nil, g_ver, g_adr, 0x41, 0x42),
			parse =
				{
					{"BYTE", "J9"},
					{"SET", "U8", "lg_rcCount = rs"},
					{"SL", "NU", "24"},
						{"BYTE", "U16", 6114001, "rs * 0.1", "0xFFFF"},
						{"BYTE", "J1"},
						{"BYTE", "U16", 6113001, "rs * 0.1", "0x8000"},
					{"EL"},
					{"SL", "NU", "lg_rcCount - 24"},
						{"BYTE", "J5"},
					{"EL"},
				},
			delay = 500,
			needLen = 30,
		},
		--step5, rc_alarm
		{
			pack = l_gb.pack(nil, g_ver, g_adr, 0x41, 0x44),
			parse =
				{
					{"BYTE", "J7"},
					{"SET", "U8", "lg_rcCount = rs"},
					{"SL", "NU", "24"},
						{"BYTE", "U8", 6024001, "rs == 1"},
						{"BYTE", "J1"},
						{"BYTE", "U8", 6028001, "rs == 1"},
					{"EL"},
					{"SL", "NU", "lg_rcCount - 24"},
						{"BYTE", "J3"},
					{"EL"},
				},
			delay = 500,
			needLen = 33,
		},
		--step6, dc_ai
		{
			pack = l_gb.pack(nil, g_ver, g_adr, 0x42, 0x42),
			parse =
				{
					{"BYTE", "J7"},
					{"SET", "U8", "lg_dcCount = rs"},
					{"SL", "NU", "lg_dcCount"},
						{"BYTE", "U16", 6111001, "rs * 0.1", "0xFFFFF"},
						{"BYTE", "U16", 6112001, "rs * 0.1", "0xFFFFF"},
						{"BYTE", "J20"},
					{"EL"},
				},
			delay = 500,
			needLen = 33,
		},
		--step7, dc_alarm
		{
			pack = l_gb.pack(nil, g_ver, g_adr, 0x42, 0x44),
			parse =
				{
					{"BYTE", "J7"},
					{"BYTE", "J3"},
					{"SL", "NU", "4"},
						{"BYTE", "U8", 6001001, "rs == 3"},
					{"EL"},
					{"SET", "U8", "lg_dcFuseCount = rs"},
					{"SL", "NU", "lg_dcFuseCount"},
						{"BYTE", "U8", 6007001, "rs == 3"},
					{"EL"},
					{"BYTE", "J2"},
					{"BYTE", "U8", 6030001, "rs == 0x80"},
					{"BYTE", "U8", 6031001, "rs == 0x80"},
					{"BYTE", "J51"},
				},
			delay = 500,
			needLen = 53,
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
		
--	l_base.printHexArr(packInfo, "Rx:")
	if g_step == 2 then
		-- init adr ver
		g_ver = packInfo[1]
		g_adr = packInfo[2]
		g_cmd = getCmd()
	elseif g_step == 3 then
		-- get time
		local offset = 7
		local getYear = ((packInfo[offset] << 8) | (packInfo[offset + 1] & 0xFF)) & 0xFFFF
		local secFrom1970 = tostring(getYear) .. "-"
		secFrom1970 = secFrom1970 .. tostring(packInfo[offset + 2]) .. "-"
		secFrom1970 = secFrom1970 .. tostring(packInfo[offset + 3]) .. " "
		secFrom1970 = secFrom1970 .. tostring(packInfo[offset + 4]) .. ":"
		secFrom1970 = secFrom1970 .. tostring(packInfo[offset + 5]) .. ":"
		secFrom1970 = secFrom1970 .. tostring(packInfo[offset + 6])
		print("time", secFrom1970)
		local devTimeSec = timeDescToTimeT(secFrom1970)
		parse_new(c_rs, 1)
		parse_addRs(c_rs, 1, 6121001, devTimeSec, 0)
	else
		local parseRs = {}
		l_base.parseScript(g_cmd[g_step - 1].parse, packInfo, parseRs)
		print("---------------------->", g_step - 1, #packInfo)
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

local g_setCmd = {}
function setWpack(c_set)
--	g_setCmd = {}
	local count = set_getArgsCount(c_set)
	for idx = 1, count do
		local cmd =  set_getOneArgByIdx(c_set, idx)
		l_base.printStr("=====================ZTE_POWER CMD SET:[" .. cmd[1] .. "]=" .. cmd[2] .. "=====================")
		if(cmd[1] == 6202001) then
			table.insert(g_setCmd, setHandleModeCmd())
			table.insert(g_setCmd, setEqualizingChargeCmd(cmd[2]))
			table.insert(g_setCmd, setAutoModeCmd())
		elseif(cmd[1] == 6303001) then
			table.insert(g_setCmd, setFloatVodCmd(cmd[2]))
		elseif(cmd[1] == 6310001) then
			table.insert(g_setCmd, setDcVolLowCmd(cmd[2]))
		elseif(cmd[1] == 6311001) then
			table.insert(g_setCmd, setDcVolHighCmd(cmd[2]))
		else
			l_base.printStr("=====================UNKOWN ZTE_POWER CMD SET:[" .. cmd[1] .. "]=" .. cmd[2] .. "=====================")
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

--设置均冲 6202001
function setEqualizingChargeCmd(value)
	local rs = 
	{
		pack = l_gb.pack({0x10, 0x00}, g_ver, g_adr, 0x41, 0x45),
		parse = 
			{
				{"BYTE", "J3"},
				{"BYTE", "U8", 6202001, "rs == 0"},
				{"BYTE", "J2"},
			},
		delay = 500,
		needLen = 18,
	}
	return rs
end

--设置成手动模式
function setHandleModeCmd()
	local rs = 
	{
		pack = l_gb.pack({0xE1}, g_ver, g_adr, 0xE1, 0x80),
		parse = 
			{
				{"BYTE", "J6"},
			},
		delay = 500,
		needLen = 18,
	}
	return rs
end

--恢复成自动模式
function setAutoModeCmd()
	local rs = 
	{
		pack = l_gb.pack({0xE0}, g_ver, g_adr, 0xE1, 0x80),
		parse = 
			{
				{"BYTE", "J6"},
			},
		delay = 500,
		needLen = 18,
	}
	return rs
end

----浮充电压设定值	6303001 F1H
function setFloatVodCmd(value)
	local va = value * 10
	local rs = 
	{
		pack = l_gb.pack({0x82, (va >> 8) & 0xFF, va & 0xFF}, g_ver, g_adr, 0x42, 0x49),
		parse = 
			{
				{"BYTE", "J3"},
				{"BYTE", "U8", 6303001, "rs == 0"},
				{"BYTE", "J2"},
			},
		delay = 500,
		needLen = 18,
	}
	return rs
end

--直流输出电压过低设定值 6310001
function setDcVolLowCmd(value)
	local va = value
	local rs = 
	{
		pack = l_gb.pack({0xA0, (va >> 8) & 0xFF, va & 0xFF}, g_ver, g_adr, 0x42, 0x84),
		parse = 
			{
				{"BYTE", "J3"},
				{"BYTE", "U8", 6310001, "rs == 0"},
				{"BYTE", "J2"},
			},
		delay = 500,
		needLen = 18,
	}
	return rs
end

--直流输出电压过高设定值 6311001 
function setDcVolHighCmd(value)
	local va = value
	local rs = 
	{
		pack = l_gb.pack({0x9F, (va >> 8) & 0xFF, va & 0xFF}, g_ver, g_adr, 0x42, 0x84),
		parse = 
			{
				{"BYTE", "J3"},
				{"BYTE", "U8", 6311001, "rs == 0"},
				{"BYTE", "J2"},
			},
		delay = 500,
		needLen = 18,
	}
	return rs
end

--[[
--整流模块XX远程开控制 6202001
function getOpenRcCmd(value, rs)
	--先设置成手动模式
	table.insert(rs, l_gb.pack({0xE1}, g_ver, g_adr, 0xE1, 0x80))
	table.insert(rs, l_gb.pack({0x20, value & 0xFF}, g_ver, g_adr, 0x41, 0x45))
	table.insert(rs, l_gb.pack({0x2F, value & 0xFF}, g_ver, g_adr, 0x41, 0x45))
	--恢复成自动模式
	table.insert(rs, l_gb.pack({0xE0}, g_ver, g_adr, 0xE1, 0x80))
end

--整流模块XX远程关控制 6202001
function getCloseRcCmd(value, rs)
	--先设置成手动模式
	table.insert(rs, l_gb.pack({0xE1}, g_ver, g_adr, 0xE1, 0x80))
	table.insert(rs, l_gb.pack({0x20, value & 0xFF}, g_ver, g_adr, 0x41, 0x45))
	--恢复成自动模式
	table.insert(rs, l_gb.pack({0xE0}, g_ver, g_adr, 0xE1, 0x80))
end

--直流输出电压过低设定值 6310001 81H或E1H或E4H
function getLowOutputVolCmd(value, rs)
	local a,b,c,d = floatToBytes(value)
	--先设置成手动模式
	table.insert(rs, l_gb.pack({0xE1}, g_ver, g_adr, 0xE1, 0x80))
	table.insert(rs, l_gb.pack({0x81, a, b, c, d}, g_ver, g_adr, 0x42, 0x48))
	--恢复成自动模式
	table.insert(rs, l_gb.pack({0xE0}, g_ver, g_adr, 0xE1, 0x80))
end

--直流输出电压过高设定值 6311001 80H或E0H或E3H
function getHighOutputVolCmd(value, rs)
	local a,b,c,d = floatToBytes(value)
	--先设置成手动模式
	table.insert(rs, l_gb.pack({0xE1}, g_ver, g_adr, 0xE1, 0x80))
	table.insert(rs, l_gb.pack({0x80,  a, b, c, d}, g_ver, g_adr, 0x42, 0x48))
	--恢复成自动模式
	table.insert(rs, l_gb.pack({0xE0}, g_ver, g_adr, 0xE1, 0x80))
end

--电池组充电过流告警点 6301001 E2H或E5H
function getBatteryOvercurrentCmd(value, rs)
	local a,b,c,d = floatToBytes(value)
	--先设置成手动模式
	table.insert(rs, l_gb.pack({0xE1}, g_ver, g_adr, 0xE1, 0x80))
	table.insert(rs, l_gb.pack({0xE2,  a, b, c, d}, g_ver, g_adr, 0x42, 0x48))
	--恢复成自动模式
	table.insert(rs, l_gb.pack({0xE0}, g_ver, g_adr, 0xE1, 0x80))
end

--温度补偿系数 6302001  F7H
function getTemCompensationCmd(value, rs)
	local a,b,c,d = floatToBytes(value)
	--先设置成手动模式
	table.insert(rs, l_gb.pack({0xE1}, g_ver, g_adr, 0xE1, 0x80))
	table.insert(rs, l_gb.pack({0xF7,  a, b, c, d}, g_ver, g_adr, 0x42, 0x48))
	--恢复成自动模式
	table.insert(rs, l_gb.pack({0xE0}, g_ver, g_adr, 0xE1, 0x80))
end

--浮充电压设定值	6303001 F1H
function getFloatChargeVolCmd(value, rs)
	local a,b,c,d = floatToBytes(value)
	--先设置成手动模式
	table.insert(rs, l_gb.pack({0xE1}, g_ver, g_adr, 0xE1, 0x80))
	table.insert(rs, l_gb.pack({0xF1,  a, b, c, d}, g_ver, g_adr, 0x42, 0x48))
	--恢复成自动模式
	table.insert(rs, l_gb.pack({0xE0}, g_ver, g_adr, 0xE1, 0x80))
end

--均充电压设定值	6308001 F2
function getEqualizingChargeVolCmd(value, rs)
	local a,b,c,d = floatToBytes(value)
	--先设置成手动模式
	table.insert(rs, l_gb.pack({0xE1}, g_ver, g_adr, 0xE1, 0x80))
	table.insert(rs, l_gb.pack({0xF2,  a, b, c, d}, g_ver, g_adr, 0x42, 0x48))
	--恢复成自动模式
	table.insert(rs, l_gb.pack({0xE0}, g_ver, g_adr, 0xE1, 0x80))
end

--均充间隔周期	6312001 F6
function getEqualizingChargeCycCmd(value, rs)
	local a,b,c,d = floatToBytes(value)
	--先设置成手动模式
	table.insert(rs, l_gb.pack({0xE1}, g_ver, g_adr, 0xE1, 0x80))
	table.insert(rs, l_gb.pack({0xF6,  a, b, c, d}, g_ver, g_adr, 0x42, 0x48))
	--恢复成自动模式
	table.insert(rs, l_gb.pack({0xE0}, g_ver, g_adr, 0xE1, 0x80))
end

--均充电流设定值	6313001 F5
function getEqualizingChargeCurCmd(value, rs)
	local a,b,c,d = floatToBytes(value)
	--先设置成手动模式
	table.insert(rs, l_gb.pack({0xE1}, g_ver, g_adr, 0xE1, 0x80))
	table.insert(rs, l_gb.pack({0xF5,  a, b, c, d}, g_ver, g_adr, 0x42, 0x48))
	--恢复成自动模式
	table.insert(rs, l_gb.pack({0xE0}, g_ver, g_adr, 0xE1, 0x80))
end
]]