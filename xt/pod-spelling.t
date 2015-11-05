use Test::More;
eval 'use Test::Spelling 0.20';
plan skip_all => 'Test::Spelling 0.20 required for testing POD coverage' if $@;

add_stopwords(<DATA>);
all_pod_files_spelling_ok();

__END__
cisco
KeePass
PWSafe
TELRC
TODO
vlan
keyring
enablecmd
autocmds
HostRanges
conf
gw
ver
myfile
