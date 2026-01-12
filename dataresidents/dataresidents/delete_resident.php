<?php
// ... header and include_once("dbconnect.php") ...
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $id = intval($_POST['id']);
    $conn->begin_transaction(); // Start transaction
    try {
        // Delete child records (household_members) first
        $sql_members = "DELETE FROM `household_members` WHERE `resident_id` = ?";
        $stmt_members = $conn->prepare($sql_members);
        $stmt_members->bind_param("i", $id);
        $stmt_members->execute();

        // Delete parent record (residents)
        $sql_resident = "DELETE FROM `residents` WHERE `id` = ?";
        $stmt_resident = $conn->prepare($sql_resident);
        $stmt_resident->bind_param("i", $id);
        $stmt_resident->execute();

        $conn->commit(); // Success
        echo json_encode(array("status" => "success"));
    } catch (Exception $e) {
        $conn->rollback(); // Failure
        echo json_encode(array("status" => "failed", "message" => $e->getMessage()));
    }
}
?>