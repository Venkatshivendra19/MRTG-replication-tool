#!/usr/bin/perl 
use Net::SNMP;
use DBI;
use DBD::mysql;
use Net::SNMP::Interfaces;
use Data::Dumper qw(Dumper);
use Net::SNMP qw(snmp_dispatcher oid_lex_sort);
use RRD::Simple();
use Cwd 'abs_path';
my $abs_path = abs_path(__FILE__);
@path=split '/',$abs_path;
splice @path,-2;
push (@path,"db.conf");
$actualpath=join('/',@path);
require "$actualpath";
my %demo;
my %sessions;

	my $ifindices ='1.3.6.1.2.1.2.2.1.1';
	my $OID_sysUpTime = '1.3.6.1.2.1.1.3.0';
	my $OID_sysContact = '1.3.6.1.2.1.1.4.0';
	my $OID_sysLocation = '1.3.6.1.2.1.1.6.0';
	my $OID_sysname='1.3.6.1.2.1.1.5.0';
	my $OID_interfacename='1.3.6.1.2.1.31.1.1.1.1';
	$dbh = DBI->connect("DBI:mysql:database=$database;host=$host;port=$port", $username,$password)or die "Unable to connect: $DBI::errstr\n";

	$sql="CREATE TABLE IF NOT EXISTS INTERFACES_SHIVI (
	id int(30) NOT NULL primary key auto_increment,
	 IP varchar(255) NOT NULL ,
	 PORT int(30) NOT NULL,
	 COMMUNITY varchar(255) NOT NULL,
	 sysname longtext NOT NULL,
	 sysuptime varchar(255) NOT NULL,
	 syscontact varchar(255) NOT NULL,
	  syslocation varchar(255) NOT NULL,
	interfacelist longtext NOT NULL,
	interfacename longtext NOT NULL,
	lastupdate varchar(255) NOT NULL,
	UNIQUE KEY(IP,PORT,COMMUNITY)
	 
		 ) ";
	$sth =$dbh->prepare($sql);
	$sth->execute();
	$sth->finish();

	$dbh->do("insert into INTERFACES_SHIVI (IP,PORT,COMMUNITY) select DEVICES.IP,DEVICES.PORT,DEVICES.COMMUNITY from DEVICES on duplicate key update IP=INTERFACES_SHIVI.IP");
	$dbh = DBI->connect("DBI:mysql:database=$database;host=$host;port=$port", $username,$password)or die "Unable to connect: $DBI::errstr\n";
	#$dbh = DBI->connect("DBI:mysql:assignments",$username,$password) or die "Unable to connect: $DBI::errstr\n";
	$query="select *from DEVICES";
	$query_handle = $dbh->prepare($query);
	$query_handle->execute();





while(@row=$query_handle->fetchrow())
{
	($id,$ip,$port,$community)=@row;
	$oid_oper='1.3.6.1.2.1.2.2.1.8.';
	$oid_speed='1.3.6.1.2.1.2.2.1.5.';
	$oid_type='1.3.6.1.2.1.2.2.1.3.';


	$sth->execute();
	$sth->finish();
        
	$demo{"$ip:$port:$community"} = {	Ip => $ip,
						port=>$port,
						community=>$community
					};

	# Create the SNMP session
	my ($session, $error) = Net::SNMP->session(
							-hostname => $ip,
							-community=> $community,
							-port     =>  $port,
							-nonblocking => 1,
							-version  => 'snmp1'
						);

	if(!defined($session))
	{
		printf("error:%s.\n",$error);
	}
		
	$demo{"$ip:$port:$community"}{session} = $session;		

	my $result;

	if (!defined($result=$session->get_table(-baseoid  => $ifindices,
					 -callback => [\&callback1,$ip,$port,$community])))
	{
		printf("ERROR: %s.\n", $session->error());
	}
	
	if (!defined($result=$session->get_request(-varbindlist  => [$OID_sysUpTime,$OID_sysContact,$OID_sysLocation,$OID_sysname],
									 -callback => [\&database,$ip,$port,$community])))
	{
		printf("ERROR: %s.\n", $session->error());
	}
}
snmp_dispatcher();


foreach(keys (%demo))
{
	#print "$_\n";
	($ip,$port,$community)=split/:/,$_;
	#print"@array";
	$if_inoctets='1.3.6.1.2.1.2.2.1.10.';
	$if_outoctets='1.3.6.1.2.1.2.2.1.16.';
	my @rrdgraphs=();
	my @filter=();

	foreach(values (% {$demo{"$ip:$port:$community"}{interfaces}}))
	{
		#print "$_..".$community."\n";
		$oper=$demo{$ip.":".$port.":".$community}{details}{$oid_oper.$_};
		$speed=$demo{$ip.":".$port.":".$community}{details}{$oid_speed.$_};
		$type=$demo{$ip.":".$port.":".$community}{details}{$oid_type.$_};
		#print $oper.$speed.$type.$ip;
		       
		if(($oper==1)&&($speed!=0)&&($type!=24))
		{
			push @filter,$_;
			push @rrdgraphs,$if_inoctets.$_,$if_outoctets.$_;
		}

	}
	

	$demo{"$ip:$port:$community"}{filtered}=[@filter];
	while(@rrdgraphs)
	{
		#print @all;
		my @spliced=splice(@rrdgraphs,0,40);

		$demo{"$ip:$port:$community"}{session}->get_request(						  
		-varbindlist => \@spliced,
		-callback    => [\&callback3 ,$ip,$port,$community],
		);
					
	}


	my @splice_ifnames;
	
	foreach(@{$demo{"$ip:$port:$community"}{filtered}})
	{
		push @splice_ifnames,"$OID_interfacename.$_";
	}
	
	 #print Dumper @splice_ifnames;
	while(@splice_ifnames)
	{
		if (!defined($result=$demo{"$ip:$port:$community"}{session}->get_request(-varbindlist  => [splice(@splice_ifnames,0,40)],
		 -callback => [\&ifname,$ip,$port,$community])))
		{

		 printf("ERROR: %s.\n", $session->error());
		}
	}

										
}
snmp_dispatcher();



foreach(keys(%demo))
{
	($ip,$port,$community)=split/:/,$_;

	my $rrd = RRD::Simple->new( file => "$_.rrd");
	my (@graphs,@create);
	if(@{$demo{"$ip:$port:$community"}{filtered}})
	{
		foreach(values ($demo{"$ip:$port:$community"}{filtered}))
		{   
			#print"$_";
			#push @instring,$demo{"$ip:$port:$community"}{bitrate}{$if_inoctets.$_};
			@BYTESIN=("bytesIn$_"=>$demo{"$ip:$port:$community"}{bitrate}{$if_inoctets.$_});
			@BYTESOUT=("bytesOut$_"=>$demo{"$ip:$port:$community"}{bitrate}{$if_outoctets.$_});
			push @graphs,@BYTESIN,@BYTESOUT;

			if(! -e "$_.rrd")
			{
				@bytein=("bytesIn$_"=>"COUNTER");
				@byteout=("bytesOut$_"=>"COUNTER");

				push @create,@bytein,@byteout;
			}
			#RRD TOOL 
		}

		if(@create)
		{
			#print Dumper \@create;
			$rrd->create( "$_.rrd","mrtg", @create) unless (-e "$_.rrd");  

		}

		#print Dumper @graphs;	
		      $rrd->update("$_.rrd",time(),@graphs);
	}
   
}


foreach my $a (keys %demo)
{
	my @ifname_string;
	my $iflist_string=join(':',(sort{$a<=>$b} @{$demo{$a}{filtered}} ) );
	#print"\n$iflist_string\n";
	
	foreach my $b ( sort{$a<=>$b} @{$demo{$a}{filtered}})
	{

		push(@ifname_string, $demo{$a}{interfacename}{$b});
	}
	
	my $name_string = join(':', @ifname_string);
  # print Dumper \%{$demo{$a}};
	#print"\n-----------$ifname_string\n";
	my $ip = $demo{$a}{'Ip'};
	my $port = $demo{$a}{'port'};
	my $community = $demo{$a}{'community'};



	my $sth=$dbh->do("update INTERFACES_SHIVI SET interfacename='$name_string',interfacelist='$iflist_string', lastupdate='" . localtime() . "' WHERE IP='$ip' AND PORT='$port' AND COMMUNITY='$community'");
}


# Start the event loop



sub callback1
{
	my ($session,$ip,$port,$community) = @_;


	if (!defined($session->var_bind_list()))
	{
		printf("ERROR: %s.\n", $session->error());
	} 

	else
	{
		my @all;
		my @indices;
		
		foreach (oid_lex_sort(keys(%{$session->var_bind_list()}))) 
		{

			$demo{"$ip:$port:$community"}{interfaces}{$_} = $session->var_bind_list()->{$_};   
		 } 

		foreach(values($demo{"$ip:$port:$community"}{interfaces}))
		{
			push @indices,$_;
		}


		foreach(@indices)
		{
			$if_oper='1.3.6.1.2.1.2.2.1.8.'.$_;
			$if_speed='1.3.6.1.2.1.2.2.1.5.'.$_;
			$if_type='1.3.6.1.2.1.2.2.1.3.'.$_;

			push @all,$if_oper,$if_speed,$if_type;
			#print Dumper @all;
		}
			#print "@all"."$ip\n";

		while(@all)
		{
			#print @all;
			my @spliced=splice(@all,0,40);
			#print Dumper @spliced;


			my $result = $session->get_request(
			  
				 -varbindlist => \@spliced ,
				 -callback    => [ \&callback2 ,$ip,$port,$community],
			       );

			if (!defined $result)
			{

			 printf "ERROR: Failed to queue get request for host '%s': %s.\n",
				$session->hostname(), $session->error();
			       
			}
		}

	}
}#end of callback1

sub callback2
{
	my ($session,$ip,$port,$community) = @_;
	
	if (!defined($session->var_bind_list())) 
	{
		printf("ERROR: %s.\n", $session->error());
	}
	else
	{
		foreach (keys (%{$session->var_bind_list()})) 
		{

			$demo{"$ip:$port:$community"}{details}{$_} = $session->var_bind_list()->{$_};   
		}
	}			 
}


sub callback3
{
	my($session,$ip,$port,$community)=@_;

	foreach (keys (%{$session->var_bind_list()})) 
	{
		$demo{"$ip:$port:$community"}{bitrate}{$_} = $session->var_bind_list()->{$_};   
	}
}		
			

sub ifname
{
	my ($session,$ip,$port,$community) = @_;


	 my $result = $session->var_bind_list();

	if (!defined $result) 
	{

		printf "!!!!!ERROR: Get request failed for host '%s': %s.\n",
		$session->hostname(), $session->error();
		return;
	 }		
 
	else
	{
		foreach(keys(%{$session->var_bind_list()}))
		{
			my @if=split('\.',$_);
                        my $prr=pop(@if);
			$demo{"$ip:$port:$community"}{interfacename}{$prr}=$result->{$_};
		}
	}
}


sub database
{
#print"hahahaahahh";
	my ($session,$ip,$port,$community) = @_;

	my $result = $session->var_bind_list();
	if (!defined $result)
	{
	 printf "ERROR: Get request failed for host '%s': %s.\n",
			$session->hostname(), $session->error();	 
	}
	
	else
	{
		my $sth=$dbh->do("update INTERFACES_SHIVI SET sysuptime='$result->{$OID_sysUpTime}',syscontact='$result->{$OID_sysContact}',syslocation='$result->{$OID_sysLocation}',sysname='$result->{$OID_sysname}' WHERE IP='$ip' AND PORT='$port' AND COMMUNITY='$community'");

	}
}





#print Dumper \%demo;
