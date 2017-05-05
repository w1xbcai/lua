--	QZTT 1017-2015基站交流智能电表技术规范V1.0更新.pdf --铁塔电表

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

   
local g_ver = 0x10
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
			pack = l_gb.pack(nil, g_ver, g_adr, 0x2C, 0x50),
			parse = 
				{
				},
			delay = 500,
			needLen = 18,
		},
		-- -- step2, get time
		-- {
		-- pack = l_gb.pack(nil, g_ver, g_adr, 0x2C, 0x4D),
			-- parse = 
				-- {
				-- },
			-- delay = 500,
			-- needLen = 24,				--34
		-- },
		-- step2, 模拟量量化数据（浮点数）
		{
			pack = l_gb.pack({01}, g_ver, g_adr, 0x2C, 0x41),
			parse = 
				{
						{"BYTE", "J7"},
					-- {"SET", "U8", "lg_acInputCount = rs"},
					-- {"SL", "NU", "lg_acInputCount"},
						{"BYTE", "F", 16101001},
						{"BYTE", "F", 16102001},
						{"BYTE", "F", 16103001},
						{"BYTE", "F", 16104001},
						{"BYTE", "F", 16105001},
						{"BYTE", "F", 16106001},	
						{"BYTE", "F", 16107001},
						{"BYTE", "F", 16108001},
						{"BYTE", "F", 16109001},
						{"BYTE", "F", 16110001},--零序电流Io
						{"BYTE", "F", 16117001},--功率因数
						
						{"BYTE", "F", 16118001},
						{"BYTE", "J1"},
						
						{"BYTE", "J4"}, --					总有功功率																	
						{"BYTE", "F", 16111001},
						{"BYTE", "F", 16112001},
						{"BYTE", "F", 16113001},
						
						{"BYTE", "J4"}, --					总无功功率
						{"BYTE", "F", 16114001},
						{"BYTE", "F", 16115001},
						{"BYTE", "F", 16116001},
						
						{"BYTE", "J8"}, --					总有功电能 总无功电能
						{"BYTE", "F", 16119001},
						{"BYTE", "F", 16120001},						
						{"BYTE", "J8"}, 

				},
			delay = 500,
			needLen = 230,
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
		
	if g_step == 2 then
		-- init adr ver
		g_ver = packInfo[1]
		g_adr = packInfo[2]
		g_cmd = getCmd()
	else
		g_cmd = getCmd()
		local parseRs = {}
		l_base.parseScript(g_cmd[g_step - 1].parse, packInfo, parseRs)
		--	print("---------------------->", g_step - 1, #packInfo)
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




