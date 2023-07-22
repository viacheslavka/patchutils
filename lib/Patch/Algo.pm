package Patch::Algo;

use strict;
use warnings;

use parent 'Exporter';
our @EXPORT_OK = qw(split_patch);


# split the given patch, remove the marked parts from it
# return the marked parts as a patch that can be applied on top of the given one
sub split_patch {
    my ($patch, $mark) = @_;

    if (ref $patch eq 'Patch') {
        my @old_files = ();
        my @new_files = ();

        my $len_diff = 0;

        for my $file ($patch->{files}->@*) {
            if (($file->{mark} // '') eq $mark) {
                push @new_files, $file;
            } else {
                my $new_file = split_patch($file, $mark);
                push @old_files, $file if $file->nonempty();
                push @new_files, $new_file if defined($new_file) && $new_file->nonempty();
            }
        }
        $patch->{files} = \@old_files;
        return Patch->new(\@new_files);
    } elsif (ref $patch eq 'Patch::PatchedFile') {
        my @old_hunks = ();
        my @new_hunks = ();

        # the difference in line count because of hunk splitting
        my $len_diff = 0;

        for my $hunk ($patch->{hunks}->@*) {
            $hunk->{new_start_line} += $len_diff;

            if (($hunk->{mark} // '') eq $mark) {
                $len_diff += $hunk->len_diff();
                $hunk->{old_start_line} = $hunk->{new_start_line};
                $hunk->{new_start_line} = $hunk->{old_start_line} - $len_diff;
                push @new_hunks, $hunk;
            } else {
                my $new_hunk = split_patch($hunk, $mark);
                push @old_hunks, $hunk if $hunk->nonempty();
                if (defined($new_hunk) && $new_hunk->nonempty()) {
                    $len_diff -= $new_hunk->len_diff();
                    push @new_hunks, $new_hunk;
                }
            }
        }
        $patch->{hunks} = \@old_hunks;
        return Patch::PatchedFile->new(@$patch{qw(mark old_prefix new_prefix
                                                  old_name new_name
                                                  old_mode new_mode
                                                  index_line)}, \@new_hunks);
    } elsif (ref $patch eq 'Patch::Hunk') {
        my @old_lines = ();
        my @new_lines = ();

        for my $line ($patch->{lines}->@*) {
            unless ($line->is_add() || $line->is_remove()) {
                push @old_lines, $line;
                push @new_lines, $line->clone();
            } elsif (($line->{mark} // '') eq $mark) {
                push @new_lines, $line;
            } else {
                push @old_lines, $line;
                push @new_lines, $line->normalize() unless $line->is_remove();
            }
        }

        $patch->{lines} = \@old_lines;
        return Patch::Hunk->new($patch->{new_start_line}, $patch->{new_start_line},
                                $patch->{context}, \@new_lines, $patch->{mark});
    }
}
