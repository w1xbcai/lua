local base = require "baseModule"
local l_gb = require "gbModule"
local l_hnct = require "hnctModule"
local l_md = require "modbusModule"

local g_ver = 0x20
local g_adr = 0x01

--local pack = l_gb.pack({0x10}, g_ver, g_adr, 0x64, 0x45)
--local pack1 = l_gb.pack(nil,  g_ver, g_adr, 0x60, 00)
local pack = l_md.pack({0x00,0x02,0x00,0xE0}, g_adr, 0x06)
local pack1 = l_md.pack({0x00,0x02,0x00,0xE0}, g_adr, 0x06)

print(base.printHexArr(pack, "Tx:"))
print(base.printHexArr(pack1, "Rx:"))

--[[

]]
   
   
   