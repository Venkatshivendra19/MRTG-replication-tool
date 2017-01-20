#!/usr/bin/perl
#use warnings;
use DBI;
use DBD::mysql;
use Cwd 'abs_path';
my $abs_path = abs_path(__FILE__);
@path=split '/',$abs_path;
splice @path,-2;
push (@path,"db.conf");
$actualpath=join('/',@path);
require "$actualpath";
$dsn="DBI:mysql:database=$database;host=$host:port=$port";
$dbh=DBI->connect($dsn,$username,$password) or die("error");
$sth=$dbh->prepare("select *from DEVICES");
$sth->execute();
my @arr=();
while(my @row=$sth->fetchrow_array())
{
$id=@row[0];
$ip=@row[1];
$port=$row[2];
$community=$row[3];
push @arr,$community.'@'.$ip.':'.$port.' ';
}
#print @arr;
$command='cfgmaker --output /etc/mrtg.cfg --global "WorkDir: /var/www/mrtg"  --global "RunAsDaemon: yes" --global "Options[_]: growright" --global "Interval:5" --ifdesc=nr,nr ' . "@arr\n ";
#print $command;
system($command);
system('mkdir -p /var/www/mrtg');
system("indexmaker --output=/var/www/mrtg/index.html /etc/mrtg.cfg");
system("env LANG=C /usr/bin/mrtg /etc/mrtg.cfg");



