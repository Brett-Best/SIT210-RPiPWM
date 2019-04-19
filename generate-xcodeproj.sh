#!/bin/bash

swift package update
swift package generate-xcodeproj --xcconfig-overrides Sources/macos.xcconfig
