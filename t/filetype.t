use strict;
use warnings;
use Test::More;
use App::furry::File;
use FindBin qw($Bin);
use File::Spec;


plan tests => 10;

my $testbin = File::Spec->catdir($Bin, 'test-bin');
ok( -d $testbin, "$testbin is a directory" );

my $i386t = File::Spec->catfile($testbin, 'i386');
ok( -f $i386t, "$i386t is a file");

my $PPCt = File::Spec->catfile($testbin, 'PPC');
ok( -f $PPCt, "$PPCt is a file");
my $universalt = File::Spec->catfile($testbin, 'universal');
ok( -f $universalt, "$universalt is a file");

for my $f ($i386t, $PPCt, $universalt) {

    chmod 0755, $f;
    ok( -x $f, "$f is executable" );
}

ok( is_universal_binary($universalt),
    "$universalt is a Universal Binary file"
);

is( type_of_file($i386t), 'i386',
    "$i386t is a i386 executable file"
);

is( type_of_file($PPCt), 'ppc',
    "$PPCt is a PPC executable file"
);

