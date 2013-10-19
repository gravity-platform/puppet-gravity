/**
 * Puppet site containing a node for installing the whole shebang.
 *
 * This site.pp is used by vagrant to set up the local machine. It has
 * been tested against CentOS 6.4.
 *
 * Use this site as inspiration for setting up your roles and profiles.
 */
node default {

  case $::osfamily {
    'RedHat': {
      class { 'epel':
        before => Class['syslogng']
      }
      package { 'rsyslog':
        ensure => purged,
	before => Class['syslogng']
      }


      $distro_syslog_logpaths = {
        # @todo create this in syslogng module
        # 'yum' => {},
      }
    }
    default: {
      $distro_syslog_logpaths = {}
    }
  }

  $syslog_logpaths_real = merge(
    $distro_syslog_logpaths,
    {
      'syslog-ng' => {},
      'sudo'      => {},
      'sshd'      => {},
      'mod_php'   => {},
      'crond'     => {},
    }
  )

  class {
    'syslogng':
      logpaths => $syslog_logpaths_real;
    'apache':
      default_mods  => false,
      default_vhost => false;
    'apache::mod::mime':
      ;
    'apache::mod::php':
      ;
    'apache::mod::dir':
      ;
    'apache::mod::alias':
      ;
    'apache::mod::status':
      ;
    'gravity':
      ;
  }

  resources { 'firewall':
    purge => true
  }

  apache::vhost { $hostname:
    port => 80,
    docroot => '/vagrant/web'
  }

  Class['syslogng'] -> Class['gravity']
  Apache::Vhost[$hostname] -> Class['gravity']
}
