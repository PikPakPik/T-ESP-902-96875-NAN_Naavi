package fr.naavi.hike.utils;

import tools.jackson.databind.ObjectMapper;

import java.lang.reflect.Field;
import java.util.Map;

/**
 * Service utilitaire pour créer des DTOs dans les tests en utilisant la réflexion.
 * Permet de définir les valeurs des champs privés sans avoir besoin de setters.
 */
public class DtoFactory {
    /**
     * Crée une instance d'un DTO et définit ses champs avec les valeurs fournies.
     *
     * @param dtoClass la classe du DTO à instancier
     * @param fieldValues map contenant le nom des champs et leurs valeurs
     * @param <T> le type du DTO
     * @return une instance du DTO avec les champs définis
     * @throws Exception si l'instanciation ou l'affectation échoue
     */
    public static <T> T createDto(Class<T> dtoClass, Map<String, Object> fieldValues) throws Exception {
        T instance = dtoClass.getDeclaredConstructor().newInstance();

        for (Map.Entry<String, Object> entry : fieldValues.entrySet()) {
            setField(instance, entry.getKey(), entry.getValue());
        }

        return instance;
    }

    /**
     * Définit la valeur d'un champ privé via réflexion.
     *
     * @param target l'objet cible
     * @param fieldName le nom du champ
     * @param value la valeur à affecter
     * @throws Exception si le champ n'existe pas ou n'est pas accessible
     */
    public static void setField(Object target, String fieldName, Object value) throws Exception {
        Field field = getField(target.getClass(), fieldName);
        field.setAccessible(true);
        field.set(target, value);
    }

    /**
     * Convertit un objet DTO en chaîne JSON.
     *
     * @param dto l'objet à convertir
     * @return la représentation JSON de l'objet
     * @throws Exception si la sérialisation échoue
     */
    public static String toJson(Object dto) throws Exception {
        ObjectMapper objectMapper = new ObjectMapper();
        return objectMapper.writeValueAsString(dto);
    }

    /**
     * Trouve un champ dans la classe ou ses superclasses.
     *
     * @param clazz la classe à examiner
     * @param fieldName le nom du champ
     * @return le Field trouvé
     * @throws NoSuchFieldException si le champ n'est pas trouvé
     */
    private static Field getField(Class<?> clazz, String fieldName) throws NoSuchFieldException {
        try {
            return clazz.getDeclaredField(fieldName);
        } catch (NoSuchFieldException e) {
            Class<?> superClass = clazz.getSuperclass();
            if (superClass != null) {
                return getField(superClass, fieldName);
            }
            throw e;
        }
    }
}