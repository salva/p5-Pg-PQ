
use ExtUtils::MakeMaker;

`pg_config --version` =~ /PostgreSQL\s+(\d+)\.(\d+\.\d+)/i;
unless (defined $1 and $1 >= 8) {
    die "libpq 8.x.x or later required (".(defined $1 ? "$1.$2" : 'none')." found)\n";
}

my $major = $1;

my $incdir = `pg_config --includedir`;
my $libdir = `pg_config --libdir`;
chomp($incdir, $libdir);

WriteMakefile( NAME          => 'Pg::PQ',
               VERSION_FROM  => 'lib/Pg/PQ.pm',
               PREREQ_PM     => {},
               ABSTRACT_FROM => 'lib/Pg/PQ.pm',
               AUTHOR        => 'Salvador Fandino <sfandino@yahoo.com>',
               LIBS          => ["-lpq -L$libdir"],
               DEFINE        => "-DPQMAJOR=$major", # e.g., '-DHAVE_SOMETHING'
               INC           => "-I. -I$incdir",
               # OBJECT        => '$(O_FILES)', # link all the C files too
             );
