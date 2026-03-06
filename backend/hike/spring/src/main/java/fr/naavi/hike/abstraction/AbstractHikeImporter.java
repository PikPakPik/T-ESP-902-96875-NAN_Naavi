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

    /**
     * Constructor for AbstractHikeImporter.
     *
     * @param hikeRepository the repository to manage hike data
     */
    protected AbstractHikeImporter(HikeRepository hikeRepository) {
        this.hikeRepository = hikeRepository;
    }

    // ============================================================
    // ===================== TEMPLATE METHOD ======================
    // ============================================================

    /**
     * Importe des randonnées à partir d'une source de données structurée (ex: JSON, CSV, etc.)
     *
     * @param records Les données à importer, sous forme de JsonNodes (une ligne de CSV peut être convertie en JsonNode par exemple)
     * @param mapping La configuration de mapping entre les champs du fichier et les champs de Hike
     */
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

    /**
     * Valide que le mapping est cohérent avec les données d'exemple (ex: les champs source existent dans le JsonNode, les unités sont supportées, etc.)
     *
     * @param mapping La configuration de mapping à valider
     * @param sample Un JsonNode d'exemple (ex: la première ligne du fichier) pour vérifier que les champs source existent
     */
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

    /**
     * Applique le mapping d'un champ du fichier à un champ de Hike, en gérant les différentes transformations possibles (unités, enums, géométrie, etc.)
     *
     * @param hike L'entité Hike en cours de construction
     * @param hikeField Le champ de Hike à remplir (ex: "distance", "difficulty", "wkbGeometry", etc.)
     * @param def La définition du mapping pour ce champ, qui contient la source dans le fichier, les éventuelles valeurs d'enum, l'unité, etc.
     * @param rawValue La valeur brute extraite du JsonNode, avant toute transformation
     */
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

    /**
     * Remplit un champ de Hike à partir d'une valeur string, en gérant les conversions nécessaires (ex: string → double pour distance, string → enum pour difficulty, etc.)
     *
     * @param hike L'entité Hike en cours de construction
     * @param field Le champ de Hike à remplir (ex: "distance", "difficulty", "wkbGeometry", etc.)
     * @param value La valeur à appliquer, déjà convertie en string (ex: "5.2" pour distance, "EASY" pour difficulty, etc.)
     */
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

    /**
     * Convertit une valeur d'une unité donnée vers l'unité standard utilisée dans Hike (ex: mètres → kilomètres pour distance, secondes → minutes pour duration, etc.)
     *
     * @param field Le champ de Hike concerné (ex: "distance", "duration", etc.)
     * @param value La valeur à convertir, dans l'unité spécifiée
     * @param unit L'unité d'origine de la valeur (ex: METERS, SECONDS, etc.)
     * @return La valeur convertie dans l'unité standard de Hike (ex: kilomètres pour distance, minutes pour duration, etc.)
     */
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

    /**
     * Parse une valeur d'enum à partir d'une string, en gérant les erreurs de format et en fournissant un message d'erreur clair
     *
     * @param enumType Le type d'enum à parser (ex: DifficultyEnum.class)
     * @param value La valeur à appliquer, déjà convertie en string (ex: "5.2" pour distance, "EASY" pour difficulty, etc.)
     * @return L'instance de l'enum correspondante, ou null si la valeur n'est pas valide
     * @param <E> Le type d'enum
     */
    protected <E extends Enum<E>> E parseEnum(Class<E> enumType, String value) {
        try {
            return Enum.valueOf(enumType, value.toUpperCase());
        } catch (Exception e) {
            throw new FileImportException(
                    "Valeur enum invalide '" + value + "' pour " + enumType.getSimpleName()
            );
        }
    }

    /**
     * Convertit une géométrie au format GeoJSON en WKB hexadécimal, en utilisant la bibliothèque JTS pour la conversion
     *
     * @param geoJson La géométrie au format GeoJSON, sous forme de string
     * @return La géométrie convertie au format WKB, sous forme de string hexadécimal
     */
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

    /**
     * Convertit un tableau de bytes en une string hexadécimale, en utilisant un StringBuilder pour construire la string finale
     *
     * @param bytes Le tableau de bytes à convertir
     * @return La string hexadécimale résultante, où chaque byte est représenté par deux caractères hexadécimaux
     */
    protected String bytesToHex(byte[] bytes) {
        StringBuilder sb = new StringBuilder(bytes.length * 2);
        for (byte b : bytes) {
            sb.append(String.format("%02x", b));
        }
        return sb.toString();
    }

    /**
     * Récupère une valeur imbriquée dans un JsonNode à partir d'un chemin de type "field1.field2.field3", en naviguant dans la hiérarchie du JsonNode
     *
     * @param node Le JsonNode de départ, à partir duquel le chemin doit être évalué
     * @param path Le chemin de la valeur à récupérer, sous forme de string avec des points pour séparer les niveaux d'imbrication (ex: "field1.field2.field3")
     * @return Le JsonNode correspondant à la valeur trouvée à ce chemin, ou null si le chemin n'existe pas dans le JsonNode
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
