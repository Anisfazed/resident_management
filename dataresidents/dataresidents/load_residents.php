<?php
error_reporting(0);
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json");

include_once("dbconnect.php");

$sqlload = "SELECT * FROM `residents` ORDER BY `lastUpdate` DESC";
$result = $conn->query($sqlload);

if ($result->num_rows > 0) {
    $residents = array();
    while ($row = $result->fetch_assoc()) {
        $reslist = array(
            'id' => $row['id'],
            'name' => $row['name'],
            'age' => $row['age'],
            'phone' => $row['phone'],
            'address' => $row['address'],
            'incomeRange' => $row['incomeRange'],
            'mukim' => $row['mukim'],
            'kampung' => $row['kampung'],
            'bantuan' => $row['bantuan'],
            'lastUpdate' => $row['lastUpdate']
        );
        
        $resident_id = $row['id'];
        $sql_members = "SELECT * FROM `household_members` WHERE `resident_id` = '$resident_id'";
        $result_members = $conn->query($sql_members);
        
        $members = array();
        while ($m_row = $result_members->fetch_assoc()) {
            $members[] = $m_row;
        }
        $reslist['household_members'] = $members;
        array_push($residents, $reslist);
    }
    echo json_encode(array('status' => 'success', 'data' => $residents));
} else {
    echo json_encode(array('status' => 'failed', 'message' => 'No residents found'));
}
?>