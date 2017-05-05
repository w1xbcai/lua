local l_base = require "baseModule"

local g_step = 1
local g_add = 1
local g_stat = 100
local g_isdebug = true
local g_endian = 0

local g_pollCmds = {}
function initPollCmds(add)
	g_pollCmds = {}
	table.insert(g_pollCmds, 1, l_mdb.pack(add, 0x03, {0x06, 0xEA, 0x60, 0xC3, 0x50, 0xDB, 0x6C}))
end

function nextPack(onePack)
	if #g_pollCmds == 0 then
		initPollCmds(g_add)
	end
	local pack = g_pollCmds[g_step]
	csb_newPack(onePack, g_stat, 8, 500, #pack);
	for i = 1, #pack do
		csb_addPackInfo(onePack, i, pack[i]);
	end
end

 

initPollCmds(g_add)
for i = 1, #g_pollCmds do
	local dd = ""
	local cmd = g_pollCmds[i]
	for j = 1, #cmd do
		dd = dd .. string.format("%02X", cmd[j]) .. " "
	end
	print("adrver cmd: " .. dd)
end	