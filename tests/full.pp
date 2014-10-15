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
      class {
        'epel':
	  before => Class['hairmareyumrepo'];
        'hairmareyumrepo':
          before => Class['syslogng']

      }
      package {
        'rsyslog':
          ensure  => absent,
	  require => Class['syslogng'];
	'syslog-ng-mongodb':
	  ensure  => present,
	  require => Package['rsyslog'],
	  before  => Class['mongodb'];
	['php-xml', 'php-pdo', 'php-pecl-mongo']:
	  ensure => present,
	  before => Class['apache::mod::php'];
      }

      $distro_syslog_logpaths = {
        'yum'      => {},
	'anacron'  => {},
	'dhclient' => {},
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

  file { '/etc/php.d/timezone.ini':
    content => 'date.timezone=Europe/Zurich',
    before  => Class['apache::mod::php'],
    notify  => Class['apache']
  }

  class {
    'syslogng':
      logpaths => $syslog_logpaths_real;
    'mongodb':
      ;
    'apache':
      default_mods  => false,
      default_vhost => false;
    'apache::mod::mime':
      ;
    'apache::mod::php':
      ;
    'apache::mod::alias':
      ;
    'apache::mod::rewrite':
      ;
    'apache::mod::status':
      ;
    'gravity':
      ;
  }

  resources { 'firewall':
    purge => true
  }

  file {
    '/vagrant/web':
      ensure => directory;
    '/vagrant/app/cache/dev':
      ensure => '/tmp';
    '/vagrant/app/logs':
      ensure => '/tmp',
      force  => true
  }

  apache::vhost { $hostname:
    port            => 80,
    docroot         => '/vagrant/web',
    rewrite_cond    => [
      '%{REQUEST_URI}  !(\.html|\.css|\.less|\.js|\.otf|\.eot|\.svg|\.ttf|\.woff)$',
    ],
    rewrite_rule    => '(.*) /app_dev.php/$1 [QSA]',
  }

  Class['syslogng'] -> Class['gravity']
  File['/vagrant/web'] -> Apache::Vhost[$hostname]
  Apache::Vhost[$hostname] -> Class['gravity']
}
