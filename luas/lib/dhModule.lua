local moduleName = ...

local ybmps = {}
_G[moduleName] = ybmps
package.loaded[moduleName] = ybmps

local base = require "baseModule"
local tableadd = base.tableadd

local c_so = require "cExtend"
local parse_setNextPos = c_so.parse_setNextPos
local parse_setNeedLen = c_so.parse_setNeedLen

--[[ 6000 protocol format
soi	ver	len	boardNo	Seq	Cmd	reserve	info	check	eoi
2	2	4	4	4	2	2	N	2	2
DD BB	01 00					00 00			CC AA
低位在前，len 不能超过2048， check为soi到info的累加和
]]

local soi = {"DD", "BB"};
local eoi = {"CC", "AA"};
local ver = {"01", "00"};

complex = ybmps

function ybmps.pack(cmdCode, boardNo, sNo, info)
	local info_len = 0;
	if info ~= nil then
		info_len = #info
	end
	local rs = {}
	--tableadd(rs, soi)
	tableadd(rs, soi[1])
	tableadd(rs, soi[2])
	tableadd(rs, ver[1])
	tableadd(rs, ver[2])
	info_len = info_len + 12;
	local b_len = base.int_to_4hex(info_len)
	b_len = base.arr_reverse(b_len)
	tableadd(rs, b_len)
	
	local b_bNo = base.int_to_4hex(boardNo)
	b_bNo = base.arr_reverse(b_bNo)
	tableadd(rs, b_bNo)

	local b_sNo = base.int_to_4hex(sNo)
	b_sNo = base.arr_reverse(b_sNo)
	tableadd(rs, b_sNo)

--	local b_code = base.int_to_2hex(cmdCode)
--	b_code = base.arr_reverse(b_code)
--	tableadd(rs, b_code)
	tableadd(rs, cmdCode)

	tableadd(rs, {"00","00"})
	if info ~= nil then
		tableadd(rs, info)
	end
	
	local check = base.getHexCheckSum(rs, 1, #rs)
	local b_check = base.int_to_2hex(check)
	b_check = base.arr_reverse(b_check)
	tableadd(rs, b_check)
	
	tableadd(rs, eoi[1])
	tableadd(rs, eoi[2])

	return rs
end

function ybmps.pack_noinfo(cmdCode, boardNo, sNo)
	return ybmps.pack(cmdCode, boardNo, sNo, nil)
end

local MINLEN = 24
function ybmps.checkPack(c_rs, len)
	local c_packLen = len
	print("c_packLen: " .. c_packLen)
	--check minLen
	if c_packLen < MINLEN then
		parse_setNextPos(c_rs, 0)
		parse_setNeedLen(c_rs, MINLEN - c_packLen)
		return 103
	end
	
	local idxOfSoi = cfb_indexof(c_rs, 0, 0xDD)
	print("idxOfSoi: " .. idxOfSoi)
	if idxOfSoi == -1 then
		parse_setNextPos(c_rs, c_packLen)
		parse_setNeedLen(c_rs, MINLEN)
		return 105
	end
	
	if idxOfSoi > 0 then 	
		c_packLen = c_packLen - idxOfSoi
		--check minLen
		if c_packLen < MINLEN then
			parse_setNextPos(c_rs, idxOfSoi)
			parse_setNeedLen(c_rs, MINLEN - c_packLen)
			return 103
		end
	end
	
	local a,b,c,d = cfb_getData(c_rs, idxOfSoi + 4, 4)
	local b_len = {d, c, b, a}
	local infoLen = base.fourBytesToInt(b_len)
	print("infoLen: " .. infoLen)
	if infoLen + 12 > c_packLen then
		parse_setNextPos(c_rs, idxOfSoi)
		parse_setNeedLen(c_rs, infoLen + MINLEN - c_packLen)
		return 103
	end
	a, b = cfb_getData(c_rs, idxOfSoi + 8 + infoLen, 2)
	local readCheck = base.twoBytesToInt({b, a})
	local calcCheck = cfb_ascParse(c_rs, "tosumcheck", idxOfSoi, infoLen + 8, 1)
	print("two check:" .. readCheck .. " : " .. calcCheck)
	if readCheck ~= calcCheck then
		parse_setNextPos(c_rs, c_packLen + idxOfSoi)
		parse_setNeedLen(c_rs, MINLEN)
		return 104
	end

	a, b = cfb_getData(c_rs, idxOfSoi + 10 + infoLen, 2)
	if (a + 52 ~= 0) and (b + 86 ~= 0) then
		parse_setNextPos(c_rs, c_packLen + idxOfSoi)
		parse_setNeedLen(c_rs, MINLEN)
		return 106
	end

	parse_setNextPos(c_rs, c_packLen)
	csb_setParseNeedLen(c_rs, 0)
	if idxOfSoi ~= 0 then
		parse_packPtrOffset(c_rs, idxOfSoi)
		return 101
	end
	return 101
end


return complex
