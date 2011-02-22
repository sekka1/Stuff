#!/usr/bin/perl
# vim: set expandtab tabstop=4 shiftwidth=4 softtabstop=4 foldmethod=marker: #

package IVMS;
use strict;
use WWW::Mechanize;
use HTTP::Cookies;
#use XML::Parser;
#use XML::SimpleObject;
use Switch;
use LWP 5.64;
use Digest::MD5;

# {{{ new
sub new {
        my $self  = {};

	$self->{PAGE_IP} = undef;
    $self->{SERVER_PORT} = undef;
    $self->{mech} = undef;

        bless($self);
        return $self;
}
# }}}
# {{{ start_mech
sub start_mech {

    my $self = shift;

    my $mech = WWW::Mechanize->new( autocheck => 1 );

    $mech->agent => "Mozilla/4.0 (compatible; MSIE 6.0; Windows NT 5.1)";

    $mech->cookie_jar( {} );    # an empty, memory-only HTTP::Cookies object

    $self->{mech} = $mech;
}
# }}}
# {{{ get_mech
sub get_mech {

    my $self = shift;

    return $self->{mech};

}
# }}}
# {{{ set_page_ip
sub set_page_ip {

	my $self = shift;

	$self->{PAGE_IP} = $_[0];	

    $self->{SERVER_PORT} = $_[1];
}
# }}}
# {{{ login
sub login {

	my $self = shift;

    my $username = $_[0];
    my $password = $_[1];

    $self->{mech}->get( "http://".$self->{PAGE_IP}.":".$self->{SERVER_PORT} );

    my $page_content = $self->{mech}->content;

    $self->{mech}->post( "http://".$self->{PAGE_IP}.":".$self->{SERVER_PORT}."/jsp/Login.do",
                            [
                                'userName' => $username,
                                'password' => $password,
                                'clienttype' => 'html',
                                'javaui' => 'javaui',
                                'login' => 'Login',
                                'screenHeight' => '750',
                                'screenWidth' => '1230',
                                'showapplet' => 'showapplet'
                            ],
                        );
}
# }}}
# {{{ get_url
sub get_url{
# Need to take in a whole url that starts with http://blah blah blah

# Will return the content of that page

    my $self = shift;

    my $url = $_[0];

    $self->{mech}->get( $url );

    return $self->{mech}->content;
}

#}}}
# {{{ get_configuration_clusterManagement
sub get_configuration_clusterManagement {

    my $self = shift;

    $self->{mech}->get( "http://".$self->{PAGE_IP}.":".$self->{SERVER_PORT}."/admin/clustermgmt.do?selectedTab=Configuration&viewId=iqClusters&displayName=Cluster+Management&firstChild=false&swipe=true&nodeClicked=iqClusters&selectedNode=iqClusters" );

    my $page_content = $self->{mech}->content;

    return $page_content;
}
# }}}
1;
