package fr.naavi.hike.service.importer;

import fr.naavi.hike.abstraction.AbstractHikeImporter;
import fr.naavi.hike.dto.input.FileMappingDTO;
import fr.naavi.hike.exception.FileImportException;
import fr.naavi.hike.repository.HikeRepository;
import fr.naavi.hike.repository.interfaces.FileImporter;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;
import tools.jackson.databind.JsonNode;
import tools.jackson.databind.ObjectMapper;
import tools.jackson.databind.node.ObjectNode;

import java.io.IOException;
import java.util.ArrayList;
import java.util.List;

@Service
public class GeoJsonImporter extends AbstractHikeImporter implements FileImporter {

    private final ObjectMapper objectMapper;

    /**
     * Constructor for GeoJsonImporter.
     *
     * @param objectMapper ObjectMapper for parsing GeoJSON files
     * @param hikeRepository HikeRepository for saving imported hikes
     */
    public GeoJsonImporter(
            ObjectMapper objectMapper,
            HikeRepository hikeRepository
    ) {
        super(hikeRepository);
        this.objectMapper = objectMapper;
    }

    /**
     * Checks if the importer supports the given content type.
     *
     * @param contentType The content type of the file to be imported
     * @return True if the content type is supported, false otherwise
     */
    @Override
    public boolean supports(String contentType) {
        return contentType.contains("geo+json") || contentType.contains("application/json");
    }

    /**
     * Imports data from a GeoJSON file. The method reads the GeoJSON file, extracts the features, and processes each feature as a record using the provided mapping.
     *
     * @param file The GeoJSON file to import
     * @param mapping The mapping configuration to apply to the imported data
     */
    @Override
    public void importData(MultipartFile file, FileMappingDTO mapping) {
        try {
            JsonNode root = objectMapper.readTree(file.getInputStream());
            JsonNode features = root.get("features");

            if (features == null || !features.isArray()) {
                throw new FileImportException("Invalid GeoJSON");
            }

            List<JsonNode> records = new ArrayList<>();

            for (JsonNode feature : features) {
                // On crée un "record" JsonNode combinant properties + geometry
                JsonNode properties = feature.get("properties");
                JsonNode geometry = feature.get("geometry");

                if (properties == null) {
                    throw new FileImportException("Feature without properties detected");
                }

                // On crée un objet JsonNode combiné
                JsonNode combined = objectMapper.createObjectNode()
                        .setAll((ObjectNode) properties)
                        .set("geometry", geometry);

                records.add(combined);
            }

            importRecords(records, mapping);
        } catch (IOException e) {
            throw new FileImportException("Error loading GeoJSON file", e);
        }
    }
}
