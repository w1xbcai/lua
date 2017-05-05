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

function getAllCheck(tab, startPos, endPos)
        local sum = getCheckSum(tab, startPos, endPos)
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

        local allcheck = getAllCheck(rs, 1, #rs)
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
    
local g_gb_min_len = 18
function gb.checkPack(pack)
	local packLen = #pack
	
	if packLen < g_gb_min_len then
		return 0, g_gb_min_len - packLen
	end
	
	local offset = 0
	while offset <= packLen do
		if pack[1] == 0x7E then
			break
		end
		table.remove(pack, 1)
		offset = offset + 1
	end
	
	if offset == packLen + 1 then
		return packLen, g_gb_min_len
	end
	
	-- if ((string.format("%02X", (pack[1]&0xFF)) ~= "7E")) then
		-- return packLen, g_gb_min_len
	-- end
	
	local infoLenBytes = asc_to_hexstr({pack[10],pack[11],pack[12],pack[13]})
	local infoLenCalc = ((infoLenBytes[1] & 0xF) << 8) | infoLenBytes[2]
	if infoLenCalc + g_gb_min_len > packLen - offset then
		return 0 + offset, infoLenCalc + g_gb_min_len - packLen + offset
	end
	
	-- local dd = ""
	-- for j = 1, #pack do
			-- dd = dd .. string.format("%02X", pack[j]) .. " "
	-- end
	-- print("check:" .. dd)
	
	local calcCheck = getAllCheck(pack, 2, infoLenCalc + 18 - 5)
	local readCheckByte = asc_to_hexstr({pack[infoLenCalc + 18 - 4],pack[infoLenCalc + 18 - 3],pack[infoLenCalc + 18 - 2],pack[infoLenCalc + 18 - 1]})
	local readCheck = ((readCheckByte[1]) << 8) | readCheckByte[2]
	
--	print("check:", calcCheck, readCheck)
	if calcCheck ~= readCheck then
		return packLen, g_gb_min_len
	end
	
	if ((pack[infoLenCalc + 18]) ~= 0x0D) then
		return packLen, g_gb_min_len
	end
	
	return packLen, 0
end

return complex  -- 返回模块的table



