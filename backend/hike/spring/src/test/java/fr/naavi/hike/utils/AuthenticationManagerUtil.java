package fr.naavi.hike.utils;

import fr.naavi.hike.dto.UserDTO;
import org.mockito.ArgumentMatchers;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.authority.SimpleGrantedAuthority;

import java.util.List;

import static org.mockito.Mockito.when;

public class AuthenticationManagerUtil {
    public static UsernamePasswordAuthenticationToken mockAuthenticationManager(
            AuthenticationManager authenticationManager,
            UserDTO user
    ) {
        List<SimpleGrantedAuthority> authorities = user.getRoles().stream()
                .map(Enum::name)
                .map(SimpleGrantedAuthority::new)
                .toList();

        UsernamePasswordAuthenticationToken authToken = new UsernamePasswordAuthenticationToken(
                user,
                null,
                authorities
        );

        when(authenticationManager.authenticate(ArgumentMatchers.any())).thenReturn(authToken);

        return authToken;
    }
}
