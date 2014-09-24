# manage a mdm
class scaleio::mdm {
  include ::scaleio
  package{'EMC-ScaleIO-mdm':
    ensure => $scaleio::version,
  }

  if has_ip_address($scaleio::primary_mdm_ip) {
    include scaleio::mdm::primary
  }

  if $scaleio::callhome {
    include scaleio::mdm::callhome
  }

  file{'/var/lib/puppet/module_data/scaleio':
    ensure => directory,
    owner  => root,
    group  => 0,
    mode   => '0600',
  }

  $scli_wrap = '/var/lib/puppet/module_data/scaleio/scli_wrap'
  file{$scli_wrap:
    content => template('scaleio/scli_wrap.erb'),
    owner   => root,
    group   => 0,
    mode    => '0700',
    require => Package['EMC-ScaleIO-mdm'];
  }
}