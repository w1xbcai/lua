local moduleName = ...

local tcl = {}    -- 局部的变量
_G[moduleName] = tcl     -- 将这个局部变量最终赋值给模块名
package.loaded[moduleName] = tcl

local base = require "baseModule"

local tableadd = base.tableadd
local checkCrc = base.getCheckSum

complex = tcl

function tcl.pack(r_info, adr, cmd)
    local info_len = 0
    if r_info ~= nil then
		info_len = #r_info
    end
    local rs = {}
	table.insert(rs, 0xF4)
	table.insert(rs, 0xF5)
    table.insert(rs, 5)
	table.insert(rs, adr[1])
	table.insert(rs, adr[2])
    table.insert(rs, cmd)
	table.insert(rs, r_info[1])
	table.insert(rs, r_info[2])
	local sum = checkCrc(rs, 3, #rs)
--	print("sum", string.format("%02X", sum))
	table.insert(rs, sum)
	table.insert(rs, 0xF4)
	table.insert(rs, 0xFB)
    return rs
end

local min_len = 11
function tcl.checkPack(pack)
	local packLen = #pack
	if packLen < min_len then
		return 0, min_len - packLen
	end
	local offset = 0
	while offset <= packLen do
		if pack[1] == 0xF4 and pack[2] == 0xF5 then
			break
		else
			table.remove(pack, 1)
			offset = offset + 1
		end
	end
	
	if offset == packLen + 1 then
		return packLen, min_len
	end
	
	local infoLen = pack[3]
	if infoLen + 6 > packLen - offset then
		return offset, infoLen + 6 - packLen + offset
	end

	local sum = checkCrc(pack, 3, #pack - 3) & 0xFF
	local readSum = pack[infoLen + 4]
--	print(sum, readSum, pack[infoLen + 4])
	if sum ~= readSum then
		return packLen, min_len
	end
	
--	print(infoLen)
	if pack[infoLen + 5] ~= 0xF4 or pack[infoLen + 6] ~= 0xFB then
		return packLen, min_len
	end
	
--	base.printHexArr(pack, "Tx:")
	
	local temp = {0xF4, 0xF5}
	local one
	for i = 3, packLen - offset - 2 do
		one = table.remove(pack, 3)
		if one == 0xF4 then
			table.insert(temp, table.remove(pack, 1))
		else
			table.insert(temp, one)
		end
	end
	table.insert(temp, 0xF4)
	table.insert(temp, 0xFB)
	return packLen, 0, temp
end

return complex  -- 返回模块的table




























