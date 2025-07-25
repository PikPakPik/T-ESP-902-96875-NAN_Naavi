package fr.naavi.identity.service;

import org.springframework.stereotype.Service;

@Service
public class RandomService {
    private static final String LETTERS_LOWER = "abcdefghijklmnopqrstuvwxyz";
    private static final String LETTERS_UPPER = "ABCDEFGHIJKLMNOPQRSTUVWXYZ";
    private static final String NUMBERS = "0123456789";
    private static final String SPECIAL_CHARS = "!\"#$%&'()*+,-./:;<=>?@[\\]^_`{|}~";

    /**
     * Generates a random string of the specified length containing lowercase letters.
     *
     * @param length the length of the string to generate
     * @return a random string of lowercase letters
     */
    public String randomString(int length) {
        return generate(length, LETTERS_LOWER + LETTERS_UPPER + NUMBERS);
    }

    /**
     * Generates a random string of the specified length containing only uppercase letters.
     *
     * @param length the length of the string to generate
     * @return a random string of uppercase letters
     */
    public String randomNumber(int length) {
        return generate(length, NUMBERS);
    }

    /**
     * Generates a random string of the specified length containing lowercase letters, uppercase letters, numbers, and special characters.
     *
     * @param length the length of the string to generate
     * @return a random string with lowercase letters, uppercase letters, numbers, and special characters
     */
    public String randomStringWithSpecialChar(int length) {
        return generate(length, LETTERS_LOWER + LETTERS_UPPER + NUMBERS + SPECIAL_CHARS);
    }

    /**
     * Generates a random string of the specified length containing only lowercase letters.
     *
     * @param length the length of the string to generate
     * @return a random string of lowercase letters
     */
    private String generate(int length, String characters) {
        if (length <= 0) {
            throw new IllegalArgumentException("La longueur doit être positive");
        }

        StringBuilder result = new StringBuilder(length);
        int charactersLength = characters.length();

        for (int i = 0; i < length; i++) {
            int randomIndex = (int) (Math.random() * charactersLength);
            result.append(characters.charAt(randomIndex));
        }

        return result.toString();
    }
}
