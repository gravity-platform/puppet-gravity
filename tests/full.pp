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

      class { '::ius':
        before => Package['php-pecl-mongo'];
      }

      package {
	['php55u-pdo', 'php55u-pecl-mongo']:
	  ensure => present,
	  before => Class['apache::mod::php'];
      }
    }
  }

  file { 
    '/etc/php.d':
      ensure => directory;
    '/etc/php.d/timezone.ini':
      content => 'date.timezone=Europe/Zurich',
      before  => Class['apache::mod::php'],
      notify  => Class['apache']
  }

  class {
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
    '/vagrant/app/cache':
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

  File['/vagrant/web'] -> Apache::Vhost[$hostname]
  Apache::Vhost[$hostname] -> Class['gravity']
}
