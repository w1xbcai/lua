--	TCL通信基站用柜式空调通讯协议V1.2.doc

local l_tcl = require "tclModule"
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

   
local g_adr = {0x00, 0x00}

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
			pack = l_tcl.pack({0x00,0x00}, g_adr, 0x70),
			parse = 
				{
				--0D 00 00 70 00 01 F0 40 16 10 B8 88 10 00
					{"BYTE", "J8"},
					{"BYTE", "U8", 15301001},
					{"BYTE", "J3"},
					{"BYTE", "U16", 15001001, "(rs & 0x3FFF) ~= 0"},
				},
			delay = 500,
			needLen = 19,
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
	local nextPos, needLen, pkg = l_tcl.checkPack(pack)
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
	table.remove(pkg, 1)
	table.remove(pkg, #pkg)
	table.remove(pkg, #pkg)
	table.remove(pkg, #pkg)

	if g_step == 2 then
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

--开机 15201001
function openAir(value, rs)
	table.insert(rs, l_tcl.pack({0x01,0x00}, g_adr, 0x0D))
end

--关机 15202001
function openAir(value, rs)
	table.insert(rs, l_tcl.pack({0x00,0x00}, g_adr, 0x0D))
end

--设置温度 18 -> 32
function openAir(value, rs)
	local tmp = tonumber(rs) - 18
	tmp = (tmp << 4) + 1
	table.insert(rs, l_tcl.pack({0x84,tmp & 0xFF, 0x00, 0x00}, g_adr, 0x6F))
end

--制冷
function openAir(value, rs)
	local tmp = tonumber(rs) - 18
	tmp = (tmp << 4) + 2
	table.insert(rs, l_tcl.pack({0x84,tmp & 0xFF, 0x00, 0x00}, g_adr, 0x6F))
end

--制热
function openAir(value, rs)
	local tmp = tonumber(rs) - 18
	tmp = (tmp << 4)
	table.insert(rs, l_tcl.pack({0x84,tmp & 0xFF, 0x00, 0x00}, g_adr, 0x6F))
end

