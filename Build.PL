use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name => 'Patch',
    license => 'artistic-2',
    dist_author => q{Viacheslav Galaktionov <slavka@slavkin.site>},
    dist_abstract => 'Parse and modify git patches',
    dist_version_from => 'lib/Patch.pm',
    build_requires => {
        'Test::More' => 0,
    },
    requires => {
        'perl' => 5,
    },
    add_to_cleanup => [ 'Patch-*' ],
);
$builder->create_build_script();
