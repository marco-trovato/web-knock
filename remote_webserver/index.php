<?php

// quick password protection
if (!isset($_POST['pass']))
    {?>
            <form method="POST">
            <center><br><br><br>You are supposed to visit this page from a foreign or mobile network<br>
            <input type="password" placeholder="Password" name="pass"></input>
            <input type="submit" name="submit" value="Enter"></input>
            </center>
            </form>
    <?
    die();
    } else { // it means it is set

      //sanitize text input before any usage
      $sanitized_pass = htmlspecialchars($_POST['pass'], ENT_QUOTES, 'UTF-8');
      // REPLACE THE NEXT LINE WITH YOUR PASSWORD ***********
      if($sanitized_pass != "YOUR_SECRET_PASSWORD_HERE")
      {
          die();
      }
}

//----------------------------------

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

