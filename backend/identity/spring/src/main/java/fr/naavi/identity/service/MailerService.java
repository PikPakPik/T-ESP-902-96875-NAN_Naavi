package fr.naavi.identity.service;

import fr.naavi.core.abstraction.BaseMailer;
import fr.naavi.identity.entity.ResetPasswordRequest;
import fr.naavi.identity.entity.User;
import jakarta.mail.MessagingException;
import jakarta.mail.internet.MimeMessage;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.mail.javamail.MimeMessageHelper;
import org.springframework.stereotype.Service;
import org.thymeleaf.context.Context;
import org.thymeleaf.spring6.SpringTemplateEngine;

@Service
public class MailerService extends BaseMailer {
    private static final Logger logger = LoggerFactory.getLogger(MailerService.class);

    @Autowired
    private SpringTemplateEngine templateEngine;

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
}
