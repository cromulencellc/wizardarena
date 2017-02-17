#
# keys to the kingdom!
#
import 'creds.pp'

node /^agent\d+$/ {
    user { 'agent':
        ensure => present,
    }


    include agent-cromulence-user
    include agent-authorized-keys
    include agent-cgc-kernel
    
    include agent-nfs

    include agent-docker    

}

node /^master\d+$/ {
    user { 'master':
	ensure => present,
    }

    
    include agent-cromulence-user
    include agent-authorized-keys
    include master-swarm

    include master-zfs
    include master-nfs
}
