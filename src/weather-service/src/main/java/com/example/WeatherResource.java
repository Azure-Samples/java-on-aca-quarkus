package com.example;

import io.quarkus.logging.Log;
import io.smallrye.mutiny.Uni;
import jakarta.ws.rs.*;
import jakarta.ws.rs.core.MediaType;

@Path("/weather")
public class WeatherResource {

    @GET
    @Path("/city")
    @Produces(MediaType.APPLICATION_JSON)
    public Uni<Weather> getWeather(@QueryParam("name") String city) {
        Log.info("Getting weather information for city: " + city);
        return Weather.find("city", city).firstResult();
    }
}
