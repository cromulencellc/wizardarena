#!/bin/sh

pushd $(dirname $0)/..
mkdir -p test/darpa-examples
cp tmp/network-appliance/examples/*.rules test/darpa-examples
popd
