package Mojo::TLS;
use Mojo::Base -strict;

# TLS support requires IO::Socket::SSL
use constant TLS => $ENV{MOJO_NO_TLS}
  ? 0
  : eval 'use IO::Socket::SSL 1.94 (); 1';

use constant {
  TLS_READ  => TLS ? IO::Socket::SSL::SSL_WANT_READ()  : 0,
  TLS_WRITE => TLS ? IO::Socket::SSL::SSL_WANT_WRITE() : 0,
  TLS_NPN   => TLS ? eval { IO::Socket::SSL->can_npn }        : 0,
  TLS_ALPN  => TLS ? eval { IO::Socket::SSL->can_alpn }       : 0,
  TLS_C_SNI => TLS ? eval { IO::Socket::SSL->can_client_sni } : 0,
  TLS_S_SNI => TLS ? eval { IO::Socket::SSL->can_server_sni } : 0,
};

use Exporter 'import';
our @EXPORT_OK = (
  qw(TLS TLS_READ TLS_WRITE TLS_NPN TLS_ALPN TLS_C_SNI TLS_S_SNI),
  qw(mojo_protocols selected_protocol)
);

sub mojo_protocols {
  (qw(http/1.1));
}

sub selected_protocol {
  my $handle = shift;
  return
      TLS_ALPN ? $handle->alpn_selected
    : TLS_NPN  ? $handle->next_proto_negotiated
    :            undef;
}

1;

=encoding utf8

=head1 NAME

Mojo::TLS - IO::Socket::SSL related constants and utilities

=head1 SYNOPSIS

  use Mojo::TLS qw(selected_protocol mojo_protocols);

  # Check ALPN/NPN negotiaged application protocol
  my $proto = selected_protocol($tls_handle);
  unless ( $proto && grep { $_ eq $proto } mojo_protocols ) {
    croak "Protocol not supported";
  }

=head1 DESCRIPTION

L<Mojo::TLS> imports IO::Socket::SSL (unless env variable MOJO_NO_TLS is set)
and provides some TLS related constants and utility functions

=head1 FUNCTIONS

=head2 selected_protocol

  my $proto = selected_protocol($tls_handle);

Returns ALPN/NPN negotiaged application protocol or undef if those TLS
extensions are not availiable.

=head2 mojo_protocols

  my @list = mojo_protocols;

Returns list of supported application protocols: 'http/1.1'

=head1 CONSTANTS

  qw(TLS TLS_READ TLS_WRITE TLS_NPN TLS_ALPN TLS_C_SNI TLS_S_SNI)

=head1 SEE ALSO

L<Mojolicious>, L<Mojolicious::Guides>, L<http://mojolicio.us>.

=cut
