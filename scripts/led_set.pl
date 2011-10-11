#!/usr/bin/perl
use warnings;
use strict;

package led_control;

#my $led_root = '/sys/devices/platform/leds-gpio/leds';
my $led_root = '/sys/class/leds';
my $led_ctrl = "brightness";

my %led_map = (
	power => 'guruplug:red:health',
	wifi  => 'guruplug:red:wmode',
	ap    => 'guruplug:green:wmode',
	bt    => 'guruplug:green:health',
);

# power seems to be always on (even with brightness = 0 and trigger = none) and won't be controlled here
my @control = ("ap", "wifi", "bt");

my %rainbow_circle = (
	ap   => "wifi",
	wifi => "bt",
	bt   => "ap",
);

# hard value
my $max = 255;

my %led = ();
foreach my $l (@control) { $led {$l} = $led_root . '/' . $led_map {$l} . '/' . $led_ctrl; }

# led shortcuts
$led {'vdr'} = $led {'bt'};
$led {'apt'} = $led {'ap'};

## numbered
$led {'0'} = $led {'wifi'};
$led {'1'} = $led {'ap'};
$led {'2'} = $led {'bt'};

# on (led_path)
sub on()  { system ("echo  $max > $_[0] 2>/dev/null"); }
sub off() { system ("echo     0 > $_[0] 2>/dev/null"); }
sub set() { system ("echo $_[1] > $_[0] 2>/dev/null"); }

sub status() {
	my $l = $_[0];
	open (RR, "<", $l) or die $!;
	my $out = <RR>;
	close (RR);
	chomp ($out);
	$out;
}
sub status_all() {
	my %status = ();
	foreach my $l (@control) { $status {$l} = &status ($led {$l}); }
	%status;
}

sub print_status() { print &status ($_[0]) . "\n"; }
sub print_status_all() {
	my %status = &status_all();
	foreach my $l (@control) { print $l . ': ' . $status {$l} . qq<\n>; }
}

sub increase() {
	my $l = $_[0];
	my $s = &status ($l);
	if ($s < $max) {
		$s++;
		&set ($l, $s);
	} else { 0; }
}
sub decrease() {
	my $l = $_[0];
	my $s = &status ($l);
	if ($s > 0) {
		$s--;
		&set ($l, $s);
	} else { 0; }
}

sub toggle() {
	my $l = $_[0];
	my $s = &status ($l);
	if ($s) {
		&off ($l);
	} else {
		&on ($l);
	}
}

sub list() {
	foreach my $key (keys %led_map) {
		print $key . ' -> ' . ${led_map {$key}}. "\n";
	}
}

sub rainbow() {
	# TODO
	127;
}

sub ledcheck() {
	my $x = $_[0];
	my $score = 0;
	if ($x) {
		if ($x =~ m/^\/proc/) {
			$score++;
		} elsif ($x =~ m/^\/sys/) {
			$score++;
		}
		$score = 0 unless (-r $x);
	}
	$score;
}

# action table - is a hash for direct access
my %action = (
	on       => \&on,
	off      => \&off,
	toggle   => \&toggle,
	status   => \&print_status,
	increase => \&increase,
	decrease => \&decrease,

	# shortcuts
	0 => \&off,
	n => \&off,

	1 => \&on,
	y => \&on,

	2 => \&toggle,
	t => \&toggle,

	3 => \&print_status,
	s => \&print_status,

	"+" => \&increase,
	"-" => \&decrease,

);
my %global_action = (
	status   => \&print_status_all,
	rainbow  => \&rainbow,
	list     => \&list,

	# shortcuts
	4 => \&rainbow,
	r => \&rainbow,
	s => \&print_status_all,
);

die "usage: led_set.pl <dev|-> <action|global_action>" if (scalar (@ARGV) != 2);
die "please specifiy a LED to control." if ($ARGV [0] eq '');
die "please specify an action." if ($ARGV [1] eq '');



my ($dev,$action);
if (($ARGV [0] eq q<all>) || ($ARGV [0] eq q<->)) {
	$dev = "undef";
	die "bad global action : " . $ARGV [1] unless (exists $global_action {$ARGV [1]});
	$action = $global_action {$ARGV [1]};
} else {
	$dev = $led {$ARGV [0]};
	die "bad LED : " . $ARGV [0] unless (exists $led {$ARGV [0]});
	die "bad LED file : $dev" unless (&ledcheck ($dev));
	die "bad action : " . $ARGV [1] unless (exists $action {$ARGV [1]});
	$action = $action {$ARGV [1]};
}


my $ret = &$action ($dev);
exit ($ret) if ($ret);
