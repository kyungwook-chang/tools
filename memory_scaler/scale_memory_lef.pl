#!/usr/bin/perl
# Scale down LEF macros.

# Settings
$newSiteName = "unit";

# This is 1/sqrt(2) 
$SF = 1.281 ;

sub RoundTo5Nm
{
	my ($val);
	$val = $_[0];
	$val = int($val * 200 + 0.5) / 200;
	return $val;
}

# Round to site width/height. Input number is in um.
sub RoundToSite
{
	my ($val);
	my ($valSite);
	$val = $_[0];
	$valSite = $_[1];
	$val = int($val/$valSite + 0.5) * $valSite;
	return $val;
}

# Round up to site width/height. Input number is in um
sub RoundUpToSite
{
	my ($val);
	my ($valSite);
	my ($tmp);
	$val = $_[0];
	$valSite = $_[1];
	
	$tmp = ($val/$valSite == int ($val/$valSite)) ? $val/$valSite : int($val/$valSite+1);
	$val = $tmp * $valSite;
	return $val;
}


if ($#ARGV != 1)
{
	die "USAGE: ./ScaleLEFMacro.pl (input LEF file) (output LEF file)\n";
}

$inFileName = $ARGV[0];
$outFileName = $ARGV[1];
if ($inFileName !~ /(.*)lef/i)
{
	die "ERROR: Input file $inFileName does not have the extension ending in .lef!\n";
}

# Open the LEF file.
open (FIN, $inFileName) or die "ERROR: Cannot open the input LEF file $inFileName!\n";

# Create the output file.
open (FOUT, "> $outFileName") or die "ERROR: Cannot create the output LEF file $outFileName !\n" ;

print FOUT "# Scaled down LEF created by ScaleLEFMacro.pl\n";
print FOUT "# Original LEF: $inFileName\n";
print FOUT "# Don't forget to change metal layer LEF separately!\n";
print FOUT "\n";

$siteWidth = 0.19;
$siteHeight = 1.4;

while ($line = <FIN>)
{
	chomp($line);
	if ($line =~ /^\s*SITE\s+(\S+)/i)
	{
		# Change site name.
		$orgSiteName = $1;
		print "INFO: Changing SITE from $orgSiteName to $newSiteName\n";
		print FOUT "SITE $newSiteName\n";
		while ($line = <FIN>)
		{
			chomp($line);
			if ($line =~ /END\s+$orgSiteName/)
			{
				print FOUT "END $newSiteName\n";
				last;
			}
			elsif ($line =~ /^(\s*)SIZE\s+(\S+)\s+BY\s+(\S+)\s+;/)
			{
				$dummy = $1;
				$siteWidth = RoundUpToNm($2 * $SF);
				$siteHeight = RoundUpToNm($3 * $SF);
				print FOUT "$dummy"."SIZE $siteWidth BY $siteHeight ;\n";
			}
			else
			{
				print FOUT "$line\n";
			}
		}
	}
	elsif ($line =~ /MACRO\s+(\S+)/i)
	{
		print FOUT "$line\n";
		$macroName = $1;
		$ignoreLayer = 0;
		while ($line = <FIN>)
		{
			chomp($line);
			if ($line =~ /END\s+$macroName/)
			{
				print FOUT "$line\n";
				print "INFO: Processed MACRO $macroName\n";
				last;
			}
			elsif ($line =~ /^(\s*)SITE\s+(\S+)\s+;/)
			{
				print FOUT "$1"."SITE $newSiteName ;\n";
			}
			elsif ($line =~ /^(\s*)SIZE\s+(\S+)\s+BY\s+(\S+)\s+;/)
			{
				$dummy = $1;
				$cellWidth = RoundTo5Nm($2 * $SF);
				$cellHeight = RoundTo5Nm($3 * $SF);
				# Oct.24.2012. Make sure cell width and height are multiples of site width and height.
				# Oct.30.2012. For macros, this is not needed.
				$cellWidth = RoundUpToSite($cellWidth, $siteWidth);
				$cellHeight = RoundUpToSite($cellHeight, $siteHeight);
				print FOUT "$1"."SIZE $cellWidth BY $cellHeight ;\n";
			}
			elsif ($line =~ /^(\s*)RECT/)
			{
				# Rectangle.
				$dummy = $1;
				$newLine = "";
				@words = split(/\s+/, $line);
				foreach $word (@words)
				{
					if ($word =~ /RECT/)
					{
						$newLine = "$dummy"."$word";
					}
					elsif ($word eq ";")
					{
						$newLine = $newLine." ;";
						print FOUT "$newLine\n";
						last;
					}
					else
					{
						$newCoord = RoundTo5Nm($word * $SF);
						$newLine = $newLine." $newCoord";
					}
				}
			}
			elsif ($line =~ /^(\s*)POLYGON/)
			{
				# Polygon.
				$found = 0;
				$dummy = $1;
				$newLine = "";
				@words = split(/\s+/, $line);
				foreach $word (@words)
				{
					if ($word =~ /POLYGON/)
					{
						$newLine = "$dummy"."$word";
					}
					elsif ($word eq ";")
					{
						$found = 1;
						$newLine = $newLine." ;";
						last;
					}
					else
					{
						$newCoord = RoundTo5Nm($word * $SF);
						$newLine = $newLine." $newCoord";
					}
				}
				print FOUT "$newLine\n";
				while ($found == 0)
				{
					while ($line = <FIN>)
					{
						chomp($line);
						$newLine = "";
						@words = split(/\s+/, $line);
						foreach $word (@words)
						{
							if ($word eq ";")
							{
								$found = 1;
								$newLine = $newLine." ;";
								last;
							}
							elsif ($word eq "")
							{
								$newLine = $newLine." ";
							}
							else
							{
								$newCoord = RoundTo5Nm($word * $SF);
								$newLine = $newLine." $newCoord";
							}
						}
						print FOUT "$newLine\n";
						if ($found)
						{
							last;
						}
					}
				}
			}
			elsif ($line =~ /^(\s+)LAYER\s+(\S+)\s+(.*)/)
			{
				# Layer change from Chartered 130nm to Synopsys 90/28nm.
				$dummy = $1;
				$theLayer = $2;
				$theRest = $3;
				if ($theLayer =~ /M(\S+)/)
				{
					$theLayer = "metal$1";
				}
				elsif ($theLayer =~ /VIA(\S+)/)
				{
					$theLayer = "via$1";
					#$viaLayer = $1;
					#if ($viaLayer =~ /(\d)\d/)
					#{
					#	$viaLayerFirst = $1;
					#	$theLayer = "VIA$viaLayerFirst";
					#}
					#else
					#{
					#	die "ERROR: VIA layer $theLayer is not recognized!\n";
					#}
				}
				
				print FOUT "$dummy LAYER $theLayer $theRest\n";
			}
			else
			{
				print FOUT "$line\n";
			}
		}
	}
	else
	{
		print FOUT "$line\n";
	}
}

close(FIN);
close(FOUT);

print "INFO: Successfully created $outFileName .\n";

