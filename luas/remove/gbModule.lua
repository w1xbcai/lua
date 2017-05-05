local moduleName = ...

local gb = {}    -- 局部的变量
_G[moduleName] = gb     -- 将这个局部变量最终赋值给模块名
package.loaded[moduleName] = gb

local base = require "baseModule"

local tableadd = base.tableadd
local hex_to_asc = base.hex_to_asc
local hexstr_to_asc = base.hexstr_to_asc
local asc_to_hexstr = base.asc_to_hexstr
local twoasc_to_hex = base.twoasc_to_hex
local getCheckSum = base.getCheckSum

complex = gb

function gb.getLenCheck(len)
        if (len == 0) then
                return 0
        end
        local sum = 0;
        sum = sum + ((len & 0x0f00) >> 8)
        sum = sum + ((len & 0x00f0) >> 4)
        sum = sum + (len & 0xf)
        sum = sum & 0x0f
        sum = ~sum
        sum = sum & 0xf
        sum = sum + 1
        sum = sum << 4
        return sum
end

function getAllCheck(tab)
        local sum = getCheckSum(tab)
        sum = sum & 0xffff
        sum = ~sum
        sum = sum & 0xffff
        sum = sum + 1
        return sum
end

function gb.pack(r_info, ver, adr, cid1, cid2)
        local info_len = 0
        if r_info ~= nil then
                info_len = #r_info
        end
        local rs = {}
        tableadd(rs, ver)
        tableadd(rs, adr)
        tableadd(rs, cid1)
        tableadd(rs, cid2)
 --     print("lencheck: " .. getLenCheck(info_len * 2) .. " :" .. info_len)
        tableadd(rs, gb.getLenCheck(info_len * 2))

        tableadd(rs, info_len * 2)
        tableadd(rs, r_info)
        rs = hexstr_to_asc(rs, 1, #rs)

        local allcheck = getAllCheck(rs)
--        print(string.format("tallcheck: %02X", allcheck))
        local check_h = (allcheck & 0xff00) >> 8
        local check_l = (allcheck & 0x00ff)
--      print(string.format("h: %02X,  l: %02X", check_h, check_l))
        hh,hl = hex_to_asc(check_h)
        lh,ll = hex_to_asc(check_l)
--      print(string.format("h: %02X,  %02X,  l: %02X, %02X", hh, hl, lh, ll))
        tableadd(rs, hh)
        tableadd(rs, hl)
        tableadd(rs, lh)
        tableadd(rs, ll)
        table.insert(rs, 1, 0x7E)
        tableadd(rs, 0x0D)
    return rs
end

--[[
	LUA_PASS			=	101,	//解包成功
	LUA_FAILED			=	102,	//解包失败,原因不明,缺省错误
	LUA_LENGTH_ERROR	=	103,	//长度不正确
	LUA_CHECK_FAILED	=	104,	//包校验错误
	LUA_NO_SOI			=   105,
	LUA_NO_EOI			=	106,
	LUA_DIRTY_DATA		=	107,	//
	LUA_NEED_MOREDATA	=	108,
	LUA_DATA_UNMATCH	=	109,
]]  
   
local MINLEN = 18
function gb.checkPack(c_rs)
	--get packLen from c
	local c_packLen = csb_getParsePackLen(c_rs)
--	print("c_packLen: " .. c_packLen)
	--check minLen
	if c_packLen < MINLEN then
		csb_setParseNextPos(c_rs, 0)
		csb_setParseNeedLen(c_rs, MINLEN - c_packLen)
		return 103
	end
	
	--check SOI
	local idxOfSoi = cfb_indexof(c_rs, 0, 0x7E)
	if idxOfSoi == -1 then
		csb_setParseNextPos(c_rs, c_packLen)
		csb_setParseNeedLen(c_rs, MINLEN)
		return 105
	end
	if idxOfSoi > 0 then 
		c_packLen = c_packLen - idxOfSoi
		--check minLen
		if c_packLen < MINLEN then
			csb_setParseNextPos(c_rs, idxOfSoi)
			csb_setParseNeedLen(c_rs, MINLEN - c_packLen)
			return 103
		end
	end
		
	local a,b,c,d = cfb_getData(c_rs, idxOfSoi + 9, 4)
	local len = {a,b,c,d}
	local rs = asc_to_hexstr(len)
	local infoLen = ((rs[1] & 0xF) << 8) | rs[2]
	local std_infoLenCheck = gb.getLenCheck(infoLen) >> 4
	local local_infoLenCheck = (rs[1] & 0xF0) >> 4
--	print("lens: " .. c_packLen .. " : " .. idxOfSoi .. " : " .. infoLen)
--	print("len: " .. infoLen .. " check: " .. local_infoLenCheck .. " : " .. std_infoLenCheck)
	if std_infoLenCheck~= local_infoLenCheck then
		csb_setParseNextPos(c_rs, c_packLen + idxOfSoi)
		csb_setParseNeedLen(c_rs, MINLEN)
		return 104
	end
	if infoLen +  MINLEN > c_packLen then
		csb_setParseNextPos(c_rs, idxOfSoi)
		csb_setParseNeedLen(c_rs, infoLen + MINLEN - c_packLen)
		return 103
	end
	
	local idxOfEoi = idxOfSoi + infoLen + 17
	a = cfb_getData(c_rs, idxOfEoi, 1)
--	print("EOI" .. string.format("%02X", a))
	if a ~= 0x0D then
	    csb_setParseNextPos(c_rs, c_packLen - 1)
            csb_setParseNeedLen(c_rs, MINLEN - 1)
	    return 106
	end
	
	a,b,c,d = cfb_getData(c_rs, idxOfEoi - 4, 4)
	len = {a,b,c,d}
	rs = asc_to_hexstr(len)
	local allLen = ((rs[1] ) << 8) | rs[2]
	local checksum = cfb_ascParse(c_rs, "tosumcheck", idxOfSoi + 1, infoLen + 12, 1)
--	print("check:" .. checksum)
	checksum = checksum & 0xFFFF;
	checksum = ~checksum
	checksum = checksum + 1
	checksum = checksum & 0xFFFF;
--	print("check sum  :" .. checksum .. ":" .. allLen)
	if checksum~= allLen then
--		print("len1 " .. checksum .. ": len2 " .. allLen)
		csb_setParseNextPos(c_rs, c_packLen + idxOfSoi)
		csb_setParseNeedLen(c_rs, MINLEN)
		return 104
	end

	csb_setParseNextPos(c_rs, c_packLen)
	csb_setParseNeedLen(c_rs, 0)
	if idxOfSoi ~= 0 then
		cfb_packPtrOffset(c_rs, idxOfSoi)
		return 107
	end
	return 101
end

return complex  -- 返回模块的table



