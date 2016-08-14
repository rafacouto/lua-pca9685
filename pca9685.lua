--[[

- Lua PCA9685 driver for NodeMCU (ESP8266)
- License: GPLv3 https://www.gnu.org/licenses/gpl-3.0.html
- Author: Rafa Couto <caligari@treboada.net>
- Documentation and examples: https://github.com/rafacouto/lua-pca9685
- Datasheet: https://cdn-shop.adafruit.com/datasheets/PCA9685.pdf

--]]

local pca9685 = {}

local PCA9685_MODE1 = 0x00
local PCA9685_LED0_ON_L = 0x06
local PCA9685_ALL_LED_ON_L = 0xfa
local PCA9685_PRE_SCALE = 0xfe
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
  local on_l = bit.band(on, 0xff)
  local on_h = bit.rshift(on, 8)
  local off_l = bit.band(off, 0xff)
  local off_h = bit.rshift(off, 8)
  _send(reg_addr, on_l, on_h, off_l, off_h)
end

function pca9685.setPwmFreq(hz)
  local prescaler = 25000000 / (hz * 4096)
  local mode1 = _read(PCA9685_MODE1)
  _send(PCA9685_MODE1, bit.bor(mode1, 16))
  _send(PCA9685_PRE_SCALE, prescaler)
  _send(PCA9685_MODE1, mode1)
  tmr.delay(1000)
  _send(PCA9685_MODE1, bit.bor(mode1, 128))
end

function pca9685.init(i2c_id, i2c_addr)
  this.i2c_id = i2c_id 
  this.i2c_addr = i2c_addr
  _send(PCA9685_MODE1, 33)
end

function pca9685.setPwmAll(on, off)
  _sendOnOff(PCA9685_ALL_LED_ON_L, on, off)
end

function pca9685.setPwm(channel, on, off)
  local reg_addr = PCA9685_LED0_ON_L + (channel * 4)
  _sendOnOff(reg_addr, on, off)
end

return pca9685

-- vim: et ts=2 ai sw=2
