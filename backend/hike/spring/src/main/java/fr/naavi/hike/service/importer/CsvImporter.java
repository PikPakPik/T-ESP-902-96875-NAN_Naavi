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

    public CsvImporter(HikeRepository hikeRepository, ObjectMapper objectMapper) {
        super(hikeRepository);
        this.objectMapper = objectMapper;
    }

    @Override
    public boolean supports(String contentType) {
        return contentType.contains("csv");
    }

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
