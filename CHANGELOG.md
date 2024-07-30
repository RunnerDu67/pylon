## 2.0.1
* Pylons can now receive an input stream instead of relying on the upstream to pump in data
* When pylons are given a stream, they can connect it to other pylons across screens and still update
* Added an option to disable focus updates while keeping childUpdates enabled

## 2.0.0
* BREAKING: Rewritten to be more reliable and allow modifications
* Please read README & Examples!

## 1.0.4
* FIX: When mirroring, skips already existing types to prevent a previous pylon overwritten from accidentally becoming the new value

## 1.0.3
* Added .withPylonNullable for futures and streams

## 1.0.2

* Attempt to find T? when searching for T with pylon<T>()
* Added pylon<T>(or: T) to provide a default value if the pylon is not found

## 1.0.1

* Stream Extensions

## 1.0.0

* Initial Release
