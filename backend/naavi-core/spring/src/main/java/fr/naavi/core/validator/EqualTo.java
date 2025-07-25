package fr.naavi.core.validator;

import jakarta.validation.Constraint;
import jakarta.validation.Payload;

import java.lang.annotation.*;

@Target({ElementType.TYPE})
@Retention(RetentionPolicy.RUNTIME)
@Constraint(validatedBy = EqualToValidator.class)
@Repeatable(EqualTo.List.class)
@Documented
public @interface EqualTo {
    /**
     * @return the error message
     */
    String message() default "must be equal to {targetProperty}";

    /**
     * @return the validation groups
     */
    Class<?>[] groups() default {};

    /**
     * @return the payload
     */
    Class<? extends Payload>[] payload() default {};

    /**
     * @return the source property
     */
    String sourceProperty();

    /**
     * @return the target property
     */
    String targetProperty();

    @Target({ElementType.TYPE})
    @Retention(RetentionPolicy.RUNTIME)
    @Documented
    @interface List {
        /**
         * @return the array of EqualTo annotations
         */
        EqualTo[] value();
    }
}
