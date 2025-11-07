package fr.naavi.hike.repository.impl;

import fr.naavi.core.dto.PaginationDTO;
import fr.naavi.core.dto.PaginatorDTO;
import fr.naavi.hike.dto.input.HikePaginationDTO;
import fr.naavi.hike.dto.output.HikeDto;
import fr.naavi.hike.entity.Hike;
import fr.naavi.hike.enums.DifficultyEnum;
import fr.naavi.hike.repository.interfaces.HikeRepositoryInterface;
import jakarta.persistence.EntityManager;
import jakarta.persistence.PersistenceContext;
import jakarta.persistence.criteria.CriteriaBuilder;
import jakarta.persistence.criteria.CriteriaQuery;
import jakarta.persistence.criteria.Expression;
import jakarta.persistence.criteria.Predicate;
import jakarta.persistence.criteria.Root;
import org.springframework.stereotype.Repository;

import java.util.ArrayList;
import java.util.List;

@Repository
public class HikeRepositoryImpl implements HikeRepositoryInterface {
    @PersistenceContext
    private EntityManager entityManager;

    private Double earthRadius = 6371.0;

    @Override
    public PaginatorDTO<HikeDto> findAllHikeWithPagination(HikePaginationDTO hikePaginationDTO) {
        CriteriaBuilder cb = entityManager.getCriteriaBuilder();
        CriteriaQuery<Hike> query = cb.createQuery(Hike.class);
        Root<Hike> hike = query.from(Hike.class);

        query.select(hike);

        CriteriaQuery<Long> countQuery = cb.createQuery(Long.class);
        Root<Hike> countRoot = countQuery.from(Hike.class);
        countQuery.select(cb.count(countRoot));

        List<Predicate> predicates = new ArrayList<>();
        List<Predicate> countPredicates = new ArrayList<>();

        Expression<Double> distanceExpr = cb.prod(
                this.earthRadius,
                cb.function("ACOS", Double.class,
                        cb.sum(
                                cb.prod(
                                        cb.function("COS", Double.class, cb.function("RADIANS", Double.class, cb.literal(hikePaginationDTO.getLatitude()))),
                                        cb.prod(
                                                cb.function("COS", Double.class, cb.function("RADIANS", Double.class, hike.get("startingPointLatitude"))),
                                                cb.function("COS", Double.class,
                                                        cb.diff(
                                                                cb.function("RADIANS", Double.class, hike.get("startingPointLongitude")),
                                                                cb.function("RADIANS", Double.class, cb.literal(hikePaginationDTO.getLongitude()))
                                                        )
                                                )
                                        )
                                ),
                                cb.prod(
                                        cb.function("SIN", Double.class, cb.function("RADIANS", Double.class, cb.literal(hikePaginationDTO.getLatitude()))),
                                        cb.function("SIN", Double.class, cb.function("RADIANS", Double.class, hike.get("startingPointLatitude")))
                                )
                        )
                )
        );

        Expression<Double> countDistanceExpr = cb.prod(
                this.earthRadius,
                cb.function("ACOS", Double.class,
                        cb.sum(
                                cb.prod(
                                        cb.function("COS", Double.class, cb.function("RADIANS", Double.class, cb.literal(hikePaginationDTO.getLatitude()))),
                                        cb.prod(
                                                cb.function("COS", Double.class, cb.function("RADIANS", Double.class, countRoot.get("startingPointLatitude"))),
                                                cb.function("COS", Double.class,
                                                        cb.diff(
                                                                cb.function("RADIANS", Double.class, countRoot.get("startingPointLongitude")),
                                                                cb.function("RADIANS", Double.class, cb.literal(hikePaginationDTO.getLongitude()))
                                                        )
                                                )
                                        )
                                ),
                                cb.prod(
                                        cb.function("SIN", Double.class, cb.function("RADIANS", Double.class, cb.literal(hikePaginationDTO.getLatitude()))),
                                        cb.function("SIN", Double.class, cb.function("RADIANS", Double.class, countRoot.get("startingPointLatitude")))
                                )
                        )
                )
        );

        predicates.add(cb.le(distanceExpr, hikePaginationDTO.getRadius().doubleValue()));
        countPredicates.add(cb.le(countDistanceExpr, hikePaginationDTO.getRadius().doubleValue()));

        String searchQuery = hikePaginationDTO.getQuery();
        if (searchQuery != null && !searchQuery.isEmpty()) {
            String likePattern = "%" + searchQuery + "%";
            predicates.add(cb.like(hike.get("name"), likePattern));
            countPredicates.add(cb.like(countRoot.get("name"), likePattern));
        }

        Integer distance = hikePaginationDTO.getDistance();
        if (distance != null && !distance.equals(0)) {
            predicates.add(cb.lessThanOrEqualTo(hike.get("distance"), distance));
            countPredicates.add(cb.lessThanOrEqualTo(countRoot.get("distance"), distance));
        }

        DifficultyEnum difficulty = hikePaginationDTO.getDifficulty();
        if (difficulty != null) {
            predicates.add(cb.equal(hike.get("difficulty"), difficulty));
            countPredicates.add(cb.equal(countRoot.get("difficulty"), difficulty));
        }

        query.where(cb.and(predicates.toArray(new Predicate[0])));
        countQuery.where(cb.and(countPredicates.toArray(new Predicate[0])));

        Long totalItems = entityManager.createQuery(countQuery).getSingleResult();

        List<String> allowedFields = List.of("name", "distance", "difficulty");
        String orderField = hikePaginationDTO.getOrderField();
        String order = hikePaginationDTO.getOrder();
        if (orderField != null && allowedFields.contains(orderField)) {
            if (PaginationDTO.ORDER_DESC.equalsIgnoreCase(order)) {
                query.orderBy(cb.desc(hike.get(orderField)));
            } else {
                query.orderBy(cb.asc(hike.get(orderField)));
            }
        }

        int page = hikePaginationDTO.getPage();
        int limit = hikePaginationDTO.getLimit();
        int offset = (page - 1) * limit;

        List<Hike> hikeEntities = entityManager.createQuery(query)
                .setFirstResult(offset)
                .setMaxResults(limit)
                .getResultList();

        List<HikeDto> hikes = hikeEntities.stream()
                .map(h -> new HikeDto(h, true))
                .toList();

        return PaginatorDTO.of(
                hikes,
                totalItems.intValue(),
                hikePaginationDTO
        );
    }
}
