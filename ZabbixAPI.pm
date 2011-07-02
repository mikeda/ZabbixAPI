package ZabbixAPI;

use strict;
use warnings;
use Data::Dumper;
use JSON;
use LWP::UserAgent;

our $VERSION = "0.01";

use constant JSONRPC  => "2.0";
use constant API_PATH => "api_jsonrpc.php";

sub new {
  my $class = shift;
  my ($url, $id) = @_;
  ### 同時に走らせるときはID変えないとダメなんだろうか？
  $id ||= 1;

  my $self = bless {
    url  => $url . API_PATH,
    id   => $id,
    auth => undef
  };

  return $self;
}

sub auth {
  my $self = shift;
  my ($user, $password) = @_;

  my %params = (
    user     => $user,
    password => $password
  );

  $self->{auth} = $self->call_api('user.authenticate', \%params);
}

sub call_api {
  my $self = shift;
  my ($method, $params, $key, $val) = @_;
  $params ||= {};

  my %request = (
    method  => $method,
    auth    => $self->{auth},
    id      => $self->{id},
    jsonrpc => JSONRPC,
    params  => $params,
  );
  my $json_request = encode_json(\%request);

  my $ua = LWP::UserAgent->new;
  my $http_res = $ua->post(
    $self->{url},
    'Content-Type' => 'application/json-rpc',
    'User-Agent'   => "ZabbixAPI/mikeda v$VERSION",
    Content        => $json_request
  );
  if($http_res->is_error){
    die "HTTP Error\n" . $http_res->status_line ."\n";
  }

  my $api_res = decode_json($http_res->content);
  if($api_res->{error}){
    die "API Error\n" . Dumper($api_res->{error});
  }

  my $ret = $api_res->{result};
  if(defined($key)){
    if(defined($val)){
      # return hash ref by key and val
      my %h;
      $h{$_->{$key}} = $_->{$val} for @$ret;
      $ret = \%h;
    }else{
      # return array ref by key
      $ret = [map {$_->{$key}} @$ret];
    }
  }
  return $ret;
}

sub DESTROY {};

sub AUTOLOAD{
  my $self = shift;
  my $method = our $AUTOLOAD;

  $method =~ s/.*:://;
  if($method =~ tr/_/./ == 1){
    $self->call_api($method, @_);
  }else{
    die "Undefined Method $AUTOLOAD";
  }
}

1;
