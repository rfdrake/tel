use strict;
use warnings;
use Test::More;
plan tests => 5;
use App::Tel;

use Config;
my $path_to_perl = $Config{perlpath};
my $tel = App::Tel->new(perl => $path_to_perl);
$tel->load_config("$ENV{PWD}/t/rc/fakerouter.rc");

{
    local($^F)= 0x8000; # turn off close-on-exec by setting SYSTEM_FD_MAX=32768
    pipe( READERR, WRITEERR ) or die "pipe: $!";
}

no warnings 'redefine';
local *App::Tel::connect = sub {
    my ($self, @arguments) = @_;

    my $fd= fileno(WRITEERR);
    $self->connected(0);
    my $session = $self->session(1);
    my $hostname = $self->{hostname};
    $session->spawn("$self->{perl} $hostname 2>&$fd");
    return $session;
};

subtest test_opt_a => sub {

    # override isatty for this test because it doesn't matter if we're running
    # under a tty.
    no warnings 'redefine';
    *POSIX::isatty = sub { 1 };

    my @expected = ( 'testvty', 'enable','tester','testenable','sh ver', ' exit' );
    my $opts = {
        a => 'sh ver; exit'
    };
    $tel->{opts} = $opts;

    is($tel->enabled, 0, 'Check if we are enabled?');
    $tel->go("t/fake_routers/loopback");
    print "\n";
    my @values = split(',',<READERR>);
    chomp(@values);
    is_deeply(\@values, \@expected, 'can we simulate an opt A login?');
    done_testing();
};

subtest test_opt_c => sub {

    my @expected = ( 'testvty', 'enable','tester','testenable','term len 0','sh ver', 'logout' );
    my $opts = {
        c => 'sh ver'
    };
    $tel->{opts} = $opts;

    $tel->go("t/fake_routers/loopback");
    print "\n";
    my @values = split(',',<READERR>);
    chomp(@values);
    is_deeply(\@values, \@expected, 'can we simulate an opt C login?');
    done_testing();
};

subtest test_opt_x => sub {

    my @expected = ( 'testvty', 'enable','tester','testenable','term len 0',
                      'sh ver', 'sh proc cpu', '', 'logout',
    );
    my $opts = {
        x => [ 't/conf/test_x' ],
    };
    $tel->{opts} = $opts;

    $tel->go("t/fake_routers/loopback");
    print "\n";
    my @values = split(',',<READERR>);
    chomp(@values);
    is_deeply(\@values, \@expected, 'can we simulate an opt x login?');
    done_testing();
};

subtest test_EOF_before_login => sub {
    $tel->load_config("$ENV{PWD}/t/rc/login_failures.rc");
    $tel->profile('default',1);
    # need to set hostname here because login() doesn't set the hostname and
    # connect() above is overriding based on the hostname.
    $tel->hostname("t/fake_routers/eof");
    {
        local $SIG{__WARN__}=sub{};  # suppress warn() for this
        $tel->login("t/fake_routers/eof");
    }
    print "\n";

    is($tel->connected, 0, "login failure eof?");
    $tel->disconnect(0);    # soft close.
    $tel->disconnect(1);    # hard close..
    done_testing();
};

subtest 'router_banner' => sub {
    $tel->load_config("$ENV{PWD}/t/rc/banner.rc");
    is($tel->{config}->{banners}->{'Fake A Router'}, 'fake', 'did we load t/rc/banner.rc?');
    $tel->profile('default',1);
    # can't use go, need to use login because go will clear the profile
    # afterwords
    $tel->hostname("t/fake_routers/banner");
    $tel->login("t/fake_routers/banner");

    is($tel->{profile}->{user}, 'faker', 'Banner user = faker?');
    is($tel->connected, 1, "Did we connect using the faker profile?");
    done_testing();
};

close(WRITEERR);

