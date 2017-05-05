local moduleName = ...

local base = {}    -- 局部的变量
_G[moduleName] = base     -- 将这个局部变量最终赋值给模块名
package.loaded[moduleName] = base

complex = base

-- runMode = 1 show log 
local runMode = 1

local auchCRCHi = {
	0x00, 0xC1, 0x81, 0x40, 0x01, 0xC0, 0x80, 0x41, 0x01, 0xC0,
	0x80, 0x41, 0x00, 0xC1, 0x81, 0x40, 0x01, 0xC0, 0x80, 0x41,
	0x00, 0xC1, 0x81, 0x40, 0x00, 0xC1, 0x81, 0x40, 0x01, 0xC0,
	0x80, 0x41, 0x01, 0xC0, 0x80, 0x41, 0x00, 0xC1, 0x81, 0x40,
	0x00, 0xC1, 0x81, 0x40, 0x01, 0xC0, 0x80, 0x41, 0x00, 0xC1,
	0x81, 0x40, 0x01, 0xC0, 0x80, 0x41, 0x01, 0xC0, 0x80, 0x41,
	0x00, 0xC1, 0x81, 0x40, 0x01, 0xC0, 0x80, 0x41, 0x00, 0xC1,
	0x81, 0x40, 0x00, 0xC1, 0x81, 0x40, 0x01, 0xC0, 0x80, 0x41,
	0x00, 0xC1, 0x81, 0x40, 0x01, 0xC0, 0x80, 0x41, 0x01, 0xC0,
	0x80, 0x41, 0x00, 0xC1, 0x81, 0x40, 0x00, 0xC1, 0x81, 0x40,
	0x01, 0xC0, 0x80, 0x41, 0x01, 0xC0, 0x80, 0x41, 0x00, 0xC1,
	0x81, 0x40, 0x01, 0xC0, 0x80, 0x41, 0x00, 0xC1, 0x81, 0x40,
	0x00, 0xC1, 0x81, 0x40, 0x01, 0xC0, 0x80, 0x41, 0x01, 0xC0,
	0x80, 0x41, 0x00, 0xC1, 0x81, 0x40, 0x00, 0xC1, 0x81, 0x40,
	0x01, 0xC0, 0x80, 0x41, 0x00, 0xC1, 0x81, 0x40, 0x01, 0xC0,
	0x80, 0x41, 0x01, 0xC0, 0x80, 0x41, 0x00, 0xC1, 0x81, 0x40,
	0x00, 0xC1, 0x81, 0x40, 0x01, 0xC0, 0x80, 0x41, 0x01, 0xC0,
	0x80, 0x41, 0x00, 0xC1, 0x81, 0x40, 0x01, 0xC0, 0x80, 0x41,
	0x00, 0xC1, 0x81, 0x40, 0x00, 0xC1, 0x81, 0x40, 0x01, 0xC0,
	0x80, 0x41, 0x00, 0xC1, 0x81, 0x40, 0x01, 0xC0, 0x80, 0x41,
	0x01, 0xC0, 0x80, 0x41, 0x00, 0xC1, 0x81, 0x40, 0x01, 0xC0,
	0x80, 0x41, 0x00, 0xC1, 0x81, 0x40, 0x00, 0xC1, 0x81, 0x40,
	0x01, 0xC0, 0x80, 0x41, 0x01, 0xC0, 0x80, 0x41, 0x00, 0xC1,
	0x81, 0x40, 0x00, 0xC1, 0x81, 0x40, 0x01, 0xC0, 0x80, 0x41,
	0x00, 0xC1, 0x81, 0x40, 0x01, 0xC0, 0x80, 0x41, 0x01, 0xC0,
	0x80, 0x41, 0x00, 0xC1, 0x81, 0x40
	}

local auchCRCLo = {
	0x00, 0xC0, 0xC1, 0x01, 0xC3, 0x03, 0x02, 0xC2, 0xC6, 0x06,
	0x07, 0xC7, 0x05, 0xC5, 0xC4, 0x04, 0xCC, 0x0C, 0x0D, 0xCD,
	0x0F, 0xCF, 0xCE, 0x0E, 0x0A, 0xCA, 0xCB, 0x0B, 0xC9, 0x09,
	0x08, 0xC8, 0xD8, 0x18, 0x19, 0xD9, 0x1B, 0xDB, 0xDA, 0x1A,
	0x1E, 0xDE, 0xDF, 0x1F, 0xDD, 0x1D, 0x1C, 0xDC, 0x14, 0xD4,
	0xD5, 0x15, 0xD7, 0x17, 0x16, 0xD6, 0xD2, 0x12, 0x13, 0xD3,
	0x11, 0xD1, 0xD0, 0x10, 0xF0, 0x30, 0x31, 0xF1, 0x33, 0xF3,
	0xF2, 0x32, 0x36, 0xF6, 0xF7, 0x37, 0xF5, 0x35, 0x34, 0xF4,
	0x3C, 0xFC, 0xFD, 0x3D, 0xFF, 0x3F, 0x3E, 0xFE, 0xFA, 0x3A,
	0x3B, 0xFB, 0x39, 0xF9, 0xF8, 0x38, 0x28, 0xE8, 0xE9, 0x29,
	0xEB, 0x2B, 0x2A, 0xEA, 0xEE, 0x2E, 0x2F, 0xEF, 0x2D, 0xED,
	0xEC, 0x2C, 0xE4, 0x24, 0x25, 0xE5, 0x27, 0xE7, 0xE6, 0x26,
	0x22, 0xE2, 0xE3, 0x23, 0xE1, 0x21, 0x20, 0xE0, 0xA0, 0x60,
	0x61, 0xA1, 0x63, 0xA3, 0xA2, 0x62, 0x66, 0xA6, 0xA7, 0x67,
	0xA5, 0x65, 0x64, 0xA4, 0x6C, 0xAC, 0xAD, 0x6D, 0xAF, 0x6F,
	0x6E, 0xAE, 0xAA, 0x6A, 0x6B, 0xAB, 0x69, 0xA9, 0xA8, 0x68,
	0x78, 0xB8, 0xB9, 0x79, 0xBB, 0x7B, 0x7A, 0xBA, 0xBE, 0x7E,
	0x7F, 0xBF, 0x7D, 0xBD, 0xBC, 0x7C, 0xB4, 0x74, 0x75, 0xB5,
	0x77, 0xB7, 0xB6, 0x76, 0x72, 0xB2, 0xB3, 0x73, 0xB1, 0x71,
	0x70, 0xB0, 0x50, 0x90, 0x91, 0x51, 0x93, 0x53, 0x52, 0x92,
	0x96, 0x56, 0x57, 0x97, 0x55, 0x95, 0x94, 0x54, 0x9C, 0x5C,
	0x5D, 0x9D, 0x5F, 0x9F, 0x9E, 0x5E, 0x5A, 0x9A, 0x9B, 0x5B,
	0x99, 0x59, 0x58, 0x98, 0x88, 0x48, 0x49, 0x89, 0x4B, 0x8B,
	0x8A, 0x4A, 0x4E, 0x8E, 0x8F, 0x4F, 0x8D, 0x4D, 0x4C, 0x8C,
	0x44, 0x84, 0x85, 0x45, 0x87, 0x47, 0x46, 0x86, 0x82, 0x42,
	0x43, 0x83, 0x41, 0x81, 0x80, 0x40
	} 

function base.getCheckCrc_A001(tab)
	local crc_h = 0xFF
	local crc_l = 0xFF
	local dataLen = #tab
	local pos = 1
	local idx
	while dataLen > 0 do
		idx = crc_h ~ (tab[pos] & 0xFF)
		crc_h = (crc_l ~ auchCRCHi[idx + 1]) & 0xFFFF
		crc_l = (auchCRCLo[idx + 1]) & 0xFFFF
		pos = pos + 1
		dataLen = dataLen - 1
	end
	return (crc_h << 8) | crc_l
end

function base.getCRC_CCITT_XModem(tab, len)  
	local crcNum = 0;
	for j = 1, len do
		for i = 7, 0, -1 do
			crcNum = crcNum * 2;
			if ((crcNum & 0x10000) ~=0) then
				crcNum = crcNum ~ 0x11021
			end
			if((tab[j] & (1 << i) ) ~= 0)   then
				crcNum =  crcNum ~ 0x11021
			end
		end
--		print(crcNum & 0xFFFF, "JIOJOJ")
	end
	crcNum = crcNum & 0xFFFF
	return crcNum
end

function base.getCrc_A001(tab, start, endPos)
	local crc_h = 0xFF
	local crc_l = 0xFF
	local dataLen = endPos
	if endPos > #tab then
		dateLen = #tab
	end
	local pos = 1
	local idx
	while dataLen > 0 do
		idx = crc_h ~ (tab[pos] & 0xFF)
		crc_h = (crc_l ~ auchCRCHi[idx + 1]) & 0xFFFF
		crc_l = (auchCRCLo[idx + 1]) & 0xFFFF
		pos = pos + 1
		dataLen = dataLen - 1
	end
	return (crc_h << 8) | crc_l
end

function base.getHexCheckSum(tab, startPos, endPos)
	local sum = 0
	local sumEnd = endPos
	if endPos > #tab then
		sumEnd = #tab
	end
	if startPos > endPos then
		return 0
	end
	for i = startPos, sumEnd do
		sum = sum + tonumber(tostring(tab[i]), 16)
	end 
	return sum
end

function base.getCheckSum(tab, startPos, endPos)
	local sum = 0
	local sumEnd = endPos
	if endPos > #tab then
		sumEnd = #tab
	end
	if startPos > endPos then
		return 0
	end
	for i = startPos, sumEnd do 
		sum = sum + (tab[i] & 0xFF)
	end 
--	print("baseCalc:", startPos, endPos, sum)
	return sum
end

function base.twoasc_to_hex(asc1, asc2)
	if asc1 == 0x20 and asc2 == 0x20 then
		return 0xFF
	end
	local hex = string.char(asc1) .. string.char(asc2)
	return tonumber(hex, 16)
end

function base.asc_to_hexstr(asc)
	local len = #asc >> 1
	local rs = {}
	for i = 1, len do
		local tmp = base.twoasc_to_hex(asc[(i << 1) - 1], asc[i << 1])
		table.insert(rs, tmp)
	end
	return rs
end
		
function base.tableadd(src, add)
	if type(src) ~= "table" then
		print("the first arg must be tale")
		return nil
	end
	if src == nil then
		return add
	end
	if add == nil then
		return src
	end
	if type(add) == "table" then
		for i = 1, #add do
			table.insert(src,table.remove(add,1))
		end
	elseif type(add) == "number" then
		table.insert(src, add)
	elseif type(add) == "string" then
		table.insert(src, add)
	end
	return src
end

local g_hex = {"0","1","2","3","4","5","6","7","8","9","A","B","C","D","E","F"}

function base.hex_to_asc(hex)
	local h = hex >> 4
	local l = hex & 0xF
	h = string.byte(g_hex[h + 1])
	l = string.byte(g_hex[l + 1])
	return h,l
end

function base.hexstr_to_asc(tab, startidx, endidx)
	if tab == nil then
		-- error_code
	end
	if endidx > #tab then
		-- error_code
	end
	newtab = {}
	for i = startidx, endidx do
		h,l = base.hex_to_asc(tab[i])
		base.tableadd(newtab, h)
		base.tableadd(newtab, l)
	end
	return newtab
end		

function base.int_to_4bytes(value)
	local rs = {};
	rs[1] = (value >> 24) & 0xFF
	rs[2] = (value >> 16) & 0xFF
	rs[3] = (value >> 8) & 0xFF
	rs[4] = (value) & 0xFF
	return rs
end

function base.int_to_2bytes(value)
	local rs = {};
	rs[1] = (value >> 8) & 0xFF
	rs[2] = (value) & 0xFF
	return rs
end

function base.arr_reverse(arr)
	local rs = {}
	local len = #arr
	for i = len, 1, -1 do
		rs[len - i + 1] = arr[i]
	end
	return rs
end

function base.to_hexarr(arr)
	local rs = {}
    local len = #arr
	for i = 1, len do
		rs[i] = string.format("%02X", arr[i])
	end
	return rs
end

function base.int_to_4hex(value)
	local b = base.int_to_4bytes(value)
	b = base.to_hexarr(b)
	return b
end

function base.int_to_2hex(value)
	local b = base.int_to_2bytes(value)
	b = base.to_hexarr(b)
	return b
end

function base.fourBytesToInt(value)
	local sum = 0
	sum = (value[1]) << 24
	sum = sum | ((value[2] & 0xFF) << 16)
	sum = sum | ((value[3] & 0xFF) << 8)
	sum = sum | (value[4] & 0xFF)
	return sum
end

function base.fourBytesToUint(value)
	local sum = 0
	sum = (value[1] & 0xFF) << 24
	sum = sum | ((value[2] & 0xFF) << 16)
	sum = sum | ((value[3] & 0xFF) << 8)
	sum = sum | (value[4] & 0xFF)
	return sum
end

function base.twoBytesToInt(value)
	local sum = 0
	sum = sum | ((value[1]) << 8)
	sum = sum | (value[2] & 0xFF)
	return sum
end

function base.twoBytesToUint(value)
	local sum = 0
	sum = sum | ((value[1] & 0xFF) << 8)
	sum = sum | (value[2] & 0xFF)
	return sum
end

function base.printHexArr(tab, head)
	if runMode ~= 1 then return end 
	local hex = head
	for j = 1, #tab do
			hex = hex .. string.format("%02X", tab[j]) .. " "
	end
	print(hex)
end

function base.printStr(...)
	if runMode ~= 1 then return end 
	print(...)
end

local SET_GLOBAL = "S"
local PARSE_BIT = "B"
local PARSE_BYTE = "Y"
local LOOP_BEGIN = "L"
local LOOP_END = "E"

function baseparse(parseStruct, startPos, endPos, script, info, parseRs)
	
--	print("parse:",parseStruct, startPos, endPos, #info)
	local idx = startPos
	while idx <= endPos do
		local actionMark = string.sub(parseStruct, idx, idx)
		local item = script[idx]
--		print("parse idx:", idx, item[1], actionMark)
		if actionMark == SET_GLOBAL then
			parseSetItem(item, info)
		elseif actionMark == PARSE_BIT then
			parseBitItem(item, info, parseRs)
		elseif actionMark == PARSE_BYTE then
			parseByteItem(item, info, parseRs)
		elseif actionMark == LOOP_BEGIN then
			local loopEndPos = getLoopEndPos(parseStruct, idx)
--			print("loopEndPos:", loopEndPos, idx)
			if loopEndPos < 0 then 
				--TOPO:: error 
				return 
			end
			local loopCount = getLoopCount(item, parseRs)
			for innerIdx = 1, loopCount do
				baseparse(parseStruct, idx + 1, loopEndPos - 1, script, info, parseRs)
			end
			idx = loopEndPos
		elseif actionMark == LOOP_END then
		
		else
			--TOPO:: error
		end
		idx = idx + 1
	end
end

--YYYYBYSLYE
function getLoopEndPos(parseStruct, startPos)
	if parseStruct == nil then return -1 end
	local len = string.len(parseStruct)
	if len < 2 or len <= startPos then return -1 end
	if startPos < 0 then return -1 end
--	print("end:",  string.sub(parseStruct, startPos, startPos))
	if LOOP_BEGIN ~= string.sub(parseStruct, startPos, startPos) then return -1 end
	local depth = -1
	local endPos = startPos + 1
	local tmp
	for idx = startPos + 1, len do
		tmp = string.sub(parseStruct, idx, idx)
		if tmp == LOOP_END then
			depth = depth + 1
		elseif tmp == LOOP_BEGIN then
			depth = depth - 1
		end
		if depth == 0 then
			return endPos
		end
		endPos = endPos + 1
	end
	return -1
end
--print("Test loop end", getLoopEndPos("YYYYBYSLYE", 8))

--item: {"BS", "P1", "n * m"}
--item: {"BS", "NU", "g_count"
function getLoopCount(item, parseRs)
	local funName = item[2]
	
	local a, b, c, d = string.find(funName,"(%a+)(%d*)")
	local mark = string.upper(c)
	local count = 0

	if mark == "P" then
		local pos = tonumber(d)
		if pos > #parseRs then return 0 end
		pos = #parseRs - pos + 1
		count = tonumber(parseRs[pos][2])
		
	elseif mark == "S" then
		local pos = tonumber(d)
		if pos > #parseRs then return 0 end
		count = tonumber(parseRs[pos][2])
	elseif mark == "NU" then
	
	else
		
	end
	
	if #item > 2 then
		local express = "return " .. string.gsub(item[3], "rs", tostring(count))
		count = load(express)()
	end
--	print("loop count:", funName, a, b, c, d, count, #parseRs)
	return count
end

function getParseStruct(script)
	local len = #script
	if len < 1 then return "" end
	local struct = ""
	for idx = 1, len do
		local item = script[idx][1]
--		print(item)
		if string.upper(item) == "SET" then
			if checkSetItem(item) then
				
			end
			struct = struct .. "S"
		elseif string.upper(item) == "BIT" then
			--TOPO:: CHECK
			struct = struct .. "B"
		elseif string.upper(item) == "BYTE" then
			--TOPO:: CHECK
			struct = struct .. "Y"
		elseif string.upper(item) == "SL" then
			--TOPO:: CHECK
			struct = struct .. "L"
		elseif string.upper(item) == "EL" then
			--TOPO:: CHECK
			struct = struct .. "E"
		else
			--TOPO:: ERROR
		end
	end
	return struct
end

function checkSetItem(item)

end

function checkBitItem(item)

end

function checkByteItem(item)

end

function checkSloopItem(item)

end

function checkEloopItem(item)

end

--item: {"SET", "U16", "g_ct = rs * 0.0004"}
--info: 
function parseSetItem(item, info)
	local rs = doParse(item[2], info)
--	print("set rs:", rs)
	if #item > 2 then
		local express = string.gsub(item[3], "rs", tostring(rs))
		load(express)()
	end
--	print("set g_count:", g_count)
end

--item: {"BIT", "BN1", 600032}
--info: 
function parseBitItem(item, info, parseRs)
	local data = info[1]
	local desc = item[2]
	local code = item[3]
	local descLen = string.len(desc)
	local funName = string.sub(desc, 1, string.len(desc) - 1) 
	local pos = tonumber(string.sub(desc, descLen, descLen))
	local rs
	rs = (data >> pos) & 1
	if string.upper(funName) == "BN" then
		if rs == 1 then
			rs = 0
		else
			rs = 1
		end
	end
	table.insert(parseRs, {code, rs})
	item[3] = code + 1
end

--item: {"BYTE", HF, 6005001, "rs * 0.4"},
--info: 
function parseByteItem(item, info, parseRs)
	local funName = item[2]
	local rs = doParse(funName, info)
--	print("parse rs:", funName, item[1], item[2], item[3], rs)
	if #item > 4 then
		local tmp = tonumber(item[5])
		if rs == tmp then
			rs = -99999999
		end
	end
	if rs ~=  -99999999 then
		if #item > 3 then
			local express = "return " .. string.gsub(item[4], "rs", tostring(rs))
			local temp = load(express)()
			if type(temp) == "boolean" then
				if temp == true then
					rs = 1
				else
					rs = 0
				end
			else
				rs = temp
			end
		end
	end
	if #item > 2 then
		local code = item[3]
		table.insert(parseRs, {code, rs})
		item[3] = code + 1
	end
end

local c_so = require "cExtend"
local BytesToFloat = c_so.BytesToFloat
function doParse(funName, info)
	local name = string.upper(funName)
	local rs, b1, b2, b3, b4
	if name == "F" then
		b1, b2, b3, b4 = table.remove(info, 1), table.remove(info, 1), table.remove(info, 1), table.remove(info, 1)
		rs = c_so.bytesToFloat(b1, b2, b3, b4)
	elseif name == "LF" then
		b1, b2, b3, b4 = table.remove(info, 1), table.remove(info, 1), table.remove(info, 1), table.remove(info, 1)
		rs = c_so.bytesToFloat(b4, b3, b2, b1)
	elseif name == "U8" then
		b1 = table.remove(info, 1)
		if b1 == 0xFF then
			rs = -99999999
		else
			rs = b1 & 0xFF
		end
	elseif name == "U16" then
		b1, b2 = table.remove(info, 1), table.remove(info, 1)
		if b1 == 0xFF  and b2 == 0xFF then
			rs = -99999999
		else
			rs = ((b1 & 0xFF) << 8) | (b2 & 0xFF)
		end
--		print("b1:", b1, b2, rs)
	elseif name == "U32" then
		b1, b2, b3, b4 = table.remove(info, 1), table.remove(info, 1), table.remove(info, 1), table.remove(info, 1)
		rs = (b1 & 0xFF) << 24
		rs = rs | ((b2 & 0xFF) << 16)
		rs = rs | ((b3 & 0xFF) << 8)
		rs = rs | (b4 & 0xFF)
	elseif name == "I8" then
		b1 = table.remove(info, 1) 
--		print("b1:", b1, b1 >> 7, (~b1) & 0xFF)
		if (b1 >> 7) > 0 then
			rs = ((~b1) & 0xFF) + 1
			rs = 0 - rs
		else
			rs = b1
		end
	elseif name == "I16" then
		b1, b2 = table.remove(info, 1), table.remove(info, 1)
		if (b1 >> 7) > 0 then
			b1 = ((~b1) & 0xFF) + 1
			b1 = 0 - b1
		end
		rs = ((b1) << 8) | (b2 & 0xFF)
	elseif name == "I32" then
		b1, b2, b3, b4 = table.remove(info, 1), table.remove(info, 1), table.remove(info, 1), table.remove(info, 1)
		if (b1 >> 7) > 0 then
			b1 = ((~b1) & 0xFF) + 1
			b1 = 0 - b1
		end
		rs = (b1) << 24
		rs = rs | ((b2 & 0xFF) << 16)
		rs = rs | ((b3 & 0xFF) << 8)
		rs = rs | (b4 & 0xFF)
	elseif name == "LU16" then
		b1, b2 = table.remove(info, 1), table.remove(info, 1)
		rs = ((b2 & 0xFF) << 8) | (b1 & 0xFF)
	elseif name == "LU32" then
		b1, b2, b3, b4 = table.remove(info, 1), table.remove(info, 1), table.remove(info, 1), table.remove(info, 1)
		rs = (b4 & 0xFF) << 24
		rs = rs | ((b3 & 0xFF) << 16)
		rs = rs | ((b2 & 0xFF) << 8)
		rs = rs | (b1 & 0xFF)
	elseif name == "LI16" then
		b1, b2 = table.remove(info, 1), table.remove(info, 1)
		if (b1 >> 7) > 0 then
			b1 = ((~b1) & 0xFF) + 1
			b1 = 0 - b1
		end
		rs = ((b2) << 8) | (b1 & 0xFF)
	elseif name == "LI32" then
		b1, b2, b3, b4 = table.remove(info, 1), table.remove(info, 1), table.remove(info, 1), table.remove(info, 1)
		if (b1 >> 7) > 0 then
			b1 = ((~b1) & 0xFF) + 1
			b1 = 0 - b1
		end
		rs = (b4) << 24
		rs = rs | ((b3 & 0xFF) << 16)
		rs = rs | ((b2 & 0xFF) << 8)
		rs = rs | (b1 & 0xFF)
	elseif name == "NU" then
		rs = 1
	elseif name == "JN" then
--		print("******************", #info)
		 for pos = 1, #info do
			 table.remove(info, 1)
		 end
--		info = {}
	else
		-- jeep func  _,_,_,count = string.find(name,"(%a+)(%d)")
		a, b, c, d = string.find(name,"(%a+)(%d*)")
		local mark = string.upper(c)
		
		if mark == "J" then
			local count = tonumber(d)
			if count > #info then
				count = #info
			end
			for pos = 1, count do
				table.remove(info, 1)
			end
		end
	end
	return rs
end

function base.parseScript(script, info, parseRs)
	local struct = getParseStruct(script)
--	print("struct:", struct)
	if #struct < 1 then return end
--	local parseRs = {}
	baseparse(struct, 1, #struct, script, info, parseRs)
	-- for i = 1, #parseRs do
		-- print(parseRs[i][1], parseRs[i][2])
	-- end
end

return complex  -- 返回模块的table
