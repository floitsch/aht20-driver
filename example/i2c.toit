import gpio
import i2c
import aht20

main:
  bus := i2c.Bus
    --sda=gpio.Pin 21
    --scl=gpio.Pin 22

  device := bus.device aht20.I2C_ADDRESS
  driver := aht20.Driver device

  print "humidity = $driver.read_humidity %"
  print "temperature = $driver.read_temperature C"
  print "dew point = $driver.read_dew_point C"
