#!/bin/bash
exec swift build -c release -Xswiftc -static-stdlib
