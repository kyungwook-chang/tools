#!/usr/bin/perl

use strict;
use warnings;
use Getopt::Long;
use Data::Dumper;
use File::Basename;

my $module;
my $netlist = "./testbench/aes_128_syn.v";
my $format = "";

GetOptions (	"nelist=s"	=> \$netlist,
				"format=s"	=> \$format
);

my @wire_map = ();
my @inst_map = ();

sub parse_netlist {
	my ($netlist_filename) = @_;
	open (FIN, "$netlist_filename");
	my $line_buf = "";
	while (<FIN>) {
		my $line = $_;
		chomp $line;
		$line_buf .= $line;
		if ($line =~ /;\s*$/) {
			#print "$line_buf\n";
			if ($line_buf =~ /^\s*input\s+(.*)\s*;\s*$/) {
				#input definition
				my @cur_inputs = $1 =~ /\S+/g;
				foreach my $cur_input (@cur_inputs) {
					$cur_input =~ s/,//g;
					$module->{wire}{$cur_input}->{is_port} = 1;
					$module->{wire}{$cur_input}->{is_input} = 1;
					$module->{wire}{$cur_input}->{term} = ();
					$module->{wire}{$cur_input}->{num} = scalar @wire_map;
					push @wire_map, $cur_input;
				}
			} elsif ($line_buf =~ /^\s*output\s+(.*)\s*;\s*$/) {
				#output definition
				my @cur_outputs = $1 =~ /\S+/g;
				foreach my $cur_output (@cur_outputs) {
					$cur_output =~ s/,//g;
					$module->{wire}{$cur_output}->{is_port} = 1;
					$module->{wire}{$cur_output}->{is_input} = 0;
					$module->{wire}{$cur_output}->{term} = ();
					$module->{wire}{$cur_output}->{num} = scalar @wire_map;
					push @wire_map, $cur_output;
				}
			} elsif ($line_buf =~ /^\s*wire\s+(.*)\s*;\s*$/) {
				#wire definition
				my @cur_wires = $1 =~ /\S+/g;
				foreach my $cur_wire (@cur_wires) {
					$cur_wire =~ s/,//g;
					$module->{wire}{$cur_wire}->{is_port} = 0;
					$module->{wire}{$cur_wire}->{is_input} = 0;
					$module->{wire}{$cur_wire}->{term} = ();
					$module->{wire}{$cur_wire}->{num} = scalar @wire_map;
					push @wire_map, $cur_wire;
				}
			} elsif ($line_buf =~ /^\s*(\S+)\s+(\S+)\s*\(\s*(.*)\s*\)\s*;\s*$/) {
				#instantiation
				my $cell_name = $1;
				my $inst_name = $2;
				my @port_maps = $3 =~ /\.\S+\s*\(\s*\S+\s*\)/g;
				$module->{inst}{$inst_name}->{cell} = $1;
				$module->{inst}{$inst_name}->{num} = scalar @inst_map;
				push @inst_map, $inst_name;
				foreach my $port_map (@port_maps) {
					#print "PORT_MAP: $port_map\n";
					$port_map =~ /\.(\S+)\s*\(\s*(\S+)\s*\)/;
					my $inst_term = $1;
					my $net = $2;

					$module->{inst}{$inst_name}->{term}{$inst_term}->{net} = $net;
					if ($inst_term =~ /^[YZQ]/) {
						$module->{inst}{$inst_name}->{term}{$inst_term}->{is_output} = 1;
					} else {
						$module->{inst}{$inst_name}->{term}{$inst_term}->{is_output} = 0;
					}

					#print "$inst_name $inst_term -> $net\n";
					my $conn;
					$conn->{inst} = $inst_name;
					$conn->{pin} = $inst_term;
					if ($inst_term =~ /^[YZQ]/) {
						$conn->{is_driver} = 1;
					} else {
						$conn->{is_driver} = 0;
					}
					push @{ $module->{wire}{$net}->{term} }, $conn;
				}
			}
			$line_buf = "";
		} else {
			next;
		}
	}
	#print Dumper \$module;
	close FIN;
}

sub write_hgr {
	my ($hgr_filename) = @_;
	open (FOUT, ">", "$hgr_filename");
	my $num_inst = scalar keys %{ $module->{inst} };
	my $num_wire = scalar keys %{ $module->{wire} };
	print FOUT "$num_wire $num_inst\n";
	for (my $wire_num=0; $wire_num<(scalar @wire_map); $wire_num++) {
		foreach my $term (@{ $module->{wire}{$wire_map[$wire_num]}->{term} }) {
			my $inst_name = $term->{inst};
			print FOUT "$module->{inst}{$inst_name}->{num} ";
		}
		print FOUT "\n";
	}
	close FOUT;
}

sub write_bookshelf {
	my ($out_basename) = @_;
	my $aux_filename = $out_basename.".aux";
	my $nodes_filename = $out_basename.".nodes";
	my $nets_filename = $out_basename.".nets";
	my $wts_filename = $out_basename.".wts";
	my $pl_filename = $out_basename.".pl";
	my $scl_filename = $out_basename.".scl";

	#aux file
	open (FOUT, ">", "$aux_filename");
	print FOUT "RowBasedPlacement : $nodes_filename $nets_filename $wts_filename $pl_filename $scl_filename";
	close FOUT;

	#nodes file
	open (FOUT, ">", "$nodes_filename");
	close FOUT;

	#nets file
	open (FOUT, ">", "$nets_filename");
	close FOUT;

	#wts file
	open (FOUT, ">", "$wts_filename");
	close FOUT;

	#pl file
	open (FOUT, ">", "$pl_filename");
	close FOUT;

	#scl file
	open (FOUT, ">", "$scl_filename");
	close FOUT;
}

parse_netlist($netlist);
#if ($format eq "bookshelf") {
	my $out_basename = basename($netlist, ".v");
	write_bookshelf($out_basename);
#} else {
	my $out_filename = basename($netlist, ".v");
	$out_filename .= ".hgr";
	write_hgr($out_filename);
#}
