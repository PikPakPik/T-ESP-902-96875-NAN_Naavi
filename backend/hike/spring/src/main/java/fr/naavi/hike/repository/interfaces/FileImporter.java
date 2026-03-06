package fr.naavi.hike.repository.interfaces;

import fr.naavi.hike.dto.input.FileMappingDTO;
import org.springframework.web.multipart.MultipartFile;

public interface FileImporter {
    boolean supports(String contentType);

    void importData(MultipartFile file, FileMappingDTO mapping);
}
