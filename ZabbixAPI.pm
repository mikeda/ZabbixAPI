package ZabbixAPI;

use strict;
use warnings;
use Data::Dumper;
use JSON;
use LWP::UserAgent;

our $VERSION = "0.01";
our $DEBUG   = 0;


sub new {
  my $class = shift;
  my ($url, $id) = @_;
  ### 同時に走らせるときはID変えないとダメなんだろうか？
  $id ||= 1;

  my $self = bless {
    url  => $url . 'api_jsonrpc.php',
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

  $self->{auth} = $self->_call_api('user.authenticate', \%params);
}

sub DESTROY {};

sub AUTOLOAD{
  my $self = shift;
  my $method = our $AUTOLOAD;

  $method =~ s/.*:://;
  if($method =~ tr/_/./ == 1){
    $self->_call_api($method, @_);
  }else{
    die "Undefined Method $AUTOLOAD";
  }
}

sub _call_api {
  my $self = shift;
  my ($method, $params, $keyname, $valname) = @_;
  $params ||= {};

  my $json_request  = $self->_create_json_request($method, $params);

  my $http_response = $self->_get_http_response($json_request);

  my $api_response  = _get_api_response($http_response);

  if(defined($keyname)){
    if(defined($valname)){
      my %h;
      $h{$_->{$keyname}} = $_->{$valname} for @$api_response;
      $api_response = \%h;
    }else{
      $api_response = [map {$_->{$keyname}} @$api_response];
    }
  }

  return $api_response;
}

sub _dprint {
  my ($package, $filename, $line) = caller 0;
  my @messages = @_;

  @messages = map { (my $t= $_) =~ s/\n/\n# /g;$t } @messages;

  print STDERR "# $package:$filename:$line\n";
  for my $message (@messages){
    print STDERR "# $message\n";
  }
}

sub _create_json_request {
  my ($self, $method, $params) = @_;
  my %request = (
    method  => $method,
    auth    => $self->{auth},
    id      => $self->{id},
    jsonrpc => '2.0',
    params  => $params,
  );
  my $json_request = encode_json(\%request);
  $DEBUG && _dprint('REQUEST JSON', $json_request);

  return $json_request;
}

sub _get_http_response {
  my ($self, $json_request) = @_;

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

  $DEBUG && _dprint('RESPONSE JSON', $http_res->content);
  return $http_res->content;

}

sub _get_api_response {
  my $http_res = shift;

  my $api_res = decode_json($http_res);
  if($api_res->{error}){
    die "API Error\n" . Dumper($api_res->{error});
  }
  my $result = $api_res->{result};

  return $result;
}

1;
