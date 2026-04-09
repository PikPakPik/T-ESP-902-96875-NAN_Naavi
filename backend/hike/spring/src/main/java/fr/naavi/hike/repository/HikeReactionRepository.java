package fr.naavi.hike.repository;

import fr.naavi.hike.entity.HikeReaction;
import fr.naavi.hike.enums.ReactionEnum;
import jakarta.transaction.Transactional;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface HikeReactionRepository extends JpaRepository<HikeReaction, Long> {
    /**
     * Check if the user has already reacted to the hike with the given reaction.
     *
     * @param userId The user ID.
     * @param hikeId The hikeId
     * @param reaction The reaction type.
     * @return True if the user has already reacted, false otherwise.
     */
    @Query("""
    select case when count(hr) > 0 then true else false end
    from HikeReaction hr
    where hr.id.userId = :userId
    and hr.id.hikeId = :hikeId
    and hr.reaction = :reaction
    """)
    boolean existsByUserAndHikeAndReaction(
            @Param("userId") Long userId,
            @Param("hikeId") Long hikeId,
            @Param("reaction") ReactionEnum reaction
    );

    /**
     * Delete a reaction from a hike for a user.
     *
     * @param userId The user ID.
     * @param hikeId the hikeId
     * @param reaction The reaction type.
     */
    @Modifying
    @Transactional
    @Query("""
    delete from HikeReaction hr
    where hr.id.userId = :userId
    and hr.id.hikeId = :hikeId
    and hr.reaction = :reaction
    """)
    void deleteByUserAndHikeAndReaction(
            @Param("userId") Long userId,
            @Param("hikeId") Long hikeId,
            @Param("reaction") ReactionEnum reaction
    );
}
