package fr.naavi.hike.service;

import fr.naavi.hike.enums.JwtEnum;
import io.jsonwebtoken.Claims;
import io.jsonwebtoken.JwtBuilder;
import io.jsonwebtoken.Jwts;
import org.bouncycastle.asn1.pkcs.PrivateKeyInfo;
import org.bouncycastle.jce.provider.BouncyCastleProvider;
import org.bouncycastle.openssl.PEMDecryptorProvider;
import org.bouncycastle.openssl.PEMEncryptedKeyPair;
import org.bouncycastle.openssl.PEMKeyPair;
import org.bouncycastle.openssl.PEMParser;
import org.bouncycastle.openssl.jcajce.JcaPEMKeyConverter;
import org.bouncycastle.openssl.jcajce.JceOpenSSLPKCS8DecryptorProviderBuilder;
import org.bouncycastle.openssl.jcajce.JcePEMDecryptorProviderBuilder;
import org.bouncycastle.operator.InputDecryptorProvider;
import org.bouncycastle.pkcs.PKCS8EncryptedPrivateKeyInfo;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import java.io.FileReader;
import java.nio.file.Files;
import java.nio.file.Paths;
import java.security.KeyFactory;
import java.security.KeyPair;
import java.security.PrivateKey;
import java.security.PublicKey;
import java.security.Security;
import java.security.spec.X509EncodedKeySpec;
import java.util.Base64;

@Service
public class JwtService {
    @Value("${jwt.default.public}")
    private String defaultPublicKeyPath;

    @Value("${jwt.default.private}")
    private String defaultPrivateKeyPath;

    @Value("${jwt.default.password}")
    private String defaultPassword;

    @Value("${jwt.exchange.public}")
    private String exchangePublicKeyPath;

    @Value("${jwt.exchange.private}")
    private String exchangePrivateKeyPath;

    @Value("${jwt.exchange.password}")
    private String exchangePassword;

    static {
        Security.addProvider(new BouncyCastleProvider());
    }

    private String getPrivateKeyPath(JwtEnum type) {
        return switch (type) {
            case EXCHANGE -> exchangePrivateKeyPath;
            default -> defaultPrivateKeyPath;
        };
    }

    private String getPublicKeyPath(JwtEnum type) {
        return switch (type) {
            case EXCHANGE -> exchangePublicKeyPath;
            default -> defaultPublicKeyPath;
        };
    }

    private String getPassword(JwtEnum type) {
        return switch (type) {
            case EXCHANGE -> exchangePassword;
            default -> defaultPassword;
        };
    }

    private PrivateKey loadPrivateKey(JwtEnum type) throws Exception {
        String keyPath = getPrivateKeyPath(type);
        String password = getPassword(type);

        try (PEMParser pemParser = new PEMParser(new FileReader(keyPath))) {
            Object object = pemParser.readObject();

            if (object instanceof PEMEncryptedKeyPair) {
                PEMEncryptedKeyPair encryptedKeyPair = (PEMEncryptedKeyPair) object;
                PEMDecryptorProvider decryptorProvider = new JcePEMDecryptorProviderBuilder()
                        .build(password.toCharArray());
                PEMKeyPair keyPair = encryptedKeyPair.decryptKeyPair(decryptorProvider);
                KeyPair kp = new JcaPEMKeyConverter().getKeyPair(keyPair);
                return kp.getPrivate();
            } else if (object instanceof PEMKeyPair) {
                PEMKeyPair keyPair = (PEMKeyPair) object;
                KeyPair kp = new JcaPEMKeyConverter().getKeyPair(keyPair);
                return kp.getPrivate();
            } else if (object instanceof PKCS8EncryptedPrivateKeyInfo) {
                PKCS8EncryptedPrivateKeyInfo encryptedPrivateKeyInfo = (PKCS8EncryptedPrivateKeyInfo) object;
                InputDecryptorProvider decryptorProvider = new JceOpenSSLPKCS8DecryptorProviderBuilder()
                        .build(password.toCharArray());
                PrivateKeyInfo privateKeyInfo = encryptedPrivateKeyInfo.decryptPrivateKeyInfo(decryptorProvider);
                return new JcaPEMKeyConverter().getPrivateKey(privateKeyInfo);
            } else {
                throw new IllegalArgumentException("Format de clé privée non supporté: " + object.getClass().getName());
            }
        }
    }

    private PublicKey loadPublicKey(JwtEnum type) throws Exception {
        String publicKeyContent = Files.readString(Paths.get(getPublicKeyPath(type)))
                .replace("-----BEGIN PUBLIC KEY-----", "")
                .replace("-----END PUBLIC KEY-----", "")
                .replaceAll("\\s", "");

        byte[] keyBytes = Base64.getDecoder().decode(publicKeyContent);
        X509EncodedKeySpec spec = new X509EncodedKeySpec(keyBytes);
        KeyFactory keyFactory = KeyFactory.getInstance("RSA");
        return keyFactory.generatePublic(spec);
    }

    /**
     * Sign a JWT with the default private key.
     *
     * @param jwtBuilder the JwtBuilder to sign
     * @return the signed JWT as a String, or null if an error occurs
     */
    public String signJwt(JwtBuilder jwtBuilder) {
        try {
            PrivateKey key = loadPrivateKey(JwtEnum.DEFAULT);
            return jwtBuilder
                    .issuer("identity")
                    .signWith(key, Jwts.SIG.RS256)
                    .compact();
        } catch (Exception e) {
            return null;
        }
    }

    /**
     * Sign a JWT with a specified private key type.
     *
     * @param jwtBuilder the JwtBuilder to sign
     * @param type the type of JWT to sign
     * @return the signed JWT as a String, or null if an error occurs
     */
    public String signJwt(JwtBuilder jwtBuilder, JwtEnum type) {
        try {
            PrivateKey key = loadPrivateKey(type);
            return jwtBuilder
                    .issuer("identity")
                    .signWith(key, Jwts.SIG.RS256)
                    .compact();
        } catch (Exception e) {
            return null;
        }
    }

    /**
     * Verify a JWT using the default public key.
     *
     * @param token the JWT to verify
     * @return the Claims contained in the JWT, or null if verification fails
     */
    public Claims verifyJwt(String token) {
        try {
            PublicKey key = loadPublicKey(JwtEnum.DEFAULT);
            return Jwts.parser()
                    .verifyWith(key)
                    .build()
                    .parseSignedClaims(token)
                    .getPayload();
        } catch (Exception e) {
            return null;
        }
    }

    /**
     * Verify a JWT using a specified public key type.
     *
     * @param token the JWT to verify
     * @param type the type of JWT to verify
     * @return the Claims contained in the JWT, or null if verification fails
     */
    public Claims verifyJwt(String token, JwtEnum type) {
        try {
            PublicKey key = loadPublicKey(type);
            return Jwts.parser()
                    .verifyWith(key)
                    .build()
                    .parseSignedClaims(token)
                    .getPayload();
        } catch (Exception e) {
            return null;
        }
    }
}
