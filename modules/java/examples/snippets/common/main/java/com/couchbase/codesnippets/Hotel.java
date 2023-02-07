package com.couchbase.codesnippets;

import java.util.Objects;

import org.jetbrains.annotations.NotNull;
import org.jetbrains.annotations.Nullable;


public class Hotel {
    @Nullable
    private String description;
    @Nullable
    private String country;
    @Nullable
    private String city;
    @Nullable
    private String name;
    @Nullable
    private String type;
    @Nullable
    private String id;

    public Hotel() { }

    public Hotel(
        @Nullable String description,
        @Nullable String country,
        @Nullable String city,
        @Nullable String name,
        @Nullable String type,
        @Nullable String id) {
        this.description = description;
        this.country = country;
        this.city = city;
        this.name = name;
        this.type = type;
        this.id = id;
    }

    @Nullable
    public final String getDescription() { return this.description; }

    public final void setDescription(@Nullable String var1) { this.description = var1; }

    @Nullable
    public final String getCountry() { return this.country; }

    public final void setCountry(@Nullable String var1) { this.country = var1; }

    @Nullable
    public final String getCity() { return this.city; }

    public final void setCity(@Nullable String var1) { this.city = var1; }

    @Nullable
    public final String getName() { return this.name; }

    public final void setName(@Nullable String var1) { this.name = var1; }

    @Nullable
    public final String getType() { return this.type; }

    public final void setType(@Nullable String var1) { this.type = var1; }

    @Nullable
    public final String getId() { return this.id; }

    public final void setId(@Nullable String var1) { this.id = var1; }

    @NotNull
    @Override
    public String toString() {
        return "Hotel(description=" + this.description + ", country=" + this.country
            + ", city=" + this.city + ", " + "name=" + this.name + ", type=" + this.type + ", id=" + this.id + ")";
    }

    @Override
    public int hashCode() { return Objects.hash(description, country, city, name, type, id); }

    @Override
    public boolean equals(Object o) {
        if (this == o) { return true; }
        if (!(o instanceof Hotel)) { return false; }
        Hotel hotel = (Hotel) o;
        return Objects.equals(description, hotel.description)
            && Objects.equals(country, hotel.country)
            && Objects.equals(city, hotel.city)
            && Objects.equals(name, hotel.name)
            && Objects.equals(type, hotel.type)
            && Objects.equals(id, hotel.id);
    }
}