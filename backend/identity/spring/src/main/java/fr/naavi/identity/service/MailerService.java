package fr.naavi.identity.service;

import fr.naavi.core.abstraction.BaseMailer;
import fr.naavi.identity.entity.Authorization;
import fr.naavi.identity.entity.ResetPasswordRequest;
import fr.naavi.identity.entity.User;
import jakarta.mail.MessagingException;
import jakarta.mail.internet.MimeMessage;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.mail.javamail.MimeMessageHelper;
import org.springframework.stereotype.Service;
import org.thymeleaf.context.Context;
import org.thymeleaf.spring6.SpringTemplateEngine;

@Service
public class MailerService extends BaseMailer {
    private static final Logger logger = LoggerFactory.getLogger(MailerService.class);

    @Autowired
    private SpringTemplateEngine templateEngine;

    @Value("${naavi.frontend.url:https://naavi-trails.fr}")
    private String frontendUrl;

    /**
     * Sends a registration email to the user.
     * This email is sent after a user successfully registers.
     *
     * @param user the user to whom the registration email will be sent
     */
    public void sendRegistrationEmail(User user) {
        sendRegistrationEmail(user, false);
    }

    /**
     * Sends a registration email to the user.
     * This email is sent after a user successfully registers.
     *
     * @param user the user to whom the registration email will be sent
     * @param createdByAdmin whether the user was created by an admin
     */
    public void sendRegistrationEmail(User user, boolean createdByAdmin) {
        try {
            MimeMessage mimeMessage = mailSender.createMimeMessage();
            MimeMessageHelper helper = new MimeMessageHelper(mimeMessage, "utf-8");

            Context context = new Context();
            context.setVariable("fullName", user.getFullName());
            context.setVariable("createdByAdmin", createdByAdmin);

            String htmlContent = templateEngine.process("registration.html", context);

            helper.setTo(user.getEmail());
            helper.setSubject("Bienvenue sur Naavi");
            helper.setText(htmlContent, true);

            this.sendEmail(mimeMessage);
        } catch (MessagingException e) {
            logger.info("Error while sending registration email to user {}", user.getEmail());
        }
    }

    /**
     * Sends a password-reset email to the user.
     * This email is sent when a user requests a password reset.
     *
     * @param resetPasswordRequest the request containing user information for password reset
     */
    public void sendForgotPasswordEmail(ResetPasswordRequest resetPasswordRequest) {
        try {
            MimeMessage mimeMessage = mailSender.createMimeMessage();
            MimeMessageHelper helper = new MimeMessageHelper(mimeMessage, "utf-8");

            Context context = new Context();
            context.setVariable("fullName", resetPasswordRequest.getUser().getFullName());
            context.setVariable("token", resetPasswordRequest.getToken());
            context.setVariable("frontendUrl", frontendUrl);

            String htmlContent = templateEngine.process("forgot-password.html", context);

            helper.setTo(resetPasswordRequest.getUser().getEmail());
            helper.setSubject("Demande de réinitialisation du mot de passe");
            helper.setText(htmlContent, true);

            this.sendEmail(mimeMessage);
        } catch (MessagingException e) {
            logger.info(
                    "Error while sending forgot password email to user {}",
                    resetPasswordRequest.getUser().getEmail()
            );
        }
    }

    /**
     * Sends a confirmation email after the password has been successfully reset.
     * This email is sent to inform the user that their password has been changed.
     *
     * @param user the user whose password has been reset
     */
    public void sendResetPasswordConfirmationEmail(User user) {
        try {
            MimeMessage mimeMessage = mailSender.createMimeMessage();
            MimeMessageHelper helper = new MimeMessageHelper(mimeMessage, "utf-8");

            Context context = new Context();
            context.setVariable("fullName", user.getFullName());

            String htmlContent = templateEngine.process("reset-password.html", context);

            helper.setTo(user.getEmail());
            helper.setSubject("Confirmation de réinitialisation du mot de passe");
            helper.setText(htmlContent, true);

            this.sendEmail(mimeMessage);
        } catch (MessagingException e) {
            logger.info("Error while sending reset password confirmation email to user {}", user.getEmail());
        }
    }

    /**
     * Sends an email confirmation email to the user.
     * This email is sent after a user registers to confirm their email address.
     *
     * @param authorization the authorization containing user information and token for email confirmation
     */
    public void sendEmailConfirmationEmail(Authorization authorization) {
        try {
            MimeMessage mimeMessage = mailSender.createMimeMessage();
            MimeMessageHelper helper = new MimeMessageHelper(mimeMessage, "utf-8");

            Context context = new Context();
            context.setVariable("fullName", authorization.getUser().getFullName());
            context.setVariable("token", authorization.getToken());
            context.setVariable("frontendUrl", frontendUrl);

            String htmlContent = templateEngine.process("email-confirmation.html", context);

            helper.setTo(authorization.getUser().getEmail());
            helper.setSubject("Confirmez votre adresse email - Naavi Trails");
            helper.setText(htmlContent, true);

            this.sendEmail(mimeMessage);
        } catch (MessagingException e) {
            logger.info(
                    "Error while sending email confirmation email to user {}",
                    authorization.getUser().getEmail()
            );
        }
    }

    /**
     * Sends an email change confirmation email to the old email address.
     * This email is sent when a user requests to change their email address.
     *
     * @param authorization the authorization containing user information and token for email change confirmation.
     */
    public void sendEmailChangeOldEmailConfirmation(Authorization authorization) {
        try {
            MimeMessage mimeMessage = mailSender.createMimeMessage();
            MimeMessageHelper helper = new MimeMessageHelper(mimeMessage, "utf-8");

            Context context = new Context();
            context.setVariable("fullName", authorization.getUser().getFullName());
            context.setVariable("token", authorization.getToken());
            context.setVariable("newEmail", authorization.getNewValue());
            context.setVariable("frontendUrl", frontendUrl);

            String htmlContent = templateEngine.process("email-change-old.html", context);

            helper.setTo(authorization.getUser().getEmail());
            helper.setSubject("Confirmation de changement d'adresse email - Naavi Trails");
            helper.setText(htmlContent, true);

            this.sendEmail(mimeMessage);
        } catch (MessagingException e) {
            logger.info(
                    "Error while sending email change confirmation to old email {}",
                    authorization.getUser().getEmail()
            );
        }
    }

    /**
     * Sends an email change confirmation email to the new email address.
     * This email is sent when a user requests to change their email address.
     *
     * @param authorization the authorization containing user information and token for email change confirmation.
     */
    public void sendEmailChangeNewEmailConfirmation(Authorization authorization) {
        try {
            MimeMessage mimeMessage = mailSender.createMimeMessage();
            MimeMessageHelper helper = new MimeMessageHelper(mimeMessage, "utf-8");

            Context context = new Context();
            context.setVariable("fullName", authorization.getUser().getFullName());
            context.setVariable("token", authorization.getToken());
            context.setVariable("oldEmail", authorization.getOldValue());
            context.setVariable("email", authorization.getNewValue());
            context.setVariable("frontendUrl", frontendUrl);

            String htmlContent = templateEngine.process("email-change-new.html", context);

            helper.setTo(authorization.getNewValue());
            helper.setSubject("Confirmez votre nouvelle adresse email - Naavi Trails");
            helper.setText(htmlContent, true);

            this.sendEmail(mimeMessage);
        } catch (MessagingException e) {
            logger.info(
                    "Error while sending email change confirmation to new email {}",
                    authorization.getNewValue()
            );
        }
    }
}
