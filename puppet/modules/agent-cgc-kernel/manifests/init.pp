class agent-cgc-kernel {
	file { '/home/cromulence/cgc_kernel':
                ensure => 'directory',
                owner => '1000',
                group => '1000',
                mode => '0600',
                require => User["cromulence"]
        } ->
	file { 'cgc-kernel-file':
		path => '/home/cromulence/cgc_kernel/linux-image-3.13.11-ckt21-defcon_3.13.11-ckt21-defcon-1_i386.deb',
		ensure => file,
		owner => '1000',
		group => '1000',
		mode => '0600',
		source => 'puppet:///modules/agent-cgc-kernel/linux-image-3.13.11-ckt21-defcon_3.13.11-ckt21-defcon-1_i386.deb',
	} ->
	file { 'cgc-kernel-header-file':
		path => '/home/cromulence/cgc_kernel/linux-headers-3.13.11-ckt21-defcon_3.13.11-ckt21-defcon-1_i386.deb',
		ensure => file,
		owner => '1000',
		group => '1000',
		mode => '0600',
		source => 'puppet:///modules/agent-cgc-kernel/linux-headers-3.13.11-ckt21-defcon_3.13.11-ckt21-defcon-1_i386.deb',
	} ~>
	file { 'cgc-firmware-image-file':
		path => '/home/cromulence/cgc_kernel/linux-firmware-image-3.13.11-ckt21-defcon_3.13.11-ckt21-defcon-1_i386.deb',
		ensure => file,
		owner => '1000',
		group => '1000',
		mode => '0600',
		source => 'puppet:///modules/agent-cgc-kernel/linux-firmware-image-3.13.11-ckt21-defcon_3.13.11-ckt21-defcon-1_i386.deb',
	} ~>
	file { 'cgc-libc-dev-file':
		path => '/home/cromulence/cgc_kernel/linux-libc-dev_3.13.11-ckt21-defcon-1_i386.deb',
		ensure => file,
		owner => '1000',
		group => '1000',
		mode => '0600',
		source => 'puppet:///modules/agent-cgc-kernel/linux-libc-dev_3.13.11-ckt21-defcon-1_i386.deb',
	} ~>
	package { 'cgc-linux-kernel-package':
		name => 'linux-image-3.13.11-ckt21-defcon',
		ensure => installed,
		provider => 'dpkg',
		source => '/home/cromulence/cgc_kernel/linux-image-3.13.11-ckt21-defcon_3.13.11-ckt21-defcon-1_i386.deb',
		require => File['/home/cromulence/cgc_kernel/linux-image-3.13.11-ckt21-defcon_3.13.11-ckt21-defcon-1_i386.deb'],
	} ~>
	package { 'cgc-linux-kernel-headers-package':
		name => 'linux-headers-3.13.11-ckt21-defcon',
		ensure => installed,
		provider => 'dpkg',
		source => '/home/cromulence/cgc_kernel/linux-headers-3.13.11-ckt21-defcon_3.13.11-ckt21-defcon-1_i386.deb',
		require => File['/home/cromulence/cgc_kernel/linux-headers-3.13.11-ckt21-defcon_3.13.11-ckt21-defcon-1_i386.deb'],
	} ~>
	package { 'cgc-firmware-image-package':
		name => 'linux-firmware-image-3.13.11-ckt21-defcon',
		ensure => installed,
		provider => 'dpkg',
		source => '/home/cromulence/cgc_kernel/linux-firmware-image-3.13.11-ckt21-defcon_3.13.11-ckt21-defcon-1_i386.deb',
		require => File['/home/cromulence/cgc_kernel/linux-firmware-image-3.13.11-ckt21-defcon_3.13.11-ckt21-defcon-1_i386.deb'],
	} ~>
	package { 'cgc-libc-dev-package':
		name => 'linux-libc-dev_3.13.11-ckt21-defcon-1_i386.deb',
		ensure => installed,
		provider => 'dpkg',
		source => '/home/cromulence/cgc_kernel/linux-libc-dev_3.13.11-ckt21-defcon-1_i386.deb',
		require => File['/home/cromulence/cgc_kernel/linux-libc-dev_3.13.11-ckt21-defcon-1_i386.deb'],
	} ~>
	file_line { "grub-file-update":
		ensure => 'present',
		path => '/etc/default/grub',
		match => "GRUB_DEFAULT=0",
		line => 'GRUB_DEFAULT="Advanced options for Ubuntu>Ubuntu, with Linux 3.13.11-ckt21-defcon"'
	} ~>
	exec { 'update_kernel':
		command => 'update-grub',
		path => '/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin',
		refreshonly => true,
		user => 'root',
	} ~>
	exec { 'reboot_system':
		command => 'reboot',
		path => '/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin',
		refreshonly => true,
		user => 'root'
	}
}
