import gpio
import i2c
import aht20

main:
  bus := i2c.Bus
    --sda=gpio.Pin 21
    --scl=gpio.Pin 22

  device := bus.device aht20.I2C-ADDRESS
  driver := aht20.Driver device

  print "humidity = $driver.read-humidity %"
  print "temperature = $driver.read-temperature C"
  print "dew point = $driver.read-dew-point C"
