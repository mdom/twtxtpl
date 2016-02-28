package App::txtnix::Tweet;
use Mojo::Base -base;
use HTTP::Date 'str2time';
use Mojo::ByteStream 'b';
use POSIX ();

has [ 'user', 'text' ];
has timestamp => sub { time };

sub strftime {
    my ( $self, $format ) = @_;
    return POSIX::strftime( $format, localtime $self->timestamp );
}

sub to_string {
    my $self = shift;
    return $self->strftime('%FT%T%z') . "\t" . $self->text;
}

sub md5_hash {
    my $self = shift;
    return b( $self->timestamp . $self->user . $self->text )->encode->md5_sum;
}

1;
