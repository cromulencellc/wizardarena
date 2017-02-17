class switch-monitoring {
	file { "/root/collect-switch-stats.pl":
		ensure => "present",
		source => "puppet:///modules/switch-monitoring/collect-switch-stats.pl",
		owner => "root",
		group => "root",
		mode => "0700",
	}
	cron { "collect-switch-stats":
		command => "/root/collect-switch-stats.pl",
		user => root,
		minute => '*',
		require => File["/root/collect-switch-stats.pl"],
	}
	file_line { 'graphite-host-switch':
		path => "/etc/hosts",
		line => "$graphite_server	graphite",
	}

	# require for perl Net::SSH::Expect install
	package { 'make':
		ensure => 'present',
	}
	package { 'libexpect-perl':
		ensure => 'present',
	}
}
