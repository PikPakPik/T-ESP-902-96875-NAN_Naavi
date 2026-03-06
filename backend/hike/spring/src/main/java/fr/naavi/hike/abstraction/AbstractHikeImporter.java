package fr.naavi.hike.abstraction;

import tools.jackson.databind.JsonNode;
import fr.naavi.hike.dto.input.FieldMappingDTO;
import fr.naavi.hike.dto.input.FileMappingDTO;
import fr.naavi.hike.entity.Hike;
import fr.naavi.hike.enums.DifficultyEnum;
import fr.naavi.hike.enums.SourceEnum;
import fr.naavi.hike.enums.UnitEnum;
import fr.naavi.hike.exception.FileImportException;
import fr.naavi.hike.repository.HikeRepository;
import org.locationtech.jts.geom.Geometry;
import org.locationtech.jts.io.WKBWriter;
import org.locationtech.jts.io.geojson.GeoJsonReader;

import java.util.Map;

public abstract class AbstractHikeImporter {
    protected final HikeRepository hikeRepository;

    protected AbstractHikeImporter(HikeRepository hikeRepository) {
        this.hikeRepository = hikeRepository;
    }

    // ============================================================
    // ===================== TEMPLATE METHOD ======================
    // ============================================================

    protected void importRecords(Iterable<JsonNode> records, FileMappingDTO mapping) {
        if (!records.iterator().hasNext()) {
            throw new FileImportException("Le fichier ne contient aucune donnée");
        }

        validateMapping(mapping, records.iterator().next());

        int index = 0;

        for (JsonNode record : records) {
            index++;

            Hike hike = new Hike();

            for (Map.Entry<String, FieldMappingDTO> entry : mapping.getMappings().entrySet()) {

                String hikeField = entry.getKey();
                FieldMappingDTO def = entry.getValue();

                if (def.getSource() == null || def.getSource().isBlank()) {
                    continue;
                }

                JsonNode rawValue = getNestedValue(record, def.getSource());
                if (rawValue == null || rawValue.isNull()) continue;

                try {
                    applyMapping(hike, hikeField, def, rawValue);
                } catch (Exception e) {
                    throw new FileImportException(
                            "Erreur à la ligne " + index
                                    + " (champ '" + hikeField + "') : "
                                    + e.getMessage()
                    );
                }
            }

            hike.setSource(SourceEnum.OFFICIAL);
            hikeRepository.save(hike);
        }
    }

    // ============================================================
    // ===================== VALIDATION ===========================
    // ============================================================

    protected void validateMapping(FileMappingDTO mapping, JsonNode sample) {
        for (Map.Entry<String, FieldMappingDTO> entry : mapping.getMappings().entrySet()) {

            String hikeField = entry.getKey();
            FieldMappingDTO def = entry.getValue();

            if (def.getSource() == null || def.getSource().isBlank()) {
                continue;
            }

            JsonNode test = getNestedValue(sample, def.getSource());
            if (test == null || test.isNull()) {
                throw new FileImportException(
                        "Champ introuvable dans le fichier : '"
                                + def.getSource()
                                + "' (champ Hike : '" + hikeField + "')"
                );
            }

            if (def.getUnit() != null && !supportsUnit(hikeField)) {
                throw new FileImportException(
                        "Le champ '" + hikeField + "' ne supporte pas les unités"
                );
            }
        }
    }

    protected boolean supportsUnit(String field) {
        return "distance".equals(field) || "duration".equals(field);
    }

    // ============================================================
    // ===================== MAPPING ==============================
    // ============================================================

    protected void applyMapping(Hike hike, String hikeField, FieldMappingDTO def, JsonNode rawValue) {
        // ================= GEOMETRY → WKB =================
        if ("wkbGeometry".equals(hikeField)) {

            if (!rawValue.isObject() && !rawValue.isTextual()) {
                throw new FileImportException(
                        "Géométrie invalide pour le champ 'wkbGeometry'"
                );
            }

            String geoJson = rawValue.isTextual() ? rawValue.asText() : rawValue.toString();
            hike.setWkbGeometry(geoJsonToWkb(geoJson));
            return;
        }

        // ================= ENUM =================
        if (def.getValues() != null) {

            String mapped = def.getValues().get(rawValue.asText());
            if (mapped == null) {
                throw new FileImportException(
                        "Valeur inconnue '" + rawValue.asText()
                                + "' pour le champ '" + hikeField + "'"
                );
            }

            setField(hike, hikeField, mapped);
            return;
        }

        // ================= UNIT =================
        if (def.getUnit() != null) {

            double numericValue;

            try {
                numericValue = rawValue.isNumber()
                        ? rawValue.asDouble()
                        : Double.parseDouble(rawValue.asText().replace(",", "."));
            } catch (Exception e) {
                return;
            }

            double converted = convertUnit(hikeField, numericValue, def.getUnit());
            setField(hike, hikeField, String.valueOf(converted));
            return;
        }

        // ================= SIMPLE =================
        setField(hike, hikeField, rawValue.asText());
    }

    // ============================================================
    // ===================== SETTERS ==============================
    // ============================================================

    protected void setField(Hike hike, String field, String value) {
        try {
            switch (field) {
                case "name" -> hike.setName(value);
                case "distance" -> hike.setDistance(Double.valueOf(value));
                case "duration" -> hike.setDuration(Double.valueOf(value));
                case "location" -> hike.setLocation(value);
                case "difficulty" -> hike.setDifficulty(parseEnum(DifficultyEnum.class, value));
                case "startingPointLatitude" -> hike.setStartingPointLatitude(Double.valueOf(value));
                case "startingPointLongitude" -> hike.setStartingPointLongitude(Double.valueOf(value));
                case "startingElevation" -> hike.setStartingElevation(Integer.valueOf(value));
                case "arrivalPointLatitude" -> hike.setArrivalPointLatitude(Double.valueOf(value));
                case "arrivalPointLongitude" -> hike.setArrivalPointLongitude(Double.valueOf(value));
                case "arrivalElevation" -> hike.setArrivalElevation(Integer.valueOf(value));
                case "wkbGeometry" -> hike.setWkbGeometry(value);
                case "wkbWaypoints" -> hike.setWkbWaypoints(value);
                default -> throw new FileImportException(
                        "Champ Hike non supporté : '" + field + "'"
                );
            }
        } catch (NumberFormatException e) {
            throw new FileImportException(
                    "Type invalide pour le champ '" + field + "' : '" + value + "'"
            );
        }
    }

    // ============================================================
    // ===================== UNITÉS ===============================
    // ============================================================

    protected double convertUnit(String field, double value, UnitEnum unit) {
        return switch (field) {
            case "distance" -> switch (unit) {
                case METERS -> value / 1000d;
                case MILES -> value * 1.60934;
                case KILOMETERS -> value;
                default -> throw new FileImportException("Unité invalide pour distance : " + unit);
            };

            case "duration" -> switch (unit) {
                case SECONDS -> value / 60d;
                case HOURS -> value * 60d;
                case MINUTES -> value;
                default -> throw new FileImportException("Unité invalide pour duration : " + unit);
            };

            default -> throw new FileImportException("Le champ '" + field + "' ne supporte pas les unités");
        };
    }

    // ============================================================
    // ===================== UTILS ================================
    // ============================================================

    protected <E extends Enum<E>> E parseEnum(Class<E> enumType, String value) {
        try {
            return Enum.valueOf(enumType, value.toUpperCase());
        } catch (Exception e) {
            throw new FileImportException(
                    "Valeur enum invalide '" + value + "' pour " + enumType.getSimpleName()
            );
        }
    }

    protected String geoJsonToWkb(String geoJson) {
        try {
            GeoJsonReader reader = new GeoJsonReader();
            Geometry geometry = reader.read(geoJson);

            WKBWriter writer = new WKBWriter();
            return bytesToHex(writer.write(geometry));

        } catch (Exception e) {
            throw new FileImportException(
                    "Erreur lors de la conversion GeoJSON → WKB : " + e.getMessage()
            );
        }
    }

    protected String bytesToHex(byte[] bytes) {
        StringBuilder sb = new StringBuilder(bytes.length * 2);
        for (byte b : bytes) {
            sb.append(String.format("%02x", b));
        }
        return sb.toString();
    }

    /**
     * Récupère une valeur imbriquée dans un JsonNode en suivant un chemin 'a.b.c'
     */
    protected JsonNode getNestedValue(JsonNode node, String path) {
        String[] parts = path.split("\\.");
        JsonNode current = node;
        for (String part : parts) {
            if (current == null) return null;
            current = current.get(part);
        }
        return current;
    }
}
