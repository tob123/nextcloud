<?php
include '/nextcloud/config/config.php';
//$servername = getenv('DB_HOST');
//$username = getenv('DB_USER');
//$password = getenv('DB_PASS');
//$dbtype = getenv('DB_TYPE');
$password = $CONFIG['dbpassword'];
$username = $CONFIG['dbuser'];
$dbtype = $CONFIG['dbtype'];
$servername = $CONFIG['dbhost'];
$db_name = $CONFIG['dbname'];
 //
// Create connection
try {
    $conn = new PDO("$dbtype:host=$servername;dbname=$db_name", $username, $password);
    $conn = null;
} catch (PDOException $e) {
    print "Error!: " . $e->getMessage() . "<br/>";
    die(1);
}
?>
