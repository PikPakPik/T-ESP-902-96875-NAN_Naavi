package fr.naavi.hike.repository.interfaces;

import fr.naavi.core.dto.PaginatorDTO;
import fr.naavi.hike.dto.input.GeoPaginationDTO;
import fr.naavi.hike.dto.output.MapElementDto;
import fr.naavi.hike.dto.input.PointOfInterestAdministrationPaginationDTO;
import fr.naavi.hike.entity.MapElement;
import fr.naavi.hike.enums.TypeMapElementEnum;

import java.util.Optional;

public interface MapElementRepositoryInterface {
    /**
     * Find all map elements with pagination.
     *
     * @param geoPaginationDTO The pagination data.
     * @param type The type of map element to retrieve.
     * @param includeAllStatus Include all status or only published ones.
     * @return The paginated map elements.
     */
    PaginatorDTO<MapElementDto> findAllWithPagination(
            GeoPaginationDTO geoPaginationDTO,
            TypeMapElementEnum type,
            boolean includeAllStatus
    );

    PaginatorDTO<MapElement> findAllAdministrationWithPagination(
            PointOfInterestAdministrationPaginationDTO paginationDTO,
            TypeMapElementEnum type
    );

    /**
     * Find a map element by ID and type.
     *
     * @param id The map element ID.
     * @param type The type of map element.
     * @return The map element, if found.
     */
    Optional<MapElement> findByIdAndType(Long id, TypeMapElementEnum type);
}
