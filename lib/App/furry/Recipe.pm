package App::furry::Recipe;
# $Id: Recipe.pm,v 1.1 2007/07/06 10:58:22 ask Exp $
# $Source: /opt/CVS/furry/lib/App/furry/Recipe.pm,v $
# $Author: ask $
# $HeadURL$
# $Revision: 1.1 $
# $Date: 2007/07/06 10:58:22 $
use strict;
use warnings;
use Class::Dot qw(:std);
use Config::Tiny;
use vars qw($VERSION);
$VERSION = 0.3;

property recipe_file => isa_String;
property executables => isa_Array;
property patterns    => isa_Hash;

sub new {
    my ($class, $recipe) = @_;

    my $self = { };
    bless $self, $class;

    my ($executables, $patterns)
        = $self->parse_recipe($recipe);

    $self->set_executables($executables);
    $self->set_patterns($patterns);
    $self->set_recipe_file($recipe);

    return $self;
}

sub parse_recipe {
    my ($self, $opt_recipe_file) = @_;
    my $in     = $opt_recipe_file || $self->recipe_file;

    my @executables;
    my %patterns;

    print ">>> Parsing recipe [$in]\n";

    my $config = Config::Tiny->new();
       $config = Config::Tiny->read($in);

    my $what    = delete $config->{what};
    my $comment = delete $config->{comment};
    while (my ($type, $exe) = each %{ $what }) {
        push @executables, $exe;
    }

    my $find_count = 0;
    while (my ($type, $value) = each %{ $config }) {
        if ($type =~ s/^find\s+sub\s+//xms) {
            $find_count++;

            my %archs;
            my @archs = split m/\s+/xms, $value->{'replace preample to'};
            for my $arc (@archs) {
                my ($arch_type, $subst) = split m/:/xms, $arc;
                $archs{$arch_type} = $subst;
            }
            $patterns{'sub'}{$type} = \%archs;
        }
    }

    my $files_count = scalar @executables;

    print "--- Recipe has $files_count file(s) to change and $find_count pattern(s) to match\n";

    return (\@executables, \%patterns);
}

1;

__END__

=pod

=head1 NAME

App::furry::Recipe - Parse furry recipe files.

=head1 VERSION

This document describes furry version v0.3.

=head1 SYNOPSIS

    use App::furry::Recipe;
    
    my $recipe      = App::furry::Recipe->new(shift @ARGV);
    my $patterns    = $recipe->patterns;
    my $executables = $recipe->executables;

=head1 DESCRIPTION

Parse furry recipe files.

=head1 SUBROUTINES/METHODS

=head2 CONSTRUCTOR

=head3 C<new($recipe)>

Create a new C<App::furry::Recipe> object using a recipe.
Parses the recipe and returns the object.

=head2 INSTANCE METHODS

=head3 C<parse_recipe($opt_recipe_file)>

Parse a recipe, if C<$opt_recipe_file> is not defined
the recipe file passed to C<new()> will be used.

Returns array ref to executables and hash ref to patterns.

=head1 DEPENDENCIES

=over 4

=item * Mac OS X >= 10.4

=item * L<Getopt::LL>

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
