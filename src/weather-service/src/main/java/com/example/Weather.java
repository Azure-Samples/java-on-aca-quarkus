package com.example;

import io.quarkus.hibernate.reactive.panache.PanacheEntity;

import jakarta.persistence.*;

@Entity
public class Weather extends PanacheEntity {

    @Column(unique = true)
    private String city;

    @Column
    private String description;

    @Column
    private String icon;

    // Getters and setters
    public String getCity() {
        return city;
    }

    public void setCity(String city) {
        this.city = city;
    }

    public String getDescription() {
        return description;
    }

    public void setDescription(String description) {
        this.description = description;
    }

    public String getIcon() {
        return icon;
    }

    public void setIcon(String icon) {
        this.icon = icon;
    }
}
