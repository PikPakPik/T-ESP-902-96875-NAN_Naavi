package fr.naavi.hike.repository.impl;

import fr.naavi.core.dto.PaginationDTO;
import fr.naavi.core.dto.PaginatorDTO;
import fr.naavi.hike.dto.input.GeoPaginationDTO;
import fr.naavi.hike.dto.output.MapElementDto;
import fr.naavi.hike.entity.MapElement;
import fr.naavi.hike.entity.MapElementReaction;
import fr.naavi.hike.enums.ReactionEnum;
import fr.naavi.hike.enums.StatusEnum;
import fr.naavi.hike.enums.TypeMapElementEnum;
import fr.naavi.hike.repository.interfaces.MapElementRepositoryInterface;
import jakarta.persistence.EntityManager;
import jakarta.persistence.NoResultException;
import jakarta.persistence.PersistenceContext;
import jakarta.persistence.criteria.*;
import org.springframework.stereotype.Repository;

import java.util.ArrayList;
import java.util.List;
import java.util.Optional;

@Repository
public class MapElementRepositoryImpl implements MapElementRepositoryInterface {

    @PersistenceContext
    private EntityManager entityManager;

    private final Double earthRadius;

    /**
     * Constructor for MapElementRepositoryImpl.
     */
    public MapElementRepositoryImpl(Double earthRadius) {
        this.earthRadius = earthRadius;
    }

    @Override
    public PaginatorDTO<MapElementDto> findAllWithPagination(
            GeoPaginationDTO geoPaginationDTO,
            TypeMapElementEnum type,
            boolean includeAllStatus
    ) {
        CriteriaBuilder cb = entityManager.getCriteriaBuilder();
        CriteriaQuery<MapElement> query = cb.createQuery(MapElement.class);
        Root<MapElement> mapElement = query.from(MapElement.class);
        mapElement.fetch("images", JoinType.LEFT);

        CriteriaQuery<Long> countQuery = cb.createQuery(Long.class);
        Root<MapElement> countRoot = countQuery.from(MapElement.class);
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
                                                cb.function("COS", Double.class, cb.function("RADIANS", Double.class, mapElement.get("latitude"))),
                                                cb.function("COS", Double.class,
                                                        cb.diff(
                                                                cb.function("RADIANS", Double.class, mapElement.get("longitude")),
                                                                cb.function("RADIANS", Double.class, cb.literal(geoPaginationDTO.getLongitude()))
                                                        )
                                                )
                                        )
                                ),
                                cb.prod(
                                        cb.function("SIN", Double.class, cb.function("RADIANS", Double.class, cb.literal(geoPaginationDTO.getLatitude()))),
                                        cb.function("SIN", Double.class, cb.function("RADIANS", Double.class, mapElement.get("latitude")))
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

        predicates.add(cb.equal(mapElement.get("type"), type));
        countPredicates.add(cb.equal(countRoot.get("type"), type));

        if (geoPaginationDTO.getQuery() != null && !geoPaginationDTO.getQuery().isEmpty()) {
            String likePattern = "%" + geoPaginationDTO.getQuery() + "%";
            predicates.add(cb.like(mapElement.get("name"), likePattern));
            countPredicates.add(cb.like(countRoot.get("name"), likePattern));
        }

        if (!includeAllStatus) {
            predicates.add(cb.equal(mapElement.get("status"), StatusEnum.PUBLISHED));
            countPredicates.add(cb.equal(countRoot.get("status"), StatusEnum.PUBLISHED));
        }

        query.where(cb.and(predicates.toArray(new Predicate[0])));
        countQuery.where(cb.and(countPredicates.toArray(new Predicate[0])));

        Long totalItems = entityManager.createQuery(countQuery).getSingleResult();

        List<String> allowedFields = List.of("name", "likes", "dislikes");
        String orderField = geoPaginationDTO.getOrderField();
        String order = geoPaginationDTO.getOrder();
        if (orderField != null && allowedFields.contains(orderField)) {
            if ("likes".equals(orderField) || "dislikes".equals(orderField)) {
                Expression<Long> reactionCountExpr = createReactionCountExpression(
                        cb,
                        query,
                        mapElement,
                        "likes".equals(orderField) ? ReactionEnum.LIKE : ReactionEnum.DISLIKE
                );

                if (PaginationDTO.ORDER_DESC.equalsIgnoreCase(order)) {
                    query.orderBy(cb.desc(reactionCountExpr));
                } else {
                    query.orderBy(cb.asc(reactionCountExpr));
                }
            } else {
                if (PaginationDTO.ORDER_DESC.equalsIgnoreCase(order)) {
                    query.orderBy(cb.desc(mapElement.get(orderField)));
                } else {
                    query.orderBy(cb.asc(mapElement.get(orderField)));
                }
            }
        }

        int page = geoPaginationDTO.getPage();
        int limit = geoPaginationDTO.getLimit();
        int offset = (page - 1) * limit;

        List<MapElement> entities = entityManager.createQuery(query)
                .setFirstResult(offset)
                .setMaxResults(limit)
                .getResultList();

        List<MapElementDto> hikes = entities.stream()
                .map(me -> new MapElementDto(me, true))
                .toList();

        return PaginatorDTO.of(
                hikes,
                totalItems.intValue(),
                geoPaginationDTO
        );
    }

    private Expression<Long> createReactionCountExpression(CriteriaBuilder cb, CriteriaQuery<MapElement> query, Root<MapElement> mapElement, ReactionEnum reactionType) {
        Subquery<Long> subquery = query.subquery(Long.class);
        Root<MapElementReaction> reactionRoot = subquery.from(MapElementReaction.class);

        subquery.select(cb.count(reactionRoot.get("id")))
                .where(cb.and(
                        cb.equal(reactionRoot.get("mapElement").get("id"), mapElement.get("id")),
                        cb.equal(reactionRoot.get("reaction"), reactionType)
                ));

        return cb.coalesce(subquery, 0L);
    }

    @Override
    public Optional<MapElement> findByIdAndType(Long id, TypeMapElementEnum type) {
        CriteriaBuilder cb = entityManager.getCriteriaBuilder();
        CriteriaQuery<MapElement> query = cb.createQuery(MapElement.class);
        Root<MapElement> root = query.from(MapElement.class);

        query.select(root)
                .where(
                        cb.and(
                                cb.equal(root.get("id"), id),
                                cb.equal(root.get("type"), type)
                        )
                );

        MapElement element;
        try {
            element = entityManager.createQuery(query).getSingleResult();
        } catch (NoResultException e) {
            element = null;
        }

        return Optional.ofNullable(element);
    }
}