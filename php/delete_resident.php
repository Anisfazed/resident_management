<?php
include_once("dbconnect.php");
if (isset($_POST['resident_id'])) {
    $id = $_POST['resident_id'];

    // 1. Padam data penduduk
    $sqldelete = "DELETE FROM `residents` WHERE `id` = '$id'";
    
    if ($conn->query($sqldelete) === TRUE) {
        
        // 2. Semak jika jadual sudah kosong
        $sqlcheck = "SELECT COUNT(*) as total FROM `residents`";
        $result = $conn->query($sqlcheck);
        $row = $result->fetch_assoc();
        
        if ($row['total'] == 0) {
            // 3. Jika kosong, reset ID auto-increment kepada 1
            $sqlreset = "ALTER TABLE `residents` AUTO_INCREMENT = 1";
            $conn->query($sqlreset);
        }
        
        echo "success";
    } else {
        echo "failed";
    }
?>