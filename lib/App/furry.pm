package App::furry;
# $Id: furry.pm,v 1.3 2007/07/06 10:58:21 ask Exp $
# $Source: /opt/CVS/furry/lib/App/furry.pm,v $
# $Author: ask $
# $HeadURL$
# $Revision: 1.3 $
# $Date: 2007/07/06 10:58:21 $
use strict;
use warnings;
require 5.00800;
use Class::Dot      qw(:std);
use File::Spec;
use Scalar::Util    qw(blessed);
use File::Temp      qw(:POSIX);
use File::Basename  qw(basename dirname);
use List::Util      qw(first);
use Fatal           qw(open close);
use File::Copy      qw(copy move);
use English         qw(-no_match_vars);
use Config::Tiny;
use Mac::PropertyList;
use App::furry::File;
use File::BSED      qw(bsed);
use vars qw($VERSION);
$VERSION = 0.3;

property options => isa_Hash;

# to be sure to find a unique match.
my $INSTR_COUNT_MAX = 20;

sub new {
    my ($class, $options_ref) = @_;
    $options_ref ||= { };

    my $self = { };
    bless $self, $class;

    $self->set_options($options_ref);

    return $self;
}

sub bake {
    my ($self, $exe, $executable, $patterns_ref, $arch, $opt_no_lipo) = @_;
    my $pt          = $executable . $arch;
    my $ptc         = basename($pt) . '.patched';
    my $ptd         = File::Spec->catdir(dirname($pt), $ptc);
    my $options     = $self->options;
    $opt_no_lipo  ||= 0;

    print ">>> Now working with architecture [$arch] for file [$executable]\n";

    if ($opt_no_lipo) {
        copy($executable, $pt);
    }
    else {
        lipo_extract($executable, "$pt", $arch);
    }

    open my $fh, '<', $exe
        or croak "Couldn't open file [$exe]: $OS_ERROR\n";

    my $in_wanted;
    my $instruction_count;
    my %instructions;
LINE:
    while (my $line = <$fh>) {
        chomp $line;

        # empty line marks end of a function
        if ($line =~ m/^ \s* $/xms) {
            $in_wanted
                ? $in_wanted
                = q{}
                : next LINE;
        }

        # starts with whitespace means an instruction
        if ($line =~ m/^ \s+  /xms) {
            if ($in_wanted && $instruction_count++ < $INSTR_COUNT_MAX) {
                push @{ $instructions{$in_wanted} },get_instruction($line);
            }
            next LINE;
        }

        for my $pattern (keys %{ $patterns_ref->{'sub'} }) {
            if ($line =~ m/^\Q$pattern\E/xms) {
                print "*** Successful match of sub pattern [$pattern]\n";
        #if (first { $line =~ m/^\Q$_\E/xms } keys %{ $patterns_ref }) {
                $in_wanted = $pattern;
                $instruction_count = 0;
                $instructions{$in_wanted} = [];
            }
        }
    }

    close $fh
        or croak "Couldn't close file [$exe]: $OS_ERROR\n";

    # remove the first temp file if it already exist.
    if (-f '0') {
        unlink '0';
    }
    # copy the file to a first temporary file: 0.
    copy($pt, '0');

    # each iteration creates a new file for a particular patch
    # with name with the number of the iteration
    # (which is $i). 1, 2, 3 and so on.
    # where the last iteration is the final product.
    my @files;
    my $i = 0;
    while (my ($sub, $instructions) = each %instructions) {
        my $replace_with = $patterns_ref->{'sub'}->{$sub}->{$arch};
        push @files, $i;
        my $search  = join q{}, @{$instructions};
        my $replace = patch_instruction($search, $replace_with);
        my $j = $i + 1;
      
        my $matches = bsed({
            search  => $search,
            replace => $replace,
            infile  => $i,
            outfile => $j,
        });
        if ($matches == -1) {
            warn "! Warning: ", File::BSED->errtostr(), "\n";
        }
        elsif ($matches == 0) {
            warn "? Warning: Did not match this step. [searched for: $search]\n";
        }
        else {
            print "--- Matched $matches time(s).\n";
        } 

        $i = $j;
    }
    unlink $pt;
    move($i, $pt);
    chmod oct(755), $pt;

    if (! $options->{keep_temp_files}) {
        for my $temporary_file (@files) {
            unlink $temporary_file;
        }
    }

    if ($options->{interactive}) {
        my $hit_enter = <STDIN>;
    }

    return;
}

sub get_instruction {
    my ($line) = @_;

    # trim the line. (we gonna split by whitespace)
    $line =~ s/^ \s+  //xms;
    $line =~ s/  \s+ $//xms;

    my ($sub_offset, $file_offset, $instruction)
        = split m/\s+/xms, $line;

    return $instruction;
}

sub patch_instruction {
    my ($instruction, $patch) = @_;

    my $patched = $instruction;
    substr($patched, 0, length($patch)) = $patch; ## no critic

    return $patched;
}

1;

__END__

=pod

=head1 NAME

App::furry - Mac OS X Cracking helper application.

=head1 VERSION

This document describes furry version v0.3.

=head1 SYNOPSIS

    furry <recipe file> [optional override executables to patch]

=head1 DESCRIPTION

Crack a list of files by a recipe.

=head1 INSTALLATION

You need to have Mac::PropertyList, Getopt::LL and Config::Tiny installed,
if you don't you have to use cpan to install them:

    sudo cpan Mac::PropertyList
    sudo cpan Config::Tiny
    sudo cpan Getopt::LL
    sudo cpan File::BSED

Then you can install furry:

    perl Makefile.PL
    make
    make test
    sudo make install

After that you can use furry with

    furry [-v|-k|-i] <recipe file> [optional override executables to crack]

where the flags are:

    -v  - Verbose mode.
    -k  - Keep temporary files.
    -i  - Interactive. (wait for enter after each file).

=head1 SUBROUTINES/METHODS

=head1 DEPENDENCIES

=over 4

=item * Mac OS X >= 10.4

=item * L<Getopt::LL>

=item * L<File::BSED>

=item * L<Mac::PropertyList>

=item * L<Config::Tiny>

=back

=head1 DIAGNOSTICS

=head1 CONFIGURATION AND ENVIRONMENT

This module requires no configuration file or environment variables.

=head1 INCOMPATIBILITIES

None known.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<App-furry@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.

=head1 AUTHOR

Ask Solem, C<< ask@0x61736b.net >>.

=head1 LICENSE AND COPYRIGHT

Copyright (c), 2007 Ask Solem C<< ask@0x61736b.net >>.

All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY FOR THE
SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN OTHERWISE
STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES PROVIDE THE
SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESSED OR IMPLIED,
INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
FITNESS FOR A PARTICULAR PURPOSE. THE ENTIRE RISK AS TO THE QUALITY AND
PERFORMANCE OF THE SOFTWARE IS WITH YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE,
YOU ASSUME THE COST OF ALL NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING WILL ANY
COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR REDISTRIBUTE THE
SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE LIABLE TO YOU FOR DAMAGES,
INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING
OUT OF THE USE OR INABILITY TO USE THE SOFTWARE (INCLUDING BUT NOT LIMITED TO
LOSS OF DATA OR DATA BEING RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR
THIRD PARTIES OR A FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER
SOFTWARE), EVEN IF SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE
POSSIBILITY OF SUCH DAMAGES.

=cut

# Local variables:
# vim: ts=4
=cut
