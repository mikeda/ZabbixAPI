#!/usr/bin/perl
use strict;
use warnings;

use Data::Dumper;
use ZabbixAPI;

my $za = ZabbixAPI->new("http://127.0.0.1/zabbix/");
$za->auth("Admin", "PASSWORD");

# get Information
print Dumper $za->apiinfo_version();
print Dumper $za->hostgroupget({output => "extend"});

# Create Host
#my $groupid = $za->hostgroup_get({filter=>{name=>"Linux servers"}})->[0]->{groupid};
#my $templateid = $za->template_get({filter=>{host=>"Template_Linux"}})->[0]->{templateid};

#my $result = $za->host_create({
#  host      => "api_test01",
#  ip        => "192.168.1.200",
#  port      => "10050",
#  useip     => 1,
#  groups    => [ { groupid => $groupid } ],
#  templates => [ { templateid => $templateid } ]
#});
#print Dumper $result;
