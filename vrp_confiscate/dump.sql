ALTER TABLE vrp_user_vehicles ADD veh_confiscate TINYINT NOT NULL DEFAULT 0;
CREATE TABLE `vrp_confiscate`(
    `id` INT AUTO_INCREMENT,
    `user_id` INT(30) NOT NULL,
    `vehicle` VARCHAR(255) NOT NULL,
    `cop` VARCHAR(255) DEFAULT 'Unknown',
    PRIMARY KEY (id)
);
