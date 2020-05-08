#!/usr/bin/perl

use strict;
use warnings;
use Getopt::Long;
#use Data::Dumper;
use File::Basename;

my $module;
my $netlist = "";
my $format = "";

GetOptions (	"netlist=s"	=> \$netlist,
				"format=s"	=> \$format
);

if ($netlist eq "" || $format eq "") {
	die("Usage: conv_netlist2hypergraph.pl -netlist <path_to_netlist> -format <output_format (hgr, bookshelf)>\n");
}

my @wire_map = ();
my @inst_map = ();

sub parse_netlist {
	my ($netlist_filename) = @_;
	open (FIN, "$netlist_filename") || die("netlist file, $netlist_filename, not found\n");
	my $line_buf = "";
	while (<FIN>) {
		my $line = $_;
		chomp $line;
		$line_buf .= $line;
		if ($line =~ /;\s*$/) {
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
					$port_map =~ /\.(\S+)\s*\(\s*(\S+)\s*\)/;
					my $inst_term = $1;
					my $net = $2;

					$module->{inst}{$inst_name}->{term}{$inst_term}->{net} = $net;
					if ($inst_term =~ /^[YZQ]/) {
						$module->{inst}{$inst_name}->{term}{$inst_term}->{is_output} = 1;
					} else {
						$module->{inst}{$inst_name}->{term}{$inst_term}->{is_output} = 0;
					}

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

	my $num_inst = scalar keys %{ $module->{inst} };
	my $num_wire = scalar keys %{ $module->{wire} };
	my $num_port = 0;
	foreach my $wire_name (keys %{ $module->{wire} }) {
		if ($module->{wire}{$wire_name}->{is_port}) {
			$num_port++;
		}
	}
	my $num_pin = 0;
	foreach my $inst_name (keys %{ $module->{inst} }) {
		my $num_inst_pin = scalar keys %{ $module->{inst}{$inst_name}->{term} };
		$num_pin += $num_inst_pin
	}

	#aux file
	open (FOUT, ">", "$aux_filename");
	print FOUT "RowBasedPlacement : $nodes_filename $nets_filename $wts_filename $pl_filename $scl_filename";
	close FOUT;

	#nodes file
	open (FOUT, ">", "$nodes_filename");
	print FOUT "UCLA nodes 1.0\n\n";
	my $num_node = $num_inst + $num_port;
	print FOUT "NumNodes : $num_node\n";
	print FOUT "NumTerminals : $num_port\n\n";
	foreach my $inst_name (keys %{ $module->{inst} }) {
		print FOUT "\t$inst_name\t0.0\t0.0\n";
	}
	foreach my $wire_name (keys %{ $module->{wire} }) {
		if ($module->{wire}{$wire_name}->{is_port}) {
			print FOUT "\t$wire_name\t0.0\t0.0\tterminal\n";
		}
	}
	close FOUT;

	#nets file
	open (FOUT, ">", "$nets_filename");
	print FOUT "UCLA nets 1.0\n\n";
	print FOUT "NumNets : $num_wire\n";
	# I'm not sure we should deal with ports... I think we should...
	$num_pin += $num_port;
	print FOUT "NumPins : $num_pin\n\n";
	foreach my $wire_name (keys %{ $module->{wire} } ) {
		my $cur_wire = $module->{wire}{$wire_name};
		my $degree = scalar @{ $cur_wire->{term} };
		print FOUT "NetDegree : $degree\n";
		foreach my $term (@{ $cur_wire->{term} } ) {
			my $term_dir = "I";
			if ($term->{is_driver}) {
				$term_dir = "O";
			} else {
				$term_dir = "I";
			}
			print FOUT "\t$term->{inst}\t$term_dir : 0.0 0.0\n";	
		}
		# I'm not sure we should deal with ports... I think we should...
		if ($cur_wire->{is_port}) {
			my $port_dir = "I";
			if ($cur_wire->{is_input}) {
				# input port is a driver of a net (equivalent to output of a pin)
				$port_dir = "O";
			} else {
				$port_dir = "I";
			}
			print FOUT "\t$wire_name\t$port_dir : 0.0 0.0\n";	
		}
	}
	close FOUT;

	#wts file
	open (FOUT, ">", "$wts_filename");
	print FOUT "UCLA wts 1.0\n\n";
	foreach my $inst_name (keys %{ $module->{inst} }) {
		print FOUT "\t$inst_name\t1\n";
	}
	foreach my $wire_name (keys %{ $module->{wire} }) {
		if ($module->{wire}{$wire_name}->{is_port}) {
			print FOUT "\t$wire_name\t1\n";
		}
	}
	close FOUT;

	#pl file
	open (FOUT, ">", "$pl_filename");
	print FOUT "UCLA pl 1.0\n\n";
	foreach my $inst_name (keys %{ $module->{inst} }) {
		print FOUT "\t$inst_name\t0\t0\t:\tN\n";
	}
	foreach my $wire_name (keys %{ $module->{wire} }) {
		if ($module->{wire}{$wire_name}->{is_port}) {
			print FOUT "\t$wire_name\t0\t0\t:\tN\n";
		}
	}
	close FOUT;

	#scl file
	open (FOUT, ">", "$scl_filename");
	print FOUT "UCLA scl 1.0\n\n";
	print FOUT "NumRows : 0\n";
	print FOUT "CoreRow Horizontal\n";
	print FOUT " Coordinate : 0\n";
	print FOUT " Height : 0\n";
	print FOUT " Sitewidth : 0\n";
	print FOUT " Sitespacing : 0\n";
	print FOUT " Siteorient : 0\n";
	print FOUT " Sitesymmetry : 0\n";
	print FOUT " SubrowOrigin : 0\tNumSites : 0\n";
	print FOUT "End\n";
	close FOUT;
}

parse_netlist($netlist);
if ($format eq "bookshelf") {
	my $out_basename = basename($netlist, ".v");
	write_bookshelf($out_basename);
} else {
	my $out_filename = basename($netlist, ".v");
	$out_filename .= ".hgr";
	write_hgr($out_filename);
}
