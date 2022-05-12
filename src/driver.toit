import binary
import serial.device as serial
import math

I2C_ADDRESS ::= 0x38

//
// Driver for the AHT10/AHT20/AHT25 sensors
//
class Driver:
  static INIT_CMD_     ::= 0xBE
  static MEASURE_CMD_  ::= 0xAC
  static RESET_CMD_    ::= 0xBA
  static STATUS_CMD_   ::= 0x71

  static WATER_VAPOR ::= 17.62
  static BAROMETRIC_PRESSURE ::= 243.5

  dev_/serial.Device ::= ?

  constructor dev/serial.Device:
    dev_ = dev 

    // initialize sensor
    sleep --ms=40
    dev_.write #[INIT_CMD_, 0x08, 0x00] 
    sleep --ms=10

    // verify calibration bit
    s := read_status
    if (s & 0x08 != 0x08) :
      throw "failed initialization"
  
  // Reads the humidity and returns it in percentage value 
  read_humidity:
    dev_.write #[MEASURE_CMD_, 0x33, 0x00]
    sleep --ms=80

    check_busy_bit_   
    dat := dev_.read 6
    return compute_hum_ dat
  
  // Reads the temperature and returns it in degrees Celsius 
  read_temperature:
    dev_.write #[MEASURE_CMD_, 0x33, 0x00]
    sleep --ms=80

    check_busy_bit_
    dat := dev_.read 6
    return compute_temp_ dat

  // Reads and compute dew point and returns it in degrees Celsius 
  read_dew_point:
    dev_.write #[MEASURE_CMD_, 0x33, 0x00]
    sleep --ms=80

    check_busy_bit_
    dat := dev_.read 6
    hum := compute_hum_ dat
    temp := compute_temp_ dat

    gamma := math.log(hum / 100) + WATER_VAPOR * temp / (BAROMETRIC_PRESSURE + temp)
    return BAROMETRIC_PRESSURE * gamma / (WATER_VAPOR - gamma)

  // Compute humidity
  compute_hum_ dat:
    hum := ((dat[1] << 16) | (dat[2] << 8) | dat[3]) >> 4
    return hum * 100.0 / 1048576

  // Compute temperature
  compute_temp_ dat:
    temp := ((dat[3] & 0x0F) << 16) | (dat[4] << 8) | dat[5]
    return ((200.0 * temp) / 1048576) - 50

  // Check for busy bit and wait for idle state
  check_busy_bit_:
    tries := 5
    while (read_status & 0x80 != 0):
      tries--
      if tries == 0: throw "sensor busy!"
      sleep --ms=1

  // Perform soft reset
  soft_reset:
    dev_.write #[RESET_CMD_]

  // Read sensor status
  read_status:
    dev_.write #[STATUS_CMD_]
    return (dev_.read 1)[0]

