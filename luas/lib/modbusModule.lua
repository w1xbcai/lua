local moduleName = ...

local modbus = {}    -- 局部的变量
_G[moduleName] = modbus     -- 将这个局部变量最终赋值给模块名
package.loaded[moduleName] = modbus

local base = require "baseModule"

local tableadd = base.tableadd
local checkCrc = base.getCrc_A001

complex = modbus

function modbus.pack(info, adr, cmd)
	local rs = {}
	table.insert(rs, adr)
	table.insert(rs, cmd)
	tableadd(rs, info)
    local check = checkCrc(rs, 1, #rs)
	table.insert(rs, (check >> 8) & 0xFF) 
	table.insert(rs, (check & 0xFF))
--	base.printHexArr(rs,"rs:")
	return rs
end

local min_len = 7
function modbus.checkPack(pack, adr)
--	base.printHexArr(pack,"rs:")
	local packLen = #pack
	if packLen < min_len then
		return 0, min_len - packLen
	end
	local offset = 0
	while offset <= packLen do
		if pack[1] == adr then
			break
		else
			table.remove(pack, 1)
			offset = offset + 1
		end
	end
	
	if offset == packLen + 1 then
		return packLen, min_len
	end
	
	local needLen = pack[3] & 0xFF
	
	if needLen + 5 > packLen - offset then
		return offset, needLen + 5 - packLen + offset
	end
	
	local crc = checkCrc(pack, 1, needLen + 3) & 0xFFFF
	local readCrc = (pack[needLen + 4] & 0xFF) << 8
	readCrc = readCrc | (pack[needLen + 5] & 0xFF)
	
--	print(crc, needLen, readCrc, pack[needLen + 5])
	if crc ~= readCrc then
		return packLen, min_len
	end
	return packLen, 0
end

return complex  -- 返回模块的table




























