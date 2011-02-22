<?php
$mbox = imap_open ("{imap.gmail.com:993/imap/ssl/novalidate-cert/notls/debug}INBOX", "pro.care.ineoquest@gmail.com", "Passw0rd!")
      or die("can't connect: " . imap_last_error());

$MC = imap_check($mbox);

// Fetch an overview for all messages in INBOX
$result = imap_fetch_overview($mbox,"1:{$MC->Nmsgs}",0);
foreach ($result as $overview) {
    echo "#{$overview->msgno} ({$overview->date}) - From: {$overview->from}
    {$overview->subject}\n";
    echo imap_qprint(imap_body($mbox, $overview->msgno)); 

    echo "\n\n#######################################\n\n";
}

// Delete a message
imap_delete($mbox, 1);

imap_close($mbox);
?>

