package Patch::Parser::Buffer;

sub new {
    my ($class, $input) = @_;
    my $fd;

    unless (ref $input) {
        open $fd, '<', \$input;
    } elsif (ref $fd eq 'SCALAR') {
        open $fd, '<', $input;
    } else {
        $fd = $input;
    }

    bless {
        line => undef,
        fd => $fd,
    };
}

sub read_line {
    my ($self) = @_;
    my $line;

    if (defined($self->{line})) {
        $line = $self->{line};
        $self->{line} = undef;
    } else {
        my $fd = $self->{fd};
        $line = scalar <$fd>;
    }

    chomp $line;
    return $line;
}

sub return_line {
    my ($self, $line) = @_;

    if (defined($self->{line})) {
        die "Only one line can be buffered";
    } else {
        $self->{line} = $line;
    }
}

package Patch::Parser;

use strict;
use warnings;

use parent 'Exporter';
our @EXPORT = qw(parse_hunk parse_patched_file parse_patch parse_patch_file);

sub parse_hunk {
    my ($buf) = @_;
    if (ref $buf ne 'Patch::Parser::Buffer') {
        $buf = Patch::Parser::Buffer->new($buf);
    }

    my $line = $buf->read_line();
    my $mark;
    my $old_start;
    my $old_len;
    my $new_start;
    my $new_len;
    my $context;


    if ($line =~ /^(?:\.(\w+)\s*)?@@ -(\d+),(\d+) \+(\d+),(\d+) @@(?: (.+?))?$/)
    {
        $mark = $1;
        $old_start = $2;
        $old_len = $3;
        $new_start = $4;
        $new_len = $5;
        $context = $6;
    } else {
        $buf->return_line($line);
        return undef;
    }

    my @lines;
    while ($line = $buf->read_line()) {
        unless ($line =~ /^(?:\.(\w+)\s*)?([ +-].*?)$/) {
            $buf->return_line($line);
            last;
        }
        push @lines, Patch::Line->new($2, $1);
    }

    my $hunk = Patch::Hunk->new($old_start, $new_start, $context, \@lines, $mark);

    # check lines
    if ($hunk->old_len() != $old_len || $hunk->new_len() != $new_len) {
        die "corrupt patch";
    }

    return $hunk;
}

sub parse_patched_file {
    my ($buf) = @_;
    if (ref $buf ne 'Patch::Parser::Buffer') {
        $buf = Patch::Parser::Buffer->new($buf);
    }

    my $header = $buf->read_line();
    my $mark;
    my $header_old_name;
    my $header_new_name;
    my $old_name;
    my $new_name;

    # diff header
    if ($header =~ /(?:(\.\w+) )?diff --git ((?:\S|\\ )+) ((?:\S|\\ )+)/) {
        $mark = $1;
        $header_old_name = $2 =~ s/\\ / /r;
        $header_new_name = $3 =~ s/\\ / /r;
    } else {
        $buf->return_line($header);
        return undef;
    }

    # extended headers
    my $line;
    my $old_mode;
    my $new_mode;
    my $index;
    while ($line = $buf->read_line()) {
        if ($line =~ /old mode (\d+)/) {
            $old_mode = $1;
        } elsif ($line =~ /^new mode (\d+)/) {
            $new_mode = $1;
        } elsif ($line =~ /^deleted file mode (\d+)/) {
            $old_mode = $1;
        } elsif ($line =~ /^new file mode (\d+)/) {
            $new_mode = $1;
        } elsif ($line =~ /^copy/) {
            die "copy from/to not supported";
        } elsif ($line =~ /^rename to ((?:\S|\\ )+)/) {
            $new_name = $1
        } elsif ($line =~ /^rename from ((?:\S|\\ )+)/) {
            $old_name = $1;
        } elsif ($line =~ /^similarity index/) {
            # ignore
        } elsif ($line =~ /^dissimilarity index/) {
            # ignore
        } elsif ($line =~ /^index /) {
            $index = $line;
        } else {
            $buf->return_line($line);
            last;
        }
    }
    # file names
    $line = $buf->read_line();
    if ($line =~ /^--- (.+)$/) {
        $old_name = $1;
    }
    $line = $buf->read_line();
    if ($line =~ /^\+\+\+ (.+)$/) {
        $new_name = $2;
    }

    $old_name = $header_old_name unless defined($old_name);
    $new_name = $header_new_name unless defined($new_name);

    my $old_prefix = undef;
    my $new_prefix = undef;

    if ($old_name =~ /([^\/]+?)\/(.+)/) {
        $old_prefix = $1;
        $old_name = $2;
    }
    if ($new_name =~ /([^\/]+?)\/(.+)/) {
        $new_prefix = $1;
        $new_name = $2;
    }

    my @hunks;
    while ($line = $buf->read_line()) {
        $buf->return_line($line);
        my $hunk = parse_hunk($buf);
        if (defined($hunk)) {
            push @hunks, $hunk;
        } else {
            last;
        }
    }

    return Patch::PatchedFile->new(
        $mark, $old_prefix, $new_prefix, $old_name, $new_name,
        $old_mode, $new_mode, $index, \@hunks
    );
}

sub parse_patch {
    my ($buf) = @_;
    if (ref $buf ne 'Patch::Parser::Buffer') {
        $buf = Patch::Parser::Buffer->new($buf);
    }

    my $line;
    my @files = ();

    while ($line = $buf->read_line()) {
        $buf->return_line($line);
        my $file = parse_patched_file($buf);
        push @files, $file;
    }

    return Patch->new(\@files);
}

sub parse_patch_file {
    my ($filename) = @_;
    open my $fd, '<', $filename;
    my $buf = Patch::Parser::Buffer->new($fd);
    my $patch = parse_patch $buf;
    close $fd;
    return $patch;
}

1;
