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
   }
   default: {}
 }

  class {
    'syslogng':
      logpaths => {
        'mod_php' => {}
      };
    'gravity':
  }

  Class['syslogng'] -> Class['gravity']
}
