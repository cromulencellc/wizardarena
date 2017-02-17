class agent-nfs {
	class {'::nfs':
		server_enabled => false,
		client_enabled => true,
	}
	nfs::client::mount {'/wa_storage':
		server => 'master1',
		share => '/wa_storage'
	}
}
