#!/bin/bash

#	-v /home/joe/cromulence/wa-monitoring/mounts/conf/graphite:/var/lib/graphite/conf/ \
#	-v /home/joe/cromulence/wa-monitoring/mounts/log:/var/log/ \
docker run --name wa-graphite \
	-d -p 8080:8080 -p 2003:2003 -p 2004:2004 -p 7002:7002 \
	-v /home/joe/cromulence/wa-monitoring/mounts/data/graphite:/var/lib/graphite/storage/whisper \
	graphite

docker run --name wa-grafana \
	-d -p 3000:3000 \
	-v /home/joe/cromulence/wa-monitoring/mounts/var/lib/grafana:/var/lib/grafana \
	grafana/grafana
