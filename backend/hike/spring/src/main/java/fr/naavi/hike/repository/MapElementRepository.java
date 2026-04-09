package fr.naavi.hike.repository;

import fr.naavi.hike.entity.MapElement;
import fr.naavi.hike.repository.interfaces.MapElementRepositoryInterface;
import org.springframework.data.jpa.repository.JpaRepository;

public interface MapElementRepository extends JpaRepository<MapElement, Long>, MapElementRepositoryInterface {
}
