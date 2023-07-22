use strict;
use Test::More tests => 4;

use Patch;
use Patch::Parser;
use Patch::Algo qw(split_patch);

my $input = parse_hunk <<EOF;
@@ -40,6 +40,11 @@ void hello(const char *) {
     {
          int i = 0;
.j+         int j = 4;
 
-         i = 4;
+         i = 5;
.j+         j = 4 * i;
.j+         i = sqrt(j);
+         i = sqrt(i);
+
          return i * 4;
     }
EOF

my $input_exp = parse_hunk <<EOF;
@@ -40,6 +40,8 @@ void hello(const char *) {
     {
          int i = 0;
 
-         i = 4;
+         i = 5;
+         i = sqrt(i);
+
          return i * 4;
     }
EOF

my $res_exp = parse_hunk <<EOF;
@@ -40,8 +40,11 @@ void hello(const char *) {
     {
          int i = 0;
.j+         int j = 4;
 
          i = 5;
.j+         j = 4 * i;
.j+         i = sqrt(j);
          i = sqrt(i);
 
          return i * 4;
     }
EOF

my $res = split_patch $input, 'j';
is_deeply($input, $input_exp, 'Input must match');
is_deeply($res, $res_exp, 'Result must match');

$input = parse_patched_file <<EOF;
diff --git a/test.c b/test.c
--- a/test.c
+++ b/test.c
@@ -40,6 +40,11 @@ void hello(const char *) {
     {
         int i = 0;
.j+        int j = 4;
 
-        i = 4;
+        i = 5;
.j+        j = 4 * i;
.j+        i = sqrt(j);
+        i = sqrt(i);
+
        return i * 4;
     }
.j@@ -60,7 +65,7 @@ int sum(int i, int j) {
     {
         int sum;
         // the easy part
-        sum = i + i;
+        sum = i + j;
         // the tricky part
         return sum;
     }
EOF

my $input_exp = parse_patched_file <<EOF;
diff --git a/test.c b/test.c
--- a/test.c
+++ b/test.c
@@ -40,6 +40,8 @@ void hello(const char *) {
     {
         int i = 0;
 
-        i = 4;
+        i = 5;
+        i = sqrt(i);
+
        return i * 4;
     }
EOF

my $res_exp = parse_patched_file <<EOF;
diff --git a/test.c b/test.c
--- a/test.c
+++ b/test.c
@@ -40,8 +40,11 @@ void hello(const char *) {
     {
         int i = 0;
.j+        int j = 4;
 
         i = 5;
.j+        j = 4 * i;
.j+        i = sqrt(j);
         i = sqrt(i);
 
        return i * 4;
     }
.j@@ -62,7 +65,7 @@ int sum(int i, int j) {
     {
         int sum;
         // the easy part
-        sum = i + i;
+        sum = i + j;
         // the tricky part
         return sum;
     }
EOF

my $res = split_patch $input, 'j';
is_deeply($input, $input_exp, 'Input must match');
is_deeply($res, $res_exp, 'Result must match');
