package fr.naavi.identity.service;

import io.jsonwebtoken.Claims;
import io.jsonwebtoken.JwtBuilder;
import io.jsonwebtoken.JwtException;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.security.Keys;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import javax.crypto.SecretKey;

@Service
public class JwtService {
    @Value("${jwt.passphrase}")
    private String passphrase;

    /**
     * Signs a JWT using the provided JwtBuilder and the configured passphrase.
     *
     * @param jwtBuilder the JwtBuilder to use for creating the JWT
     * @return the signed JWT as a String
     */
    public String signJwt(JwtBuilder jwtBuilder) {
        return jwtBuilder
                .issuer("identity")
                .signWith(this.getSecretKey())
                .compact();
    }

    /**
     * Verifies a JWT token and returns the claims contained within it.
     *
     * @param token the JWT token to verify
     * @return the claims contained in the JWT
     */
    public Claims verifyJwt(String token) throws JwtException, IllegalArgumentException {
        return Jwts.parser()
                .verifyWith(this.getSecretKey())
                .build()
                .parseSignedClaims(token)
                .getPayload();
    }

    /**
     * Generates a SecretKey from the configured passphrase.
     *
     * @return a JwtBuilder ready to be signed
     */
    private SecretKey getSecretKey() {
       return Keys.hmacShaKeyFor(passphrase.getBytes());
    }
}
