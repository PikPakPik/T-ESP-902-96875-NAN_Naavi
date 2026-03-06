package fr.naavi.hike.service.importer;

import fr.naavi.hike.dto.input.FileMappingDTO;
import fr.naavi.hike.exception.FileImportException;
import fr.naavi.hike.repository.interfaces.FileImporter;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

import java.util.List;

@Service
public class FileImportService {
    private final List<FileImporter> importers;

    /**
     * Constructor for FileImportService.
     *
     * @param importers List of available importers
     */
    public FileImportService(
            List<FileImporter> importers
    ) {
        this.importers = importers;
    }

    /**
     * Imports a file using the appropriate importer based on the file's content type.
     *
     * @param file The file to import.
     * @param mapping The mapping configuration to apply to the imported data.
     */
    public void importFile(MultipartFile file, FileMappingDTO mapping) {
        FileImporter importer = importers.stream()
                .filter(i -> i.supports(file.getContentType()))
                .findFirst()
                .orElseThrow(() -> new FileImportException("File format not supported"));

        importer.importData(file, mapping);
    }
}

