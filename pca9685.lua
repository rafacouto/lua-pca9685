

-- Lua PCA9685 driver for NodeMCU (ESP8266)
-- License: GPLv3 https://www.gnu.org/licenses/gpl-3.0.html
-- Author: Rafa Couto <caligari@treboada.net>
-- Documentation and examples: https://github.com/rafacouto/lua-pca9685
-- Datasheet: https://cdn-shop.adafruit.com/datasheets/PCA9685.pdf


local PCA9685_MODE1 = 0x00
local PCA9685_LED0_ON_L = 0x06
local PCA9685_ALL_LED_ON_L = 0xfa
local PCA9685_PRE_SCALE = 0xfe

function pca9685__send(reg_addr, ...)
  i2c.start(pca9685_id)
  i2c.address(pca9685_id, pca9685_addr, i2c.TRANSMITTER)
  i2c.write(pca9685_id, reg_addr)
  i2c.write(pca9685_id, ...)
  i2c.stop(pca9685_id)
end

function pca9685__read(reg_addr)
  i2c.start(pca9685_id)
  i2c.address(pca9685_id, pca9685_addr, i2c.TRANSMITTER)
  i2c.write(pca9685_id, reg_addr)
  i2c.stop(pca9685_id)
  i2c.start(pca9685_id)
  i2c.address(pca9685_id, pca9685_addr, i2c.RECEIVER)
  local result = i2c.read(pca9685_id, 1)
  i2c.stop(pca9685_id)
  return result:byte(1)
end

function pca9685__sendOnOff(reg_addr, on, off)
  local on_l = bit.band(on, 0xff), on_h = bit.rshift(on, 8)
  local off_l = bit.band(off, 0xff), off_h = bit.rshift(off, 8)
  pca9685__send(reg_addr, on_l, on_h, off_l, off_h)
end

function pca9685_setPwmFreq(hz)
  local prescaler = 25000000 / (hz * 4096)
  local mode1 = pca9685__read(PCA9685_MODE1)
  pca9685__send(PCA9685_MODE1, bit.bor(mode1, 16))
  pca9685__send(PCA9685_PRE_SCALE, prescaler)
  pca9685__send(PCA9685_MODE1, mode1)
  tmr.delay(1000)
  pca9685__send(PCA9685_MODE1, bit.bor(mode1, 128))
end

function pca9685_setupI2C(i2c_id, i2c_addr, pin_sda, pin_scl)
  i2c.setup(i2c_id, pin_sda, pin_scl, i2c.SLOW)
end

function pca9685_init(i2c_id)
  pca9685_id = i2c_id 
  pca9685__send(PCA9685_MODE1, 33)
end

function pca9685_setPwmAll(on, off)
  pca9685__sendOnOff(PCA9685_ALL_LED_ON_L, on, off)
end

function pca9685_setPwm(channel, on, off)
  local reg_addr = PCA9685_LED0_ON_L + (channel * 4)
  pca9685__sendOnOff(reg_addr, on, off)
end

--[[

-- configuration
I2C_ID = 0
I2C_PIN_SDA = 5
I2C_PIN_SCL = 6
I2C_ADDRESS = 0x40

-- initialization
pca9685_setupI2C(I2C_ID, I2C_PIN_SDA, I2C_PIN_SCL, I2C_ADDRESS)
pca9685_init(I2C_ID)

-- set PWM frequency in Hz (SG90 is 20ms period --> 50Hz)
pca9685_setPwmFreq(50)

-- 
pca9685_setPwmAll(0, 2000)

--]]

-- vim: et ts=2 ai sw=2
