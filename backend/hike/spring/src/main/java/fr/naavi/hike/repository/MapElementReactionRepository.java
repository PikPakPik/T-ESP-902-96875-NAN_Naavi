package fr.naavi.hike.repository;

import fr.naavi.hike.entity.MapElementReaction;
import fr.naavi.hike.enums.ReactionEnum;
import jakarta.transaction.Transactional;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface MapElementReactionRepository extends JpaRepository<MapElementReaction, Long> {
    /**
     * Check if the user has already reacted to the map element with the given reaction.
     *
     * @param userId The user ID.
     * @param mapElementId The mapElementId
     * @param reaction The reaction type.
     * @return True if the user has already reacted, false otherwise.
     */
    @Query("""
    select case when count(r) > 0 then true else false end
    from MapElementReaction r
    where r.id.userId = :userId
    and r.id.mapElementId = :mapElementId
    and r.reaction = :reaction
    """)
    boolean existsByUserAndMapElementAndReaction(
            @Param("userId") Long userId,
            @Param("mapElementId") Long mapElementId,
            @Param("reaction") ReactionEnum reaction
    );

    /**
     * Delete a reaction from a map element for a user.
     *
     * @param userId The user ID.
     * @param mapElementId the mapElementId
     * @param reaction The reaction type.
     */
    @Modifying
    @Transactional
    @Query("""
    delete from MapElementReaction r
    where r.id.userId = :userId
    and r.id.mapElementId = :mapElementId
    and r.reaction = :reaction
    """)
    void deleteByUserAndMapElementAndReaction(
            @Param("userId") Long userId,
            @Param("mapElementId") Long mapElementId,
            @Param("reaction") ReactionEnum reaction
    );
}
