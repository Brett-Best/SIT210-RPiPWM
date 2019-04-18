import Foundation
import SwiftyGPIO

let pwms = SwiftyGPIO.hardwarePWMs(for: .RaspberryPi3)!

signal(SIGINT) { _ in
  print("RPiPWM Finished")
  let pwms = SwiftyGPIO.hardwarePWMs(for: .RaspberryPi3)!
  guard let ledPWM = pwms[0]?[.P18] else {
    fatalError()
  }
  ledPWM.stopPWM()
  exit(0)
}

// Physical Pin -> GPIO Mapping
// 7 -> P4
guard let ledPWM = pwms[0]?[.P18] else {
  fatalError()
}

print("""
RPiPWM LED + Distance Detector

xxx
""")

ledPWM.initPWM()

var duty: Float = 0
var directionIsUp = true

repeat {
  ledPWM.startPWM(period: 500, duty: duty)
  
  usleep(100_000)
  
  ledPWM.stopPWM()
  
  if duty >= 100 {
    directionIsUp = false
  }
  
  if duty <= 100 {
    directionIsUp = true
  }
  
  duty = directionIsUp ? duty + 0.1 : duty - 0.1
} while (true)

