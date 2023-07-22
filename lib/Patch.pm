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

use List::Util qw(any);

sub nonempty {
    my ($self) = @_;

    return defined($self) && scalar($self->{lines}->@*) &&
           any { $_->is_add() || $_->is_remove() } $self->{lines}->@*;
};

use List::Util qw(any);

sub nonempty {
    my ($self) = @_;

    return scalar($self->{hunks}->@*) &&
           any { $_->nonempty() } $self->{hunks}->@*;
};

use List::Util qw(any);

sub nonempty {
    my ($self) = @_;

    return scalar($self->{files}->@*) &&
           any { $_->nonempty() } $self->{files}->@*;
};
