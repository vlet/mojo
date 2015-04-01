package Mojo::Transaction::HTTP2;
use Mojo::Base 'Mojo::Transaction';
use Protocol::HTTP2::Server;
use Mojo::Util qw(url_unescape);

has http2 => sub {
  my $self = shift;

  my $server;

  $server = Protocol::HTTP2::Server->new(
    on_request => sub {
      my ($stream_id, $headers, $body) = @_;
      $self->res(Mojo::Message::Response->new);
      $self->res->headers->server('Mojolicious (Perl)');
      $self->req->parse(_to_psgi_env($headers));
      $self->emit('request');

      my $res  = $self->res->fix_headers;
      my $hash = $res->headers->to_hash(1);
      my @headers;
      for my $name (keys %$hash) {
        push @headers, map { $name => $_ } @{$hash->{$name}};
      }

      $server->response(
        ':status' => $res->code // 404,
        stream_id => $stream_id,
        headers   => \@headers,
        data      => $res->body
      );
    }
  );
};

sub server_read {
  my ($self, $chunk) = @_;
  $self->{state} ||= 'read';
  $self->http2->feed($chunk);
}

sub server_write {
  my $self = shift;
  $self->{state} ||= 'write';
  my $chunks = '';
  while (my $frame = $self->http2->next_frame) {
    $chunks .= $frame;
  }
  return $chunks;
}

sub _to_psgi_env {
  my ($headers) = @_;
  my $env = {'SERVER_PROTOCOL' => 'http/1.1',};

  for my $i (0 .. @$headers / 2 - 1) {
    my ($h, $v) = ($headers->[$i * 2], $headers->[$i * 2 + 1]);
    if ($h eq ':method') {
      $env->{REQUEST_METHOD} = $v;
    }
    elsif ($h eq ':scheme') {
      $env->{'psgi.url_scheme'} = $v;
    }
    elsif ($h eq ':path') {
      $env->{REQUEST_URI} = $v;
      my ($path, $query) = ($v =~ /^([^?]*)\??(.*)?$/s);
      $env->{QUERY_STRING} = $query || '';
      $env->{PATH_INFO} = url_unescape($path);
    }
    elsif ($h eq ':authority') {

      #TODO: what to do with :authority?
    }
    elsif ($h eq 'content-length') {
      $env->{CONTENT_LENGTH} = $v;
    }
    elsif ($h eq 'content-type') {
      $env->{CONTENT_TYPE} = $v;
    }
    else {
      my $header = 'HTTP_' . uc($h);
      if (exists $env->{$header}) {
        $env->{$header} .= ', ' . $v;
      }
      else {
        $env->{$header} = $v;
      }
    }
  }

  return $env;
}

1;
