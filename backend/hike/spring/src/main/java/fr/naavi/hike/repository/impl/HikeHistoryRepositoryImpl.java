package fr.naavi.hike.repository.impl;

import fr.naavi.core.dto.PaginationDTO;
import fr.naavi.core.dto.PaginatorDTO;
import fr.naavi.hike.dto.output.HikeHistoryDto;
import fr.naavi.hike.entity.HikeHistory;
import fr.naavi.hike.repository.interfaces.HikeHistoryRepositoryInterface;
import jakarta.persistence.EntityManager;
import jakarta.persistence.PersistenceContext;
import jakarta.persistence.criteria.CriteriaBuilder;
import jakarta.persistence.criteria.CriteriaQuery;
import jakarta.persistence.criteria.Root;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public class HikeHistoryRepositoryImpl implements HikeHistoryRepositoryInterface {
    @PersistenceContext
    private EntityManager entityManager;

    @Override
    public PaginatorDTO<HikeHistoryDto> findAllWithPagination(PaginationDTO paginationDTO, Long userId) {
        CriteriaBuilder cb = entityManager.getCriteriaBuilder();
        CriteriaQuery<HikeHistory> query = cb.createQuery(HikeHistory.class);
        Root<HikeHistory> hikeHistory = query.from(HikeHistory.class);

        query.select(hikeHistory);

        CriteriaQuery<Long> countQuery = cb.createQuery(Long.class);
        Root<HikeHistory> countRoot = countQuery.from(HikeHistory.class);
        countQuery.select(cb.count(countRoot));

        query.where(cb.equal(hikeHistory.get("user"), userId));
        countQuery.where(cb.equal(countRoot.get("user"), userId));

        Long totalItems = entityManager.createQuery(countQuery).getSingleResult();

        int page = paginationDTO.getPage();
        int limit = paginationDTO.getLimit();
        int offset = (page - 1) * limit;

        List<HikeHistory> hikeEntities = entityManager.createQuery(query)
                .setFirstResult(offset)
                .setMaxResults(limit)
                .getResultList();

        List<HikeHistoryDto> hikes = hikeEntities.stream()
                .map(h -> new HikeHistoryDto(h, true))
                .toList();

        return PaginatorDTO.of(
                hikes,
                totalItems.intValue(),
                paginationDTO
        );
    }
}
