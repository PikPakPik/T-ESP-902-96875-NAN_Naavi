package fr.naavi.hike.repository.interfaces;

import fr.naavi.hike.dto.input.FileMappingDTO;
import org.springframework.web.multipart.MultipartFile;

public interface FileImporter {
    /**
     * Checks if the importer supports the given content type.
     *
     * @param contentType The content type of the file to be imported
     * @return True if the content type is supported, false otherwise
     */
    boolean supports(String contentType);

    /**
     * Imports data from a file.
     *
     * @param file the file to import
     * @param mapping the mapping configuration to apply to the imported data
     */
    void importData(MultipartFile file, FileMappingDTO mapping);
}
