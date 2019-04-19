import Foundation
import Rainbow
import SwiftyGPIO

print(
  "RPiPWM LED + Distance Detector\n\n".magenta.bold.underline +
    "# Wiring\n\n".cyan.bold +
    """
  | Name            | Physical Pin | BCM Mapping |
  |-----------------|:------------:|:-----------:|
  | Blue LED        |      12      |     P18     |
  | HC-SR04 Trigger |      37      |     P26     |
  | HC-SR04 Echo    |      40      |     P21     |
  \n
  """.green +
    "# Logging\n".cyan.bold
)

#if os(macOS)
print("This application only runs on the Raspbery Pi 3!\nPress any key to exit...".lightRed)
_ = readLine()
exit(0)
#endif

func cubic(_ x: Float, a: Float, b: Float, c: Float, d: Float) -> Float {
  return a + b * x + c * pow(x,2) + d * pow(x,3)
}

// In centimetres
func distance(from pulseDuration: Double) -> Double {
  return pulseDuration * 17150
}

// In seconds
func durationBetweenTimers(start: UnsafeMutablePointer<timespec>, end: UnsafeMutablePointer<timespec>) -> Double {
  let start = start.pointee
  let end = end.pointee
  
  var seconds: Double = Double(end.tv_sec-start.tv_sec)
  seconds = seconds + Double(end.tv_nsec - start.tv_nsec) / 1000000000.0
  
  return seconds
}

enum GPIOValue: Int {
  case low = 0
  case high = 1
}

let board: SupportedBoard = .RaspberryPi3

let gpios = SwiftyGPIO.GPIOs(for: board)
let pwms = SwiftyGPIO.hardwarePWMs(for: board)!

signal(SIGINT) { _ in
  print("RPiPWM Finished")
  let pwms = SwiftyGPIO.hardwarePWMs(for: .RaspberryPi3)!
  guard let ledPWM = pwms[0]?[.P18] else {
    fatalError()
  }
  ledPWM.stopPWM()
  exit(0)
}

guard let pwmLED = pwms[0]?[.P18] else {
  fatalError("Unable to create ledPWM from PWM 0 P18!")
}

guard let gpioTrigger = gpios[.P26] else {
  fatalError("Unable to create gpioTrigger from GPIO BCM P26")
}

guard let gpioEcho = gpios[.P21] else {
  fatalError("Unable to create gpioEcho from GPIO BCM P21")
}

var duty: Float = 0
var directionIsUp = true

pwmLED.initPWM()

gpioTrigger.direction = .OUT
gpioTrigger.value = GPIOValue.low.rawValue

gpioEcho.direction = .IN

print("Waiting for HC-SR04 to settle!")

sleep(2)

repeat {
  print("Reading distance...")
  
  gpioTrigger.value = GPIOValue.high.rawValue
  
  usleep(10) // 10 microseconds
  
  gpioTrigger.value = GPIOValue.low.rawValue
  
  while gpioEcho.value == GPIOValue.low.rawValue {
    // NO-OP
  }
  
  let startPulseTime: UnsafeMutablePointer<timespec>
  clock_gettime(CLOCK_MONOTONIC, startPulseTime)
  
  while gpioEcho.value == GPIOValue.high.rawValue {
    // NO-OP
  }
  
  let endPulseTime: UnsafeMutablePointer<timespec>
  clock_gettime(CLOCK_MONOTONIC, endPulseTime)
  
  print("Distance: \(distance(from: durationBetweenTimers(start: startPulseTime, end: endPulseTime)))")
  
  let adjDuty = cubic(duty, a: 0.009458672, b: 0.8190362, c: -1.028707, d: 1.224677) * 100
  pwmLED.startPWM(period: 750, duty: max(0, min(100, adjDuty)))
  
  sleep(1)
  
  usleep(5000)
  
  pwmLED.stopPWM()
  
  if duty >= 1 {
    directionIsUp = false
  }
  
  if duty <= 0 {
    directionIsUp = true
  }
  
  duty = directionIsUp ? duty + 0.001 : duty - 0.001
  
  //  print(duty)
} while (true)

/*
 #!/usr/bin/python
 import RPi.GPIO as GPIO
 import time
 
 try:
 GPIO.setmode(GPIO.BOARD) .
 
 PIN_TRIGGER = 7 .
 PIN_ECHO = 11 .
 
 GPIO.setup(PIN_TRIGGER, GPIO.OUT) .
 GPIO.setup(PIN_ECHO, GPIO.IN) .
 
 GPIO.output(PIN_TRIGGER, GPIO.LOW) .
 
 print "Waiting for sensor to settle" .
 
 time.sleep(2) .
 
 print "Calculating distance"
 
 GPIO.output(PIN_TRIGGER, GPIO.HIGH) .
 
 time.sleep(0.00001) .
 
 GPIO.output(PIN_TRIGGER, GPIO.LOW) .
 
 while GPIO.input(PIN_ECHO)==0:
 pulse_start_time = time.time()
 while GPIO.input(PIN_ECHO)==1:
 pulse_end_time = time.time()
 
 pulse_duration = pulse_end_time - pulse_start_time
 distance = round(pulse_duration * 17150, 2)
 print "Distance:",distance,"cm"
 
 finally:
 GPIO.cleanup()
 */
