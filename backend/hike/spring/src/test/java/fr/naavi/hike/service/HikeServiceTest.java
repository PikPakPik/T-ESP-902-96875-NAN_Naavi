package fr.naavi.hike.service;

import fr.naavi.hike.entity.Hike;
import fr.naavi.hike.enums.StatusEnum;
import fr.naavi.hike.repository.HikeHistoryRepository;
import fr.naavi.hike.repository.HikeRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
public class HikeServiceTest {

    @Mock
    private HikeRepository hikeRepository;

    @Mock
    private HikeHistoryRepository hikeHistoryRepository;

    @Mock
    private OpenStreetMapService openStreetMapService;

    @InjectMocks
    private HikeService hikeService;

    private Hike hike;

    @BeforeEach
    void setUp() {
        hike = new Hike();
        hike.setName("Test Hike");
        hike.setStatus(StatusEnum.PUBLISHED);
        when(hikeRepository.save(hike)).thenReturn(hike);
    }

    @Test
    void softDeleteHike_shouldSetStatusToDeleted() {
        hikeService.softDeleteHike(hike);

        assertEquals(StatusEnum.DELETED, hike.getStatus());
    }

    @Test
    void softDeleteHike_shouldCallRepositorySave() {
        hikeService.softDeleteHike(hike);

        verify(hikeRepository).save(hike);
    }

    @Test
    void softDeleteHike_shouldPreserveOtherFields() {
        hike.setName("Ma Randonnée");

        hikeService.softDeleteHike(hike);

        assertEquals("Ma Randonnée", hike.getName());
        assertEquals(StatusEnum.DELETED, hike.getStatus());
    }
}
