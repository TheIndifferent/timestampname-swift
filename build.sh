#!/bin/bash -xe
rm -rf .build
exec swift build -c release -Xswiftc -static-stdlib
