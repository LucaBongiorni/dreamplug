#!/usr/bin/perl
use warnings;
use strict;

package led_control;

my $led_root = '/sys/devices/platform/leds-gpio/leds';
my $led_ctrl = "brightness";
my $s = '/';

my %led_map = (
	power => 'guruplug:red:health',
	wifi  => 'guruplug:red:wmode',
	ap    => 'guruplug:green:wmode',
	bt    => 'guruplug:green:health',
);

my @control = ("ap", "wifi", "bt");

my %circle = (
	ap => "wifi",
	wifi => "bt",
	bt => "ap",
);

# hard value
my $max = 255;

my %led = ();
foreach my $l (@control) {
	$led {$l} = $led_root . $s . $led_map {$l} . $s . $led_ctrl;
}

# led shortcuts
$led {'vdr'} = $led {'bt'};
$led {'apt'} = $led {'ap'};

## numbered
$led {'0'} = $led {'wifi'};
$led {'1'} = $led {'ap'};
$led {'2'} = $led {'bt'};

# on (led_path)
sub on() {
#	die "bad led: $_[0]" unless (-w $_[0]);
	system ("echo $max > $_[0] 2>/dev/null");
}

sub off() {
#	die "bad led: $_[0]" unless (-w $_[0]);
	system ("echo 0 > $_[0] 2>/dev/null");
}

sub set() {
	system ("echo $_[1] > $_[0] 2>/dev/null");
}

sub print_status() {
#	die "bad led: $_[0]" unless (-w $_[0]);
	print &status ($_[0]) . "\n";
}

sub status() {
#	die "bad led: $_[0]" unless (-w $_[0]);
	my $l = $_[0];
	open (RR, "<", $l) or die $!;
	my $out = <RR>;
	close (RR);
	chomp ($out);
	$out;
}

sub increase() {
	my $l = $_[0];
	my $s = &status ($l);
	if ($s < $max) {
		$s++;
		&set ($l, $s);
	}
}
sub decrease() {
	my $l = $_[0];
	my $s = &status ($l);
	if ($s > 0) {
		$s--;
		&set ($l, $s);
	}
}

sub toggle() {
#	die "bad led: $_[0]" unless (-w $_[0]);
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
	0;
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
	rainbow  => \&rainbow,
	list     => \&list,
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

	4 => \&rainbow,
	r => \&rainbow,

	"+" => \&increase,
	"-" => \&decrease,

);


die "usage: led_set.pl <dev> <action>" if (scalar (@ARGV) != 2);
die "please specifiy a LED to control." if ($ARGV [0] eq '');
die "please specify an action." if ($ARGV [1] eq '');

die "bad LED : " . $ARGV [0] unless (exists $led {$ARGV [0]});
my $dev = $led {$ARGV [0]};
die "bad LED file : $dev" unless (&ledcheck ($dev));

die "bad action : " . $ARGV [1] unless (exists $action {$ARGV [1]});
my $action = $action {$ARGV [1]};

&$action ($dev);
