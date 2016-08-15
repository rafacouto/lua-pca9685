--[[

- Lua PCA9685 driver for NodeMCU (ESP8266)
- License: GPLv3 https://www.gnu.org/licenses/gpl-3.0.html
- Author: Rafa Couto <caligari@treboada.net>
- Documentation and examples: https://github.com/rafacouto/lua-pca9685
- Datasheet: https://cdn-shop.adafruit.com/datasheets/PCA9685.pdf

--]]

local pca9685 = {}

local REG_MODE1 = 0x00
local BIT_ALLCALL = 0
local BIT_SLEEP = 4
local BIT_AI = 5
local BIT_RESTART = 7
local REG_LED0 = 0x06
local REG_ALL_LED = 0xfa
local REG_PRE_SCALE = 0xfe
local this = {}

local function _send(reg_addr, ...)
  i2c.start(this.i2c_id)
  i2c.address(this.i2c_id, this.i2c_addr, i2c.TRANSMITTER)
  i2c.write(this.i2c_id, reg_addr)
  i2c.write(this.i2c_id, ...)
  i2c.stop(this.i2c_id)
end

local function _read(reg_addr)
  i2c.start(this.i2c_id)
  i2c.address(this.i2c_id, this.i2c_addr, i2c.TRANSMITTER)
  i2c.write(this.i2c_id, reg_addr)
  i2c.stop(this.i2c_id)
  i2c.start(this.i2c_id)
  i2c.address(this.i2c_id, this.i2c_addr, i2c.RECEIVER)
  local result = i2c.read(this.i2c_id, 1)
  i2c.stop(this.i2c_id)
  return result:byte(1)
end

local function _sendOnOff(reg_addr, on, off)
  if on < 0 or on > 4095 then return end
  if off < 0 or off > 4095 then return end
  local on_l = bit.band(on, 0xff)
  local on_h = bit.rshift(on, 8)
  local off_l = bit.band(off, 0xff)
  local off_h = bit.rshift(off, 8)
  _send(reg_addr, on_l, on_h, off_l, off_h)
end

function pca9685.setPwmFreq(hz)
  if hz < 24 or hz > 1526 then return end
  local mode1 = _read(REG_MODE1)
  _send(REG_MODE1, bit.set(mode1, BIT_SLEEP))
  local prescaler = math.ceil((25000000 / (hz * 4096)) - 1)
  _send(REG_PRE_SCALE, prescaler)
  _send(REG_MODE1, mode1)
  tmr.delay(500)
  _send(REG_MODE1, bit.set(mode1, BIT_RESTART))
end

function pca9685.init(i2c_id, i2c_addr)
  this.i2c_id = i2c_id 
  this.i2c_addr = i2c_addr
  _send(REG_MODE1, bit.set(0, BIT_ALLCALL, BIT_AI))
end

function pca9685.setPwmAll(on, off)
  _sendOnOff(REG_ALL_LED, on, off)
end

function pca9685.setPwm(channel, on, off)
  local reg_addr = REG_LED0 + (channel * 4)
  _sendOnOff(reg_addr, on, off)
end

return pca9685

-- vim: et ts=2 ai sw=2
