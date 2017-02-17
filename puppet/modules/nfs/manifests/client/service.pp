# == Class: nfs::client::service
#
# This Function exists to
#  1. manage the needed services for nfs clients
#
#
# === Links
#
# * {Puppet Docs: Using Parameterized Classes}[http://j.mp/nVpyWY]
#
#
# === Authors
#
# * Daniel Klockenkaemper <mailto:dk@marketing-factory.de>
#

class nfs::client::service {

  if $::nfs::client::nfs_v4 {
    $create_services = $::nfs::effective_nfsv4_client_services
    if $::nfs::server_enabled {
      $subscription = [ Concat[$::nfs::exports_file], Augeas[$::nfs::idmapd_file] ]
    } else {
      $subscription = [ Augeas[$::nfs::idmapd_file] ]
    }
  } else {
    $create_services = $::nfs::effective_client_services
    if $::nfs::server_enabled {
      $subscription  = [ Concat[$::nfs::exports_file] ]
    } else {
      $subscription = []
    }
  }

  $service_defaults = {
    ensure     => running,
    enable     => true,
    hasrestart => $::nfs::client_services_hasrestart,
    hasstatus  => $::nfs::client_services_hasstatus,
    subscribe  => $subscription
  }

  create_resources('service', $create_services, $service_defaults )
}
