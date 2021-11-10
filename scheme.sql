CREATE DATABASE archiver;

CREATE USER archiver@localhost IDENTIFIED BY 'archiver';
GRANT ALL PRIVILEGES ON archiver.* TO archiver@localhost;
FLUSH PRIVILEGES;

CREATE TABLE `source` (
	`no` BIGINT(20) NOT NULL AUTO_INCREMENT,
	`description` VARCHAR(256) NULL DEFAULT NULL COLLATE 'utf8mb4_unicode_ci',
	`type` VARCHAR(32) NOT NULL COMMENT 'json, m3u8 등' COLLATE 'utf8mb4_unicode_ci',
	`active` TINYINT(4) NOT NULL DEFAULT '1',
	`url` VARCHAR(1024) NULL DEFAULT NULL COMMENT '값이 있다면 그 url을 바로 curl로 긁으면 됨' COLLATE 'utf8mb4_unicode_ci',
	`command` VARCHAR(2048) NULL DEFAULT NULL COMMENT 'url이 없고 이 값이 있다면 이 명령 실행 (ubuntu 기준)' COLLATE 'utf8mb4_unicode_ci',
	`created_at` DATETIME NOT NULL DEFAULT current_timestamp(),
	`updated_at` DATETIME NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
	`interval` TIME NOT NULL DEFAULT '00:10:00',
	`last_checked_at` DATETIME NULL DEFAULT NULL,
	PRIMARY KEY (`no`) USING BTREE
)
COLLATE='utf8mb4_unicode_ci'
ENGINE=InnoDB
;

CREATE TABLE `archive` (
	`no` BIGINT(20) NOT NULL AUTO_INCREMENT,
	`source_no` BIGINT(20) NOT NULL,
	`revision` INT(11) NOT NULL,
	`content` MEDIUMTEXT NULL DEFAULT NULL COMMENT 'revision이 같은 row들 중 첫 번째에만 이 값이 있으면 됨' COLLATE 'utf8mb4_unicode_ci',
	`archived_at` DATETIME NOT NULL DEFAULT current_timestamp(),
	PRIMARY KEY (`no`) USING BTREE,
	INDEX `FK_archive_source` (`source_no`) USING BTREE,
	CONSTRAINT `FK_archive_source` FOREIGN KEY (`source_no`) REFERENCES `archiver`.`source` (`no`) ON UPDATE RESTRICT ON DELETE RESTRICT
)
COLLATE='utf8mb4_unicode_ci'
ENGINE=InnoDB
;

CREATE TABLE `error_log` (
	`no` BIGINT(20) NOT NULL AUTO_INCREMENT,
	`source_no` BIGINT(20) NOT NULL,
	`http_status_code` INT(11) NULL DEFAULT NULL,
	`message` MEDIUMTEXT NULL DEFAULT NULL COLLATE 'utf8mb4_unicode_ci',
	`logged_at` DATETIME NOT NULL DEFAULT current_timestamp(),
	PRIMARY KEY (`no`) USING BTREE,
	INDEX `FK_error_log_source` (`source_no`) USING BTREE,
	CONSTRAINT `FK_error_log_source` FOREIGN KEY (`source_no`) REFERENCES `archiver`.`source` (`no`) ON UPDATE RESTRICT ON DELETE RESTRICT
)
COLLATE='utf8mb4_unicode_ci'
ENGINE=InnoDB
;

ALTER TABLE `source`
	ADD COLUMN `update_hook` VARCHAR(2048) NULL DEFAULT NULL COMMENT 'revision이 올라갈 때 이 명령 실행 (ubuntu 기준)' COLLATE 'utf8mb4_unicode_ci' AFTER `command`;

ALTER TABLE `archive`
	ADD INDEX `IX_source_no_revision` (`source_no`, `revision`);
