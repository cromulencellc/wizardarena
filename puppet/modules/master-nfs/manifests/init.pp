class master-nfs {
	#package { 'nfs-kernel-server':
	#	ensure => latest,
	#}->
	class { '::nfs':
		server_enabled => true
	}
	nfs::server::export { '/wa_storage':
		ensure => 'mounted',
		clients => 'agent1(rw,insecure,async,no_root_squash) agent2(rw,insecure,async,no_root_squash)'
	}
}
