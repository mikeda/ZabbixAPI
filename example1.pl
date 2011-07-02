#!/usr/bin/perl
use strict;
use warnings;

use Data::Dumper;
use ZabbixAPI;

my $za = ZabbixAPI->new("http://127.0.0.1/zabbix/");
$za->auth("USER", "PASSWORD");

print Dumper $za->apiinfo_version();
#@response
#$VAR1 = '1.3';

print Dumper $za->hostgroup_get({output => "extend"});
#@response
#$VAR1 = [
#          {
#            'name' => 'Templates',
#            'groupid' => '1',
#            'internal' => '0'
#          },
#        ...

print Dumper $za->hostgroup_get({output => "extend"}, 'name');
#@response
#$VAR1 = [
#          'Templates',
#          'Linux servers',
#        ...

print Dumper $za->hostgroup_get({output => "extend"}, 'groupid', 'name');
#@response
#$VAR1 = {
#          '3' => 'Windows servers',
#          '2' => 'Linux servers',
#          '1' => 'Templates',
#        ...
