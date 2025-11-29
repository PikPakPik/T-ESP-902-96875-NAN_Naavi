package fr.naavi.core.abstraction;

import fr.naavi.core.properties.SmtpProperties;
import jakarta.mail.MessagingException;
import jakarta.mail.internet.MimeMessage;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.mail.MailException;
import org.springframework.mail.SimpleMailMessage;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.mail.javamail.MimeMessagePreparator;

public class BaseMailer {
    private static final Logger logger = LoggerFactory.getLogger(BaseMailer.class);

    @Autowired
    protected JavaMailSender mailSender;

    @Autowired
    protected SmtpProperties smtpProperties;

    /**
     * Sends an email using the provided message.
     */
    protected <T> void sendEmail(T message) {
        try {
            if (smtpProperties.getFrom() != null && !smtpProperties.getFrom().trim().isEmpty()) {
                switch (message) {
                    case SimpleMailMessage simpleMessage -> simpleMessage.setFrom(smtpProperties.getFrom());
                    case MimeMessage mimeMessage -> mimeMessage.setFrom(smtpProperties.getFrom());
                    default -> throw new IllegalArgumentException("Message type not supported: " + message.getClass().getName());
                }
            }

            switch (message) {
                case SimpleMailMessage simpleMessage -> this.mailSender.send(simpleMessage);
                case MimeMessage mimeMessage -> this.mailSender.send(mimeMessage);
                case MimeMessagePreparator preparator -> this.mailSender.send(preparator);
                default -> throw new IllegalArgumentException("Message type not supported: " + message.getClass().getName());
            }
        } catch (MailException | MessagingException e) {
            logger.error("Error sending email: {}", e.getMessage());
        }
    }
}
