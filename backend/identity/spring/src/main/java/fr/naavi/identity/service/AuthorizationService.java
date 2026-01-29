package fr.naavi.identity.service;

import fr.naavi.core.service.RandomService;
import fr.naavi.identity.dto.input.UserDTO;
import fr.naavi.identity.entity.Authorization;
import fr.naavi.identity.entity.User;
import fr.naavi.identity.enums.AuthorizationTypeEnum;
import fr.naavi.identity.enums.StatusEnum;
import fr.naavi.identity.repository.AuthorizationRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.util.Optional;

@Service
public class AuthorizationService {
    private static final Logger logger = LoggerFactory.getLogger(AuthorizationService.class);
    private final AuthorizationRepository authorizationRepository;
    private final RandomService randomService;
    private final UserService userService;
    private final MailerService mailerService;

    /**
     * Constructs a UserService
     */
    @Autowired
    public AuthorizationService(
            AuthorizationRepository authorizationRepository,
            RandomService randomService,
            UserService userService,
            MailerService mailerService
    ) {
        this.authorizationRepository = authorizationRepository;
        this.randomService = randomService;
        this.userService = userService;
        this.mailerService = mailerService;
    }

    /**
     * Create an authorization for registration
     *
     * @param user The user
     * @return The created authorization
     */
    public Authorization createAuthorizationForRegistration(User user) {
        Authorization authorization = new Authorization();

        authorization.setUser(user);
        authorization.setType(AuthorizationTypeEnum.REGISTRATION);
        authorization.setToken(this.randomService.randomString(32));

        return this.authorizationRepository.save(authorization);
    }

    /**
     * Create an authorization for update email
     *
     * @param user The user
     * @param userDto The user DTO
     * @return The created authorization
     */
    public Authorization createAuthorizationForUpdateOldEmail(User user, UserDTO userDto) {
        Authorization authorization = new Authorization();

        authorization.setUser(user);
        authorization.setType(AuthorizationTypeEnum.CHANGE_OLD_EMAIL);
        authorization.setNewValue(userDto.getEmail());
        authorization.setOldValue(user.getEmail());
        authorization.setToken(this.randomService.randomString(32));

        return this.authorizationRepository.save(authorization);
    }

    /**
     * Create an authorization for update email
     *
     * @param authorization The authorization
     * @return The created authorization
     */
    public Authorization createAuthorizationForUpdateNewEmail(Authorization authorization) {
        Authorization newAuthorization = new Authorization();

        newAuthorization.setUser(authorization.getUser());
        newAuthorization.setType(AuthorizationTypeEnum.CHANGE_NEW_EMAIL);
        newAuthorization.setNewValue(authorization.getNewValue());
        newAuthorization.setOldValue(authorization.getOldValue());
        newAuthorization.setToken(this.randomService.randomString(32));

        return this.authorizationRepository.save(newAuthorization);
    }

    /**
     * Check if an authorization request exists
     *
     * @param token The token
     * @return The authorization if exists, null otherwise
     */
    public Authorization checkIfAuthorizationRequestExists(String token) {
        Optional<Authorization> authorization = this.authorizationRepository.findByToken(token);

        if (authorization.isEmpty()) {
            return null;
        }

        Authorization request = authorization.get();

        if (request.getExpiredAt().isBefore(LocalDateTime.now())) {
            this.authorizationRepository.delete(request);
            return null;
        }

        return request;
    }

    /**
     * Process an authorization
     *
     * @param authorization The authorization
     */
    public void processAuthorization(Authorization authorization) {
        switch (authorization.getType()) {
            case AuthorizationTypeEnum.REGISTRATION:
                this.userService.updateStatus(authorization.getUser(), StatusEnum.VERIFIED);
                break;
            case AuthorizationTypeEnum.CHANGE_OLD_EMAIL:
                Authorization newAuthorization = this.createAuthorizationForUpdateNewEmail(authorization);
                this.mailerService.sendEmailChangeNewEmailConfirmation(newAuthorization);
                break;
            case AuthorizationTypeEnum.CHANGE_NEW_EMAIL:
                this.userService.updateEmail(authorization.getUser(), authorization.getNewValue());
                break;
            default:
                logger.warn("Unknown authorization type {} for authorization id {}", authorization.getType(), authorization.getId());
                break;
        }

        this.authorizationRepository.delete(authorization);
    }
}
