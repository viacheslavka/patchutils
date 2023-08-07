use strict;
use Test::More tests => 2;

use Patch;
use Patch::Parser;

is_deeply(parse_patched_file(<<EOF),
.mark diff --git a/file1 b/file1
--- a/file1
+++ b/file1
@@ -1,1 +1,1 @@
-old
+new
EOF
Patch::PatchedFile->new('mark', 'a', 'b', 'file1', 'file1', undef, undef, undef,
    [
        Patch::Hunk->new(1, 1, undef,
            [
                Patch::Line->new('-old'),
                Patch::Line->new('+new'),
            ]),
    ]),
'Marked file parsing');

is_deeply(<<EOF,
.mark diff --git a/file1 b/file1
--- a/file1
+++ b/file1
@@ -1,1 +1,1 @@
-old
+new
EOF
Patch::PatchedFile->new('mark', 'a', 'b', 'file1', 'file1', undef, undef, undef,
    [
        Patch::Hunk->new(1, 1, undef,
            [
                Patch::Line->new('-old'),
                Patch::Line->new('+new'),
            ]),
    ])->to_string(),
'Marked file formatting');
