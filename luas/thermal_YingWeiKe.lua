--	英维克-EX热交换系列-U6平台-modbus协议V1.0

local l_md = require "modbusModule"
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
			pack = l_md.pack({0x01, 0x00, 0x00, 0x01}, g_adr, 0x03),
			parse = 
				{
					{"BYTE", "U16", 25004001},

				},
			delay = 500,
			needLen = 7,
		},
		-- step2,
		{
			pack = l_md.pack({0x05, 0x00, 0x00, 0x04}, g_adr, 0x03),
			parse = 
				{
					{"BYTE", "J2"},
					{"BYTE", "U16", 25103001,"rs*0.1"},
					{"BYTE", "J2"},
					{"BYTE", "U16", 25101001,"rs*0.1"},

				},
			delay = 500,
			needLen = 13,
		},
		-- step3,
		{
			pack = l_md.pack({0x06,0x0C,0x00,0x05}, g_adr, 0x03),
			parse = 
				{	
					{"SET", "U8", "lg_alarm_air = rs"},
					{"SET", "U8", "lg_alarm_air = lg_alarm_air + rs"},
					{"SET", "U8", "lg_alarm_air = lg_alarm_air + rs"},
					{"SET", "U8", "lg_alarm_air = lg_alarm_air + rs"},
					{"BYTE", "NU", 25003001, "lg_alarm_air > 0"},
					{"BYTE", "J2"},
					{"SET", "U8", "lg_alarm_device = rs"},
					{"SET", "U8", "lg_alarm_device = lg_alarm_device + rs"},
					{"SET", "U8", "lg_alarm_device = lg_alarm_device + rs"},
					{"SET", "U8", "lg_alarm_device = lg_alarm_device + rs"},
					{"BYTE", "NU", 25002001, "lg_alarm_device > 0"},
				
				},
			delay = 500,
			needLen = 15,
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
	local nextPos, needLen = l_md.checkPack(pack, g_adr)
	parse_setNextPos(c_rs, nextPos)
	parse_setNeedLen(c_rs, needLen)
	
	if (needLen ~= 0) then
		parse_setStatus(c_rs, 102)
		return
	else
		parse_setStatus(c_rs, 101)
	end
	print("check", nextPos, needLen)
	
	table.remove(pack, 1)
	table.remove(pack, 1)
	table.remove(pack, 1)
	table.remove(pack, #pack)
	table.remove(pack, #pack)

	if g_step == 2 or g_step == 3  or g_step == 4then
		g_cmd = getCmd()
		local parseRs = {}
		l_base.parseScript(g_cmd[g_step - 1].parse, pack, parseRs)
		print("---------------------->", g_step - 1, #pack)
		if #pack == 0 then
			parse_new(c_rs, #parseRs)
			for idx = 1, #parseRs do
				if parseRs[idx][2] == -99999999 or tostring(parseRs[idx][2]) == "nan" then
					parse_addRs(c_rs, idx, parseRs[idx][1], parseRs[idx][2], 1)
				else
					parse_addRs(c_rs, idx, parseRs[idx][1], parseRs[idx][2], 0)
				end
			end
			return
		end
	end
	parse_setNeedLen(c_rs, 0)
	parse_setStatus(c_rs, 102)
	parse_new(c_rs, 0)
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

--监控开机0x0801 	0x01开机 0x00 关机
function openDevice(value , rs)
	table.insert(rs, l_md.pack({0x08, 0x00, 0x00, 0x01}, g_adr, 0x06))
end

--监控关机0x0801 	0x01开机 0x00 关机
function openDevice(value , rs)
	table.insert(rs, l_md.pack({0x08, 0x00, 0x00, 0x00}, g_adr, 0x06))
end

function parseW()

end

