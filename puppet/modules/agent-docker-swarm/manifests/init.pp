class agent-docker-swarm {
	::docker::image {'swarm': }

	::docker::run { 'swarm':
		image => 'swarm',
		command => "join --addr=${::ipaddress_eth1}:2375"
	}
#	exec { 'consul join swarm-1':
#		path => '/usr/local/bin/',
#		before => Class['docker'],
#		tries => 10,
#		try_sleep => 1,
#	}		
}
