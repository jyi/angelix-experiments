#!/usr/bin/perl -w
use strict;

my @tests = (
    "helin-segv",
    "help-version",
    "hufts",
    "memcpy-abuse",
    "mixed",
    "null-suffix-clobber-part1",
    "null-suffix-clobber-part2",
    "stdin",
    "trailing-nul",
    "zdiff",
    "zgrep-f",
    "zgrep-signal",
    "znew-k"
);

if (length($ARGV[0]) == 0)
{
    die "Must specify a test number";
}

my $length = scalar @tests;
#If the string "length" is the only argument, then return the number of test cases and exit without error.
if ($ARGV[0] =~ m/length/) { print $length  ; exit 0 }

my $num = $ARGV[0] - 1;
my $name = $tests[$num];



if ($num < 0 || $num > $length)
{
    die "Invalid test number: $num" ;
}

chdir "tests" or die "We're in the wrong directory: $!" ;
print "[gzip-run-tests.pl] make $name.log\n";
my @result = `rm -f $name.log && chmod +x $name && make $name.log`;
chdir "..";
foreach my $line(@result)
{
    print "line: $line";
    if ($line =~ m/^PASS/)
    {
        print "PASS: $name\n";
        exit 0;
    }
    elsif ($line =~ m/^FAIL/)
    {
        print "FAIL: $name\n";
        exit 1;
    }
}
