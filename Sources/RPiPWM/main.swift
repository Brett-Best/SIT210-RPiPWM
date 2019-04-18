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

ledPWM.startPWM(period: 500, duty: 50)

repeat {
sleep(1)
} while (true)

