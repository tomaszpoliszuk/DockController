#/bin/sh

#	build for regular jailbreaks
export DEVELOPER_DIR=/Volumes/Xcode_11_7/Xcode.app/Contents/Developer
make clean
make package FINALPACKAGE=1

#	build for rootless jailbreaks
export -n DEVELOPER_DIR
make clean
make package FINALPACKAGE=1 THEOS_PACKAGE_SCHEME=rootless
