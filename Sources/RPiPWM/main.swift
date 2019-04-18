import Foundation
import SwiftyGPIO

let gpios = SwiftyGPIO.GPIOs(for: .RaspberryPi3)

func setGPIOsValue(value: Bool) {
  gpios.forEach { (_, gpio) in
    gpio.value = value ? 1 : 0
  }
}

gpios.forEach { (_, gpio) in
  gpio.direction = .OUT
}

setGPIOsValue(value: false)

signal(SIGINT) { _ in
  setGPIOsValue(value: false)
  print("Blinker Finished")
  exit(0)
}

// Physical Pin -> GPIO Mapping
// 7 -> P4
guard let ledGPIO = gpios[.P4] else {
  fatalError()
}

print("""
LED Blinker

Toggles the output on physical pin 7.
""")

repeat {
  ledGPIO.value = (ledGPIO.value == 0) ? 1 : 0
  Thread.sleep(forTimeInterval: 0.25)
} while (true)

