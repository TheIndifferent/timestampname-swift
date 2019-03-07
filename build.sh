#!/bin/bash
rm -rf .build
exec swift build -c release -Xswiftc -static-stdlib
