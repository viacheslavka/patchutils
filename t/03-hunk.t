use strict;
use Test::More tests => 6;

use Patch;
use Patch::Parser;

my $hunk = Patch::Hunk->new(4, 4, '',
                [ Patch::Line->new(' a b c'),
                  Patch::Line->new(' d e f'),
                  Patch::Line->new('-g h i'),
                  Patch::Line->new('+j k l'),
                  Patch::Line->new('+m n o'),
                ]);

is($hunk->added_lines(), 2);
is($hunk->removed_lines(), 1);
is($hunk->len_diff(), 1);
is($hunk->old_len(), 3);
is($hunk->new_len(), 4);

is($hunk->to_string(), <<EOF);
@@ -4,3 +4,4 @@
 a b c
 d e f
-g h i
+j k l
+m n o
EOF
