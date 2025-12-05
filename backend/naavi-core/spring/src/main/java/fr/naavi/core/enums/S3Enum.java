package fr.naavi.core.enums;

import java.util.Locale;

public enum S3Enum {
    HIKES,
    POINTS_OF_INTEREST,
    USERS,
    SIGNALEMENTS;

    @Override
    public String toString() {
        return this.name().toLowerCase(Locale.ROOT);
    }
}
