class gravity::firewall::pre {
  Firewall {
    require => undef,
  }

  firewall { "000 related and established requests":
    proto  => 'all',
    state  => ['RELATED', 'ESTABLISHED'],
    action => 'accept',
  }
  firewall { '001 accept all to lo interface':
    proto => 'all',
    iniface => 'lo',
    action => 'accept',
  }
  firewall { "005 accept all icmp requests":
    proto  => "icmp",
    action => "accept",
  }
  firewall { "010 accept all ssh requests":
    proto  => "tcp",
    port   => [22],
    action => "accept",
  }
  firewall { "010 accept all http requests":
    proto  => "tcp",
    port   => [80],
    action => "accept",
  }
  firewall { "010 accept local mongodb requests":
    proto  => "tcp",
    port   => [27017],
    source => '127.0.0.1',
    action => "accept",
  }

  firewall { "900 reject all other requests":
    reject => 'icmp-host-prohibited',
    action => "reject",
  }
}
