use Test::More tests => 2;
use Test::Exception;

use App::Tel::Passwd;

dies_ok { App::Tel::Passwd::load_module(undef) } 'load_module on undef file croaks';
dies_ok { App::Tel::Passwd::load_module('___a datastore that probably will never exist___') } 'load_module on non-existant file croaks';
