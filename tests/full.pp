/**
 * puppet site containing a default node that install the whole shebang
 *
 * This site.pp is used by vagrant so set up the local machine.
 */
node default {

  case $::osfamily {
    'RedHat': {
      class { 'epel':
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
    }
  )

  class {
    'syslogng':
      logpaths => $syslog_logpaths_real;
    'apache':
      default_mods => false;
    'apache::mod::php':
      ;
    'apache::mod::alias':
      ;
    'apache::mod::status':
      ;
    'gravity':
  }

  apache::vhost { $hostname:
    port => 80,
    docroot => '/vagrant/web'
  }

  Class['syslogng'] -> Class['gravity']
  Apache::Vhost[$hostname] -> Class['gravity']
}
