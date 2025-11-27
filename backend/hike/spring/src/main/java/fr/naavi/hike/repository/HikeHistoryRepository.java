package fr.naavi.hike.repository;

import fr.naavi.hike.entity.HikeHistory;
import fr.naavi.hike.repository.interfaces.HikeHistoryRepositoryInterface;
import org.springframework.data.jpa.repository.JpaRepository;

public interface HikeHistoryRepository extends JpaRepository<HikeHistory, Long>, HikeHistoryRepositoryInterface {
}
