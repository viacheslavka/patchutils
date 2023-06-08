use strict;
use Test::More tests => 2;

use Patch;
use Patch::Parser;

use experimental 'for_list';

my @cases = (
'
diff --git a/test.c b/test.c
index 0000000..0000000 100644
--- a/test.c
+++ b/test.c
@@ -40,6 +40,11 @@ void hello(const char *) {
     {
         int i = 0;
+        int j = 4;
 
-        i = 4;
+        i = 5;
+        j = 4 * i;
+        i = sqrt(j);
+        i = sqrt(i);
+
        return i * 4;
    }
@@ -60,7 +65,7 @@ int sum(int i, int j) {
     {
         int sum;
         // the easy part
-        sum = i + i;
+        sum = i + j;
         // the tricky part
         return sum;
     }
' => Patch::PatchedFile->new(undef, 'a', 'b', 'test.c', 'test.c',
                             undef, undef, 'index 0000000..0000000 100644',
                             [
                                Patch::Hunk->new(40, 40, 'void hello(const char *) {', [
                                    Patch::Line->new('     {'),
                                    Patch::Line->new('         int i = 0;'),
                                    Patch::Line->new('+        int j = 4;'),
                                    Patch::Line->new(' '),
                                    Patch::Line->new('-        i = 4;'),
                                    Patch::Line->new('+        i = 5;'),
                                    Patch::Line->new('+        j = 4 * i;'),
                                    Patch::Line->new('+        i = sqrt(j);'),
                                    Patch::Line->new('+        i = sqrt(i);'),
                                    Patch::Line->new('+'),
                                    Patch::Line->new('        return i * 4;'),
                                    Patch::Line->new('    }'),
                                ]),
                                Patch::Hunk->new(60, 65, 'int sum(int i, int j) {', [
                                    Patch::Line->new('     {'),
                                    Patch::Line->new('         int sum;'),
                                    Patch::Line->new('         // the easy part'),
                                    Patch::Line->new('-        sum = i + i;'),
                                    Patch::Line->new('+        sum = i + j;'),
                                    Patch::Line->new('         // the tricky part'),
                                    Patch::Line->new('         return sum;'),
                                    Patch::Line->new('     }'),
                                ]),
                             ]),
);

for my ($input, $exp) (@cases) {
    $input =~ s/\A\s+//s;
    my $patched_file = parse_patched_file($input);
    is_deeply($patched_file, $exp);
    is($patched_file->to_string(), $input);
}
