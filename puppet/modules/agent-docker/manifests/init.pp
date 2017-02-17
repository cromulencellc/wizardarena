class agent-docker {
	file { '/wa_storage/docker/':
		ensure => 'directory',
		owner => '1000',
		group => '1000',
		mode => '0600',
		require => User['cromulence']
	} ->
	file { "/wa_storage/docker/${hostname}":
		ensure => 'directory',
		owner => '1000',
		group => '1000',
		mode => '0600',
		require => User['cromulence']
	} ->
	file { 'docker-binary-file':
		path => '/usr/bin/docker',
		ensure => file,
		owner => '0',
		group => '0',
		mode => '0755',
		source => 'puppet:///modules/agent-docker/docker',
	}
	file { 'docker-swarm-file':
		path => '/usr/bin/swarm',
		ensure => file,
		owner => '0',
		group => '0',
		mode => '0755',
		source => 'puppet:///modules/agent-docker/swarm',
	}->
	file { 'docker-daemon-file':
		path => '/etc/init.d/docker-daemon',
		ensure => file,
		owner => '0',
		group => '0',
		mode => '0755',
		source => 'puppet:///modules/agent-docker/docker-daemon',
	}->
	service { 'docker-daemon':
		ensure => running
	}
}
