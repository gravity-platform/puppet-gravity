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
        '::yum':
          ;
        '::ius':
          before => [
            Package['php55u-pdo'],
            Package['php55u-pecl-mongo'],
            Package['php55u-mysqlnd'],
          ];
        '::yum::repo::mongodb':
          before => Package['mongodb-org'];
      }

      package {
        'php55u-mysqlnd':
          before => Package['php55u-pdo'],
          notify => Class['::apache'];
        ['php55u-pdo', 'php55u-pecl-mongo', ]:
          ensure => present,
          before => Class['::apache::mod::php'],
          notify => Class['::apache'];
      }
    }
  }

  file { 
    '/etc/php.d':
      ensure => directory;
    '/etc/php.d/timezone.ini':
      content => 'date.timezone=Europe/Zurich',
      before  => Class['::apache::mod::php'],
      notify  => Class['::apache']
  }

  class {
    '::mongodb::server':
      user         => 'mongod',
      group        => 'mongod',
      package_name => 'mongodb-org';
    '::apache':
      default_mods  => false,
      default_vhost => false;
    '::apache::mod::mime':
      ;
    '::apache::mod::php':
      package_name => 'php55u';
    '::apache::mod::alias':
      ;
    '::apache::mod::rewrite':
      ;
    '::apache::mod::status':
      ;
    'gravity':
      ;
  }

  resources { 'firewall':
    purge => false,
  }
  Firewall {
    before => Class['gravity::firewall::post'],
    require => [
      Class['gravity::firewall::pre'],
    ]
  }
  class {
    'firewall': ;
  }
  class { ['gravity::firewall::pre', 'gravity::firewall::post']:
    require => Class['firewall']
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
    rewrites => [
      {
        comment      => 'single page url',
        rewrite_cond => ['%{REQUEST_URI}  !(\.html|\.css|\.less|\.js|\.otf|\.eot|\.svg|\.ttf|\.woff)$'],
        rewrite_rule => ['(.*) /app_dev.php/$1 [QSA]'],
      },
    ]
  }

  exec { 'restart apache':
    command     => '/etc/init.d/httpd restart',
    refreshonly => true,
  }

  File['/vagrant/web'] -> Apache::Vhost[$hostname]
  Class['gravity'] -> Apache::Vhost[$hostname]
  Service['httpd'] ~> Exec['restart apache']
}
