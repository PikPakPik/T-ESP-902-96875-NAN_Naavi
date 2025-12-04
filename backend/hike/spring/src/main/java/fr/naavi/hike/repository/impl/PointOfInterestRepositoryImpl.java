package fr.naavi.hike.repository.impl;

import fr.naavi.core.dto.PaginationDTO;
import fr.naavi.core.dto.PaginatorDTO;
import fr.naavi.hike.dto.input.GeoPaginationDTO;
import fr.naavi.hike.dto.output.PointOfInterestDto;
import fr.naavi.hike.entity.PointOfInterest;
import fr.naavi.hike.enums.StatusEnum;
import fr.naavi.hike.repository.interfaces.PointOfInterestRepositoryInterface;
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
public class PointOfInterestRepositoryImpl implements PointOfInterestRepositoryInterface {
    @PersistenceContext
    private EntityManager entityManager;

    @Autowired
    private Double earthRadius;

    @Override
    public PaginatorDTO<PointOfInterestDto> findAllPointOfInterestWithPagination(GeoPaginationDTO geoPaginationDTO) {
        CriteriaBuilder cb = entityManager.getCriteriaBuilder();
        CriteriaQuery<PointOfInterest> query = cb.createQuery(PointOfInterest.class);
        Root<PointOfInterest> pointOfInterest = query.from(PointOfInterest.class);

        query.select(pointOfInterest);

        CriteriaQuery<Long> countQuery = cb.createQuery(Long.class);
        Root<PointOfInterest> countRoot = countQuery.from(PointOfInterest.class);
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
                                                cb.function("COS", Double.class, cb.function("RADIANS", Double.class, pointOfInterest.get("latitude"))),
                                                cb.function("COS", Double.class,
                                                        cb.diff(
                                                                cb.function("RADIANS", Double.class, pointOfInterest.get("longitude")),
                                                                cb.function("RADIANS", Double.class, cb.literal(geoPaginationDTO.getLongitude()))
                                                        )
                                                )
                                        )
                                ),
                                cb.prod(
                                        cb.function("SIN", Double.class, cb.function("RADIANS", Double.class, cb.literal(geoPaginationDTO.getLatitude()))),
                                        cb.function("SIN", Double.class, cb.function("RADIANS", Double.class, pointOfInterest.get("latitude")))
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
                                                cb.function("COS", Double.class, cb.function("RADIANS", Double.class, countRoot.get("latitude"))),
                                                cb.function("COS", Double.class,
                                                        cb.diff(
                                                                cb.function("RADIANS", Double.class, countRoot.get("longitude")),
                                                                cb.function("RADIANS", Double.class, cb.literal(geoPaginationDTO.getLongitude()))
                                                        )
                                                )
                                        )
                                ),
                                cb.prod(
                                        cb.function("SIN", Double.class, cb.function("RADIANS", Double.class, cb.literal(geoPaginationDTO.getLatitude()))),
                                        cb.function("SIN", Double.class, cb.function("RADIANS", Double.class, countRoot.get("latitude")))
                                )
                        )
                )
        );

        predicates.add(cb.le(distanceExpr, geoPaginationDTO.getRadius().doubleValue()));
        countPredicates.add(cb.le(countDistanceExpr, geoPaginationDTO.getRadius().doubleValue()));

        String searchQuery = geoPaginationDTO.getQuery();
        if (searchQuery != null && !searchQuery.isEmpty()) {
            String likePattern = "%" + searchQuery + "%";
            predicates.add(cb.like(pointOfInterest.get("name"), likePattern));
            countPredicates.add(cb.like(countRoot.get("name"), likePattern));
        }

        predicates.add(cb.like(pointOfInterest.get("status"), String.valueOf(StatusEnum.PUBLISHED)));
        countPredicates.add(cb.like(countRoot.get("status"), String.valueOf(StatusEnum.PUBLISHED)));

        query.where(cb.and(predicates.toArray(new Predicate[0])));
        countQuery.where(cb.and(countPredicates.toArray(new Predicate[0])));

        Long totalItems = entityManager.createQuery(countQuery).getSingleResult();

        List<String> allowedFields = List.of("name");
        String orderField = geoPaginationDTO.getOrderField();
        String order = geoPaginationDTO.getOrder();
        if (orderField != null && allowedFields.contains(orderField)) {
            if (PaginationDTO.ORDER_DESC.equalsIgnoreCase(order)) {
                query.orderBy(cb.desc(pointOfInterest.get(orderField)));
            } else {
                query.orderBy(cb.asc(pointOfInterest.get(orderField)));
            }
        }

        int page = geoPaginationDTO.getPage();
        int limit = geoPaginationDTO.getLimit();
        int offset = (page - 1) * limit;

        List<PointOfInterest> pointOfInterestEntities = entityManager.createQuery(query)
                .setFirstResult(offset)
                .setMaxResults(limit)
                .getResultList();

        List<PointOfInterestDto> pointsOfInterest = pointOfInterestEntities.stream()
                .map(poi -> new PointOfInterestDto(poi, true))
                .toList();

        return PaginatorDTO.of(
                pointsOfInterest,
                totalItems.intValue(),
                geoPaginationDTO
        );
    }
}
