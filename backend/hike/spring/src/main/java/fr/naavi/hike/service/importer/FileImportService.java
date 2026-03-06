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

    public FileImportService(
            List<FileImporter> importers
    ) {
        this.importers = importers;
    }

    public void importFile(MultipartFile file, FileMappingDTO mapping) {
        FileImporter importer = importers.stream()
                .filter(i -> i.supports(file.getContentType()))
                .findFirst()
                .orElseThrow(() -> new FileImportException("File format not supported"));

        importer.importData(file, mapping);
    }
}

