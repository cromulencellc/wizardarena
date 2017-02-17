class master-swarm {
	file { 'docker-binary-file':
		path => '/usr/bin/docker',
		ensure => file,
		owner => '0',
		group => '0',
		mode => '0755',
		source => 'puppet:///modules/master-swarm/docker',
	}
	file { 'docker-swarm-file':
		path => '/usr/bin/swarm',
		ensure => file,
		owner => '0',
		group => '0',
		mode => '0755',
		source => 'puppet:///modules/master-swarm/swarm',
	}
	file { 'swarm-server-config-file':
		path => '/etc/default/swarm-server',
		ensure => file,
		owner => '0',
		group => '0',
		mode => '0644',
		source => 'puppet:///modules/master-swarm/swarm-server-config',
	}->
	file { 'swarm-server-init-file':
		path => '/etc/init.d/swarm-server',
		ensure => file,
		owner => '0',
		group => '0',
		mode => '0755',
		source => 'puppet:///modules/master-swarm/swarm-server',
		require => File['/usr/bin/swarm']
	}->
	service {'swarm-server':
		ensure => 'running',
	}
}
