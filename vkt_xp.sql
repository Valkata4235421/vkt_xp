CREATE TABLE IF NOT EXISTS vkt_xp (
    identifier VARCHAR(50) NOT NULL,
    category VARCHAR(50) NOT NULL,
    xp INT DEFAULT 0,
    level INT DEFAULT 1,
    PRIMARY KEY (identifier, category)
);