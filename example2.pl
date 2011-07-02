#!/usr/bin/perl
use strict;
use warnings;

use Data::Dumper;
use ZabbixAPI;

# Create new host

my $user       = "Admin";
my $password   = "mikedax";

my $hostname   = 'api_test01';
my $ip         = '192.168.1.150';
my @hostgroups = ('Linux servers', 'Zabbix servers');
my @templates  = ('Template_Linux', 'Template_App_MySQL');

my $za = ZabbixAPI->new("http://127.0.0.1/zabbix/");
$za->auth($user, $password);

my $groupids = $za->hostgroup_get(
  { filter => {name => \@hostgroups} },
  'groupid'
);
my $templateids = $za->template_get(
  { filter => {host => \@templates} },
  'templateid'
);

my $result = $za->host_create({
  host      => $hostname,
  ip        => $ip,
  port      => "10050",
  useip     => 1,
  groups    => [
    map {{groupid    => $_}} @$groupids
  ],
  templates => [
    map {{templateid => $_}} @$templateids
  ],
});
print Dumper $result;
