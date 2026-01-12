<?php
error_reporting(0);
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json");

// Check if POST data exists
if (!isset($_POST) || empty($_POST)) {
    $response = array('status' => 'failed', 'message' => 'No data provided');
    echo json_encode($response);
    die;
}

include_once("dbconnect.php");

// 1. Extract Resident (KIR) Data
$name = $_POST['name'];
$age = $_POST['age'];
$phone = $_POST['phone'];
$address = $_POST['address'];
$incomeRange = $_POST['incomeRange'];
$mukim = $_POST['mukim'];
$kampung = $_POST['kampung'];
$bantuan = $_POST['bantuan']; 
$lastUpdate = date("Y-m-d");

// 2. Extract Household Members Data
// The Flutter app sends this as a JSON string under the key 'household'
$household_json = isset($_POST['household']) ? $_POST['household'] : '[]'; 
// Use stripslashes if your server adds magic quotes to the POST data
$household_members = json_decode(stripslashes($household_json), true);

// Start Transaction
$conn->begin_transaction();

try {
    // Insert into residents table
    $sql_resident = "INSERT INTO `residents`(`name`, `age`, `phone`, `address`, `incomeRange`, `mukim`, `kampung`, `bantuan`, `lastUpdate`) 
                     VALUES ('$name', '$age', '$phone', '$address', '$incomeRange', '$mukim', '$kampung', '$bantuan', '$lastUpdate')";

    if ($conn->query($sql_resident) === TRUE) {
        $resident_id = $conn->insert_id; // Get the ID of the KIR

        // Insert household members if any exist
        if (!empty($household_members) && is_array($household_members)) {
            foreach ($household_members as $member) {
                // Mapping from Flutter JSON keys
                $m_name = $conn->real_escape_string($member['name']);
                $m_relation = $conn->real_escape_string($member['relation']);
                $m_age = $conn->real_escape_string($member['age']);
                $m_status = $conn->real_escape_string($member['status']);

                // Verify your table name is 'household_members'
                $sql_member = "INSERT INTO `household_members`(`resident_id`, `name`, `relation`, `age`, `status`) 
                               VALUES ('$resident_id', '$m_name', '$m_relation', '$m_age', '$m_status')";
                
                if (!$conn->query($sql_member)) {
                    throw new Exception("Failed to insert household member: " . $conn->error);
                }
            }
        }

        // Commit transaction
        $conn->commit();
        echo json_encode(array('status' => 'success', 'message' => 'Data saved successfully'));
    } else {
        throw new Exception("Failed to insert resident: " . $conn->error);
    }
} catch (Exception $e) {
    // If anything fails, rollback the entire transaction so we don't have partial data
    $conn->rollback();
    echo json_encode(array('status' => 'failed', 'message' => $e->getMessage()));
}
?>