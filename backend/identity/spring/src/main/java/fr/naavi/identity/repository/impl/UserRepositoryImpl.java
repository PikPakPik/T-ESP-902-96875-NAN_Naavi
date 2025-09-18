package fr.naavi.identity.repository.impl;

import fr.naavi.core.dto.PaginationDTO;
import fr.naavi.core.dto.PaginatorDto;
import fr.naavi.identity.dto.output.UserDto;
import fr.naavi.identity.entity.User;
import fr.naavi.identity.enums.StatusEnum;
import fr.naavi.identity.repository.interfaces.UserRepositoryInterface;
import jakarta.persistence.EntityManager;
import jakarta.persistence.PersistenceContext;
import jakarta.persistence.criteria.CriteriaBuilder;
import jakarta.persistence.criteria.CriteriaQuery;
import jakarta.persistence.criteria.Root;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public class UserRepositoryImpl implements UserRepositoryInterface {
    @PersistenceContext
    private EntityManager entityManager;

    @Override
    public PaginatorDto<UserDto> findAllUserWithPagination(PaginationDTO paginationDTO) {
        CriteriaBuilder cb = entityManager.getCriteriaBuilder();
        CriteriaQuery<User> query = cb.createQuery(User.class);
        Root<User> user = query.from(User.class);

        query.select(user);

        CriteriaQuery<Long> countQuery = cb.createQuery(Long.class);
        Root<User> countRoot = countQuery.from(User.class);
        countQuery.select(cb.count(countRoot));

        String searchQuery = paginationDTO.getQuery();
        if (searchQuery != null && !searchQuery.isEmpty()) {
            String likePattern = "%" + searchQuery + "%";
            query.where(
                    cb.or(
                            cb.like(user.get("firstname"), likePattern),
                            cb.like(user.get("lastname"), likePattern),
                            cb.like(user.get("email"), likePattern)
                    )
            );
            countQuery.where(
                    cb.or(
                            cb.like(countRoot.get("firstname"), likePattern),
                            cb.like(countRoot.get("lastname"), likePattern),
                            cb.like(countRoot.get("email"), likePattern)
                    )
            );
        }

        Long totalItems = entityManager.createQuery(countQuery).getSingleResult();

        List<String> allowedFields = List.of("firstname", "lastname", "email");
        String orderField = paginationDTO.getOrderField();
        String order = paginationDTO.getOrder();
        if (orderField != null && allowedFields.contains(orderField)) {
            if (PaginationDTO.ORDER_DESC.equalsIgnoreCase(order)) {
                query.orderBy(cb.desc(user.get(orderField)));
            } else {
                query.orderBy(cb.asc(user.get(orderField)));
            }
        }

        int page = paginationDTO.getPage();
        int limit = paginationDTO.getLimit();
        int offset = (page - 1) * limit;

        List<User> userEntities = entityManager.createQuery(query)
                .setFirstResult(offset)
                .setMaxResults(limit)
                .getResultList();

        List<UserDto> users = userEntities.stream()
                .map(u -> new UserDto(u, true))
                .toList();

        return PaginatorDto.of(
                users,
                totalItems.intValue(),
                paginationDTO
        );
    }

    @Override
    public Optional<User> findByIdAndStatusNotDeleted(Long id) {
        CriteriaBuilder cb = entityManager.getCriteriaBuilder();
        CriteriaQuery<User> query = cb.createQuery(User.class);
        Root<User> user = query.from(User.class);
        query.select(user)
                .where(
                        cb.and(
                                cb.equal(user.get("id"), id),
                                cb.notEqual(user.get("status"), StatusEnum.DELETED)
                        )
                );
        List<User> result = entityManager.createQuery(query).getResultList();
        return result.isEmpty() ? Optional.empty() : Optional.of(result.get(0));
    }
}
