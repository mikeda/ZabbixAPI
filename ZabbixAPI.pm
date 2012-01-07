package ZabbixAPI;

use strict;
use warnings;

use JSON;
use LWP::UserAgent;
use Data::Dumper;

our $VERSION = "0.01";
our $DEBUG   = 0;


sub new {
  my ($class, $url, $id) = @_;
  $id ||= 1;

  if($url !~ /\/api_jsonrpc\.php$/){
    if($url !~ /\/$/){
      $url .= '/';
    }
    $url .= 'api_jsonrpc.php';
  }

  my $json = JSON->new->utf8;
  $DEBUG && $json->pretty;

  my $self = {
    url  => $url,
    id   => $id,
    auth => undef,
    json => $json
  };

  return bless $self, $class;
}

sub DESTROY {};

sub AUTOLOAD{
  my $self = shift;
  my $method = our $AUTOLOAD;

  $method =~ s/.*:://;
  if($method =~ tr/_/./ == 1){
    $self->_call_api($method, @_);
  }else{
    die "bad method:$AUTOLOAD";
  }
}

sub _call_api {
  my $self = shift;
  my ($method, $params, $keyname, $valname) = @_;
  $params ||= {};

  # create JSON request
  my $json_req = $self->{json}->encode(
    {
      method  => $method,
      auth    => $self->{auth},
      id      => $self->{id},
      jsonrpc => '2.0',
      params  => $params
    }
  );
  $DEBUG && _dprint("Request:\n" . $json_req);

  # POST HTTP request
  my $ua = LWP::UserAgent->new;
  my $http_res = $ua->post(
    $self->{url},
    'Content-Type' => "application/json-rpc",
    'User-Agent'   => "ZabbixAPI/mikeda v$VERSION",
    'Content'      => $json_req
  );

  if($http_res->is_error){
    die "HTTP Error\n" . $http_res->status_line;
  }
  my $json_res = $http_res->content;

  $DEBUG && _dprint("Response:\n" . $json_res);

  # decode JSON response
  my $api_res = $self->{json}->decode($json_res);
  if($api_res->{error}){
    die "API Error\n" . Dumper($api_res->{error});
  }
  my $res = $api_res->{result};

  # modify result
  if(defined($keyname)){
    if(defined($valname)){
      # return hash
      my %h;
      $h{$_->{$keyname}} = $_->{$valname} for @$res;
      $res = \%h;
    }else{
      # return array
      $res = [map {$_->{$keyname}} @$res];
    }
  }

  return $res;
}

sub _dprint {
  my ($pkg, $file, $line) = caller 0;
  my $msg = shift;

  print STDERR "# $file:$line\n";
  for my $m (split "\n", $msg){
    print STDERR "# $m\n";
  }
  print STDERR "\n";
}

sub auth {
  my $self = shift;
  my ($user, $password) = @_;

  my %params = (
    user     => $user,
    password => $password
  );

  $self->{auth} = $self->_call_api('user.authenticate', \%params);
}

1;
