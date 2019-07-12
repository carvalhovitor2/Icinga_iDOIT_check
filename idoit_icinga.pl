#!/usr/bin/perl

use strict;
use warnings;
use LWP::UserAgent;
use JSON;
use HTTP::Headers;
use LWP::Simple qw(get);
use Data::Dumper;


my $url = 'https://idoit.svc.eurotux.pt/i-doit/src/jsonrpc.php';
my $header = [ 'Content-type' => 'application/json' ];
my @array = ();


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
sub IDOIT_cmbd_category_read_GENERATOR{
	my $id = $_[0];
	my $category = $_[1];
	my $apikey = $_[2];
	my $body = to_json({"version"=>"2.0","method"=>"cmdb.category.read","params"=>{"objID"=>$id,"category"=>$category,"apikey"=>$apikey,"language"=>"en"},"id"=>1});
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

sub ICINGA_queryHost_body_GENERATOR{
	my host
	my $user = $_[0]
}




my $responseJSON = IDOIT_listREQUEST(5, "lk3cuqphh", "https://idoit.svc.eurotux.pt/i-doit/src/jsonrpc.php");
my @list = ($responseJSON->{result});
#print Dumper $responseJSON->{result}->[0];
foreach my $titles (@list){
	foreach my $title (@$titles){
		my $ip_response = IDOIT_general_REQUEST($url, IDOIT_cmbd_category_read_GENERATOR($title->{id},"C__CATG__IP", "lk3cuqphh"), "lk3cuqphh");
		print "Title\t$title->{title}\n";
		print "Type\t$title->{type_title}\n";
		print "$ip_response->{result}->[0]->{primary_hostaddress}->{ref_title}\n";	
		print "---------------------------\n";
		print "---------------------------\n";
	}
}




