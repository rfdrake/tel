use Test::More;
eval "use Test::Kwalitee 'kwalitee_ok'; 1" or plan skip_all => 'Test::Kwalitee required';
BEGIN {
    plan skip_all => 'these tests are for release candidate testing'
        unless $ENV{RELEASE_TESTING};
}

kwalitee_ok();
done_testing;
