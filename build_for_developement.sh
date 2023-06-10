#/bin/sh

#	build for regular jailbreaks
export DEVELOPER_DIR=/Volumes/Xcode_11_7/Xcode.app/Contents/Developer
make clean
make package

#	build for rootless jailbreaks
export -n DEVELOPER_DIR
make clean
make package THEOS_PACKAGE_SCHEME=rootless
