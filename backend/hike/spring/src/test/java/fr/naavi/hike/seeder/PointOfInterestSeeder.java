package fr.naavi.hike.seeder;

import fr.naavi.hike.entity.PointOfInterest;
import fr.naavi.hike.enums.PointOfInterestCategoryEnum;
import fr.naavi.hike.enums.StatusEnum;
import fr.naavi.hike.repository.PointOfInterestRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Component;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.context.TestPropertySource;

import java.util.ArrayList;
import java.util.List;
import java.util.concurrent.ThreadLocalRandom;

@Component
@ActiveProfiles("ci")
@TestPropertySource(locations = "classpath:application-ci.properties")
public class PointOfInterestSeeder {
    @Autowired
    private PointOfInterestRepository pointOfInterestRepository;

    public static final List<String> COORDINATES = List.of(
            "Forêt de Fontainebleau,48.4183572,2.4707593",
            "Parking du Signal (Paris),48.8638,2.3369",
            "Source de la Bonde (Mercantour),44.7333,6.9667",
            "Chamonix (Aiguille du Midi parking),45.9237,6.8694",
            "Col de la Croix (Lyon),45.7640,4.8357",
            "Corniches de la Côte d'Azur (Nice),43.7102,7.2620",
            "Plateau du Vercors,44.8667,5.4167",
            "Aire de service (A63),43.2951,-0.3708",
            "Source naturelle (Gorges du Verdon),43.7376,6.3247",
            "Massif Central (Puy de Dôme parking),45.7772,3.0870",
            "Gare de Toulouse (Périphérie),43.6045,1.4440",
            "La Rochelle (Tour de la Chaîne),46.1667,-1.1500",
            "Port de Saint-Malo,48.6493,-2.0257",
            "Île-de-Beauté (Ajaccio hinterland),41.9192,8.7386",
            "Fontaine urbaine (Bordeaux),44.8378,-0.5792",
            "Mont-Saint-Michel (aire d'accueil),48.6361,-1.5115",
            "Entrée Parc National Queyras,44.7330,6.8660",
            "Belvédère (Tours),47.3941,0.6848",
            "Aire naturelle (Couserans),42.9230,1.1700",
            "Vallées des Pyrénées (Pau),43.2951,-0.3708"
    );

    public static final List<String> EXTRA_COORDINATES = List.of(
            "Parc national des Écrins,44.9000,6.2500",
            "Aire du Mont-Blanc,45.8330,6.8667",
            "Source de la Loire,45.0000,3.5000",
            "Col de la Vanoise,45.3200,6.8167",
            "Gorges du Tarn,44.3000,3.5000",
            "e vue (Cap Fréhel,48.6511,-2.3989",
            "Massif des Vosges,48.0000,7.0000",
            "Port de Nice,43.7034,7.2663",
            "Source du Lot,44.6000,2.0000",
            "Île de Ré,46.1833,-1.3600"
    );

    public void seedPointsOfInterest() {
        pointOfInterestRepository.deleteAll();

        List<PointOfInterest> pointsOfInterest = new ArrayList<>();
        StatusEnum[] status = {StatusEnum.DRAFT, StatusEnum.UNPUBLISHED};

        for (String coordinate : COORDINATES) {
            String[] coords = coordinate.split(",");
            PointOfInterestCategoryEnum[] values = PointOfInterestCategoryEnum.values();
            int idx = ThreadLocalRandom.current().nextInt(values.length);

            PointOfInterest pointOfInterest = this.createPointOfInterest(
                    coords[0],
                    Double.parseDouble(coords[1]),
                    Double.parseDouble(coords[2]),
                    List.of(values[idx]),
                    StatusEnum.PUBLISHED
            );
            pointsOfInterest.add(pointOfInterest);
        }

        for (int i = 0; i < EXTRA_COORDINATES.size(); i++) {
            String[] coords = EXTRA_COORDINATES.get(i).split(",");
            PointOfInterestCategoryEnum[] values = PointOfInterestCategoryEnum.values();
            int idx = ThreadLocalRandom.current().nextInt(values.length);

            PointOfInterest pointOfInterest = this.createPointOfInterest(
                    coords[0],
                    Double.parseDouble(coords[1]),
                    Double.parseDouble(coords[2]),
                    List.of(values[idx]),
                    status[i % status.length]
            );
            pointsOfInterest.add(pointOfInterest);
        }

        pointOfInterestRepository.saveAll(pointsOfInterest);
    }

    private PointOfInterest createPointOfInterest(
            String name,
            Double latitude,
            Double longitude,
            List<PointOfInterestCategoryEnum> categories,
            StatusEnum status
    ) {
        PointOfInterest pointOfInterest = new PointOfInterest();
        pointOfInterest.setName(name);
        pointOfInterest.setDescription("Description du POI");
        pointOfInterest.setLatitude(latitude);
        pointOfInterest.setLongitude(longitude);
        pointOfInterest.setCategories(categories);
        pointOfInterest.setStatus(status);
        return pointOfInterest;
    }
}
