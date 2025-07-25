package fr.naavi.identity.service;

import fr.naavi.core.abstraction.BaseMailer;
import fr.naavi.identity.entity.ResetPasswordRequest;
import fr.naavi.identity.entity.User;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.mail.SimpleMailMessage;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.stereotype.Service;

@Service
public class MailerService extends BaseMailer {

    /**
     * Constructs for MailerService.
     */
    @Autowired
    public MailerService(JavaMailSender mailSender) {
        super(mailSender);
    }

    /**
     * Sends a registration email to the user.
     * This email is sent after a user successfully registers.
     *
     * @param user the user to whom the registration email will be sent
     */
    public void sendRegistrationEmail(User user) {
        SimpleMailMessage mailMessage = new SimpleMailMessage();

        mailMessage.setTo(user.getEmail());
        mailMessage.setSubject("Welcome to Naavi");
        mailMessage.setText("Thank you for registering, " + user.getFullName() + "!");

        this.sendEmail(mailMessage);
    }

    /**
     * Sends a password-reset email to the user.
     * This email is sent when a user requests a password reset.
     *
     * @param resetPasswordRequest the request containing user information for password reset
     */
    public void sendForgotPasswordEmail(ResetPasswordRequest resetPasswordRequest) {
        SimpleMailMessage mailMessage = new SimpleMailMessage();

        mailMessage.setTo(resetPasswordRequest.getUser().getEmail());
        mailMessage.setSubject("Password Reset Request");
        mailMessage.setText("Hello " + resetPasswordRequest.getUser().getFullName()
                + ",\n\n"
                + "We received a request to reset your password. If you did not make this request, please ignore this email.\n\n"
                + "To reset your password, please click the link below:\n"
                + "http://naavi-trails.fr/reset-password?token=" + resetPasswordRequest.getToken()
                + "\n\n"
                + "Thank you,\nNaavi Team"
        );

        this.sendEmail(mailMessage);
    }

    /**
     * Sends a confirmation email after the password has been successfully reset.
     * This email is sent to inform the user that their password has been changed.
     *
     * @param user the user whose password has been reset
     */
    public void sendResetPasswordConfirmationEmail(User user) {
        SimpleMailMessage mailMessage = new SimpleMailMessage();

        mailMessage.setTo(user.getEmail());
        mailMessage.setSubject("Password Reset Confirmation");
        mailMessage.setText("Hello " + user.getFullName()
                + ",\n\n"
                + "Your password has been successfully reset. If you did not make this change, please contact support immediately.\n\n"
                + "Thank you,\nNaavi Team"
        );

        this.sendEmail(mailMessage);
    }
}
