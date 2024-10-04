import binary
import serial.device as serial
import math

I2C-ADDRESS ::= 0x38

//
// Driver for the AHT10/AHT20/AHT25 sensors
//
class Driver:
  static INIT-CMD_     ::= 0xBE
  static MEASURE-CMD_  ::= 0xAC
  static RESET-CMD_    ::= 0xBA
  static STATUS-CMD_   ::= 0x71

  static WATER-VAPOR ::= 17.62
  static BAROMETRIC-PRESSURE ::= 243.5

  dev_/serial.Device ::= ?

  constructor dev/serial.Device:
    dev_ = dev

    // initialize sensor
    sleep --ms=40
    dev_.write #[INIT-CMD_, 0x08, 0x00]
    sleep --ms=10

    // verify calibration bit
    s := read-status
    if (s & 0x08 != 0x08) :
      throw "failed initialization"

  // Reads the humidity and returns it in percentage value
  read-humidity:
    dev_.write #[MEASURE-CMD_, 0x33, 0x00]
    sleep --ms=80

    check-busy-bit_
    dat := dev_.read 6
    return compute-hum_ dat

  // Reads the temperature and returns it in degrees Celsius
  read-temperature:
    dev_.write #[MEASURE-CMD_, 0x33, 0x00]
    sleep --ms=80

    check-busy-bit_
    dat := dev_.read 6
    return compute-temp_ dat

  // Reads and compute dew point and returns it in degrees Celsius
  read-dew-point:
    dev_.write #[MEASURE-CMD_, 0x33, 0x00]
    sleep --ms=80

    check-busy-bit_
    dat := dev_.read 6
    hum := compute-hum_ dat
    temp := compute-temp_ dat

    gamma := math.log(hum / 100) + WATER-VAPOR * temp / (BAROMETRIC-PRESSURE + temp)
    return BAROMETRIC-PRESSURE * gamma / (WATER-VAPOR - gamma)

  // Compute humidity
  compute-hum_ dat:
    hum := ((dat[1] << 16) | (dat[2] << 8) | dat[3]) >> 4
    return hum * 100.0 / 1048576

  // Compute temperature
  compute-temp_ dat:
    temp := ((dat[3] & 0x0F) << 16) | (dat[4] << 8) | dat[5]
    return ((200.0 * temp) / 1048576) - 50

  // Check for busy bit and wait for idle state
  check-busy-bit_:
    tries := 5
    while (read-status & 0x80 != 0):
      tries--
      if tries == 0: throw "sensor busy!"
      sleep --ms=1

  // Perform soft reset
  soft-reset:
    dev_.write #[RESET-CMD_]

  // Read sensor status
  read-status:
    dev_.write #[STATUS-CMD_]
    return (dev_.read 1)[0]

