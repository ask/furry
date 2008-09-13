# $Id: Build.PL,v 1.1.1.1 2007/07/05 20:16:49 ask Exp $
# $Source: /opt/CVS/furry/Build.PL,v $
# $Author: ask $
# $HeadURL$
# $Revision: 1.1.1.1 $
# $Date: 2007/07/05 20:16:49 $
use strict;
use warnings;

sub BEGIN {
    use File::Spec;
    use FindBin qw($Bin);
    my $inc = File::Spec->catdir($Bin, 'inc');
    unshift @INC, $inc;
}

use Module::Build;

# ##########################################################

# Configuration for this script is done in the config.ph file.
our $BUILD_CONFIGFILE = 'config.ph';

# ##########################################################



sub YES { 1 };
sub NO  { 0 };

$ENV{DEVEL_COVER_OPTIONS} = '-ignore,blib/Class/InsideOut/Policy/Modwheel.pm';
my $builder = Module::Build->new(
    module_name          => 'App::furry',
    license              => 'perl',
    dist_author          => 'Ask Solem <ASKSH@cpan.org>',
    all_from             => 'lib/App/furry.pm',
    dynamic_config       => NO,
    sign                 => NO, # asksh: have to find out why my signature fails.
    create_makefile_pl   => 'traditional',
    create_readme        => YES,
    recursive_test_files => YES,
    requires             => {
        'version'                               => 0,
        'Mac::PropertyList'                     => 0,
        'Getopt::LL'                            => 0,
        'File::BSED',                           => 0.4,
        'Scalar::Util'                          => 0,
        'File::Temp'                            => 0,
        'File::Basename'                        => 0,
        'File::Spec'                            => 0,
        'List::Util'                            => 0,
        'Fatal'                                 => 0,
        'File::Copy'                            => 0,
        'Config::Tiny'                          => 0,
    },
    recommends           => {
        'Test::Pod'             => 1.22,    # Last significant bug-change.
        'Pod::Coverage'         => 0.18,       
        'Test::Pod::Coverage'   => 1.08,    # Last significant bug-change.
        'Test::Exception'       => 0.25,
        'Perl::Critic'          => 1.051,
        'Test::Perl::Critic'    => 1.0,
        'Test::YAML::Meta'      => 0.04,
        'IO::Capture::Stderr'   => 0,
       'Test::Kwalitee'        => 0.30,
    },
    build_requires       => {
     'Test::Simple'            => 0.42,    # 
    },
    add_to_cleanup       => [ qw(
        a.out
        test.pl
        test.c
        test.cpp
        test.m
        *.swp
        .gdb_history
        install.cache
        t/cache
        cache/
    ) ],
    meta_merge => {
        distribution_type   => 'Application',
        resources           => {
        },
    },
    urls => {
        license => 'http://dev.perl.org/licenses/',
    },
);

$builder->create_build_script( );
