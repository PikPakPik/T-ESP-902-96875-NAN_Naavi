package fr.naavi.hike.repository.impl;

import fr.naavi.core.dto.PaginationDTO;
import fr.naavi.core.dto.PaginatorDTO;
import fr.naavi.hike.dto.input.GeoPaginationDTO;
import fr.naavi.hike.dto.output.HikeDto;
import fr.naavi.hike.entity.Hike;
import fr.naavi.hike.entity.HikeReaction;
import fr.naavi.hike.enums.DifficultyEnum;
import fr.naavi.hike.enums.ReactionEnum;
import fr.naavi.hike.enums.StatusEnum;
import fr.naavi.hike.enums.VisibilityEnum;
import fr.naavi.hike.repository.interfaces.HikeRepositoryInterface;
import jakarta.persistence.EntityManager;
import jakarta.persistence.PersistenceContext;
import jakarta.persistence.criteria.*;
import org.springframework.stereotype.Repository;

import java.util.ArrayList;
import java.util.List;

@Repository
public class HikeRepositoryImpl implements HikeRepositoryInterface {
    @PersistenceContext
    private EntityManager entityManager;

    private final Double earthRadius;

    /**
     * Constructor for HikeRepositoryImpl.
     */
    public HikeRepositoryImpl(Double earthRadius) {
        this.earthRadius = earthRadius;
    }

    @Override
    public PaginatorDTO<HikeDto> findAllHikeWithPagination(GeoPaginationDTO geoPaginationDTO, boolean includeAllStatus) {
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

        if (!includeAllStatus) {
            predicates.add(cb.equal(hike.get("status"), StatusEnum.PUBLISHED));
            countPredicates.add(cb.equal(countRoot.get("status"), StatusEnum.PUBLISHED));
            predicates.add(cb.equal(hike.get("visibility"), VisibilityEnum.PUBLIC));
            countPredicates.add(cb.equal(countRoot.get("visibility"), VisibilityEnum.PUBLIC));
        }

        query.where(cb.and(predicates.toArray(new Predicate[0])));
        countQuery.where(cb.and(countPredicates.toArray(new Predicate[0])));

        Long totalItems = entityManager.createQuery(countQuery).getSingleResult();

        List<String> allowedFields = List.of("name", "distance", "difficulty", "likes", "dislikes");
        String orderField = geoPaginationDTO.getOrderField();
        String order = geoPaginationDTO.getOrder();
        System.out.println(order);
        if (orderField != null && allowedFields.contains(orderField)) {
            if ("likes".equals(orderField) || "dislikes".equals(orderField)) {
                Expression<Long> reactionCountExpr = createReactionCountExpression(
                        cb,
                        query,
                        hike,
                        "likes".equals(orderField) ? ReactionEnum.LIKE : ReactionEnum.DISLIKE
                );

                if (PaginationDTO.ORDER_DESC.equalsIgnoreCase(order)) {
                    query.orderBy(cb.desc(reactionCountExpr));
                } else {
                    query.orderBy(cb.asc(reactionCountExpr));
                }
            } else {
                if (PaginationDTO.ORDER_DESC.equalsIgnoreCase(order)) {
                    query.orderBy(cb.desc(hike.get(orderField)));
                } else {
                    query.orderBy(cb.asc(hike.get(orderField)));
                }
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

    private Expression<Long> createReactionCountExpression(CriteriaBuilder cb, CriteriaQuery<Hike> query, Root<Hike> hike, ReactionEnum reactionType) {
        Subquery<Long> subquery = query.subquery(Long.class);
        Root<HikeReaction> reactionRoot = subquery.from(HikeReaction.class);

        subquery.select(cb.count(reactionRoot.get("id")))
                .where(cb.and(
                        cb.equal(reactionRoot.get("hike").get("id"), hike.get("id")),
                        cb.equal(reactionRoot.get("reaction"), reactionType)
                ));

        return cb.coalesce(subquery, 0L);
    }

    @Override
    public PaginatorDTO<HikeDto> findAllByUserIdWithPagination(PaginationDTO paginationDTO, Long userId) {
        CriteriaBuilder cb = entityManager.getCriteriaBuilder();
        CriteriaQuery<Hike> query = cb.createQuery(Hike.class);
        Root<Hike> hike = query.from(Hike.class);

        CriteriaQuery<Long> countQuery = cb.createQuery(Long.class);
        Root<Hike> countRoot = countQuery.from(Hike.class);
        countQuery.select(cb.count(countRoot));

        Predicate ownerPredicate = cb.equal(hike.get("userId"), userId);
        Predicate notDeleted = cb.notEqual(hike.get("status"), StatusEnum.DELETED);
        query.where(cb.and(ownerPredicate, notDeleted));

        Predicate countOwnerPredicate = cb.equal(countRoot.get("userId"), userId);
        Predicate countNotDeleted = cb.notEqual(countRoot.get("status"), StatusEnum.DELETED);
        countQuery.where(cb.and(countOwnerPredicate, countNotDeleted));

        List<String> allowedFields = List.of("name", "distance", "difficulty", "createdAt");
        String orderField = paginationDTO.getOrderField();
        String order = paginationDTO.getOrder();
        if (orderField != null && allowedFields.contains(orderField)) {
            if (PaginationDTO.ORDER_DESC.equalsIgnoreCase(order)) {
                query.orderBy(cb.desc(hike.get(orderField)));
            } else {
                query.orderBy(cb.asc(hike.get(orderField)));
            }
        } else {
            query.orderBy(cb.desc(hike.get("createdAt")));
        }

        Long totalItems = entityManager.createQuery(countQuery).getSingleResult();

        int page = paginationDTO.getPage();
        int limit = paginationDTO.getLimit();
        int offset = (page - 1) * limit;

        List<Hike> hikeEntities = entityManager.createQuery(query)
                .setFirstResult(offset)
                .setMaxResults(limit)
                .getResultList();

        List<HikeDto> hikes = hikeEntities.stream()
                .map(h -> new HikeDto(h, true))
                .toList();

        return PaginatorDTO.of(hikes, totalItems.intValue(), paginationDTO);
    }
}
