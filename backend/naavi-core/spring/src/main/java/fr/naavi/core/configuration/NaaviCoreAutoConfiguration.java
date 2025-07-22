package fr.naavi.core.configuration;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.autoconfigure.AutoConfiguration;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.ComponentScan;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.mail.javamail.JavaMailSenderImpl;

import java.util.Properties;

/**
 * Auto-configuration class for the Naavi Core module.
 *
 * <p>This configuration class automatically scans the "fr.naavi.core" package
 * for Spring components and configures necessary beans.</p>
 *
 * <p>Currently, it provides configuration for JavaMailSender using properties
 * prefixed with {@code spring.mail} to setup email sending capabilities.</p>
 */
@AutoConfiguration
@ComponentScan(basePackages = "fr.naavi.core")
public class NaaviCoreAutoConfiguration {
    // TODO: Add any necessary beans or configurations specific to Naavi Core

    //<editor-fold desc="email">
    @Value("${spring.mail.host}")
    private String mailHost;

    @Value("${spring.mail.port}")
    private int mailPort;

    @Value("${spring.mail.username}")
    private String mailUsername;

    @Value("${spring.mail.password}")
    private String mailPassword;

    @Value("${spring.mail.properties.mail.smtp.auth}")
    private boolean smtpAuth;

    @Value("${spring.mail.properties.mail.transport.protocol}")
    private String transportProtocol;

    @Value("${spring.mail.properties.mail.smtp.ssl.enable}")
    private boolean sslEnable;

    @Value("${spring.mail.properties.mail.smtp.starttls.enable}")
    private boolean starttlsEnable;

    /**
     * Creates and configures a {@link JavaMailSender} bean with
     * the specified mail server settings.
     *
     * @return a configured {@code JavaMailSender} instance.
     */
    @Bean
    public JavaMailSender javaMailSender() {
        JavaMailSenderImpl mailSender = new JavaMailSenderImpl();
        mailSender.setDefaultEncoding("UTF-8");
        mailSender.setHost(mailHost);
        mailSender.setPort(mailPort);
        mailSender.setUsername(mailUsername);
        mailSender.setPassword(mailPassword);

        Properties props = mailSender.getJavaMailProperties();
        props.put("mail.transport.protocol", transportProtocol);
        props.put("mail.smtp.auth", smtpAuth);
        props.put("mail.smtp.ssl.enable", sslEnable);
        props.put("mail.smtp.starttls.enable", starttlsEnable);

        return mailSender;
    }
    //<editor-fold>
}