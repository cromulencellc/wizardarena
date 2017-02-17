#!/usr/bin/perl

my $hostname = `hostname | awk -F \. ' { print \$1 } '`; chomp $hostname;

my $date = `date +%s`;
chomp $date;

#
# CPU load
#
my $uptime = `uptime`;
my $load1 = 0;
my $load5 = 0;
my $load15 = 0;
if ($uptime =~ /load average: ([0-9\.]+), ([0-9\.]+), ([0-9\.]+)/) {
	$load1 = $1;
	$load5 = $2;
	$load15 = $3;
}
`echo "$hostname.load1 $load1 $date" | nc -q0 graphite 2003`;
`echo "$hostname.load5 $load5 $date" | nc -q0 graphite 2003`;
`echo "$hostname.load15 $load15 $date" | nc -q0 graphite 2003`;

#
# Disk space
#
my $t = `df -k | grep '% /\$'`;
my $root = 0;
if ($t =~ /(\d+)%/) {
	$root = $1;
}
`echo "$hostname.root $root $date" | nc -q0 graphite 2003`;

#
# Total process counts
#
my $allprocs = `ps -elf | wc -l`; chomp $allprocs;
`echo "$hostname.procs.all $allprocs $date" | nc -q0 graphite 2003`;

#
# Per-service process counts
#
my $t = `ls -C1 /etc/xinetd.d/*_xinetd | awk -F \/ ' { print \$4 } ' | awk -F _ ' { print \$1 } '`;
my @services = split /\n/, $t;
my @procs = split /\n/, `ps -elf | grep -v "runc start"`;
for my $s (@services) {
	my $serviceprocs = grep(/$s/, @procs);
	`echo "$hostname.procs.$s $serviceprocs $date" | nc -q0 graphite 2003`;
}

#
# Traffic accounting
#
$nfacct = `/usr/sbin/nfacct list reset`;
my @lines = split /\n/, $nfacct;
foreach my $line (@lines) {
	my $pkts, $bytes, $object;
	if ($line =~ /^{ pkts = (\d+), bytes = (\d+) } = (.*);$/) {
		$pkts = int($1);
		$bytes = int($2);
		$object = $3;
		if ($object =~ /bytes.in$/) {
			`echo "$hostname.services.$object $bytes $date" | nc -q0 graphite 2003`;
		} else {
			`echo "$hostname.services.$object $pkts $date" | nc -q0 graphite 2003`;
		}
	}
}
