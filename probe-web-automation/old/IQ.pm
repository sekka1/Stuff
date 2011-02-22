#!/usr/bin/perl
# vim: set expandtab tabstop=4 shiftwidth=4 softtabstop=4 foldmethod=marker: #

package IQ;
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
    $self->{mech} = undef;

        bless($self);           # but see below
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
# {{{ set_nsp_ip
sub set_page_ip {

	my $self = shift;

	$self->{PAGE_IP} = $_[0];	
}
# }}}
# {{{ login
sub login {

	my $self = shift;

    my $username = $_[0];
    my $password = $_[1];

    $self->{mech}->get( "http://".$self->{PAGE_IP}."/" );

    my $page_content = $self->{mech}->content;

    # Login page hashes the password and combining it with a nounce before posting
    # it to the server in this format:  <User Name>:<Password>:<Nounce>
    $page_content =~ /name="nonce" value="(.*)">/g;

    my $nounce = $1;

    my $encoded_string = Digest::MD5::md5_hex( $username . ':' . $password . ':' . $nounce );

    $self->{mech}->post( "http://".$self->{PAGE_IP}."/",
                            [
                                'URL' => 'GET:/fs/index.htm',
                                'argList' => 'REMOTE_ADDR=192.168.1.28 SERVER_SOFTWARE=INEOQUEST/2.0 SERVER_NAME=IQ Cricket SERVER_PROTOCOL=HTTP/1.1 SERVER_PORT=80 REQUEST_METHOD=GET PATH_INFO=/ HOST= 192.168.1.106 ACCEPT_ENCODING=gzip,deflate END_OF_HEADERS=',
                                'encoded' => 'Admin:' . $encoded_string,
                                'mimeHeaderList' => 'Content-Encoding=gzip',
                                'nonce' => $nounce
                            ],
                        );
}
# }}}
sub add_user {
# Adds a user into a probe

        my $self = shift;

        my $add_users_name = $_[0];
        my $add_users_password = $_[1];
        my $add_users_access_level = $_[2];

        my $access_level_map_number = -1;

        if( $add_users_access_level =~ /public/ ){
            $access_level_map_number = 0;
        }
        if( $add_users_access_level =~ /private/ ){
            $access_level_map_number = 1;
        }
        if( $add_users_access_level =~ /admin/ ){
            $access_level_map_number = 2;
        }

        $self->{mech}->get("http://".$self->{PAGE_IP}."/security/userconfig.html");
        $self->{mech}->get("http://".$self->{PAGE_IP}."/security/userconfig.html?account_list=0&userName=".$add_users_name."&password=".$add_users_password."&access_level=$access_level_map_number&account_submit=Add+User");
}
sub delete_user {
# Delete a user on the probe

    my $self = shift;

    my $user_to_delete = $_[0];
    my $add_users_access_level = $_[1];

    # Look for the user mapping to the <account_list> var that will get passed into
    # the GET delete URL
    $self->{mech}->get( "http://".$self->{PAGE_IP}."/security/userconfig.html" );

    my $page_content = $self->{mech}->content;

    $page_content =~ /<option value="(.*)"  >$user_to_delete,/g;

    my $account_list_map = $1;

    # Get the access level mapping
    my $access_level_map_number = -1;

        if( $add_users_access_level =~ /public/ ){
            $access_level_map_number = 0;
        }
        if( $add_users_access_level =~ /private/ ){
            $access_level_map_number = 1;
        }
        if( $add_users_access_level =~ /admin/ ){
            $access_level_map_number = 2;
        }

    $self->{mech}->get("http://".$self->{PAGE_IP}."/security/userconfig.html?account_list=".$account_list_map."&account_submit=Delete+User&userName=&password=&access_level=".$access_level_map_number);

}
sub change_admins_password {
# Changes the admins password.  Since there is no password change utility in the web interface,
# this function is here to facilitate that piece.  It will first create a temp user with admin priv,
# then delete the "Admin" user, then create an Admin user with the new password, and then delte the
#temp admin user.

    my $self = shift;
    
    my $new_admins_password = $_[0];

    # Add temp user with admin priv
    $self->add_user( 'tempadmin', 'Sunsh1ne!90', 'admin' );

    # delete the "Admin" user
    $self->delete_user( 'Admin', 'admin' );

    # Add "Admin" user with the new password
    $self->add_user( 'Admin', $new_admins_password, 'admin' );

    # delete temp admin user
    $self->delete_user( 'tempadmin', 'admin' );
}


1;
