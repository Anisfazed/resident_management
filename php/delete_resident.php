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
    $conn->begin_transaction(); // Start atomic operation

    try {
        // Delete child records first
        $sql_members = "DELETE FROM `household_members` WHERE `resident_id` = ?";
        $stmt_members = $conn->prepare($sql_members);
        $stmt_members->bind_param("i", $id);
        $stmt_members->execute();

        // Delete parent record
        $sql_resident = "DELETE FROM `residents` WHERE `id` = ?";
        $stmt_resident = $conn->prepare($sql_resident);
        $stmt_resident->bind_param("i", $id);

        if ($stmt_resident->execute() && $stmt_resident->affected_rows > 0) {
            $conn->commit(); // Save changes
            $response = array("status" => "success", "message" => "Deleted successfully");
        } else {
            $conn->rollback();
            $response = array("status" => "failed", "message" => "No record found");
        }
    } catch (Exception $e) {
        $conn->rollback(); // Cancel all changes on error
        $response = array("status" => "failed", "message" => $e->getMessage());
    }
    echo json_encode($response);
}
?>