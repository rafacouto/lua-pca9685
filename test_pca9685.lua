
-- configuration
I2C_ID = 0
I2C_PIN_SDA = 5
I2C_PIN_SCL = 6
I2C_ADDRESS = 0x40

-- initialization
i2c.setup(I2C_ID, I2C_PIN_SDA, I2C_PIN_SCL, i2c.SLOW)
pca9685 = require "pca9685"
pca9685.init(I2C_ID, I2C_ADDRESS)

-- move 1000/4096 to 2000/4096 every 5s
tmr.alarm(0, 5000, tmr.ALARM_AUTO, function()
  if off==2000 then off=1000 else off=2000 end
  pca9685.setPwmAll(0,off)
end)

