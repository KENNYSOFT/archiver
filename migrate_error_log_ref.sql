UPDATE archiver.error_log e SET e.message_ref = 1, e.message = NULL WHERE e.message = (SELECT m.message FROM archiver.error_message m WHERE m.`no` = 1);
