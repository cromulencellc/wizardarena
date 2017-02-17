class server-monitoring {
	file { "/root/collect-stats.pl":
		ensure => "present",
		source => "puppet:///modules/server-monitoring/collect-stats.pl",
		owner => "root",
		group => "root",
		mode => "0700",
	}
	cron { "collect-stats":
		command => "/root/collect-stats.pl",
		user => root,
		minute => '*',
		require => File["/root/collect-stats.pl"],
	}
	file_line { 'graphite-host':
		path => "/etc/hosts",
		line => "52.3.115.65	graphite",
	}
}
