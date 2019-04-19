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

struct DistanceMath {
  private init() {}
  
  // In centimetres
  static func distance(from pulseDuration: Double) -> Double {
    return pulseDuration * 17150
  }
  
  // In seconds
  static func durationBetweenPulseTimes(start: timespec, end: timespec) -> Double {
    var seconds: Double = Double(end.tv_sec-start.tv_sec)
    seconds = seconds + Double(end.tv_nsec - start.tv_nsec) / 1000000000.0
    
    return seconds
  }
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

pwmLED.initPWM()

gpioTrigger.direction = .OUT
gpioTrigger.value = GPIOValue.low.rawValue

gpioEcho.direction = .IN

print("Waiting for HC-SR04 to settle!")

sleep(2)

repeat {
  gpioTrigger.value = GPIOValue.high.rawValue
  
  usleep(10) // 10 microseconds
  
  gpioTrigger.value = GPIOValue.low.rawValue
  
  var attempts = 0
  while gpioEcho.value == GPIOValue.low.rawValue {
    usleep(10_000)
    attempts = attempts + 1
    if attempts > 10 {
      continue
    }
  }
  
  var startPulseTime = timespec()
  clock_gettime(CLOCK_MONOTONIC, &startPulseTime)
  
  attempts = 0
  while gpioEcho.value == GPIOValue.high.rawValue {
    usleep(10_000)
    attempts = attempts + 1
    if attempts > 10 {
      continue
    }
  }
  
  var endPulseTime = timespec()
  clock_gettime(CLOCK_MONOTONIC, &endPulseTime)
  
  let distance = DistanceMath.distance(from: DistanceMath.durationBetweenPulseTimes(start: startPulseTime, end: endPulseTime))
  print("Distance: \(distance)")
  
  if !(0.0...400.0).contains(distance) {
    print("Invalid distance.")
    continue
  }
  
  let adjDuty = cubic(Float(distance)/400, a: 0.0011964, b: 0.70587, c: 1.745203, d: 2.069473)*100
  pwmLED.stopPWM()
  pwmLED.startPWM(period: 750, duty: max(0, min(100, adjDuty)))
  
  usleep(100_000)
} while (true)
