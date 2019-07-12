#!/usr/bin/perl

use strict;
use warnings;
use LWP::UserAgent;
use JSON;
use HTTP::Headers;
use LWP::Simple qw(get);
use Data::Dumper;


sub REQUEST{
	my $type = $_[0];
	my $apikey = $_[1];
	my $url = 'https://idoit.svc.eurotux.pt/i-doit/src/jsonrpc.php';
	my $body = {"version"=>"2.0","method"=>"cmdb.objects.read","params"=>{"filter"=>{"type"=> $type},"order_by"=>"title","apikey"=>$apikey,"language"=>"en"},"id"=>1};
	my $json_body = to_json ($body);
	my $req = HTTP::Request->new( 'POST', $url);
	$req->header( 'Content-Type' => 'application/json' );
	$req->content ( $json_body );
	my $lwp = LWP::UserAgent->new;
	$lwp->ssl_opts( verify_hostname => 0 ,SSL_verify_mode => 0x00);
	return $lwp->request($req);
}

my $responseJSON = REQUEST(5, "lk3cuqphh");
my $decoded = decode_json($responseJSON->content);
my @list = ($decoded->{result});
foreach my $titles (@list){
	foreach my $title (@$titles){
		print "Title\t$title->{title}\n";
		print "Type\t$title->{type_title}\n";
		print "sysID\t$title->{sysid}\n";
		print "---------------------------\n";
		print "---------------------------\n";
	}
}
a
