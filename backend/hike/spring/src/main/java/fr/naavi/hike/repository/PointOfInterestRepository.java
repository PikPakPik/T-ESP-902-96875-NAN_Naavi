package fr.naavi.hike.repository;

import fr.naavi.hike.entity.PointOfInterest;
import fr.naavi.hike.repository.interfaces.PointOfInterestRepositoryInterface;
import org.springframework.data.jpa.repository.JpaRepository;

public interface PointOfInterestRepository extends JpaRepository<PointOfInterest, Long>, PointOfInterestRepositoryInterface {
}
