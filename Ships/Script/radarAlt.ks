function get_altitude_above_terrain {
    // Obtener la altitud del radar, que es la altitud sobre el terreno
    local radar_altitude is ship:altitude - ship:geoposition:terrainheight.

    // Si la altitud del radar es negativa (debajo del terreno), ajustarla a cero
    if radar_altitude < 0 {
        set radar_altitude to 0.
    }

    return radar_altitude.
}
print get_altitude_above_terrain().