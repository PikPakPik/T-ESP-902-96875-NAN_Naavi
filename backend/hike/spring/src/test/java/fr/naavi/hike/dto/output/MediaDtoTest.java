package fr.naavi.hike.dto.output;

import fr.naavi.core.enums.S3Enum;
import fr.naavi.hike.entity.Media;
import org.junit.jupiter.api.Test;

import java.time.LocalDateTime;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNull;

class MediaDtoTest {

    @Test
    void hikeImageFilenameAlignsWithS3Key() {
        Media media = new Media();
        media.setId(10L);
        media.setFilename("deadbeef.png");
        media.setUser(5L);
        media.setCreatedAt(LocalDateTime.of(2024, 6, 1, 12, 0));

        MediaDto dto = new MediaDto(media, false, S3Enum.HIKES, 42L);

        // S3Enum.toString() est en minuscules (aligné sur S3Service.upload)
        assertEquals("hikes/42/deadbeef.png", dto.getFilename());
        assertEquals(10L, dto.getId());
        assertNull(dto.getUserId());
        assertEquals(media.getCreatedAt(), dto.getCreatedAt());
    }

    @Test
    void userIdIncludedWhenShowUserIdTrue() {
        Media media = new Media();
        media.setId(1L);
        media.setFilename("x.jpg");
        media.setUser(99L);
        media.setCreatedAt(LocalDateTime.now());

        MediaDto dto = new MediaDto(media, true, S3Enum.HIKES, 7L);

        assertEquals("hikes/7/x.jpg", dto.getFilename());
        assertEquals(99L, dto.getUserId());
    }
}
