local moduleName = ...

local midea = {}    -- 局部的变量
_G[moduleName] = midea     -- 将这个局部变量最终赋值给模块名
package.loaded[moduleName] = midea

local base = require "baseModule"

local tableadd = base.tableadd
local getCheckSum = base.getCheckSum

complex = midea

local midea_len = 14

function midea.pack(r_info,  destAdr)
	local rs = {}
	table.insert(rs, 0xA0)
	table.insert(rs, destAdr)
	if r_info ~= nil then
		tableadd(rs, r_info)
	end
	local check = getCheckSum(rs, 1, #rs)
	check = ((check ~ 0xFF) + 1) & 0xFF
	table.insert(rs, check)
	table.insert(rs, 1, 0xAA)
	table.insert(rs, 0x55)
    return rs
end

function midea.checkPack(pack, pwd)
	if pack == nil then
		return 0, midea_len
	end
	
	local packLen = #pack
	if packLen < midea_len then
		return 0, midea_len - packLen
	end
	
	local offset = 0
	while offset <= packLen do
		if pack[1] == 0xAA then
			break
		end
		table.remove(pack, 1)
		offset = offset + 1
	end
	
	if offset == packLen + 1 then
		return packLen, midea_len
	end

	if midea_len > packLen - offset then
		return 0 + offset, midea_len - packLen + offset
	end
	
	if pack[midea_len] ~= 0x55 then
		return packLen, midea_len
	end
	return packLen, 0
end

return complex  -- 返回模块的table



