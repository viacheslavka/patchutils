use strict;
use Test::More tests => 6;

use Patch;
use Patch::Parser;

use experimental 'for_list';

my @cases = (
'
@@ -4,2 +4,3 @@
 a b c
 d e f
+g h i
' => Patch::Hunk->new(4, 4, undef,
                [ Patch::Line->new(' a b c'),
                  Patch::Line->new(' d e f'),
                  Patch::Line->new('+g h i'),
                ]),
'
@@ -4,2 +4,3 @@ int test(const char *s) {
 a b c
 d e f
+g h i
' => Patch::Hunk->new(4, 4, 'int test(const char *s) {',
                [ Patch::Line->new(' a b c'),
                  Patch::Line->new(' d e f'),
                  Patch::Line->new('+g h i'),
                ]),
'
@@ -4,2 +4,3 @@ int test(const char *s) {
 a b c
 d e f
.remove+g h i
' => Patch::Hunk->new(4, 4, 'int test(const char *s) {',
                [ Patch::Line->new(' a b c'),
                  Patch::Line->new(' d e f'),
                  Patch::Line->new('+g h i', 'remove'),
                ]),
);

for my ($input, $exp) (@cases) {
    $input =~ s/\A\s+//s;
    my $hunk = parse_hunk($input);
    is_deeply($hunk, $exp);
    is($hunk->to_string(), $input);
}
