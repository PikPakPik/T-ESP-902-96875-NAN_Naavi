package fr.naavi.hike.service;

import fr.naavi.hike.dto.UserDTO;
import fr.naavi.hike.entity.Media;
import fr.naavi.hike.repository.MediaRepository;
import org.springframework.stereotype.Service;

@Service
public class MediaService {
    private final MediaRepository mediaRepository;

    /**
     * Constructor for MediaService.
     *
     * @param mediaRepository The media repository.
     */
    public MediaService(
            MediaRepository mediaRepository
    ) {
        this.mediaRepository = mediaRepository;
    }

    /**
     * Save a media.
     *
     * @param user The user.
     * @param filename The filename.
     * @return The saved media.
     */
    public Media save(UserDTO user, String filename) {
        Media media = new Media();
        media.setFilename(filename);
        media.setUser(user.getId());
        return mediaRepository.save(media);
    }

    /**
     * Delete a media.
     *
     * @param media The media to delete.
     */
    public void delete(Media media) {
        mediaRepository.delete(media);
    }
}
