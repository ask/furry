package App::furry::File;
# $Id: File.pm,v 1.2 2007/07/06 10:58:22 ask Exp $
# $Source: /opt/CVS/furry/lib/App/furry/File.pm,v $
# $Author: ask $
# $HeadURL$
# $Revision: 1.2 $
# $Date: 2007/07/06 10:58:22 $
use strict;
use warnings;
use version;
use Carp;
use File::Spec;
use Scalar::Util    qw(blessed);
use File::Temp      qw(:POSIX);
use File::Basename  qw(basename dirname);
use Fatal           qw(open close);
use English         qw(-no_match_vars);
use Config::Tiny;
use Mac::PropertyList;
require 5.00800;
require   Exporter;
use base 'Exporter';
use vars qw($VERSION);
$VERSION = 0.3;

my $OTOOL             = 'otx';
my %OTOOL_ARCH_OPTION = (
    'ppc'   => '-arch ppc',
    'i386'  => '-arch i386',
);
my $OTOOL_OPTIONS     = q{};

# lipo options.
my $LIPO              = 'lipo';

our @EXPORT = qw(
    find_exe_in_bundle
    lipo_extract
    lipo_concat 
    disassemble
    is_universal_binary
    type_of_file
);

our @EXPORT_OK = @EXPORT;

sub find_exe_in_bundle {
    my ($name) = @_;

    if (-d $name) {
        my $dirname    =  $name;
           $dirname    =~ s{/$}{}xms;
           $dirname    =  basename($dirname);
        my ($pname, $extension) = split m/\./xms, $dirname;
        my $try = File::Spec->catfile($name, 'Contents', 'MacOS', $pname);
        return $try if -x $try;

        my $contents   = File::Spec->catdir($name, 'Contents');
        my $info_plist = File::Spec->catfile($contents, 'Info.plist');

        my $info_data  = Mac::PropertyList::parse_plist_file($info_plist);
        my $exe= property_as_string($info_data->{CFBundleExecutable});

        croak "Can't find executable in bundle [$name]. Or is it a directory?"
            if not $exe;

        my $exe_path   = File::Spec->catfile($contents, 'MacOS', $exe);

        return $exe_path;
    }

    elsif (-x _) {
        return $name;
    }

    #die "Couldn't find executable: $name\n";
}

sub property_as_string {
    my ($property) = @_;

    return if !$property;
    return if !blessed $property;
    return if !$property->isa('Mac::PropertyList::string');
    return if !defined $property->value;

    return $property->value;
}

sub lipo_extract {
    my ($input, $output, $arch) = @_;

    my $cmd = qq{$LIPO "$input" -extract $arch -output "$output"};

    print ">>> Extracting architecture $arch from [$input]\n";

    my $ret = system $cmd;
    return if not $ret;

    return $output;
}

sub lipo_concat {
    my ($input_x86, $input_ppc, $output) = @_;

    my $cmd = qq{$LIPO -create "$input_x86" "$input_ppc" -output "$output"};

    print ">>> Merging x86 and ppc into universal binary [$output]\n";
    
    my $ret = system $cmd;
    return if not $ret;

    return $output;
}

sub disassemble {
    my ($input, $arch) = @_;

    my $output  = tmpnam();

    my $arch_option = $OTOOL_ARCH_OPTION{$arch};

    print ">>> Disassembling file [$input], architecture [$arch] into [$output]\n";

    # Disassemble the executable, output to the temporary file.
    my $cmd = qq{$OTOOL $OTOOL_OPTIONS $arch_option "$input" > "$output"};

    my $ret = system 'sh', '-c', $cmd;

    return $output;
}

sub is_universal_binary { 
    my ($executable) = @_;

    my $ret = qx{file "$executable" | grep 'universal binary'}; ## no critic

    return $ret ? 1 : 0;
}

sub type_of_file {
    my ($executable) = @_;

    my $file_type = qx{file "$executable"}; ## no critic
    my ($info, $arch_info) = split m/\s*:\s*/xms, $file_type;

    return 'ppc'  if $arch_info =~ m/ppc/xms;
    return 'i386' if $arch_info =~ m/i386/xms;

    return;
}

__END__
