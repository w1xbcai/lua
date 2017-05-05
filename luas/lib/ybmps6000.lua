local l_dh = require "dhModule"

local g_step = 1
local g_ver = {0x01, 0x00}
local g_seq = 1
local g_stat = 100

--所有要发送到采集命令的集合
--暂时去掉扩展板了，仅保留一个基础板。
local g_pollCmds = {}
function initPollCmds(count)
	g_pollCmds = {}
	--取通道类型
	--table.insert(g_pollCmds, 1, l_dh.pack({"13", "00"}, 0, g_seq, nil))
	--g_seq = g_seq + 1
	--取通道实时数据
	table.insert(g_pollCmds, 1, l_dh.pack({"37","00"}, 0, g_seq, nil))
	g_seq = g_seq + 1
end

function nextPack(onePack)
	if #g_pollCmds == 0 then
		initPollCmds(0)
	end
	if g_step >= #g_pollCmds + 1 then
		csb_newPack(onePack, g_stat, 24, 500, 0);
		g_step = 1
	else
		local pack = g_pollCmds[g_step]
		csb_newPack(onePack, g_stat, 24, 500, #pack);
		for i = 1, #pack do
			csb_addPackInfo(onePack, i, tonumber(pack[i], 16));
		end
	end
end

function parse(c_rs)
	local checkrs = l_dh.checkPack(c_rs)
	csb_setParseResult(c_rs, checkrs)
	if g_step <= #g_pollCmds then
		if checkrs == 101 or checkrs == 107 then
			local parseRs = parse_adio(c_rs)	
			local newCount = #parseRs
			csb_newParse(c_rs, newCount)
			for i = 1, newCount do
				local one = parseRs[i]
				--print(one[1] .. " : " .. one[2])
				csb_copyParseRs(c_rs, i, one[1], one[2], 0)
			end
		else
			csb_newParse(c_rs, 0)
		end
	end
	g_step = g_step + 1
end

--解析通道类型，暂时未用
function parse_type(c_rs)


end

--解析通道实时数据
--自定义一个默认配置:温度(18101001),湿度(18102001),门碰(18009001),红外(18003001),
--水浸(18001001),烟雾(18002001),无效设备.1-26.
function parse_adio(c_rs)
	local parseRs = {}
	local offset = 20
	local adioCount = 26
	local a,b,c,d
	local codes = {18101001,18102001,18009001,18003001,18001001,18002001}
	local pos = 1
	for i = 1, adioCount do
		local one = cfb_hexParse(c_rs, "4bytesToHex", offset)
		local code = 0
		if i < #codes then
			code = codes[i]
		end
		table.insert(parseRs, pos, {code, one})
		offset = offset + 4
		pos = pos + 1
	end
	return parseRs
end

--[[
initPollCmds(0)
for i = 1, #g_pollCmds do
	local dd = ""
	local cmd = g_pollCmds[i]
	for j = 1, #cmd do
		dd = dd .. cmd[j] .. " "
	end
	print("adrver cmd: " .. dd)
end
]]
