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
local g_ver = 0x01
local g_adr = 0x00

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

local g_pollCmds = {}
function initPollCmds(adr)
	g_pollCmds = {}
	table.insert(g_pollCmds, 1, l_gb.pack(nil, g_ver, adr, 0x40, 0x42))
	table.insert(g_pollCmds, 2, l_gb.pack(nil, g_ver, adr, 0x41, 0x42))
	table.insert(g_pollCmds, 3, l_gb.pack(nil, g_ver, adr, 0x42, 0x42))
	table.insert(g_pollCmds, 4, l_gb.pack(nil, g_ver, adr, 0x42, 0x44))
end

function nextPack(onePack)
	if #g_pollCmds == 0 then
		initPollCmds(g_adr)
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
		if g_step == 1 then
			parse_ac_ai(c_rs, packInfo)
		elseif g_step == 2 then
			parse_rc_ai(c_rs, packInfo)
		elseif g_step == 3 then
			parse_dc_ai(c_rs, packInfo)
		elseif g_step == 4 then
			parse_sys_alarm(c_rs, packInfo)
		else
			parse_new(c_rs, 0)
		end
	end
	g_step = g_step + 1
end

--7E 30 31 30 30 34 30 30 30 44 30 33 30 30 30 30 31 30 38 44 30 30 38 43 46 30 38 43 31 30 31 46 39 30 30 30 33 30 30 34 33 30 30 33 44 30 30 30 30 30 30 30 30 30 30 30 30 30 30 30 30 46 33 46 39 0D 
--00 01 08 D0 08 CF 08 C1 01 F9 00 03 00 43 00 3D 00 00 00 00 00 00 00 00
function parse_ac_ai(c_rs, info)
	local ver = info[1]
	local adr = info[2]
	local cid1 = info[3]
	local cid2 = info[4]
	local rate = 0.1
	local codes = {6101001, 6102001, 6103001, 6110001, 6107001, 6108001, 6109001, 6101002, 6102002, 6103002, 6110002}
	local offset = 9
	parse_new(c_rs, 11)
	for idx = 1, 11 do
		local rs = ((info[offset] & 0xFF) << 8) | (info[offset + 1] & 0xFF)
		rs = rs * rate
		parse_addRs(c_rs, idx, codes[idx], rs, 1)
		offset = offset + 2
	end
end

--7E 30 31 30 30 34 31 30 30 39 30 33 34 30 30 30 33 30 30 30 37 30 37 37 45 30 30 30 30 30 30 32 34 30 38 30 37 31 35 30 43 30 39 41 34 30 30 32 43 30 38 30 37 31 35 30 45 30 39 42 37 30 30 32 42 46 32 46 43 0D 
--00 03 00 07 07 7E 00 00 00 24 08 07 15 0C 09 A4 00 2C 08 07 15 0E 09 B7 00 2B
function parse_rc_ai(c_rs, info)
	local ver = info[1]
	local adr = info[2]
	local cid1 = info[3]
	local cid2 = info[4]
	
	local smr_alarm_code = 6024001
	local smr_fan_alarm_code = 6025001
	local smr_tmp_alarm_code = 6024001	--暂时不做
	local smr_cur_code = 6113001
	local smr_tmp_code = 6114001
	local offset = 7
	local smrCount = ((info[offset] & 0xFF) << 8) | (info[offset + 1] & 0xFF)
	offset = offset + 2
	
	parse_new(c_rs, smrCount * 5)
	local dataidx = 1
	for idx = 1, smrCount do
		--整流模块故障
		local rs = 0
		if ((info[offset] & 0x01) > 0) or ((info[offset+1] & 0xD0) > 0) 
			or ((info[offset+1] & 0xFA) == 0) then
			rs = 1
		end
		parse_addRs(c_rs, dataidx, smr_alarm_code, rs, 1)
		smr_alarm_code = smr_alarm_code + 1
		dataidx = dataidx + 1
		
		--风扇故障
		rs = 0
		if (info[offset+1] & 0x10) > 0 then
			rs = 1
		end
		parse_addRs(c_rs, dataidx, smr_fan_alarm_code, rs, 1)
		smr_fan_alarm_code = smr_fan_alarm_code + 1
		dataidx = dataidx + 1
		
		--模块内温度告警
		rs = 0
		if (info[offset+1] & 0x40) > 0 then
			rs = 1
		end
		parse_addRs(c_rs, dataidx, smr_tmp_alarm_code, rs, 1)
		smr_tmp_alarm_code = smr_tmp_alarm_code + 1
		dataidx = dataidx + 1
		offset = offset + 4
		
		--电流
		rs = ((info[offset]) << 8) | (info[offset + 1] & 0xFF)
		rs = rs * 0.01
		parse_addRs(c_rs, dataidx, smr_cur_code, rs, 1)
		smr_cur_code = smr_cur_code + 1
		dataidx = dataidx + 1
		offset = offset + 2
		
		--温度
		rs = ((info[offset]) << 8) | (info[offset + 1] & 0xFF)
		parse_addRs(c_rs, dataidx, smr_tmp_code, rs, 1)
		smr_tmp_code = smr_tmp_code + 1
		dataidx = dataidx + 1
		offset = offset + 2
	end
	
end

--7E 30 31 30 30 34 32 30 30 44 30 33 30 30 30 30 32 31 34 46 39 30 30 35 33 30 31 44 31 30 30 37 46 31 34 46 42 30 30 37 46 30 31 38 35 31 34 46 41 30 30 30 44 30 31 45 46 30 30 37 46 46 33 36 30 0D 
--00 02 14 F9 00 53 01 D1 00 7F 14 FB 00 7F 01 85 14 FA 00 0D 01 EF 00 7F
function parse_dc_ai(c_rs, info)
	local ver = info[1]
	local adr = info[2]
	local cid1 = info[3]
	local cid2 = info[4]
	
	local battery_cur_code = 6115001
	local sys_vol_code = 6111001
	local sys_loadCur_code = 6112001
	
	local offset = 7
	local batteryCount = ((info[offset] & 0xFF) << 8) | (info[offset + 1] & 0xFF)
	offset = offset + 4
	if batteryCount > 1 then
		parse_new(c_rs, 4)
	else
		parse_new(c_rs, 3)
	end
	
	local batteryCur = ((info[offset]) << 8) | (info[offset + 1] & 0xFF)
	batteryCur = batteryCur * 0.01
	parse_addRs(c_rs, 1, battery_cur_code, batteryCur, 1)
	battery_cur_code = battery_cur_code + 1
	offset = offset + 6
	
	local sysVol = ((info[offset] & 0xFF) << 8) | (info[offset + 1] & 0xFF)
	sysVol = sysVol * 0.01
	parse_addRs(c_rs, 2, sys_vol_code, sysVol, 1)
	offset = offset + 4
	
	local sysCur = ((info[offset] & 0xFF) << 8) | (info[offset + 1] & 0xFF)
	sysCur = sysCur * 0.01
	parse_addRs(c_rs, 3, sys_loadCur_code, sysCur, 1)
	offset = offset + 4
	
	if batteryCount > 1 then
		batteryCur = ((info[offset]) << 8) | (info[offset + 1] & 0xFF)
		batteryCur = batteryCur * 0.01
		parse_addRs(c_rs, 4, battery_cur_code, batteryCur, 1)
	end
	
end

--7E 30 31 30 30 34 32 30 30 34 30 30 43 30 30 30 30 30 30 30 30 30 30 30 30 46 42 36 32 0D 
--00 00 00 00 00 00
function parse_sys_alarm(c_rs, info)
	local adr = info[1]
	local ver = info[2]
	local cid1 = info[3]
	local cid2 = info[4]
	local offset = 9
	
	local battery_fuse_alarm_code = 6001001
	local load_fuse_alarm_code = 6007001
	local battery_tempHigh_alarm_code = 6003001
	local spd_alarm_code = 6021001
	local battery_discharge_alarm_code = 6004001
	parse_new(c_rs, 5)
	
	local rs = 0
	if (info[offset] & 0x04) > 0 then
		rs = 1
	end
	parse_addRs(c_rs, 1, battery_tempHigh_alarm_code, rs, 1)
	
	rs = 0
	if (info[offset + 1] & 0x04) > 0 then
		rs = 1
	end
	parse_addRs(c_rs, 2, battery_fuse_alarm_code, rs, 1)
	
	rs = 0
	if (info[offset + 1] & 0x08) > 0 then
		rs = 1
	end
	parse_addRs(c_rs, 3, load_fuse_alarm_code, rs, 1)
	offset = offset + 2
	
	rs = 0
	if (info[offset + 1] & 0x02) > 0 then
		rs = 1
	end
	parse_addRs(c_rs, 4, spd_alarm_code, rs, 1)
	
	rs = 0
	if (info[offset + 1] & 0x08) > 0 then
		rs = 1
	end
	parse_addRs(c_rs, 5, battery_discharge_alarm_code, rs, 1)
	
end


--[[
6001001	电池XX熔丝故障告警		遥信	电池熔丝故障告警
6002001	电池XX充电过流告警		遥信	电池充电过流告警状态
6003001	电池XX温度过高告警		遥信	电池组温度高于设定告警阈值
6004001	电池放电不平衡告警		遥信	电池放电不平衡(1组<2组/(1组>2组)
6005001	电池供电告警		遥信	开关电源处于电池供电中
6006001	负载电流过高告警		遥信	遥测值,若负载总电流高于设定告警阈值
6007001	负载熔丝XX故障告警		遥信	负载熔丝或空开故障,引起负载供电中断
6008001	输出电压过低告警		遥信	输出电压过低告警
6009001	输出电压过高告警		遥信	输出电压过高告警
6010001	输出中断告警		遥信	输出中断
6011001	直流屏通讯中断告警		遥信	直流屏通讯中断告警状态
6012001	监控模块故障告警		遥信	监控模块故障告警
6013001	交流输入空开跳告警		遥信	交流输出分路断开
6014001	交流输入XX电压过高告警		遥信	交流输入电压超过阈值
6015001	交流输入XX电压过低告警		遥信	交流输入电压超过阈值
6016001	交流输入XX停电告警		遥信	交流输入停电
6017001	交流输入XX缺相告警		遥信	交流输入缺相
6018001	交流输入XX频率过高告警		遥信	交流输入频率越限告警
6019001	交流输入XX频率过低告警		遥信	交流输入频率越限告警
6020001	市电切换失败故障告警		遥信	市电切换失败故障告警状态
6021001	防雷器空开断开告警		遥信	防雷器空开断开
6022001	防雷器故障告警		遥信	交流防雷器断故障告警状态
6023001	交流屏通讯中断告警		遥信	交流屏通讯中断告警
6024001	整流模块XX故障告警		遥信	模块故障告警状态
6025001	整流模块XX风扇告警		遥信	模块风扇告警
6026001	整流模块XX过压关机告警		遥信	整流模块过压关机告警
6027001	整流模块XX温度过高告警		遥信	模块过温告警状态
6028001	整流模块XX通信状态告警		遥信	模块通讯中断告警状态
6029001	其他告警		遥信	未列入以上告警的告警信息
		一级低压脱离告警		遥信	第一级低压脱离开关动作，其后的负载被断电
		二级低压脱离告警		遥信	第二级低压脱离开关动作，其后的负载被断电
6101001	交流输入XX相电压Ua		遥测	
6102001	交流输入XX相电压Ub		遥测	
6103001	交流输入XX相电压Uc		遥测	
6104001	交流输入XX线电压Uab		遥测	
6105001	交流输入XX线电压Ubc		遥测	
6106001	交流输入XX线电压Uca		遥测	
6107001	交流输入XX相电流Ia		遥测	
6108001	交流输入XX相电流Ib		遥测	
6109001	交流输入XX相电流Ic		遥测	
6110001	交流输入XX频率		遥测	
6111001	直流电压		遥测	
6112001	负载总电流		遥测	
6113001	整流模块XX电流		遥测	
6114001	整流模块XX温度		遥测	
6115001	电池组XX电流		遥测	
6201001	快充工作允许设定值		遥控	
6202001	均充控制		遥控	
6203001	远程开关机控制		遥控	
6204001	整流模块XX远程开控制		遥控	
6205001	整流模块XX远程关控制		遥控	
6206001	自动均充工作允许设定值		遥控	
6207001	系统控制状态		遥控	
6301001	电池充电限流设定值		遥调	
6302001	温度补偿参考温度设定值		遥调	
6303001	浮充电压设定值		遥调	
6304001	浮充电压低告警设定值		遥调	
6305001	浮充电压高告警设定值		遥调	
6306001	均充工作允许设定		遥调	
6307001	均充持续时间设定值		遥调	
6308001	均充电压设定值		遥调	
6309001	整流模块XX限流点		遥调	
6310001	系统输出最高电压设定值		遥调	
6311001	系统输出最低电压设定值		遥调	
6312001	系统过载告警设定值		遥调	
6313001	均充电流设定值		遥调	
]]


