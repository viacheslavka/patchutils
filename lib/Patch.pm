use strict;
use warnings;

package Patch::Line;

sub new {
    my ($cls, $contents, $mark) = @_;

    return bless {
        mark => $mark,
        contents => $contents,
    }, $cls;
};

sub clone {
    my ($self) = @_;

    return bless {
        $self->%*
    }, ref $self;
}

sub normalize {
    my ($self) = @_;

    return bless {
        mark => $self->{mark},
        contents => $self->{contents} =~ s/^[+-]/ /r,
    }, ref $self;
}

sub to_string {
    my ($self) = @_;

    if (defined($self->{mark})) {
        return '.' . $self->{mark} . $self->{contents};
    }
    return $self->{contents};
};

sub is_add {
    my ($self) = @_;

    return $self->{contents} =~ /^\+/;
}

sub is_remove {
    my ($self) = @_;

    return $self->{contents} =~ /^-/;
}

sub clear_marks {
    my ($self) = @_;

    $self->{mark} = undef;
}

package Patch::Hunk;

use List::Util qw(any);

sub new {
    my ($cls, $old_start, $new_start, $context, $lines, $mark) = @_;

    return bless {
        mark => $mark,
        old_start_line => $old_start,
        new_start_line => $new_start,
        context => $context,

        lines => $lines,
    }, $cls;
}

sub added_lines {
    my ($self) = @_;
    my $n = 0;

    for ($self->{lines}->@*) {
        $n++ if $_->is_add;
    }

    return $n;
}

sub removed_lines {
    my ($self) = @_;
    my $n = 0;

    for ($self->{lines}->@*) {
        $n++ if $_->is_remove;
    }

    return $n;
}

sub old_len {
    my ($self) = @_;
    my $n = 0;

    for ($self->{lines}->@*) {
        $n++ unless $_->is_add;
    }

    return $n;
}

sub len_diff {
    my ($self) = @_;
    my $n = 0;

    for ($self->{lines}->@*)
    {
        $n++ if $_->is_add;
        $n-- if $_->is_remove;
    }

    return $n;
}

sub new_len {
    my ($self) = @_;

    return $self->old_len + $self->len_diff;
}

sub to_string {
    my ($self) = @_;
    my $header = sprintf('%s@@ -%d,%d +%d,%d @@%s',
                         $self->{mark} ? '.' . $self->{mark} : '',
                         $self->{old_start_line},
                         $self->old_len,
                         $self->{new_start_line},
                         $self->new_len,
                         $self->{context} ? ' ' . $self->{context} : '');

    return join("\n", $header, map($_->to_string, $self->{lines}->@*)) . "\n";
}

sub nonempty {
    my ($self) = @_;

    return defined($self) && scalar($self->{lines}->@*) &&
           any { $_->is_add() || $_->is_remove() } $self->{lines}->@*;
};

sub clear_marks {
    my ($self) = @_;

    $self->{mark} = undef;
    $_->clear_marks() for $self->{lines}->@*;
}

package Patch::PatchedFile;

use List::Util qw(any);

sub new {
    my ($cls, $mark, $old_prefix, $new_prefix,
        $old_name, $new_name, $old_mode, $new_mode,
        $index_line, $hunks) = @_;

    return bless {
        mark => $mark,
        old_prefix => $old_prefix,
        new_prefix => $new_prefix,
        old_name => $old_name,
        new_name => $new_name,
        old_mode => $old_mode,
        new_mode => $new_mode,
        index_line => $index_line,
        hunks => $hunks,
    }, $cls;
};

sub to_string {
    my ($self) = @_;
    my $result;

    # Form git patch header
    $result = sprintf("diff --git %s/%s %s/%s\n",
                      $self->{old_prefix}, $self->{old_name},
                      $self->{new_prefix}, $self->{new_name});

    # Leave important extended headers
    if (defined($self->{old_mode} and defined($self->{new_mode}) and
            $self->{old_mode} ne $self->{new_mode})) {
        $result .= "old mode $self->{old_mode}\n";
        $result .= "new mode $self->{new_mode}\n";
    }

    $result .= $self->{index_line} . "\n" if defined($self->{index_line});

    if (defined($self->{old_name}) and defined($self->{new_name}) and
            ($self->{old_name} ne $self->{new_name})) {
        $result .= "rename from $self->{old_name}\n";
        $result .= "rename to $self->{new_name}\n";
    }

    if (defined($self->{old_name}) and not defined($self->{new_name})) {
        $result .= "deleted mode $self->{old_mode}";
    }

    if (not defined($self->{old_name}) and defined($self->{new_name})) {
        $result .= "new file mode $self->{new_mode}";
    }

    # Form unified diff header
    $result .= sprintf("--- %s\n", defined($self->{old_name}) ? "$self->{old_prefix}/$self->{old_name}" : '/dev/null');
    $result .= sprintf("+++ %s\n", defined($self->{old_name}) ? "$self->{new_prefix}/$self->{new_name}" : '/dev/null');

    # Dump all hunks
    $result .= $_->to_string for $self->{hunks}->@*;

    return $result;
};

sub nonempty {
    my ($self) = @_;

    return scalar($self->{hunks}->@*) &&
           any { $_->nonempty() } $self->{hunks}->@*;
};

sub clear_marks {
    my ($self) = @_;

    $self->{mark} = undef;
    $_->clear_marks() for $self->{hunks}->@*;
}

package Patch;

use List::Util qw(any);

our $VERSION = '0.001';

sub new {
    my ($cls, $files) = @_;
    return bless { files => $files }, $cls;
};

sub nonempty {
    my ($self) = @_;

    return scalar($self->{files}->@*) &&
           any { $_->nonempty() } $self->{files}->@*;
};

sub to_string {
    my ($self) = @_;

    return join "\n", map $_->to_string, $self->{files}->@*;
}

sub clear_marks {
    my ($self) = @_;

    $_->clear_marks() for $self->{files}->@*;
}

1;
