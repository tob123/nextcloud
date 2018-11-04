<?php
$servername = getenv('DB_HOST');
$username = getenv('DB_USER');
$password = getenv('DB_PASS');
$dbtype = getenv('DB_TYPE');

// Create connection
try {
    $conn = new PDO("$dbtype:host=$servername", $username, $password);
    $conn = null;
} catch (PDOException $e) {
    print "Error!: " . $e->getMessage() . "<br/>";
    die(1);
}
?>

