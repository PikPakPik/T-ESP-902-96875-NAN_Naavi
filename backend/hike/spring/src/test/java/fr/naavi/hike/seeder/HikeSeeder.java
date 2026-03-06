package fr.naavi.hike.seeder;

import fr.naavi.hike.entity.Hike;
import fr.naavi.hike.enums.DifficultyEnum;
import fr.naavi.hike.enums.SourceEnum;
import fr.naavi.hike.enums.StatusEnum;
import fr.naavi.hike.repository.HikeRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Component;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.context.TestPropertySource;

import java.util.ArrayList;
import java.util.List;

@Component
@ActiveProfiles("ci")
@TestPropertySource(locations = "classpath:application-ci.properties")
public class HikeSeeder {
    @Autowired
    private HikeRepository hikeRepository;

    public static final List<String> COORDINATES = List.of(
            "Place du Commerce,47.213056,-1.557778",
            "Place de la République,47.205313,-1.554651",
            "Place Marc-Elder,47.216467,-1.550488",
            "Allée Brancas,47.213670,-1.556509",
            "Place de la Bourse,47.212577,-1.559063",
            "Nantes centre,47.218102,-1.552800",
            "Rezé centre,47.200000,-1.566700",
            "Saint-Herblain centre,47.216671,-1.650000",
            "Orvault centre,47.266700,-1.616700",
            "Vertou centre,47.167700,-1.472800",
            "Couëron centre,47.216700,-1.733300",
            "Carquefou centre,47.300000,-1.500000",
            "La Chapelle-sur-Erdre,47.300000,-1.550000",
            "Bouguenais centre,47.183300,-1.616700",
            "Sainte-Luce-sur-Loire,47.250000,-1.500000"
    );

    public static final List<String> VENDEE_COORDINATES = List.of(
            "La Roche-sur-Yon,46.6700,-1.4264",
            "Les Sables-d'Olonne,46.4970,-1.7840",
            "Saint-Gilles-Croix-de-Vie,46.6498,-1.8511",
            "Saint-Jean-de-Monts,46.7362,-1.8654",
            "Noirmoutier-en-l'Ile,47.0110,-2.2050",
            "Challans,46.8682,-1.8366",
            "Luçon,46.4438,-1.1683",
            "Fontenay-le-Comte,46.4590,-0.8570",
            "Talmont-Saint-Hilaire,46.3586,-1.6376",
            "Moutiers-les-Mauxfaits,46.3520,-1.4760",
            "Les Herbiers,46.8688,-0.8813",
            "Ile d'Yeu,46.7486,-2.3943",
            "Saint-Hilaire-de-Riez,46.7178,-1.8247",
            "La Tranche-sur-Mer,46.1751,-1.3799",
            "Bouin,46.8580,-1.6430"
    );

    public static final List<String> SARTHE_COORDINATES = List.of(
            "Le Mans,48.006100,0.199600",
            "La Flèche,47.677800,-0.243900",
            "Sablé-sur-Sarthe,47.837800,-0.838600",
            "Arnage,47.974700,0.205600",
            "Allonnes,48.000000,0.200000"
    );


    public void seedHikes() {
        hikeRepository.deleteAll();

        List<Hike> hikes = new ArrayList<>();
        DifficultyEnum[] difficulties = {DifficultyEnum.EASY, DifficultyEnum.MEDIUM, DifficultyEnum.HARD};
        StatusEnum[] status = {StatusEnum.DRAFT, StatusEnum.UNPUBLISHED};

        for (int i = 0; i < COORDINATES.size(); i++) {
            String[] coords = COORDINATES.get(i).split(",");
            Hike hike = this.createHike(
                    coords[0],
                    Double.parseDouble(coords[1]),
                    Double.parseDouble(coords[2]),
                    Double.parseDouble(coords[1]),
                    Double.parseDouble(coords[2]),
                    difficulties[i % difficulties.length],
                    StatusEnum.PUBLISHED
            );
            hikes.add(hike);
        }

        for (int i = 0; i < VENDEE_COORDINATES.size(); i++) {
            String[] coords = VENDEE_COORDINATES.get(i).split(",");
            Hike hike = this.createHike(
                    coords[0],
                    Double.parseDouble(coords[1]),
                    Double.parseDouble(coords[2]),
                    Double.parseDouble(coords[1]),
                    Double.parseDouble(coords[2]),
                    difficulties[i % difficulties.length],
                    status[i % status.length]
            );
            hikes.add(hike);
        }

        hikeRepository.saveAll(hikes);
    }

    private Hike createHike(
            String name,
            Double startingPointLatitude,
            Double startingPointLongitude,
            Double arrivalPointLatitude,
            Double arrivalPointLongitude,
            DifficultyEnum difficulty,
            StatusEnum status
    ) {
        Hike hike = new Hike();
        hike.setName(name);
        hike.setStartingPointLatitude(startingPointLatitude);
        hike.setStartingPointLongitude(startingPointLongitude);
        hike.setStartingElevation(0);
        hike.setArrivalPointLatitude(arrivalPointLatitude);
        hike.setArrivalPointLongitude(arrivalPointLongitude);
        hike.setArrivalElevation(0);
        hike.setDistance(1500.0);
        hike.setDuration((double) (3600 + (int)(Math.random() * 7200)));
        hike.setLocation("Unknown");
        hike.setDifficulty(difficulty);
        hike.setSource(SourceEnum.COMMUNITY);
        hike.setStatus(status);
        hike.setWkbGeometry(null);
        hike.setWkbWaypoints(null);
        return hike;
    }
}
