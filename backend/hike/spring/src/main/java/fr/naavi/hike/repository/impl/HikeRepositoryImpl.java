package fr.naavi.hike.repository.impl;

import fr.naavi.core.dto.PaginationDTO;
import fr.naavi.core.dto.PaginatorDTO;
import fr.naavi.hike.dto.input.GeoPaginationDTO;
import fr.naavi.hike.dto.output.HikeDto;
import fr.naavi.hike.entity.Hike;
import fr.naavi.hike.enums.DifficultyEnum;
import fr.naavi.hike.enums.StatusEnum;
import fr.naavi.hike.repository.interfaces.HikeRepositoryInterface;
import jakarta.persistence.EntityManager;
import jakarta.persistence.PersistenceContext;
import jakarta.persistence.criteria.CriteriaBuilder;
import jakarta.persistence.criteria.CriteriaQuery;
import jakarta.persistence.criteria.Expression;
import jakarta.persistence.criteria.Predicate;
import jakarta.persistence.criteria.Root;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Repository;

import java.util.ArrayList;
import java.util.List;

@Repository
public class HikeRepositoryImpl implements HikeRepositoryInterface {
    @PersistenceContext
    private EntityManager entityManager;

    @Autowired
    private Double earthRadius;

    @Override
    public PaginatorDTO<HikeDto> findAllHikeWithPagination(GeoPaginationDTO geoPaginationDTO) {
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
                                        cb.function("COS", Double.class, cb.function("RADIANS", Double.class, cb.literal(geoPaginationDTO.getLatitude()))),
                                        cb.prod(
                                                cb.function("COS", Double.class, cb.function("RADIANS", Double.class, hike.get("startingPointLatitude"))),
                                                cb.function("COS", Double.class,
                                                        cb.diff(
                                                                cb.function("RADIANS", Double.class, hike.get("startingPointLongitude")),
                                                                cb.function("RADIANS", Double.class, cb.literal(geoPaginationDTO.getLongitude()))
                                                        )
                                                )
                                        )
                                ),
                                cb.prod(
                                        cb.function("SIN", Double.class, cb.function("RADIANS", Double.class, cb.literal(geoPaginationDTO.getLatitude()))),
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
                                        cb.function("COS", Double.class, cb.function("RADIANS", Double.class, cb.literal(geoPaginationDTO.getLatitude()))),
                                        cb.prod(
                                                cb.function("COS", Double.class, cb.function("RADIANS", Double.class, countRoot.get("startingPointLatitude"))),
                                                cb.function("COS", Double.class,
                                                        cb.diff(
                                                                cb.function("RADIANS", Double.class, countRoot.get("startingPointLongitude")),
                                                                cb.function("RADIANS", Double.class, cb.literal(geoPaginationDTO.getLongitude()))
                                                        )
                                                )
                                        )
                                ),
                                cb.prod(
                                        cb.function("SIN", Double.class, cb.function("RADIANS", Double.class, cb.literal(geoPaginationDTO.getLatitude()))),
                                        cb.function("SIN", Double.class, cb.function("RADIANS", Double.class, countRoot.get("startingPointLatitude")))
                                )
                        )
                )
        );

        predicates.add(cb.le(distanceExpr, geoPaginationDTO.getRadius().doubleValue()));
        countPredicates.add(cb.le(countDistanceExpr, geoPaginationDTO.getRadius().doubleValue()));

        String searchQuery = geoPaginationDTO.getQuery();
        if (searchQuery != null && !searchQuery.isEmpty()) {
            String likePattern = "%" + searchQuery + "%";
            predicates.add(cb.like(hike.get("name"), likePattern));
            countPredicates.add(cb.like(countRoot.get("name"), likePattern));
        }

        Integer distance = geoPaginationDTO.getDistance();
        if (distance != null && !distance.equals(0)) {
            predicates.add(cb.lessThanOrEqualTo(hike.get("distance"), distance));
            countPredicates.add(cb.lessThanOrEqualTo(countRoot.get("distance"), distance));
        }

        DifficultyEnum difficulty = geoPaginationDTO.getDifficulty();
        if (difficulty != null) {
            predicates.add(cb.equal(hike.get("difficulty"), difficulty));
            countPredicates.add(cb.equal(countRoot.get("difficulty"), difficulty));
        }

        predicates.add(cb.like(hike.get("status"), String.valueOf(StatusEnum.PUBLISHED)));
        countPredicates.add(cb.like(countRoot.get("status"), String.valueOf(StatusEnum.PUBLISHED)));

        query.where(cb.and(predicates.toArray(new Predicate[0])));
        countQuery.where(cb.and(countPredicates.toArray(new Predicate[0])));

        Long totalItems = entityManager.createQuery(countQuery).getSingleResult();

        List<String> allowedFields = List.of("name", "distance", "difficulty");
        String orderField = geoPaginationDTO.getOrderField();
        String order = geoPaginationDTO.getOrder();
        if (orderField != null && allowedFields.contains(orderField)) {
            if (PaginationDTO.ORDER_DESC.equalsIgnoreCase(order)) {
                query.orderBy(cb.desc(hike.get(orderField)));
            } else {
                query.orderBy(cb.asc(hike.get(orderField)));
            }
        }

        int page = geoPaginationDTO.getPage();
        int limit = geoPaginationDTO.getLimit();
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
                geoPaginationDTO
        );
    }
}
