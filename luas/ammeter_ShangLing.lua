--	力创-LCDG-DMSD40（基本功能）四路三相电子式电能表Modbus通讯协议（V1.0) -- 未完成

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
		-- step1, get ver adr
		{
			pack = l_gb.pack(nil, g_ver, g_adr, 0x90, 0x4F),
			parse = 
				{
				},
			delay = 500,
			needLen = 18,
		},
		-- -- step2, get time
		-- {
		-- pack = l_gb.pack(nil, g_ver, g_adr, 0x90, 0x4D),
			-- parse = 
				-- {
				-- },
			-- delay = 500,
			-- needLen = 32,
		-- },
		-- step2, 模拟量量化数据（浮点）
		{
			pack = l_gb.pack(nil, g_ver, g_adr, 0x90, 0x41),
			parse = 
				{
					{"BYTE", "J7"},
					
					{"BYTE", "F", 16104001}, --三相电压
					{"BYTE", "F", 16105001},
					{"BYTE", "F", 16106001},		
					
					{"BYTE", "F", 16107001}, --五路  三相电流
					{"BYTE", "F", 16108001},
					{"BYTE", "F", 16109001},						
					{"BYTE", "F", 16107002}, 
					{"BYTE", "F", 16108002},
					{"BYTE", "F", 16109002},	
					{"BYTE", "F", 16107003}, 
					{"BYTE", "F", 16108003},
					{"BYTE", "F", 16109003},	
					{"BYTE", "F", 16107004}, 
					{"BYTE", "F", 16108004},
					{"BYTE", "F", 16109004},	
					-- {"BYTE", "F", 16107005}, 
					-- {"BYTE", "F", 16108005},
					-- {"BYTE", "F", 16109005},
					{"BYTE", "J12"},--跳过第5路
					

					{"BYTE", "J4"}, --总有功功率 五路
					{"BYTE", "F", 16111001}, 
					{"BYTE", "F", 16112001},
					{"BYTE", "F", 16113001},
					{"BYTE", "J4"}, 
					{"BYTE", "F", 16111002}, 
					{"BYTE", "F", 16112002},
					{"BYTE", "F", 16113002},
					{"BYTE", "J4"}, 
					{"BYTE", "F", 16111003}, 
					{"BYTE", "F", 16112003},
					{"BYTE", "F", 16113003},
					{"BYTE", "J4"}, 
					{"BYTE", "F", 16111004}, 
					{"BYTE", "F", 16112004},
					{"BYTE", "F", 16113004},
					{"BYTE", "J4"}, 
					-- {"BYTE", "F", 16111005}, 
					-- {"BYTE", "F", 16112005},
					-- {"BYTE", "F", 16113005},
					{"BYTE", "J12"},--跳过第5路

					{"BYTE", "J4"}, --总无功功率 五路
					{"BYTE", "F", 16114001}, 
					{"BYTE", "F", 16115001},
					{"BYTE", "F", 16116001},
					{"BYTE", "J4"}, 
					{"BYTE", "F", 16114002}, 
					{"BYTE", "F", 16115002},
					{"BYTE", "F", 16116002},
					{"BYTE", "J4"}, 
					{"BYTE", "F", 16114003}, 
					{"BYTE", "F", 16115003},
					{"BYTE", "F", 16116003},
					{"BYTE", "J4"}, 
					{"BYTE", "F", 16114004}, 
					{"BYTE", "F", 16115004},
					{"BYTE", "F", 16116004},
					{"BYTE", "J4"}, 
					-- {"BYTE", "F", 16114005}, 
					-- {"BYTE", "F", 16115005},
					-- {"BYTE", "F", 16116005},	
					{"BYTE", "J12"},--跳过第5路					
					
					{"BYTE", "J80"}, --跳过所有视在功率
					
					{"BYTE", "F", 16117001}, --总功率因数 五路
					{"BYTE", "J12"}, 
					{"BYTE", "F", 16117002}, 
					{"BYTE", "J12"}, 
					{"BYTE", "F", 16117003}, 
					{"BYTE", "J12"}, 
					{"BYTE", "F", 16117004}, 
					{"BYTE", "J12"}, 					
					-- {"BYTE", "F", 16117005}, 
					{"BYTE", "J4"}, 	
					
					{"BYTE", "J12"}, 	
					
					{"BYTE", "F", 16118001}, 

				},
			delay = 1000,
			needLen = 812,
		},
		--step3, 获取电能数据
		-- {
			-- pack = l_gb.pack(nil, g_ver, g_adr, 0x90, 0x80),
			-- parse = 
				-- {
					
				-- },
			-- delay = 500,
			-- needLen = 300,
		-- },
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
		-- init adr ver
		g_ver = packInfo[1]
		g_adr = packInfo[2]
		g_cmd = getCmd()
	else
		g_cmd = getCmd()
		local parseRs = {}
		l_base.parseScript(g_cmd[g_step - 1].parse, packInfo, parseRs)
--		print("---------------------->", g_step - 1, #packInfo)
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
