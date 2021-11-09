#!/usr/bin/perl -w
use strict;
use Cwd;

my $DEBUG_ENABLED = 1;

my @tests = (
    "ascii_tag.log",
    "long_tag.log",
    "short_tag.log",
    "strip_rw.log",
    "rewrite.log",
    "bmp2tiff_palette.sh.log",
    "bmp2tiff_rgb.sh.log",
    "gif2tiff.sh.log",
    "ppm2tiff_pbm.sh.log",
    "ppm2tiff_pgm.sh.log",
    "ppm2tiff_ppm.sh.log",
    "tiffcp-g3.sh.log",
    "tiffcp-g3-1d.sh.log",
    "tiffcp-g3-1d-fill.sh.log",
    "tiffcp-g3-2d.sh.log",
    "tiffcp-g3-2d-fill.sh.log",
    "tiffcp-g4.sh.log",
    "tiffcp-logluv.sh.log",
    "tiffcp-thumbnail.sh.log",
    "tiffdump.sh.log",
    "tiffinfo.sh.log",
    "tiffcp-split.sh.log",
    "tiffcp-split-join.sh.log",
    "tiff2ps-PS1.sh.log",
    "tiff2ps-PS2.sh.log",
    "tiff2ps-PS3.sh.log",
    "tiff2ps-EPS1.sh.log",
    "tiff2pdf.sh.log",
    "tiffcrop-doubleflip-logluv-3c-16b.sh.log",
    "tiffcrop-doubleflip-minisblack-1c-16b.sh.log",
    "tiffcrop-doubleflip-minisblack-1c-8b.sh.log",
    "tiffcrop-doubleflip-minisblack-2c-8b-alpha.sh.log",
    "tiffcrop-doubleflip-miniswhite-1c-1b.sh.log",
    "tiffcrop-doubleflip-palette-1c-1b.sh.log",
    "tiffcrop-doubleflip-palette-1c-4b.sh.log",
    "tiffcrop-doubleflip-palette-1c-8b.sh.log",
    "tiffcrop-doubleflip-rgb-3c-16b.sh.log",
    "tiffcrop-doubleflip-rgb-3c-8b.sh.log",
    "tiffcrop-extract-logluv-3c-16b.sh.log",
    "tiffcrop-extract-minisblack-1c-16b.sh.log",
    "tiffcrop-extract-minisblack-1c-8b.sh.log",
    "tiffcrop-extract-minisblack-2c-8b-alpha.sh.log",
    "tiffcrop-extract-miniswhite-1c-1b.sh.log",
    "tiffcrop-extract-palette-1c-1b.sh.log",
    "tiffcrop-extract-palette-1c-4b.sh.log",
    "tiffcrop-extract-palette-1c-8b.sh.log",
    "tiffcrop-extract-rgb-3c-16b.sh.log",
    "tiffcrop-extract-rgb-3c-8b.sh.log",
    "tiffcrop-extractz14-logluv-3c-16b.sh.log",
    "tiffcrop-extractz14-minisblack-1c-16b.sh.log",
    "tiffcrop-extractz14-minisblack-1c-8b.sh.log",
    "tiffcrop-extractz14-minisblack-2c-8b-alpha.sh.log",
    "tiffcrop-extractz14-miniswhite-1c-1b.sh.log",
    "tiffcrop-extractz14-palette-1c-1b.sh.log",
    "tiffcrop-extractz14-palette-1c-4b.sh.log",
    "tiffcrop-extractz14-palette-1c-8b.sh.log",
    "tiffcrop-extractz14-rgb-3c-16b.sh.log",
    "tiffcrop-extractz14-rgb-3c-8b.sh.log",
    "tiffcrop-R90-logluv-3c-16b.sh.log",
    "tiffcrop-R90-minisblack-1c-16b.sh.log",
    "tiffcrop-R90-minisblack-1c-8b.sh.log",
    "tiffcrop-R90-minisblack-2c-8b-alpha.sh.log",
    "tiffcrop-R90-miniswhite-1c-1b.sh.log",
    "tiffcrop-R90-palette-1c-1b.sh.log",
    "tiffcrop-R90-palette-1c-4b.sh.log",
    "tiffcrop-R90-palette-1c-8b.sh.log",
    "tiffcrop-R90-rgb-3c-16b.sh.log",
    "tiffcrop-R90-rgb-3c-8b.sh.log",
    "tiff2rgba-logluv-3c-16b.sh.log",
    "tiff2rgba-minisblack-1c-16b.sh.log",
    "tiff2rgba-minisblack-1c-8b.sh.log",
    "tiff2rgba-minisblack-2c-8b-alpha.sh.log",
    "tiff2rgba-miniswhite-1c-1b.sh.log",
    "tiff2rgba-palette-1c-1b.sh.log",
    "tiff2rgba-palette-1c-4b.sh.log",
    "tiff2rgba-palette-1c-8b.sh.log",
    "tiff2rgba-rgb-3c-16b.sh.log",
    "tiff2rgba-rgb-3c-8b.sh.log"
    );

sub debug {
    my $msg = shift;

    if ($DEBUG_ENABLED) {
        printf "[libtiff-run-tests] " . $msg . "\n";
    }
}

sub get_tiff_pdf_files {
    my $test_name = shift;

    my $old_cwd = getcwd;
    chdir "../golden/test" or die "We're in the wrong directory: $!";
    system("bash -c 'make clean &> /dev/null'");
    system("bash -c 'rm -f *.tif &> /dev/null'");
    system("bash -c 'rm -f *.tiff &> /dev/null'");
    system("bash -c 'rm -f *.pdf &> /dev/null'");
    system("rm -f $test_name &> /dev/null");
    debug "test: " . $test_name;
    my @result = `CC='angelix-compiler --klee' bash -c 'make -e $test_name' 2>&1`;

    my $pre_ls_file_tif="ls_of_tif.pre";
    my $post_ls_file_tif="ls_of_tif.post";
    my @diff_files_tif=`bash -c 'comm -13 <(sort $pre_ls_file_tif) <(sort $post_ls_file_tif)'`;
    chomp @diff_files_tif;

    if (scalar @diff_files_tif == 0) {
        debug "failed to obtain tiff files";
        @diff_files_tif = ();
    }

    my $pre_ls_file_pdf="ls_of_pdf.pre";
    my $post_ls_file_pdf="ls_of_pdf.post";
    my @diff_files_pdf=`bash -c 'comm -13 <(sort $pre_ls_file_pdf) <(sort $post_ls_file_pdf)'`;
    chomp @diff_files_pdf;

    if (scalar @diff_files_pdf == 0) {
        debug "failed to obtain pdf files";
        @diff_files_pdf = ();
    }

    chdir $old_cwd;

    return (\@diff_files_tif, \@diff_files_pdf);
}

sub get_cost_pdf {
    my $pdf_file = shift;
    my $test_name = shift;
    my $penalty_1 = defined $ENV{PENALTY1} ? $ENV{PENALTY1} : 1;
    my $penalty_2 = defined $ENV{PENALTY2} ? $ENV{PENALTY2} : 1;

    my $cur_pdf_file = "test/$pdf_file";
    debug "pdf file: " . $cur_pdf_file;
    my $golden_pdf = "../golden/test/$pdf_file";
    debug "golden pdf: " . $golden_pdf;

    my $dist = `bash -c "diff -U 0 <(pdftotext -bbox $golden_pdf /dev/stdout 2> /dev/null) <(pdftotext -bbox $cur_pdf_file /dev/stdout 2> /dev/null) 2> /dev/null | wc -c"`;

    debug "cost for " . $pdf_file . ": " . $dist;
    return "$dist";
}

sub get_cost_tiff {
    my $tiff_file = shift;
    my $test_name = shift;
    my $penalty_1 = defined $ENV{PENALTY1} ? $ENV{PENALTY1} : 1;
    my $penalty_2 = defined $ENV{PENALTY2} ? $ENV{PENALTY2} : 1;

    debug "compute cost against golden tiff";
    my $golden_tiff = "../golden/test/$tiff_file";
    debug "golden tiff: " . $golden_tiff;

    my $golden_info = "../golden/test/$tiff_file.info";
    my $ret1 = system("bash -c 'tiffinfo -d -i ../golden/test/$tiff_file > $golden_info 2> /dev/null'");
    unless (-e $golden_info) {
        # return cost 0 since there is no golden info.
        return 0;
    }

    my $info_file = "test/$tiff_file.info";
    my $ret2 = system("bash -c 'tiffinfo -d -i test/$tiff_file > $info_file' 2> /dev/null");
    if ($ret2 != 0) {
        debug "tiffinfo failed to generate a target info file " . $info_file;
    }

    my $dist = `python3 /angelix-experiments/.aux/libtiff/scripts/dist_tiff.py $golden_info $info_file`;

    unless (-e $info_file) {
        debug "target info file does not exist";
        $dist *= $penalty_1
    }

    unless (-s $info_file) {
        debug "target info file " . $info_file . " is empty";
        $dist *= $penalty_2
    }

    debug "cost for " . $tiff_file . ": " . $dist;
    return "$dist";
}

sub inst_num {
    my $name = shift;

    my $inst_file_name = "inst/$name.inst";
    if (-e $inst_file_name) {
        debug "exits! $inst_file_name";
        my $inst = `cat $inst_file_name`;
        return $inst;
    }

    system("bash -c 'make clean &> /dev/null'");
    system("rm -f $name &> /dev/null");
    my @result = `CC='angelix-compiler --klee' bash -c 'perf stat -e instructions:u make -e $name' 2>&1`;
    my $stat = (grep(/instructions:u/, @result))[0];
    chomp $stat;
    $stat =~ s/^\s+//;
    my $inst_num = (split /\s+/, $stat)[0];

    system("bash -c 'mkdir -p inst && echo $inst_num > $inst_file_name'");

    return $inst_num;
}

sub compute_cost {
    my $name = shift;
    my $num_errors = shift;
    my $num_warnings = shift;
    my $cur_inst_num = shift;
    my $segfault = shift;
    my $use_perf = shift;

    my $should_inst_increase = 0;

    # sum up cost
    my $total_cost = 0;
    my @all_files = get_tiff_pdf_files($name);
    my @tiff_files = @{$all_files[0]};
    my @pdf_files = @{$all_files[1]};

    for my $tiff_file (@tiff_files) {
        debug "tiff file: " . $tiff_file;
        my $cost = get_cost_tiff($tiff_file, $name);
        $total_cost += $cost;
    }
    for my $pdf_file (@pdf_files) {
        debug "pdf file: " . $pdf_file;
        my $cost = get_cost_pdf($pdf_file, $name);
        $total_cost += $cost;
    }
    debug "output diff cost: " . $total_cost;

    if (int($total_cost) == 0) {
        my $default_cost = $ENV{ANGELIX_DEFAULT_NON_ZERO_COST};
        debug "Use a predefined non-zero cost " . $default_cost;
        $total_cost = $default_cost;
    }

    if (defined $ENV{ANGELIX_ERROR_COST} && $num_errors != 0) {
        $total_cost += $ENV{ANGELIX_ERROR_COST} * $num_errors;
    }

    if (defined $ENV{ANGELIX_WARNING_COST} && $num_warnings != 0) {
        $total_cost += $ENV{ANGELIX_WARNING_COST} * $num_warnings;
    }

    if ($use_perf == 1) {
        my $old_cwd = getcwd;
        chdir "../golden/test";
        my $golden_inst_num = inst_num($name);
        debug "golden_inst_num: $golden_inst_num";
        chdir $old_cwd;

        chdir "../validation/test";
        my $validation_inst_num = inst_num($name);
        debug "validation_inst_num: $validation_inst_num";
        chdir $old_cwd;

        if ($golden_inst_num > $validation_inst_num) {
            $should_inst_increase = 1;
        }

        my $inst_digits = `python3 -c "print(len(str($validation_inst_num)))"`;
        debug "inst digits: " . $inst_digits;
        my $inst_weight = `python3 -c "import numpy as np; print(np.power(10, $inst_digits / 2))"`;
        debug "inst_weight: " . $inst_weight;

        my $x;
        if ($should_inst_increase == 1) {
            # as more instructions are executed, cost decreases.
            debug "prefer more instructions";
            my $inc = ($cur_inst_num - $validation_inst_num) / $validation_inst_num * $inst_weight;
            debug "increment: $inc";
            $x = $inc;
        } else {
            debug "prefer less instructions";
            my $dec = ($validation_inst_num - $cur_inst_num) / $validation_inst_num * $inst_weight;
            debug "decrement: $dec";
            $x = $dec;
        }
        # my $inst_cost = `python3 -c "import numpy as np; print((-$total_cost / (1+$total_cost * np.exp(-($x+$total_cost*np.e/$total_cost))))+($total_cost))"`;
        my $inst_cost = `python3 -c "import numpy as np; k = 1 / np.power(10, len(str($total_cost))); print($total_cost / (1 + np.exp(-k * (-$x))))"`;
        debug "inst cost: $inst_cost\n";
        $total_cost += $inst_cost;
    }

    printf "total cost: %s\n", $total_cost;

    # write total cost to cost file
    my $cost_file = defined $ENV{ANGELIX_COST_FILE} ? $ENV{ANGELIX_COST_FILE} : "cost";
    open(FH, '>', $cost_file) or die $!;
    print FH $total_cost;
    close(FH);

    return $total_cost;
}

####################################
# Main
####################################

if (length($ARGV[0]) == 0)
{
    die "Must specify a test number";
}

my $length = scalar @tests;
if ($ARGV[0] =~ m/length/) { print $length; exit 0 }

my $num = $ARGV[0] - 1;
my $name = $tests[$num];

my $should_compute_cost = 0;
if (defined $ENV{ANGELIX_COMPUTE_COST}) {
    $should_compute_cost = 1
}

my $use_perf = 0;
if (defined $ENV{ANGELIX_USE_PERF}) {
    $use_perf = 1
}

my $fault_localize = 0;
if (defined $ENV{ANGELIX_FAULT_LOCALIZE}) {
    $fault_localize = 1
}

if ($num < 0 || $num > $length)
{
    die "Invalid test number: $num";
}
chdir "test" or die "We're in the wrong directory: $!";
system("bash -c 'make clean &> /dev/null'");
system("bash -c 'rm -f *.tif &> /dev/null'");
system("bash -c 'rm -f *.tiff &> /dev/null'");
system("bash -c 'rm -f *.info &> /dev/null'");
system("rm -f $name &> /dev/null");
printf("test: %s\n", $name);

debug "num: " . $num;
if ($num == 21) {
    system("cp -r /angelix-experiments/.aux/libtiff/2007-11-02-371336d-865f7b2/test /angelix-experiments/.angelix/validation");
    system("cp -r /angelix-experiments/.aux/libtiff/2007-11-02-371336d-865f7b2/test /angelix-experiments/.angelix/frontend");
    system("cp -r /angelix-experiments/.aux/libtiff/2007-11-02-371336d-865f7b2/test /angelix-experiments/.angelix/golden");
}

debug "should_compute_cost: " . $should_compute_cost;
debug "fault_localize: " . $fault_localize;
debug "use_perf: " . $use_perf;
my @result;
if ($should_compute_cost == 1 || $fault_localize == 1) {
    if ($use_perf == 1) {
        @result = `CC='angelix-compiler --klee' bash -c 'perf stat -e instructions:u make -e $name' 2>&1`;
    } else {
        @result = `CC='angelix-compiler --klee' bash -c 'make -e $name'`;
    }
} else {
    @result = `CC='angelix-compiler --klee' bash -c 'make -e $name'`;
}

system("cat $name");
my $num_errors = 0;
my $num_warnings = 0;
if ($should_compute_cost == 1) {
    $num_errors = `cat $name | grep -n "Error" | wc -l`;
    debug "num_errors: " . $num_errors;
    $num_warnings = `cat $name | grep -n "Warning" | wc -l`;
    debug "num_warnings: " . $num_warnings;
}
chdir "..";

my $inst_num;
if ($should_compute_cost == 1 && $use_perf == 1) {
    my $stat = (grep(/instructions:u/, @result))[0];
    chomp $stat;
    $stat =~ s/^\s+//;
    $inst_num = (split /\s+/, $stat)[0];
    my $inst_file_name = "inst/$name.inst";
    debug "current inst num: " . $inst_num;
    system("bash -c 'mkdir -p inst && echo $inst_num > $inst_file_name'");
}

my $segfault = 0;
foreach my $line (@result)
{
    system("bash -c 'killall -r lt-.* &> /dev/null'");

    if ($line =~ m/^PASS/)
    {
        print "PASS: $name\n";
        # if ($should_compute_cost == 1) {
        #     my $cost=compute_cost($name, $num_errors, $num_warnings,
        #                           $inst_num, $segfault, $use_perf);
        #     if ($cost == 0) {
        #         exit 0;
        #     } else {
        #         exit 1;
        #     }
        # }
        exit 0;
    }
    elsif ($line =~ m/Segmentation fault/)
    {
        print "[libtiff-run-tests] Segfault occurred\n";
        $segfault = 1;
    }
    elsif ($line =~ m/^FAIL/)
    {
        print "FAIL: $name\n";

        if ($should_compute_cost == 1) {
            compute_cost($name, $num_errors, $num_warnings, $inst_num, $segfault, $use_perf);
        }
        exit 1;
    }
}
