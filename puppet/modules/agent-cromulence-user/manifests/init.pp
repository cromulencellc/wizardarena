define agent_cromulence_user () {

        # create the user in passwd, shadow, and group
        file_line { "passwd-cromulence-$name":
                ensure => 'present',
                path => "/etc/passwd",
                match => "^cromulence",
                line => "cromulence:x:1000:1000:cromulence,,,:/home/cromulence:/bin/bash"
        }
        file_line { "shadow-cromulence-$name":
                ensure => 'present',
                path => "/etc/shadow",
                match => "cromulence",
                line => "cromulence:x:16756:0:99999:7:::"
        }
        file_line { "group-cromulence-$name":
                ensure => 'present',
                path => "/etc/group",
                match => "^sudo",
                line => "sudo:x:27:cromulence"
        }
        file_line { "group2-cromulence-$name":
                ensure => 'present',
                path => "/etc/group",
                match => "^cromulence",
                line => "cromulence:x:1000:"
        }

        # create the home directory
        file { "/home/cromulence":
                ensure => 'directory',
                owner => "1000",
                group => "1000",
                mode => '0600',
                require => File_line["passwd-cromulence-$name"],
        }
}

class agent-cromulence-user {
        user { 'cromulence':
                ensure => present,
                uid => '1000',
                gid => '1000',
                home => '/home/cromulence',
                groups => 'sudo'
        }

        file { '/home/cromulence':
                ensure => 'directory',
                owner => '1000',
                group => '1000',
                mode => '0600',
                require => User["cromulence"]
        }
}
