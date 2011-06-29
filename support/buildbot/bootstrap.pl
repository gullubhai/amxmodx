#!/usr/bin/perl

use strict;
use Cwd;
use File::Basename;

my ($myself, $path) = fileparse($0);
chdir($path);

require 'helpers.pm';

#Go to main source dir
chdir(Build::PathFormat('../..'));

#Do the annoying revision bumping.
#Linux needs some help here.
if ($^O eq "linux")
{
	Build::Command("flip -u modules.versions");
	Build::Command("flip -u support/versionchanger.pl");
	Build::Command("chmod +x support/versionchanger.pl");
}
Build::Command(Build::PathFormat('support/versionchanger.pl') . ' --buildstring="-dev"');

my $DEVENV = "C:\\Windows\\Microsoft.NET\\Framework\\v4.0.30319\\MSBuild.exe";

#Build the amxmodx builder tool.
chdir('installer/builder');
if ($^O eq "linux") {
	Build::Command("make");
} else {
	Build::Command("\"$DEVENV\" builder.csproj /p:Configuration=Release /t:Rebuild");
}
if (!(-f 'builder.exe')) {
	die "Could not find build tool.\n";
}
chdir('../..');

if (-d '../OUTPUT') {
	Build::Delete(Cwd::abs_path('../OUTPUT'));
}
Build::Command("mkdir " . Build::PathFormat('../OUTPUT'));

#Output directions on how to build.
open(DIRECTIONS, '>installer/builder/directions.info');
if ($^O eq "linux") {
	print DIRECTIONS "compress = /bin/tar\n";
} else {
	print DIRECTIONS "compress = C:\\WINDOWS\\zip.exe\n";
}
print DIRECTIONS "source = " . Cwd::abs_path('.') . "\n";
print DIRECTIONS "makeopts = \n";
print DIRECTIONS "output = " . Cwd::abs_path('../OUTPUT') . "\n";
if ($^O eq "linux") {
	print DIRECTIONS "devenv = /usr/bin/make\n";
} else {
	print DIRECTIONS "devenv = $DEVENV\n";
}
print DIRECTIONS "release = amxmodx-" . Build::ProductVersion('product.version') .
				 "-hg" . Build::HgRevNum('.') . "\n";
close(DIRECTIONS);

