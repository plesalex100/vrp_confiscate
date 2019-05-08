CREATE TABLE `vrp_confiscate`(
    `id` INT AUTO_INCREMENT,
    `user_id` INT(30) NOT NULL,
    `vehicle` VARCHAR(255) NOT NULL,
    `cop` VARCHAR(255) DEFAULT 'Unknown',
    PRIMARY KEY (id)
);