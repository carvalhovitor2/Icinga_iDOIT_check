#!/usr/bin/perl

use strict;
use warnings;
use LWP::UserAgent;
use JSON;
use HTTP::Headers;
use LWP::Simple qw(get);
use Data::Dumper;
use Getopt::Long qw(GetOptions);
use HTTP::Request::Common;

my $url = 'https://idoit.svc.eurotux.pt/i-doit/src/jsonrpc.php';
my $header = [ 'Content-type' => 'application/json' ];
my @array = ();
my %group_type_hash = ('building' => 3,
			'server' => 5,
			'switch' => 8,
			'client' => 10,
			'printer' => 11,
			'storage' => 12,
			'appliance' => 23,
			'accesspoint' => 27,
			'virtual' => 59);

sub IDOIT_listREQUEST{
	my $group_type = $_[0];
	my $apikey = $_[1];
	my $url = $_[2];
	###Creating a batch request
	my $body = to_json({"version"=>"2.0","method"=>"cmdb.objects.read","params"=>{"filter"=>{"type"=> $group_type},"order_by"=>"title","apikey"=>$apikey,"language"=>"en"},"id"=>1});	
	my $req = HTTP::Request->new( 'POST', $url);
	$req->header( 'Content-Type' => 'application/json' );
	$req->content ( $body );
	my $lwp = LWP::UserAgent->new;
	$lwp->ssl_opts( verify_hostname => 0 ,SSL_verify_mode => 0x00);
	my $responseJSON =  $lwp->request($req);
	return decode_json($responseJSON->content);
}


#In case you need to generate a batch of similar JSON requests changing just the ID and the category
sub IDOIT_cat_read_GENERATOR{
	my $id = $_[0];
	my $category = $_[1];
	my $apikey = $_[2];
	my $body = to_json({"version"=>"2.0","method"=>"cmdb.category.read","params"=>{"objID"=>$id,"category"=>$category,"apikey"=>$apikey,"language"=>"en"},"id"=>1});
	return $body;
}

#Object read generator
sub IDOIT_obj_read_GENERATOR{
	my $id = $_[0];
        my $apikey = $_[1];
        my $body = to_json({"version"=>"2.0","method"=>"cmdb.object.read","params"=>{"id"=>$id,"apikey"=>$apikey,"language"=>"en"},"id"=>1});
        return $body;
}

#Just pass the JSON body as an argument
sub IDOIT_general_REQUEST{
	my $url = $_[0];
        my $body = $_[1];
	my $apikey = $_[2];
	my $req = HTTP::Request->new( 'POST', $url);
        $req->header( 'Content-Type' => 'application/json' );
        $req->content ( $body );
        my $lwp = LWP::UserAgent->new;
        $lwp->ssl_opts( verify_hostname => 0 ,SSL_verify_mode => 0x00);
        my $responseJSON =  $lwp->request($req);
        return decode_json($responseJSON->content);
}



##############################################################
##############################################################
##############################################################
#		Functions related to icinga		     #
#							     #		


sub ICINGA_query_hosts{
	#my $type = $_[0];
	my $user = $_[0];
	my $pass = $_[1];
	#	my $uri = "https://10.10.10.239:5665/v1/objects/$type";
	my $ua = LWP::UserAgent->new();
        $ua->ssl_opts( verify_hostname => 0 ,SSL_verify_mode => 0x00);
	my $req = GET 'https://localhost:5665/v1/objects/hosts';
	$req->authorization_basic("$user", "$pass");
	my $response = $ua->request($req);
	return decode_json($response->content);
}

sub ICINGA_hostname_search{
	my @list1 = $_[0];
	my $hostname = $_[1];
	my $host_ip = $_[2];
	my $flag = 0;
	foreach my $names (@list1){
        	foreach my $name (@$names){
			#	print "$hostname\n";
			#	print "print "$name->{name}\n";
                	if ($host_ip eq $name->{attrs}->{address}){
				if ( $hostname eq $name->{name} ){
					$flag = 1;
					return $flag;
				}
				else {
					$flag = 2;
					return $flag;
				}
			}
        	        
        	
		}

	}	
	return $flag;
}

##############################################################
##############################################################
##############################################################
#			Actual Script			     #
#							     #



my $obj_type = "server";
GetOptions('type=s' => \$obj_type,) or die "Usage: $0 --type {server, client, switch, printer, storage, virtual, building, accesspoint, appliance}\n ";

#print $group_type_hash{$obj_type};

my $responseJSON = IDOIT_listREQUEST($group_type_hash{$obj_type}, "lk3cuqphh", "https://idoit.svc.eurotux.pt/i-doit/src/jsonrpc.php");
my @list = ($responseJSON->{result});
my $icinga_response = ICINGA_query_hosts("root", "c1552fd540393237");
my @lista = ($icinga_response->{results});
#print Dumper $responseJSON->{result}->[0];
foreach my $titles (@list){
	foreach my $title (@$titles){
		my $ip_response = IDOIT_general_REQUEST($url, IDOIT_cat_read_GENERATOR($title->{id},"C__CATG__IP", "lk3cuqphh"), "lk3cuqphh");
		#	print "Title\t$title->{title}\n";
		#	print "print "Type\t$title->{type_title}\n";
		#	print "print "$ip_response->{result}->[0]->{primary_hostaddress}->{ref_title}\n";	
		#	print "print "---------------------:------\n";
		#	print "print "---------------------------\n";
		if(ICINGA_hostname_search(@lista, $title->{title}, $ip_response->{result}->[0]->{primary_hostaddress}->{ref_title}) == 0){
			print "Host: $title->{title} - NOT BEING MONITORED\n";
			print "---------------------------------------------\n";
			next;
		}
		elsif(ICINGA_hostname_search(@lista, $title->{title}, $ip_response->{result}->[0]->{primary_hostaddress}->{ref_title}) == 2){
			print "Host: $title->{title} - OUTDATED\n";
			print "---------------------------------------------\n";
			next;
		}
		 elsif(ICINGA_hostname_search(@lista, $title->{title}, $ip_response->{result}->[0]->{primary_hostaddress}->{ref_title}) == 1){
			print "Host: $title->{title} - OK";
			next;
		}
	}	
}


#my $icinga_response = ICINGA_query_hosts("root", "c1552fd540393237");
#my @list1 = ($icinga_response->{results});
#foreach my $names (@list1){
#	foreach my $name (@$names){
#		print "$name->{name}\n";
#		print "$name->{attrs}->{address}\n";
#	}
#}


