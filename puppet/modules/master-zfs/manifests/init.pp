class master-zfs {
	if ! Package['ubuntu-zfs'] {

		exec { 'fix-dependencies1':
			cwd => '/home/cromulence',
			command => '/usr/bin/apt-get -f install -y'
		}~>
		exec { 'software-properties-common':
			cwd => '/home/cromulence',
			command => '/usr/bin/apt-get --yes -f install software-properties-common',
		}~>
		exec { 'add-zfs-apt':
			cwd => '/home/cromulence',
			command => '/usr/bin/add-apt-repository --yes ppa:zfs-native/stable',
		}~>
		exec { 'fix-dependencies':
			cwd => '/home/cromulence',
			command => '/usr/bin/apt-get -f install -y'
		}~>
		exec { 'upate-apt-zfs':
			cwd => '/home/cromulence',
			command => '/usr/bin/apt-get update -y',
		}~>
		file { '/home/cromulence/zfs-files':
			ensure => 'directory',
			owner => '1000',
			group => '1000',
			mode => '0600',
			require => User["cromulence"]
		}~>
		file { 'zfs-package-archive':
			path => '/home/cromulence/zfs-files/zfs-package.tgz',
			ensure => file,
                owner => '0',
                group => '0',
                mode => '0644',
                source => 'puppet:///modules/master-zfs/zfs-package.tgz',
		}~>
		exec { 'untar-zfs-package':
			cwd => '/home/cromulence/zfs-files',
			command => '/bin/tar xvf zfs-package.tgz'
		}~>
		package { 'gcc':
			name => 'gcc',
			ensure => installed,
		}~>
		package { 'make':
                name => 'make',
                ensure => installed,
                provider => 'dpkg',
                source => '/home/cromulence/zfs-files/make_3.81-8.2ubuntu3_amd64.deb',
		}~>
		package { 'patch':
			name => 'patch',
			ensure => installed,
			provider => 'dpkg',
			source => '/home/cromulence/zfs-files/patch_2.7.1-4ubuntu2.3_amd64.deb',
		}~>
		package { 'dkms':
			name => 'dkms',
			ensure => installed,
                provider => 'dpkg',
                source => '/home/cromulence/zfs-files/dkms_2.2.0.3-1.1ubuntu5.14.04.5_all.deb',
		}~>
		package { 'zfs-doc':
			name => 'zfs-doc',
			ensure => installed,
			provider => 'dpkg',
			source => '/home/cromulence/zfs-files/zfs-doc_0.6.5.3-1~trusty_amd64.deb',
		}~>
		package { 'zfs-spl':
			name => 'spl',
			ensure => installed,
                provider => 'dpkg',
                source => '/home/cromulence/zfs-files/spl_0.6.5.3-1~trusty_amd64.deb'
		}~>
		package { 'zfs-utils':
			name => 'zfsutils',
			ensure => installed,
			provider => 'dpkg',
			source => '/home/cromulence/zfs-files/zfsutils_0.6.5.3-1~trusty_amd64.deb'
		}~>
		package { 'zfs-package':
			name => 'ubuntu-zfs',
			ensure => installed,
		provider => 'dpkg',
		source => '/home/cromulence/zfs-files/ubuntu-zfs_8~trusty_amd64.deb',
		}~>
		exec { 'add-zfs-driver':
			command => '/sbin/modprobe zfs',
			path => '/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin',
			refreshonly => true,
			user => 'root'
		}~>
	#	zpool { 'storage-zfs-pool-wa':
	#		pool => 'storage-zfs-wa',
	#		ensure => present,
	#		disk => 'todo',
	#	}-> 
		zfs { 'storage-zfs-wa':
			ensure => present,
			quota => '80G',
			compression => 'off',
			mountpoint => '/wa_storage',
		}
	}
}
