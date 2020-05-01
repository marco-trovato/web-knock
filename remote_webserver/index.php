<?php

$filename = "ip.txt";

// reading old ip saved
$file = fopen($filename, 'r');
$oldip = fgets($file);
fclose($fh);
echo "Old IP address: " . $oldip . "<br>";

$ip=$_SERVER['REMOTE_ADDR'];

//checking if the ip has changed
if ($ip==$oldip) {
    echo "IP not changed, doing nothing.";
    die();
}

//writing new ip
$file = fopen($filename,"w"); //w is write, a is append
fwrite($file,$ip);
fclose($file);
echo "IP updated successfully: " . $ip;

?> 

