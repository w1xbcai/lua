local l_dh = require "dhModule"
local l_base = require "baseModule"
--[[  ]]
--============================================================
local c_so = require "cExtend"

local parse_addRs = c_so.parse_addRs
local pack_new = c_so.pack_new
local pack_addInfo = c_so.pack_addInfo
local parse_setNextPos = c_so.parse_setNextPos
local parse_setNeedLen = c_so.parse_setNeedLen
local parse_getPackInfo = c_so.parse_getPackInfo
local parse_new = c_so.parse_new
local parse_setStatus = c_so.parse_setStatus
local BytesToFloat = c_so.bytesToFloat
--============================================================

local g_step = 1
local g_ver = {0x01, 0x00}
local g_seq = 1
local g_stat = 101
local g_max_pes_count = 100

function luaInit(verLen, ver, adrLen, adr)

end

--所有要发送到采集命令的集合
--暂时去掉扩展板了，仅保留一个基础板。
local g_pollCmds = {}
local g_needLen = {}
function initPollCmds(count)
	g_pollCmds = {}
	table.insert(g_pollCmds, 1, l_dh.pack({"13","00"}, 0, g_seq, nil))
	g_seq = g_seq + 1
	--取通道实时数据
	table.insert(g_pollCmds, 2, l_dh.pack({"25","00"}, 0, g_seq, nil))
	g_seq = g_seq + 1
	if g_seq > 123456789 then
		g_seq = 1
	end
	g_needLen = {}
end

function nextPack(onePack)
	if #g_pollCmds == 0 then
		initPollCmds(0)
	end
	if g_step >= #g_pollCmds + 1 then
		pack_new(onePack, 101, 0, 0, 0);
		g_step = 1
	else
		local pack = g_pollCmds[g_step]
		pack_new(onePack, g_stat, 100, 500, #pack);
		for i = 1, #pack do
			pack_addInfo(onePack, i, tonumber(pack[i], 16));
		end
		g_step = g_step + 1
	end	
end

function printArr(info)
	local dd = ""
	for j = 1, #info do
		dd = dd .. string.format("%02X", (info[j]&0xFF)) .. " "
	end
	print("Rx: " .. dd)
end

local ybmps6000MinResLen = 24
function checkYbmps6000pack(c_rs, info)
--	printArr(info)
	
	local packLen = #info
	if packLen < ybmps6000MinResLen then
		parse_setNextPos(c_rs, 0)
		parse_setNeedLen(c_rs, ybmps6000MinResLen - packLen)
		return 102
	end
	
	if ((string.format("%02X", (info[1]&0xFF)) ~= "DD") or (string.format("%02X", (info[2]&0xFF)) ~= "BB")) then
		parse_setNextPos(c_rs, packLen)
		parse_setNeedLen(c_rs, ybmps6000MinResLen)
		return 102
	end
	
	local msgLen = l_base.fourBytesToInt({info[8],info[7],info[6],info[5]})
--	print("msgLen:" .. msgLen .. " allLen:" .. packLen )
	if msgLen + 12 > packLen then
		parse_setNextPos(c_rs, 0)
		parse_setNeedLen(c_rs, msgLen + 12 - packLen)
		return 103
	end

	local readCheck = l_base.twoBytesToInt({info[packLen - 2], info[packLen - 3]})
	local calcCheck = l_base.getCheckSum(info, 1, packLen - 4)
--	print("two check:" .. readCheck .. " : " .. calcCheck)
	if readCheck ~= calcCheck then
		parse_setNextPos(c_rs, packLen)
		parse_setNeedLen(c_rs, ybmps6000MinResLen)
		return 102
	end
	
	if ((string.format("%02X", (info[packLen-1]&0xFF)) ~= "CC") or (string.format("%02X", (info[packLen]&0xFF)) ~= "AA")) then
		parse_setNextPos(c_rs, packLen)
		parse_setNeedLen(c_rs, ybmps6000MinResLen)
		return 102
	end
	
	parse_setNextPos(c_rs, packLen)
	parse_setNeedLen(c_rs, 0)
	if (tonumber(info[19]) == 1) and (tonumber(info[20]) == 0) then
		return 101
	end
	return 102
end

function parse(c_rs)
	local info = parse_getPackInfo(c_rs)
	local checkrs = checkYbmps6000pack(c_rs, info)
	parse_setStatus(c_rs, checkrs)
	parse_setNextPos(c_rs, #info)
	if checkrs == 101  then
		if g_step == 2 then
			parse_new(c_rs, 0)
			parse_type(c_rs, info)
		elseif g_step == 3 then
			parse_adio(c_rs, info)
		else
			parse_new(c_rs, 0)
		end
	end
end

--[[
0x01	电池电压(总电压, 云博旧式)    0x85	空调控制反馈       0x0E	电组数1总电压                0xC1	空调控制
0x02	温度(云博老式传感器)          0x86	动环控制反馈       0x0F	电池组1中间电压              0xC2	灯控
0x03	湿度(云博老式传感器)          0x87	市电检测           0x10	电池组2总电压                0xC3	烟雾控制
0x04	交流电压                    0x88	供电检测           0x11	电池组2中间电压              0xD0	交电电压UA或UAB
0x05	空调反馈                    0x89	交流负载检测       0x12	直接读取DI信号的水浸         0xD1	交流电压UB或UBC
0x06	DVR检测                    0x8A	电池浮充告警       0x13	室外防盗                     0xD2	交流电压UC或UCA
0x07	开门按钮                    0x8B	电池欠压告警       0x80	旧烟感 ,  需要复位去静电     0xD3	交流电流IA
0x08	烟感复位(老式传感器)          0x8C	直流负载检测       0x81	通过检测频率的水浸           0xD4	交流电流IB
0x09	中间电池电压(云博旧式)        0x8D	充电欠压告警       0x82	门磁                         0xD5	交流电流IC
0x0A	烟感, 正常DI信号，			  0x8E	直流充电状态       0x83	振动                         0xD6	交流电流IN
0x0B	模拟独立温度                  0x90	玻璃破碎传感器     0x84	红外                         0xFF	无效设备(未接的端口)
0x0C	模拟独立湿度                  0xC0	电控锁输出
]]
--Rx: DD BB 01 00 44 00 00 00 00 00 00 00 01 00 00 00 14 00 01 00 
--0E 00 0F 00 10 00 11 00 82 01 82 01 82 01 82 01 82 01 82 01 82 01 12 01 0B 00 0C 00 04 00 04 00 82 01 82 01 82 01 82 01 82 01 82 01 82 01 0A 01 C0 02 C0 02 C0 02 C0 02 A0 0C CC AA
local g_pesCount = 0
local g_pesCfgTab = {}
function parse_type(c_rs, pack)
--	print("type len", #pack)
	 if #pack ~= 120 then
		parse_setNeedLen(c_rs, 0)
		parse_setStatus(c_rs, 102)
		return
	 end
	local g_battery_allVol_code = 7102001	--电池组总电压	
	local g_battery_half_top = 07106001 --前半组电压
	local g_battery_half_tail = 07107001 --后半组电压
	local g_water_code = 18001001	--水浸告警
	local g_smoke_code = 18002001	--烟雾告警
	local g_infrared_code = 18003001	--红外告警
	local g_temp_code = 18101001		--环境温度
	local g_hum_code = 18102001		--环境湿度
	local g_door_code = 17101001		--门磁开关状态

	local offset = 21
	local chanCount = (#pack - ybmps6000MinResLen) / 2
	g_pesCount = chanCount
	g_pesCfgTab = {}
	for idx = 1, chanCount do
		local devType = (pack[offset] & 0xFF)
		local chanType = (pack[offset + 1] & 0xFF)
		local code = 0
		if (devType == 0x01 or devType == 0x0E  --or devType == 0x0F or devType == 0x11 --去除中间电压
			or devType == 0x10 or devType == 0x09) then
			--如果是电压
			code = g_battery_allVol_code
			g_battery_allVol_code = g_battery_allVol_code + 1
		elseif (devType == 0x12 or devType == 0x81) then
			--如果是水浸
			code = g_water_code
			g_water_code = g_water_code + 1
		elseif (devType == 0x08 or devType == 0x0A) then
			--如果是烟雾
			code = g_smoke_code
			g_smoke_code = g_smoke_code + 1
		elseif (devType == 0x84) then
			--如果是红外
			code = g_infrared_code
			g_infrared_code = g_infrared_code + 1
		elseif (devType == 0x0B or devType == 0x02) then
			--环境温度
			code = g_temp_code
			g_temp_code = g_temp_code + 1
		elseif (devType == 0x0C or devType == 0x03) then
			--环境湿度
			code = g_hum_code
			g_hum_code = g_hum_code + 1
		elseif (devType == 0x82) then
			--门磁
			code = g_door_code
			g_door_code = g_door_code + 1
		 elseif (devType == 0x14 or devType == 0x16) then
			code = g_battery_half_top
			g_battery_half_top = g_battery_half_top + 1
		 elseif (devType == 0x15 or devType == 0x17) then
			code = g_battery_half_tail
			g_battery_half_tail = g_battery_half_tail + 1
		else
			code = 0
			g_pesCount = g_pesCount - 1
		end
--		print("data:", idx, string.format("%02X", chanType), string.format("%02X", devType), code)
		g_pesCfgTab[idx] = {chanType, code}
		offset = offset + 2
	end
end


--DD BB 01 00 7C 00 00 00 00 00 00 00 02 00 00 00 26 00 01 00 
--00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
--00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
--00 00 00 00 01 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
--00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
--00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
--00 00 00 00 00 00 00 00 00 00 00 00 3F 02 CC AA
--解析通道实时数据
function parse_adio(c_rs, pack)
	print("adio len", #pack)
	 if #pack ~= 216 then
		parse_setNeedLen(c_rs, 0)
		parse_setStatus(c_rs, 102)
		parse_new(c_rs, 0)
		return
	 end
	local offset = 21
	local pesCount = (#pack - 24) / 4
	parse_new(c_rs, g_pesCount)
--	print("count:" , pesCount, g_pesCount)
	local j = 1
	for idx = 1, pesCount do
		if (g_pesCfgTab[idx][2] ~= 0)  then
			local rs
			if (g_pesCfgTab[idx][1] == 0) then
				rs = BytesToFloat(pack[offset], pack[offset+1], pack[offset+2], pack[offset+3])
			else
				rs = l_base.fourBytesToInt({pack[offset+3], pack[offset+2], pack[offset+1], pack[offset]})
			end
			if j <= g_pesCount then
				parse_addRs(c_rs, j, g_pesCfgTab[idx][2], rs, 0)
--				print("->rs:", idx, j, g_pesCfgTab[idx][1], g_pesCfgTab[idx][2])
				j = j + 1
			end
		end
		offset = offset + 4
	end
end

function printTx(cmd)
	local dd = ""
	for j = 1, #cmd do
		dd = dd .. cmd[j] .. " "
	end
	print("Tx: " .. dd)
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

function ctrDoOpen(chan, rs)
	table.insert(rs, l_dh.pack({"27","00"}, 0, g_seq, {chan, 1, 0}))
end

function ctrDoClose(chan, rs)
	table.insert(rs, l_dh.pack({"27","00"}, 0, g_seq, {chan, 0, 0}))
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
