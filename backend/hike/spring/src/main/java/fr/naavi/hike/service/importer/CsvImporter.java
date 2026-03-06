package fr.naavi.hike.service.importer;

import fr.naavi.hike.abstraction.AbstractHikeImporter;
import fr.naavi.hike.dto.input.FileMappingDTO;
import fr.naavi.hike.exception.FileImportException;
import fr.naavi.hike.repository.HikeRepository;
import fr.naavi.hike.repository.interfaces.FileImporter;
import org.apache.commons.csv.CSVFormat;
import org.apache.commons.csv.CSVRecord;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;
import tools.jackson.databind.JsonNode;
import tools.jackson.databind.ObjectMapper;

import java.io.IOException;
import java.io.InputStreamReader;
import java.io.Reader;
import java.util.ArrayList;
import java.util.List;

@Service
public class CsvImporter extends AbstractHikeImporter implements FileImporter {

    private final ObjectMapper objectMapper;

    /**
     * Constructor for CsvImporter.
     *
     * @param hikeRepository the repository to manage hike data
     * @param objectMapper the object mapper to convert CSV records to JSON
     */
    public CsvImporter(HikeRepository hikeRepository, ObjectMapper objectMapper) {
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
        return contentType.contains("csv");
    }

    /**
     * Imports data from a CSV file. The method reads the CSV file, converts each record to a JSON node, and then processes the records using the provided mapping.
     *
     * @param file the CSV file to import
     * @param mapping the mapping configuration to apply to the imported data
     */
    @Override
    public void importData(MultipartFile file, FileMappingDTO mapping) {
        try {
            Reader reader = new InputStreamReader(file.getInputStream());

            Iterable<CSVRecord> csv = CSVFormat.DEFAULT.builder()
                    .setDelimiter(';')
                    .setHeader()
                    .setSkipHeaderRecord(true)
                    .setTrim(true)
                    .build()
                    .parse(reader);

            List<JsonNode> records = new ArrayList<>();

            for (CSVRecord row : csv) {
                JsonNode node = objectMapper.valueToTree(row.toMap());
                records.add(node);
            }

            importRecords(records, mapping);
        } catch (IOException e) {
            throw new FileImportException("Error loading CSV file", e);
        }
    }
}
