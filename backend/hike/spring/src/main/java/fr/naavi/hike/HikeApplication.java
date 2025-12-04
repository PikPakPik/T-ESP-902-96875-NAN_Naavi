package fr.naavi.hike;

import io.swagger.v3.oas.annotations.OpenAPIDefinition;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.cache.annotation.EnableCaching;

@OpenAPIDefinition(
        tags = {
                @Tag(
                        name = "Administration",
                        description = "Points d'accès pour la gestion des utilisateurs (réservé aux administrateurs)"
                ),
                @Tag(
                        name = "Randonnée",
                        description = "Points d'accès pour la gestion des randonnées"
                ),
                @Tag(
                        name = "Point d'intérêt",
                        description = "Points d'accès pour la gestion des points d'intérêt"
                ),
                @Tag(
                        name = "Service",
                        description = "Points d'accès pour la santé et la configuration du service de randonnée"
                )
        }
)
@EnableCaching
@SpringBootApplication
public class HikeApplication {
    /**
     * @param args Command line arguments
     */
    public static void main(String[] args) {
        SpringApplication.run(HikeApplication.class, args);
    }
}
