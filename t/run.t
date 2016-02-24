use strict;
use warnings;
use Path::Tiny;
use Test::More;
use Test::Output;
use Mojolicious::Lite;
use Mojo::UserAgent::Server;
use OptArgs 'class_optargs';

my $config  = Path::Tiny->tempfile;
my $twtfile = Path::Tiny->tempfile;

sub run {
    my ( $class, $opts ) = class_optargs( 'App::txtnix::Cmd', @_ );
    $opts = {
        config    => $config,
        twtfile   => $twtfile,
        use_pager => 0,
        following => { bob => '/bob.txt', alice => '/alice.txt' },
        %$opts,
    };
    $class->new($opts)->run();
}

# Silence
app->log->level('fatal');

get '/bob.txt'   => { text => "2016-02-03T00:00:00Z \tWhoo!" };
get '/alice.txt' => { text => "2016-02-02T00:00:00Z \tTweet!" };

stdout_is( sub { run('timeline') }, <<'EOO');
2016-02-03 00:00 bob: Whoo!
2016-02-02 00:00 alice: Tweet!
EOO

run( 'tweet', 'Hello World' );
like( $twtfile->slurp_utf8, qr/[\d:TZ-]+\tHello World/ );

stdout_is(
    sub { run( 'follow', 'bob', '/bob.txt' ) },
    qq{You're already following bob.\n}
);

stdout_is(
    sub { run( 'follow', 'bob', '/bob2.0.txt' ) },
    qq{You're already following bob under a differant url.\n}
);

stdout_is( sub { run( 'unfollow', 'bob' ) }, qq{You've unfollowed bob.\n} );

stdout_is(
    sub { run( 'unfollow', 'charlie' ) },
    qq{You're not following charlie.\n}
);

stdout_is( sub { run('following') }, qq{alice @ /alice.txt\n} );

stdout_is( sub { run( 'follow', 'bob', '/bob.txt' ) },
    qq{You're now following bob.\n} );

stdout_is(
    sub { run( 'config', 'get', 'disclose_identity' ) },
    qq{The configuration key disclose_identity is unset.\n}
);

stdout_is( sub { run( 'config', 'set', 'disclose_identity', 1 ) }, qq{} );

stdout_is( sub { run( 'config', 'get', 'disclose_identity' ) }, qq{1\n} );

stdout_is( sub { run( 'config', 'remove', 'disclose_identity' ) }, qq{} );

stdout_is(
    sub { run( 'config', 'get', 'disclose_identity' ) },
    qq{The configuration key disclose_identity is unset.\n}
);

done_testing;