# A description of what this class does
#
# @summary A short summary of the purpose of this class
#
# @example
#   include pe_git::server
class pe_git::server {
  user { 'git':
    ensure   => present,
    shell    => '/bin/git-shell',
    password => 'X', # Deliberately disable password login
  } ->
  file { '/home/git':
    ensure => directory,
    owner  => 'git',
    group  => 'git',
    mode   => '0711',
  } ->
  file { '/home/git/.ssh':
    ensure => directory,
    owner  => 'git',
    group  => 'git',
    mode   => '0700',
  } ->
  Ssh_authorized_key <<| title == 'pe_git_key' |>>
}
