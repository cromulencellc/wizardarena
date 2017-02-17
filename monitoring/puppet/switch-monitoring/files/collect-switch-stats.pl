#!/usr/bin/perl

use Net::SSH::Expect;

our %data;

#Switch#sho int description 
#Interface                      Status         Protocol Description
#Vl1                            up             down     
#Vl999                          up             up       
#Gi0/1                          up             up       uplink
#Gi0/2                          up             up       router
#Gi0/3                          up             up       storage
#Gi0/4                          up             up       capture
#Gi0/5                          up             up       team1-odroid
#Gi0/6                          down           down     team1-table
#Gi0/7                          up             up       team2-odroid
#Gi0/8                          down           down     team2-table
sub ParseDescr() {
	# send 'show int description'
	my $l = $ssh->exec('show int description');
	my @lines = split /\n/, $l;

	foreach my $line (@lines) {
		next if ($line =~ /^Interface/);
		next if ($line =~ /^Vl/);
		if ($line =~ /^(Gi[^\s]+)\s+[^\s]+\s+[^\s]+\s+(.*)\s+$/) {
			my $port = $1;
			my $descr = $2;
			chomp $descr;
			$port =~ s/\//-/g;
			$descr =~ s/\s/-/g;
			$data{$port}{'descr'} = $descr;
		} elsif ($line =~ /^(Gi[^\s]+)\s+[^\s]+\s+[^\s]+\s+$/) {
			my $port = $1;
			$port =~ s/\//-/g;
			$data{$port}{'descr'} = "blank";
		}
	}	
}

#Switch#sho int counters 
#
#Port            InOctets    InUcastPkts    InMcastPkts    InBcastPkts 
#Gi0/1          113596212         126629          12614           6720 
#Gi0/2      1659477711466     1439674107              2              6 
#Gi0/3          255433195        2474744            151            408 
#Gi0/4                  0              0              0              0 
#Gi0/5         9528405053      106103884             34              0 
#Gi0/6                  0              0              0              0 
#
#Port           OutOctets   OutUcastPkts   OutMcastPkts   OutBcastPkts 
#Gi0/1           37323725         100014          11978           8136 
#Gi0/2      1659577524053     1461402252         101538           7879 
#Gi0/3         7241456288        4819882          28164            747 
#Gi0/4            4417020             35          58501            543 
#Gi0/5        28726680776      159574296          19038              0 
#Gi0/6                  0              0              0              0 
sub ParseCounters() {
	# send 'show int counters'
	my $l = $ssh->exec('show int counters');
	my @lines = split /\n/, $l;

	my $section;
	foreach my $line (@lines) {
		if ($line =~ /^Port\s+InOctets/) {
			$section = "in";
			next;
		}
		if ($line =~ /^Port\s+OutOctets/) {
			$section = "out";
			next;
		}

		if ($line =~ /^(Gi[^\s]+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)/) {
			my $port = $1;
			my $InOctets = $2;
			my $OutOctets = $3+$4+$5;
			$port =~ s/\//-/g;
			if ($section eq "in") {
				$data{$port}{'InOctets'} = $InOctets;
				$data{$port}{'InPkts'} = $OutOctets;
			} elsif ($section eq "out") {
				$data{$port}{'OutOctets'} = $InOctets;
				$data{$port}{'OutPkts'} = $OutOctets;
			}
		}
	}
}


#Switch#sho mls qos interface statistics | include Gigabit|Policer
#GigabitEthernet0/1
#Policer: Inprofile:            0 OutofProfile:            0 
#GigabitEthernet0/2
#Policer: Inprofile:            0 OutofProfile:            0 
sub ParseQoS() {
	# send 'show mls qos interface statistics | include Gigabit|Policer'
	my $l = $ssh->exec('show policy-map interface | include Gigabit|bytes;');
	my @lines = split /\n/, $l;

	my $port;
	my $inprofile = -1;
	my $outofprofile = -1;
	for my $line (@lines) {
		if ($line =~ /^ Gi[a-zA-Z]+([^\s]+)/) {
			if ($inprofile != -1) {
				$data{$port}{'InProfile'} = $inprofile;
				$data{$port}{'OutofProfile'} = $outofprofile;
				$inprofile = 0;
				$outofprofile = 0;
			}
			$port = "Gi$1";
			$port =~ s/\//-/g;
			next;
		}
		if ($line =~ /conformed (\d+) bytes/) {
			$inprofile += $1;
		}
		if ($line =~ /exceeded (\d+) bytes/) {
			$outofprofile += $1;
		}
	}
}

sub SendData() {
	my $date = `date +%s`;
	chomp $date;
	my $message;
	foreach my $port (keys %data) {
		foreach my $counter (keys $data{$port}) {
			next if ($counter eq "descr");
			my $descr = $data{$port}{'descr'};
			next if ($descr eq "blank");
			my $val = $data{$port}{$counter};

			$message .= "switch.$descr.$counter $val $date\n";
		}
	}

	open (OUT, "|nc -q0 graphite 2003");
	print OUT $message;
	close (OUT);
}

# connect
our $ssh = Net::SSH::Expect->new (
	host => "10.3.1.2",
	user => 'mon',
	password => 'g1mm13y0urd@ta',
	raw_pty => 1,
	timeout => 5,
);
$ssh->timeout(5);
my $login_output = $ssh->login();
if ($login_output != /switch/) {
	die "Login failed\n";
}
$ssh->timeout(1);
$ssh->exec('term length 0');

ParseDescr();
ParseCounters();
ParseQoS();
SendData();

$ssh->close();

