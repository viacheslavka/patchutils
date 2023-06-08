use strict;
use Test::More tests => 9;

use Patch::Parser;

my $text = <<EOF;
@@ diff --git ...
@@
line1
  indented line
line2
line3
line4
EOF

my $buffer = Patch::Parser::Buffer->new($text);

is($buffer->read_line(), '@@ diff --git ...');
is($buffer->read_line(), '@@');
is($buffer->read_line(), 'line1');
is($buffer->read_line(), '  indented line');
is($buffer->read_line(), 'line2');

$buffer->return_line('line2');
is($buffer->read_line(), 'line2');

eval { $buffer->return_line('line2'); $buffer->return_line('line0'); };
isnt($@, 0);

is($buffer->read_line(), 'line2');
is($buffer->read_line(), 'line3');
