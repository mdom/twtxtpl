package App::txtnix::Plugin::GistStore;
use Mojo::Base 'App::txtnix::Plugin';
use Path::Tiny;
use Mojo::JSON qw(true false);

has url => sub { "https://api.github.com/gists" };

sub post_tweet {
    my $self = shift;
    my $app  = $self->app;
    my $ua   = $app->ua;

    my $token    = $self->config->{access_token};
    my $username = $self->config->{user};
    my $id       = $self->config->{id};

    if ( !$token || !$username ) {
        warn "Missing parameter access_token or user for GistStore.\n";
        return 0;
    }

    my $url = Mojo::URL->new( $self->url )->userinfo("$username:$token");

    if ($id) {
        $url->path( $url->path . '/' . $id );
    }

    my $file = $app->twtfile;

    if ( !$file || !$file->exists ) {
        warn "Can't find twtfile to upload\n";
        return 0;
    }

    my $tx = $ua->post(
        $url => json => {
            description => "twtxt.txt for $username",
            public      => true,
            files       => {
                "twtxt.txt" => {
                    content => $file->slurp_utf8,
                }
            }
        }
    );

    my $res = $tx->result;
    if ( $res->is_success ) {
        print "Uploaded gist.\n";
        if ( !$id ) {
            my $config = $app->read_config;
            $config->{'Store::Gist'}->{id} = $res->json->{id};
            $config->write( $app->config_file, 'utf8' );
        }
    }
    else {
        my $err   = $tx->error;
        my $error = $err->{message};
        $error = $err->{code} . " $error" if $err->{code};
        warn "Error while uploading gist: $error\n";
    }

    return;
}

1;
