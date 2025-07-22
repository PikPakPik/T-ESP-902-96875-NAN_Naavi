package fr.naavi.core.abstraction;

import jakarta.mail.internet.MimeMessage;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.mail.MailException;
import org.springframework.mail.SimpleMailMessage;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.mail.javamail.MimeMessagePreparator;

public class BaseMailer {
    private final JavaMailSender mailSender;
    private static final Logger logger = LoggerFactory.getLogger(BaseMailer.class);

    /**
     * Constructs for MailerService.
     */
    public BaseMailer(JavaMailSender mailSender) {
        this.mailSender = mailSender;
    }

    /**
     * Sends an email using the provided message.
     */
    protected <T> void sendEmail(T message) {
        try {
            switch (message) {
                case SimpleMailMessage simpleMessage -> this.mailSender.send(simpleMessage);
                case MimeMessage mimeMessage -> this.mailSender.send(mimeMessage);
                case MimeMessagePreparator preparator -> this.mailSender.send(preparator);
                default ->
                        throw new IllegalArgumentException("Message type not supported: " + message.getClass().getName());
            }
        } catch (MailException e) {
            logger.error("Error sending email", e);
        }
    }
}
