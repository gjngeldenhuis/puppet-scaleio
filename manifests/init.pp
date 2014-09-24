# manage an scaleio installation
#
# Parameters:
#
# * version: which version to be installed. default: installed (latest in repo)
# * callhome: should callhome on the mdms be installed?
# * primary_mdm_ip: ip of the primary mdm, if any of the current ips of a host matches this ip, it will be configured as primary mdm
# * secondary_mdm_ip: ip of the secondary mdm, if any of the current ips of a host matches this ip, it will be configured as secondary mdm
# * tb_ip: ip of the tiebreaker, if any of the current ips of a host matches this ip, it will be configured as a tiebreaker
# * password: for the mdm
# * syslog_ip_port: if set we will configure a syslog server
# * components: will configure the different components any out of:
#    - sds
#    - sdc
#    - mdm
#    - tb
class scaleio(
  $version          = 'installed',
  $callhome         = true,
  $primary_mdm_ip   = undef,
  $secondary_mdm_ip = undef,
  $tb_ip            = undef,
  $license          = undef,
  $password         = 'admin',
  $syslog_ip_port   = undef,
  $system_name      = undef,
  $components       = [],
) {

  ensure_packages(['numactl','python-paramiko'])

  # both must be set and if they are they should be valid
  if $primary_mdm_ip or $secondary_mdm_ip {
    validate_re($primary_mdm_ip, '^(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)(\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)){3}$')
    validate_re($secondary_mdm_ip, '^(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)(\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)){3}$')
    if $primary_mdm_ip == $secondary_mdm_ip {
      fail('$primary_mdm_ip and $secondary_mdm_ip can\'t be the same!')
    }
  }
  if $tb_ip {
    validate_re($tb_ip, '^(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)(\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)){3}$')
  }

  if 'sdc' in $components {
    include scaleio::sdc
  }
  if 'sds' in $components {
    include scaleio::sds
  }
  if 'mdm' in $components or ($primary_mdm_ip and has_ip_address($primary_mdm_ip)) or ($secondary_mdm_ip and has_ip_address($secondary_mdm_ip)) {
    include scaleio::mdm
  }
  if 'tb' in $components or ($tb_ip and has_ip_address($tb_ip)) {
    include scaleio::tb
  }

}