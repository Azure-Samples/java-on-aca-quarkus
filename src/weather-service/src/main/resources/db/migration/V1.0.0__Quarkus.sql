DROP TABLE IF EXISTS weather;

CREATE TABLE weather (
   id           int NOT NULL AUTO_INCREMENT PRIMARY KEY,
   city         VARCHAR(255) NOT NULL UNIQUE,
   description  VARCHAR(255) NOT NULL,
   icon         VARCHAR(255) NOT NULL
);

INSERT INTO weather (id, city, description, icon) VALUES (1, 'Paris, France', 'Very cloudy!', 'weather-fog');
INSERT INTO weather (id, city, description, icon) VALUES (2, 'London, UK', 'Quite cloudy', 'weather-pouring');
