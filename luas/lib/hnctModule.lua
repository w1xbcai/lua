local moduleName = ...

local hnct = {}    -- 局部的变量
_G[moduleName] = hnct     -- 将这个局部变量最终赋值给模块名
package.loaded[moduleName] = hnct

local base = require "baseModule"

local tableadd = base.tableadd
local getCheckSum = base.getCheckSum

complex = hnct

local hnct_len = 73

function decode(data, pwd)
	local password = {(pwd >> 8) & 0xFF, pwd & 0xFF}
--	base.printHexArr(password, "CHECK:")
	for idx = 1, #data do
		local pos = (idx - 1) % 2 + 1
		data[idx] = (data[idx] ~ (((password[pos]) ~ 0xDE)));
	end
end

function hnct.pack(r_info, machineNum, cmd, stat, seq, pwd)
	local rs = {}
	table.insert(rs, 0xEB)
	table.insert(rs, (machineNum >> 8) & 0xFF)
	table.insert(rs, (machineNum & 0xFF))
	table.insert(rs, cmd)
	table.insert(rs, stat)
	table.insert(rs, (seq >> 8) & 0xFF)
	table.insert(rs, (seq & 0xFF))
	local addLen = hnct_len - 9
	if r_info ~= nil then
		tableadd(rs, r_info)
		addLen = addLen - #r_info
	end
	for idx = 1, addLen + 1 do
		table.insert(rs, 0)
	end
	table.insert(rs, 0xEA)
	local sum = getCheckSum(rs, 1, #rs)
	sum = (sum & 0xFF) ~ 0xAC
	rs[hnct_len - 1] = sum
	decode(rs, pwd)
    return rs
end

function hnct.checkPack(pack, pwd)
	if pack == nil then
		return 0, hnct_len
	end
	
	local packLen = #pack
	if packLen < hnct_len then
		return 0, hnct_len - packLen
	end
	
	decode(pack, pwd)
	
	local offset = 0
	while offset <= packLen do
		if pack[1] == 0xEB then
			break
		end
		table.remove(pack, 1)
		offset = offset + 1
	end
	
	if offset == packLen + 1 then
		return packLen, hnct_len
	end

	if hnct_len > packLen - offset then
		return 0 + offset, hnct_len - packLen + offset
	end
	
	if pack[hnct_len] ~= 0xEA then
		return packLen, hnct_len
	end
	return packLen, 0
end

return complex  -- 返回模块的table



