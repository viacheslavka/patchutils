use strict;
use Test::More tests => 6;

use Patch;
use Patch::Parser;

use experimental 'for_list';

my @cases = (
'
diff --git a/dir/file.txt b/dir/file.txt
new file mode 100644
--- /dev/null
+++ b/dir/file.txt
@@ -0,0 +0,1 @@
+new file contents
' => Patch::PatchedFile->new(undef, 'a', 'b', undef, 'dir/file.txt',
                             undef, '100644', undef,
                             [
                                Patch::Hunk->new(0, 0, undef, [
                                    Patch::Line->new('+new file contents'),
                                ]),
                             ]),
'
diff --git a/dir/file.txt b/dir/file.txt
deleted file mode 100644
--- a/dir/file.txt
+++ /dev/null
@@ -0,1 +0,0 @@
-new file contents
' => Patch::PatchedFile->new(undef, 'a', 'b', 'dir/file.txt', undef,
                             '100644', undef, undef,
                             [
                                Patch::Hunk->new(0, 0, undef, [
                                    Patch::Line->new('-new file contents'),
                                ]),
                             ]),
'
diff --git a/dir/file1.txt b/dir/file2.txt
rename from dir/file1.txt
rename to dir/file2.txt
' => Patch::PatchedFile->new(undef, 'a', 'b', 'dir/file1.txt', 'dir/file2.txt',
                             undef, undef, undef,
                             []),
);

for my ($input, $exp) (@cases) {
    $input =~ s/\A\s+//s;
    my $patched_file = parse_patched_file($input);
    is_deeply($patched_file, $exp);
    is($patched_file->to_string(), $input);
}
