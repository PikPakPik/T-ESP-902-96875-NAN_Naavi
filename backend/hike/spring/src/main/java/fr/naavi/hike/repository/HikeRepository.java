package fr.naavi.hike.repository;

import fr.naavi.hike.entity.Hike;
import fr.naavi.hike.repository.interfaces.HikeRepositoryInterface;
import org.springframework.data.jpa.repository.JpaRepository;

public interface HikeRepository extends JpaRepository<Hike, Long>, HikeRepositoryInterface {
}
