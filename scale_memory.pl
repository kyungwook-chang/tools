#!/usr/bin/perl

##################################################################################################
# CLN16FCLL SVT -> ULVT
# scaling factor is derived by comparing INV and NAND cell of base_svt_tt_85c and base_ulvt_tt_85c
# delay x0.641
# slew x0.691
# power x1
# leakage x115
# cap x1.117
# area x1
$delay_scaling_factor = 0.641;
$slew_scaling_factor = 0.691;
$power_scaling_factor = 1;
$leakage_scaling_factor = 115;
$capacitance_scaling_factor = 1.117;
$area_scaling_factor = 1;

@delay_value_keywords = ("cell_rise", "cell_fall", "retaining_rise", "retaining_fall");
@slew_value_keywords = ("rise_transition", "retain_rise_slew", "cell_fall", "retaining_fall_slew");
@power_value_keywords = ("rise_power", "fall_power");
@leakage_value_keywords = ("leakage_power");
@capacitance_value_keywords = ("capacitance", "rise_capacitance", "fall_capacitance");
@area_value_keywords = ("area");
sub compare_delay_stmt {
	$cmp_string = shift;
	foreach $index (0..$#delay_value_keywords) {
		if ($cmp_string =~ m/\b$delay_value_keywords[$index]\b/) {
			return 1;
		}
	}
	return 0;
}
sub compare_slew_stmt {
	$cmp_string = shift;
	foreach $index (0..$#slew_value_keywords) {
		if ($cmp_string =~ m/\b$slew_value_keywords[$index]\b/) {
			return 1;
		}
	}
	return 0;
}
sub compare_power_stmt {
	$cmp_string = shift;
	foreach $index (0..$#power_value_keywords) {
		if ($cmp_string =~ m/\b$power_value_keywords[$index]\b/) {
			return 1;
		}
	}
	return 0;
}
sub compare_leakage_stmt {
	$cmp_string = shift;
	foreach $index (0..$#leakage_value_keywords) {
		if ($cmp_string =~ m/\b$leakage_value_keywords[$index]\b/) {
			return 1;
		}
	}
	return 0;
}
sub compare_capacitance_stmt {
	$cmp_string = shift;
	foreach $index (0..$#capacitance_value_keywords) {
		if ($cmp_string =~ m/\b$capacitance_value_keywords[$index]\b/) {
			return 1;
		}
	}
	return 0;
}
sub compare_area_stmt {
	$cmp_string = shift;
	foreach $index (0..$#area_value_keywords) {
		if ($cmp_string =~ m/\b$area_value_keywords[$index]\b/) {
			return 1;
		}
	}
	return 0;
}

($input_file, $output_file) = @ARGV;
if (not defined $input_file) {
	die "USAGE: kcMemScale.pl input_file [output_file]";
}
if (not defined $output_file) {
	$output_file = $input_file;
	$output_file =~ s/\.lib$/.scaled.D${delay_scaling_factor}_S${slew_scaling_factor}_P${power_scaling_factor}_L${leakage_scaling_factor}_C${capacitance_scaling_factor}_A${area_scaling_factor}.lib/g;
}

$scale_cur_line = 0;
$brace_lvl = 0;
my @scope_stamp;
push(@scope_stamp, "top");
my @brace_stamp;

open (FIN, "$input_file") || die ("Cannot open the file");
open (FOUT, "> $output_file");
foreach $line (<FIN>) {
	if ($line =~ m/{/) {
		$brace_lvl++;
	} 

	if ($scope_stamp[-1] eq "top" and $line =~ m/^\s*cell\s*\((.*)\)/) {
		#print "Entering SCOPE: cell, BRACE_LVL: $brace_lvl\n";
		push(@brace_stamp, $brace_lvl);
		push(@scope_stamp, "cell");
		#print "CUR_CELL: $1\n";
	} elsif ($scope_stamp[-1] eq "cell" and compare_area_stmt($line)) {
		$scale_cur_line = 1;
		$scaling_factor = $area_scaling_factor;
	} elsif ($scope_stamp[-1] eq "cell" and compare_leakage_stmt($line)) {
		#print "Entering SCOPE: leakage_power, BRACE_LVL: $brace_lvl\n";
		push(@brace_stamp, $brace_lvl);
		push(@scope_stamp, "leakage_power");
	} elsif ($scope_stamp[-1] eq "leakage_power" and $line =~ m/value/) {
		$scale_cur_line = 1;
		$scaling_factor = $leakage_scaling_factor;
	} elsif ($scope_stamp[-1] eq "cell" and $line =~ m/^\s*bus\s*\((.*)\)/) {
		#print "Entering SCOPE: bus, BRACE_LVL: $brace_lvl\n";
		push(@brace_stamp, $brace_lvl);
		push(@scope_stamp, "bus");
		#print "CUR_BUS: $1\n";
	} elsif (($scope_stamp[-1] eq "cell" or $scope_stamp[-1] eq "bus") and $line =~ m/^\s*pin\s*\((.*)\)/) {
		#print "Entering SCOPE: pin, BRACE_LVL: $brace_lvl\n";
		push(@brace_stamp, $brace_lvl);
		push(@scope_stamp, "pin");
		#print "CUR_PIN: $1\n";
	} elsif (($scope_stamp[-1] eq "bus" or $scope_stamp[-1] eq "pin") and compare_capacitance_stmt($line)) {
		$scale_cur_line = 1;
		$scaling_factor = $capacitance_scaling_factor;
	} elsif (($scope_stamp[-1] eq "bus" or $scope_stamp[-1] eq "pin") and $line =~ m/^\s*timing\s*\((.*)\)/) {
		#print "Entering SCOPE: timing, BRACE_LVL: $brace_lvl\n";
		push(@brace_stamp, $brace_lvl);
		push(@scope_stamp, "timing");
	} elsif ($scope_stamp[-1] eq "timing" and compare_delay_stmt($line)) {
		#print "Entering SCOPE: delay, BRACE_LVL: $brace_lvl\n";
		push(@brace_stamp, $brace_lvl);
		push(@scope_stamp, "delay");
	} elsif ($scope_stamp[-1] eq "delay" and $line =~ m/value/) {
		$scale_cur_line = 1;
		$scaling_factor = $delay_scaling_factor;
	} elsif ($scope_stamp[-1] eq "timing" and compare_slew_stmt($line)) {
		#print "Entering SCOPE: slew, BRACE_LVL: $brace_lvl\n";
		push(@brace_stamp, $brace_lvl);
		push(@scope_stamp, "slew");
	} elsif ($scope_stamp[-1] eq "slew" and $line =~ m/value/) {
		$scale_cur_line = 1;
		$scaling_factor = $slew_scaling_factor;
	} elsif (($scope_stamp[-1] eq "bus" or $scope_stamp[-1] eq "pin") and $line =~ m/^\s*internal_power\s*\((.*)\)/) {
		#print "Entering SCOPE: timing, BRACE_LVL: $brace_lvl\n";
		push(@brace_stamp, $brace_lvl);
		push(@scope_stamp, "internal_power");
	} elsif ($scope_stamp[-1] eq "internal_power" and compare_power_stmt($line)) {
		#print "Entering SCOPE: power, BRACE_LVL: $brace_lvl\n";
		push(@brace_stamp, $brace_lvl);
		push(@scope_stamp, "power");
	} elsif ($scope_stamp[-1] eq "power" and $line =~ m/value/) {
		$scale_cur_line = 1;
		$scaling_factor = $power_scaling_factor;
	}

	# DO SCALING
	if ($scale_cur_line == 1) {
		$modified_line = $line;
		$modified_line =~ s/([-+]?[0-9]*\.?[0-9]+([eE][-+]?[0-9]+)?)/$1 * $scaling_factor/eg;
		print FOUT "$modified_line";
	} else {
		print FOUT "$line";
	}

	if ($line =~ m/}/) {
		if ($brace_lvl == $brace_stamp[-1]) {
			#print "Exiting SCOPE: $scope_stamp[-1], BRACE_LVL: $brace_stamp[-1]\n";
			pop(@brace_stamp);
			pop(@scope_stamp);
		}
		$brace_lvl--;
	}
	if ($scale_cur_line == 1 and $line =~ m/;/) {
		$scale_cur_line = 0;
	}
}
