package fr.naavi.identity;

import io.swagger.v3.oas.annotations.OpenAPIDefinition;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.cache.annotation.EnableCaching;
import org.springframework.scheduling.annotation.EnableScheduling;

@OpenAPIDefinition(
        tags = {
                @Tag(
                        name = "Sécurité",
                        description = "Points d'accès pour l'authentification et l'inscription des utilisateurs"
                ),
                @Tag(
                        name = "Utilisateur",
                        description = "Points d'accès pour récupérer les informations de l'utilisateur connecté"
                ),
                @Tag(
                        name = "Administration",
                        description = "Points d'accès pour la gestion des utilisateurs (réservé aux administrateurs)"
                ),
                @Tag(
                        name = "Service",
                        description = "Points d'accès pour la santé et la configuration du service d'identité"
                )
        }
)
@EnableCaching
@EnableScheduling
@SpringBootApplication
public class IdentityApplication {
    /**
     * @param args Command line arguments
     */
    public static void main(String[] args) {
        SpringApplication.run(IdentityApplication.class, args);
    }
}
