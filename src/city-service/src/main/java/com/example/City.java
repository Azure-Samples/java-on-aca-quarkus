package com.example;

import io.quarkus.hibernate.reactive.panache.PanacheEntity;

import jakarta.persistence.*;

@Entity
public class City extends PanacheEntity {

    @Column(unique = true)
    private String name;

    public String getName() {
        return name;
    }

    public void setName(String name) {
        this.name = name;
    }
}
