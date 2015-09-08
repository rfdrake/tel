use Test::More tests => 5;
use Test::Exception;

use App::Tel::Passwd;

dies_ok { App::Tel::Passwd::load_module(undef) } 'load_module on undef file croaks';
dies_ok { App::Tel::Passwd::load_module('___a datastore that probably will never exist___') } 'load_module on non-existant file croaks';
lives_ok { App::Tel::Passwd::load_module('KeePass') } 'load_module on basic KeePass module works';
lives_ok { App::Tel::Passwd::load_module('KEEPASS') } 'uppercase works';
lives_ok { App::Tel::Passwd::load_module('keepass_entry') } 'trailing data works';