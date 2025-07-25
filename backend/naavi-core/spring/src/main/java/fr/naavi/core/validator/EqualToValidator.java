package fr.naavi.core.validator;

import jakarta.validation.ConstraintValidator;
import jakarta.validation.ConstraintValidatorContext;
import org.springframework.beans.BeanWrapper;
import org.springframework.beans.BeanWrapperImpl;

public class EqualToValidator implements ConstraintValidator<EqualTo, Object> {
    private String sourceProperty;
    private String targetProperty;

    @Override
    public void initialize(EqualTo constraintAnnotation) {
        this.sourceProperty = constraintAnnotation.sourceProperty();
        this.targetProperty = constraintAnnotation.targetProperty();

        if (sourceProperty == null || sourceProperty.isEmpty()) {
            throw new IllegalArgumentException("Source property must not be null or empty");
        }

        if (targetProperty == null || targetProperty.isEmpty()) {
            throw new IllegalArgumentException("Target property must not be null or empty");
        }

        if (sourceProperty.equals(targetProperty)) {
            throw new IllegalArgumentException("Source and target properties must not be the same");
        }
    }

    @Override
    public boolean isValid(Object obj, ConstraintValidatorContext constraintValidatorContext) {
        BeanWrapper beanWrapper = new BeanWrapperImpl(obj);

        Object sourceValue = beanWrapper.getPropertyValue(sourceProperty);
        Object targetValue = beanWrapper.getPropertyValue(targetProperty);

        if (sourceValue == null && targetValue == null) {
            return true;
        }

        boolean isValid = sourceValue != null && sourceValue.equals(targetValue);

        if (!isValid) {
            constraintValidatorContext.disableDefaultConstraintViolation();

            String customMessage = String.format("must be equal to %s", targetProperty);
            constraintValidatorContext
                    .buildConstraintViolationWithTemplate(customMessage)
                    .addPropertyNode(sourceProperty)
                    .addConstraintViolation();
        }

        return isValid;
    }
}
