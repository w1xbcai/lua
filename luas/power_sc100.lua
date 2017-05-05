--	中恒-SC100通信协议(V14.0)

local l_s3p = require "s3pModule"
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

   
local g_adr = {0x00, 0x01}

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
			pack = l_s3p.pack({0x00}, {0x00, 0x01}, 0x40),
			parse = 
				{
				},
			delay = 500,
			needLen = 24,
		},
		-- step2, ac_ai
		{
			pack = l_s3p.pack({0x40, 0x7E}, {0x00, 0x01}, 0x45),
			parse = 
				{
					{"BYTE", "J9"},
--					{"BYTE", "LF", 1234567},
					{"BYTE", "LF", 6101001},
					{"BYTE", "LF", 6102001},
					{"BYTE", "LF", 6103001},
					{"BYTE", "LF", 6110001},
    
					{"BYTE", "LF", 6111001},
					{"BYTE", "LF", 6112001},
					{"BYTE", "LF", 6115001},
					{"BYTE", "J8"},
					{"BYTE", "LF", 6125001},
					{"BYTE", "J4"},

				},
			delay = 500,
			needLen = 30,
		},
		-- step3, 16610 Rectifier Registration State
		{
			pack = l_s3p.pack({0x40, 0xE2}, {0x00, 0x01}, 0x45),
			parse = 
				{
					-- {"SL", "NU", "23"},
						-- {"BYTE", "U8", 6028001, "rs == 2"},
					-- {"EL",},
					{"BYTE", "JN"},
				},
			delay = 500,
			needLen = 30,
		},
		-- step4 , 16620 Rectifier Data
		{
			pack = l_s3p.pack({0x40, 0xEC}, {0x00, 0x01}, 0x45),
			parse = 
				{
					-- {"SL", "NU", "23"},
						-- {"BYTE", "U8", 6028001, "rs == 2"},
					-- {"EL",
					{"BYTE", "JN"},
				},
			delay = 500,
			needLen = 30,
		},
		
		--[[5.10 Alarm Configuration
		601 System Alarm Urgency
		16585Equalize Start Y
		16586Equalize Stop Y
		16588Fast Charge Stop
		16633 Restart Rectifier
		--step3, ac_alarm
		{
			pack = l_s3p.pack({0x40, 0x9C}, g_adr, 0x65),
			parse = 
				{
					{"BYTE", "J12"},
					{"SET", "U8", "lg_fuseCount = rs"},
					{"SL", "NU", "lg_fuseCount"},
						{"BYTE", "J1"},
					{"EL"},
					{"BYTE", "J1"},
					{"BYTE", "U8", 6022001, "rs == 0x81"},
					{"BYTE", "J6"},
					{"BYTE", "U8", 6020001, "rs == 0xE3"},
					{"BYTE", "J14"},
				},
			delay = 500,
			needLen = 30,
		},
		]]
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
	local nextPos, needLen, pkg = l_s3p.checkPack(pack)
	parse_setNextPos(c_rs, nextPos)
	parse_setNeedLen(c_rs, needLen)
	
--	print("check", nextPos, needLen)
	if needLen ~= 0 or pkg == nil then
		parse_setStatus(c_rs, 102)
		return
	else
		parse_setStatus(c_rs, 101)
	end
	table.remove(pkg, 1)
	table.remove(pkg, #pkg)
	table.remove(pkg, #pkg)
	
	if g_step == 2 then
		-- init adr ver

	else
		g_cmd = getCmd()
		local parseRs = {}
		l_base.parseScript(g_cmd[g_step - 1].parse, pkg, parseRs)
--		print("---------------------->", g_step - 1, #pkg)
		if #pkg == 0 then
			parse_new(c_rs, #parseRs)
			for idx = 1, #parseRs do
--				print("chekc", tostring(parseRs[idx][2]) == "nan")
				if parseRs[idx][2] == -99999999 or tostring(parseRs[idx][2]) == "nan" then
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

--设置均冲 6202001
function getEqualizingChargeCmd(value, rs)
	--先设置成手动模式
	table.insert(rs, l_gb.pack({0xE1}, g_ver, g_adr, 0xE1, 0x80))
	table.insert(rs, l_gb.pack({0x10, 0x00}, g_ver, g_adr, 0x41, 0x45))
	--恢复成自动模式
	table.insert(rs, l_gb.pack({0xE0}, g_ver, g_adr, 0xE1, 0x80))
end

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
	table.insert(rs, l_gb.pack({0xE5, value & 0xFF}, g_ver, g_adr, 0x41, 0x45))
	table.insert(rs, l_gb.pack({0xE6, value & 0xFF}, g_ver, g_adr, 0x41, 0x45))
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