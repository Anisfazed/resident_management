<?php
error_reporting(0);
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json");

include_once("dbconnect.php");

if ($_SERVER['REQUEST_METHOD'] === 'POST') {

    if (!isset($_POST['id']) || empty($_POST['id'])) {
        echo json_encode(array("status" => "failed", "message" => "Missing resident ID"));
        die;
    }

    $id = intval($_POST['id']);
    $name = $_POST['name'];
    $age = intval($_POST['age']);
    $phone = $_POST['phone'];
    $address = $_POST['address'];
    $incomeRange = $_POST['incomeRange'];
    $mukim = $_POST['mukim'];
    $kampung = $_POST['kampung'];
    $bantuan = $_POST['bantuan'];
    $lastUpdate = date("Y-m-d");

    $household_json = isset($_POST['household']) ? $_POST['household'] : '[]'; 
    $household_members = json_decode(stripslashes($household_json), true);

    $conn->begin_transaction();

    try {
        $sql = "UPDATE `residents` SET 
                `name` = ?, 
                `age` = ?, 
                `phone` = ?, 
                `address` = ?, 
                `incomeRange` = ?, 
                `mukim` = ?, 
                `kampung` = ?, 
                `bantuan` = ?, 
                `lastUpdate` = ? 
                WHERE `id` = ?";

        $stmt = $conn->prepare($sql);
        $stmt->bind_param("sisssssssi", 
            $name, 
            $age, 
            $phone, 
            $address, 
            $incomeRange, 
            $mukim, 
            $kampung, 
            $bantuan, 
            $lastUpdate, 
            $id
        );

        if (!$stmt->execute()) {
            throw new Exception("Update KIR failed: " . $conn->error);
        }

        $sql_delete = "DELETE FROM `household_members` WHERE `resident_id` = ?";
        $stmt_del = $conn->prepare($sql_delete);
        $stmt_del->bind_param("i", $id);
        $stmt_del->execute();

        if (!empty($household_members) && is_array($household_members)) {
            foreach ($household_members as $member) {
                $m_name = $conn->real_escape_string($member['name']);
                $m_relation = $conn->real_escape_string($member['relation']);
                $m_age = $conn->real_escape_string($member['age']);
                $m_status = $conn->real_escape_string($member['status']);

                $sql_member = "INSERT INTO `household_members`(`resident_id`, `name`, `relation`, `age`, `status`) 
                               VALUES ('$id', '$m_name', '$m_relation', '$m_age', '$m_status')";
                
                if (!$conn->query($sql_member)) {
                    throw new Exception("Failed to update household member: " . $conn->error);
                }
            }
        }

        $conn->commit();
        echo json_encode(array("status" => "success", "message" => "Update successful"));

    } catch (Exception $e) {
        $conn->rollback();
        echo json_encode(array("status" => "failed", "message" => $e->getMessage()));
    }

} else {
    echo json_encode(array("status" => "failed", "message" => "Invalid request method"));
}
?>