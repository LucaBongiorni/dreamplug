#!/usr/bin/perl
use warnings;
use strict;

package dp_file_importer;

# import_map: FROM((FS::ABSOLUTE)) TO((GIT::RELATIVE))
my %import_map = (
	'/root/bin/led_set.pl' => 'scripts/led_set.pl',
	'/root/bin/remount-ro' => 'scripts/remount',
	'/root/bin/dp-kinstall.sh' => 'scripts/dp-kernel-install.sh',
	'/root/bin/senderliste_erstellen' => 'scripts/senderliste_erstellen',
	'/root/bin/reg-smbuser.sh' => 'scripts/experimental/register_smbuser.sh',
	'/root/bin/checklog' => 'scripts/checklog',
	'/root/bin/psearch' => 'scripts/psearch',

	'/etc/init.d/uapd' => 'scripts/init.d/uapd',
	'/etc/init.d/cacheloader' => 'scripts/init.d/cacheloader',
	'/etc/init.d/rc.local.shutdown' => 'scripts/init.d/rc.local.shutdown',

	'/etc/sudoers.d/vdr_led' => 'conf/sudoers.d/vdr_led',
	'/etc/apt/preferences.d' => 'conf/apt/preferences.d',
	'/etc/apt/sources.list' => 'conf/apt/sources.list',
	'/etc/rsyslog.d' => 'conf/rsyslog.d',
	'/etc/rc.local' => 'conf/rc.local',

	'/etc/fstab.example' => 'conf/fstab',

	'/boot/config-2.6.38.8-dream1' => 'kernel/config/2.6.38.8-dream1',
);

# areas where files should not be executable
# kernel configs are executable thanks to vfat
my @noexe_dirs = (q<conf>, q<kernel/config>);

# cmd suffixes
my $NOERR = ' 2>/dev/null ';
my $NOSTD = ' 1>/dev/null ';

sub basename() {
	my $x = $_[0];
	chomp ($x);
	if ($x) {
		$x =~ s?.*/??;
	}
	$x;
}

sub dirname() {
	my $x = $_[0];
	chomp ($x);
	if ($x) {
		$x =~ s,^(.*)/.*?$,$1,g;
		$x = "/" unless ($x);
	}
	$x;
}

sub chomp_path() {
	my $x = $_[0];
	chomp ($x);
	if ($x) {
		$x =~ s=/{1,}=/=g;
		$x =~ s=/{1,}$==;
	}
	$x;
}

sub mkdir_p() {
	my $dir = $_[0];
	chomp ($dir);
	return if (-d $dir);

	my $mindepth = $_[1];
	chomp ($mindepth);
	$mindepth = q() unless ($mindepth);

	my @dirs = ();
	push (@dirs, $dir);
	while ($dir ne $mindepth) {
		$dir = &dirname ($dir);
		push (@dirs, $dir);	

		last unless ($dir);
		last if (-d $dir);
		last if ($dir eq $mindepth);
	}
	
	while (@dirs) {
		$dir = pop (@dirs);
		mkdir ($dir) unless (-d $dir);
	}
}

my $gitroot = $ENV {'PWD'};
my $CP_UPDATE = "cp -vuLfR --";
my $CP_IMPORT = "cp -vLfR --";

my $ARG_BREAK = 195;

my $CP = $CP_UPDATE;


sub arg_handle() {
	my $x = $_[0];
	my $ret = 0;

	chomp ($x);
	unless ($x) {
		$ret = 1;
	} elsif ($x eq q<-->) {
		$ret = $ARG_BREAK;
	} elsif (($x eq q<!>) || ($x eq q<--import>)) {
		$CP = $CP_IMPORT;
	} elsif ($x eq q<--update>) {
		$CP = $CP_UPDATE;
	} else {
		die "unknown arg: '$x'. known args are {--import/!,--update}.";
	}
	$ret;
}
foreach my $arg (@ARGV) { last if (&arg_handle ($arg) == $ARG_BREAK); }

if ($CP eq $CP_IMPORT) { print "using cp import mode.\n"; }
	else { print "using cp update mode.\n"; }


## fetch files
foreach my $file (keys %import_map) {
	if (-e $file) {
		my $dest = &chomp_path ($gitroot . "/" . $import_map {$file});
		my $dir = &dirname ($dest);
		&mkdir_p ($dir, $gitroot);
		$dest = $dir if (-d $file);
		my $cmd = "$CP $file $dest" . $NOERR;
		print "error importing $file\n" if (system ($cmd));
	}
}

## fixup permissions
foreach my $reldir (@noexe_dirs) {
	my $dir = &chomp_path ($gitroot . "/" . $reldir);
	my $F = q< find >;
	my $FF = q< -type f -exec chmod -x {} \;>;
	if (-d $dir) {
		my $cmd = $F . $dir . $FF . $NOERR . $NOSTD;
		print "error when running $cmd!\n" if (system ($cmd));
	}
}
