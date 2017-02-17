class master-zfs {
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
	package { 'zfs-spl':
		name => 'spl',
		ensure => installed,
		provider => 'dpkg',
		source => '/home/cromulence/zfs-files/spl_0.6.5.3-1~trusty_amd64.deb',
		require => File['/home/cromulence/zfs-files/spl_0.6.5.3-1~trusty_amd64.deb'],
	}~>	
	package { 'zfs-package':
		name => 'ubuntu-zfs',
		ensure => installed,
		provider => 'dpkg',
		source => '/home/cromulence/zfs-files/ubuntu-zfs_8~trusty_amd64.deb',
		require => File['/home/cromulence/zfs-files/ubuntu-zfs_8~trusty_amd64.deb'],
	}~>
	zfs { 'storage-zfs-wa':
		ensure => present,
		quota => '80G',
		compression => 'off',
		mountpoint => '/wa_storage',
	}
}
