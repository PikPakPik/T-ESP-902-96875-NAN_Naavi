package fr.naavi.identity.util;

import fr.naavi.identity.dto.output.AuthenticationDTO;
import fr.naavi.identity.entity.Session;
import fr.naavi.identity.entity.User;
import fr.naavi.identity.repository.SessionRepository;
import fr.naavi.identity.seeder.UserSeeder;
import org.mockito.ArgumentMatchers;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.authority.SimpleGrantedAuthority;

import java.time.LocalDateTime;
import java.util.List;

import static org.mockito.Mockito.when;

public class AuthenticationManagerUtil {
    public static final String ACCESS_TOKEN = "fake-access-token";
    public static final String REFRESH_TOKEN = "fake-refresh-token";

    public static Session mockAuthenticationManager(
            AuthenticationManager authenticationManager,
            SessionRepository sessionRepository,
            User user
    ) {
        AuthenticationDTO authDTO = new AuthenticationDTO(ACCESS_TOKEN, REFRESH_TOKEN);

        List<SimpleGrantedAuthority> authorities = user.getRoles().stream()
                .map(Enum::name)
                .map(SimpleGrantedAuthority::new)
                .toList();

        UsernamePasswordAuthenticationToken authToken = new UsernamePasswordAuthenticationToken(
                user,
                UserSeeder.USER_DEFAULT_PASSWORD,
                authorities
        );
        authToken.setDetails(authDTO);

        Session session = new Session();
        session.setUser(user);
        session.setAccessToken(ACCESS_TOKEN);
        session.setRefreshToken(REFRESH_TOKEN);
        session.setClientIp("127.0.0.1");
        session.setUserAgent("JUnit");
        LocalDateTime now = LocalDateTime.now();
        session.setCreatedAt(now);
        session.setAccessTokenExpiredAt(now.plusDays(1));
        session.setRefreshTokenExpiredAt(now.plusDays(7));

        sessionRepository.save(session);

        when(authenticationManager.authenticate(ArgumentMatchers.any())).thenReturn(authToken);

        return session;
    }

    public static UsernamePasswordAuthenticationToken mockAuthenticationManager(
            AuthenticationManager authenticationManager,
            User user
    ) {
        AuthenticationDTO authDTO = new AuthenticationDTO(ACCESS_TOKEN, REFRESH_TOKEN);

        List<SimpleGrantedAuthority> authorities = user.getRoles().stream()
                .map(Enum::name)
                .map(SimpleGrantedAuthority::new)
                .toList();

        UsernamePasswordAuthenticationToken authToken = new UsernamePasswordAuthenticationToken(
                user,
                UserSeeder.USER_DEFAULT_PASSWORD,
                authorities
        );
        authToken.setDetails(authDTO);

        when(authenticationManager.authenticate(ArgumentMatchers.any())).thenReturn(authToken);

        return authToken;
    }
}
