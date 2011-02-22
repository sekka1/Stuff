<?php

// Email Settings
$email_host = "imap.gmail.com";
$email_port = "993";
$email_user = "pro.care.ineoquest@gmail.com";
$email_pass = "Passw0rd!";

// SPlunk Server
$server = '172.17.56.5';
$port = '9999';

// Connect to imap server
$mbox = imap_open ("{".$email_host.":".$email_port."/imap/ssl/novalidate-cert/notls/debug}INBOX", $email_user, $email_pass)
      or die("can't connect: " . imap_last_error());

$MC = imap_check($mbox);

// Fetch an overview for all messages in INBOX
$result = imap_fetch_overview($mbox,"1:{$MC->Nmsgs}",0);

if( imap_last_error() != 'Mailbox is empty' ){

    echo count( $result );

    // Loop through all the emails
    foreach ($result as $overview) {

        $msgno = $overview->msgno;
        $date = $overview->date;
        $from = $overview->from;
        $subject = $overview->subject;
        $body = imap_qprint(imap_body($mbox, $overview->msgno));

        $body_array = parse_body( $body );


        // Create the key=val,key=val format for splunk
        $output = "from=" . $from . ",host=" . $body_array['host'] . ",address=" . $body_array['address'] . ",create_datetime=" . $body_array['event_datetime'] . ",subject=" . $subject . ",service=" . $body_array['service'] . ",notification_type=" . $body_array['notification_type'] . ",state=" . $body_array['state'] . ",additional_info=" . $body_array['additional_info'];
    
        exec( '/bin/echo \'' . $output . '\' | /usr/bin/nc -w 1 -u ' . $server . ' ' .  $port );

        //print( $output ."\n" );

        sleep( 10 );

        // Insert event into DB
        //$query = "INSERT INTO events VALUES( '', '".$date."', '".$from."', '".mysql_real_escape_string( $subject )."', 'localhost', '".$body_array['notification_type']."', '".$body_array['service']."', '".$body_array['host']."', '".$body_array['address']."', '".$body_array['state']."', '".$body_array['event_datetime']."', '".mysql_real_escape_string( $body_array['additional_info'] )."', NOW(), NOW() )";

        // Delete a message
        imap_delete( $mbox, $msgno );
    }

    imap_close($mbox);

}

function parse_body( $body ){

    $body_lines = split( "\n", $body );

    $return_array = array();

    $return_array['notification_type'] = trim( preg_replace( '/Notification Type: /', '', $body_lines[2] ) );
    $return_array['service'] = trim( preg_replace( '/Service: /', '', $body_lines[4] ) );
    $return_array['host'] = trim( preg_replace( '/Host: /', '', $body_lines[5] ) );
    $return_array['address'] = trim( preg_replace( '/Address: /', '', $body_lines[6] ) );
    $return_array['state'] = trim( preg_replace( '/State: /', '', $body_lines[7] ) );
    $return_array['event_datetime'] = trim( preg_replace( '/Date\/Time: /', '', $body_lines[9] ) );
    $return_array['additional_info'] = trim( $body_lines[13] );

    return $return_array;
}

?>

