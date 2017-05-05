local moduleName = ...

local s3p = {}    -- 局部的变量
_G[moduleName] = s3p     -- 将这个局部变量最终赋值给模块名
package.loaded[moduleName] = s3p

local base = require "baseModule"

local tableadd = base.tableadd
local checkCrc = base.getCRC_CCITT_XModem

complex = s3p

function s3p.pack(r_info, adr, cid1)
    local info_len = 0
    if r_info ~= nil then
		info_len = #r_info
    end
    local rs = {}
	table.insert(rs, 1, 0x7E)
    tableadd(rs, adr[1])
	tableadd(rs, adr[2])
    tableadd(rs, cid1)
    tableadd(rs, #r_info)
	tableadd(rs, r_info)
	local tmp = checkCrc(rs, #rs)
	tableadd(rs, (tmp >> 8))
	tableadd(rs, (tmp & 0xFF))
	local rs = escape(rs, 2, #rs)
    table.insert(rs, 1, 0x7E)

    return rs
end

function escape(tab, sPos, ePos)
	if ePos > #tab then
		ePos = #tab
	end
	local rs = {}
	
	local idx = sPos
	while idx <= ePos do
		if tab[idx] == 0x7D then
			table.insert(rs, 0x7D)
			table.insert(rs, 0x5D)
--			idx = idx + 1
		elseif tab[idx] == 0x7E then
			table.insert(rs, 0x7D)
			table.insert(rs, 0x5E)
--			idx = idx + 1
		else
			table.insert(rs, tab[idx])
		end
		idx = idx + 1
	end
	return rs
end

local min_len = 8
function s3p.checkPack(pack)
	local packLen = #pack
	if packLen < min_len then
		return 0, min_len - packLen
	end
	local offset = 0
	while offset <= packLen do
		if pack[1] == 0x7E then
			table.remove(pack, 1)
			break
		end
		table.remove(pack, 1)
		offset = offset + 1
	end
	
	if offset == packLen + 1 then
		return packLen, min_len
	end
	
	local temp = {0x7E}
	local one
	local deCodeCount = 0
	for i = 2, packLen - offset do
		one = table.remove(pack, 1)
		if one == 0x7D then
			one = table.remove(pack, 1)
			one = one + 0x20
			deCodeCount = deCodeCount + 1
		end
		table.insert(temp, one)
	end
	
	local readLen = temp[5] & 0xFF
	if readLen + 7  + deCodeCount > packLen - offset then
		return offset, readLen + 7 - packLen + offset + deCodeCount
	end
	
	local crc = checkCrc(temp, readLen + 5)
	local readCrcH = temp[readLen + 6]
	local readCrcL = temp[readLen + 7]
	local readCrc = ((readCrcH & 0xFF) << 8) |  readCrcL
--	print("crc", crc, readCrc, readCrcH, readCrcL, readLen + 5)
	if crc ~= readCrc then
		return packLen, min_len
	end
	return packLen, 0, temp
end

return complex  -- 返回模块的table




























