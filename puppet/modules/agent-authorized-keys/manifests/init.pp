define agent_authkey () {
        file { "/home/cromulence/.ssh":
		ensure => 'directory',
                owner => '1000',
                group => '1000',
                mode => '0700',
        }
        file { "/home/cromulence/.ssh/authorized_keys":
		source => 'puppet:///modules/agent-authorized-keys/authorized_keys',
                owner => '1000',
                group => '1000',
                mode => '0400'
        }
}

class agent-authorized-keys {
    agent_authkey { 'agent': }
}
