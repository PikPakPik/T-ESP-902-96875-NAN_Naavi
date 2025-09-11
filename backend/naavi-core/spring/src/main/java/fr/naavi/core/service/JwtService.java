package fr.naavi.core.service;

import fr.naavi.core.enums.JwtEnum;
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
import org.bouncycastle.operator.OperatorCreationException;
import org.bouncycastle.pkcs.PKCS8EncryptedPrivateKeyInfo;
import org.bouncycastle.pkcs.PKCSException;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import java.io.FileReader;
import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Paths;
import java.security.KeyFactory;
import java.security.KeyPair;
import java.security.NoSuchAlgorithmException;
import java.security.PrivateKey;
import java.security.PublicKey;
import java.security.Security;
import java.security.spec.InvalidKeySpecException;
import java.security.spec.X509EncodedKeySpec;
import java.util.Base64;

@Service
public class JwtService {
    @Value("${jwt.issuer}")
    private String issuer;
    
    @Value("${jwt.default.public}")
    private String defaultPublicKeyPath;

    @Value("${jwt.default.private}")
    private String defaultPrivateKeyPath;

    @Value("${jwt.default.password}")
    private String defaultPassword;

    @Value("${jwt.auth.public}")
    private String authPublicKeyPath;

    @Value("${jwt.auth.private}")
    private String authPrivateKeyPath;

    @Value("${jwt.auth.password}")
    private String authPassword;

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
            case AUTH -> authPrivateKeyPath;
            case EXCHANGE -> exchangePrivateKeyPath;
            default -> defaultPrivateKeyPath;
        };
    }

    private String getPublicKeyPath(JwtEnum type) {
        return switch (type) {
            case AUTH -> authPublicKeyPath;
            case EXCHANGE -> exchangePublicKeyPath;
            default -> defaultPublicKeyPath;
        };
    }

    private String getPassword(JwtEnum type) {
        return switch (type) {
            case AUTH -> authPassword;
            case EXCHANGE -> exchangePassword;
            default -> defaultPassword;
        };
    }

    private PrivateKey loadPrivateKey(JwtEnum type) throws IOException, PKCSException, OperatorCreationException {
        String keyPath = getPrivateKeyPath(type);
        String password = getPassword(type);

        try (PEMParser pemParser = new PEMParser(new FileReader(keyPath, StandardCharsets.UTF_8))) {
            Object object = pemParser.readObject();

            if (object instanceof PEMEncryptedKeyPair encryptedKeyPair) {
                PEMDecryptorProvider decryptorProvider = new JcePEMDecryptorProviderBuilder()
                        .build(password.toCharArray());
                PEMKeyPair keyPair = encryptedKeyPair.decryptKeyPair(decryptorProvider);
                KeyPair kp = new JcaPEMKeyConverter().getKeyPair(keyPair);
                return kp.getPrivate();
            } else if (object instanceof PEMKeyPair keyPair) {
                KeyPair kp = new JcaPEMKeyConverter().getKeyPair(keyPair);
                return kp.getPrivate();
            } else if (object instanceof PKCS8EncryptedPrivateKeyInfo encryptedPrivateKeyInfo) {
                InputDecryptorProvider decryptorProvider = new JceOpenSSLPKCS8DecryptorProviderBuilder()
                        .build(password.toCharArray());
                PrivateKeyInfo privateKeyInfo = encryptedPrivateKeyInfo.decryptPrivateKeyInfo(decryptorProvider);
                return new JcaPEMKeyConverter().getPrivateKey(privateKeyInfo);
            } else {
                throw new IllegalArgumentException("Private key format not supported: " + object.getClass().getName());
            }
        }
    }

    private PublicKey loadPublicKey(JwtEnum type) throws InvalidKeySpecException, NoSuchAlgorithmException, IOException {
        String publicKeyContent = Files.readString(Paths.get(getPublicKeyPath(type)), StandardCharsets.UTF_8)
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
                    .issuer(this.issuer)
                    .signWith(key, Jwts.SIG.RS256)
                    .compact();
        } catch (IOException | PKCSException | OperatorCreationException e) {
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
                    .issuer(this.issuer)
                    .signWith(key, Jwts.SIG.RS256)
                    .compact();
        } catch (IOException | PKCSException | OperatorCreationException e) {
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
        } catch (InvalidKeySpecException | NoSuchAlgorithmException | IOException e) {
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
        } catch (InvalidKeySpecException | NoSuchAlgorithmException | IOException e) {
            return null;
        }
    }
}
