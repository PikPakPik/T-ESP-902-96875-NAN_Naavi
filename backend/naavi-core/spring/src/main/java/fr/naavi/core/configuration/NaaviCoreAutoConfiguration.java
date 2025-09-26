package fr.naavi.core.configuration;

import fr.naavi.core.properties.SmtpProperties;
import org.springframework.boot.autoconfigure.AutoConfiguration;
import org.springframework.boot.context.properties.EnableConfigurationProperties;
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
@EnableConfigurationProperties(SmtpProperties.class)
public class NaaviCoreAutoConfiguration {
    /**
     * Creates and configures a {@link JavaMailSender} bean with
     * the specified mail server settings.
     *
     * @return a configured {@code JavaMailSender} instance.
     */
    @Bean
    public JavaMailSender javaMailSender(SmtpProperties smtpProps) {
        if (smtpProps.getHost() == null || smtpProps.getHost().trim().isEmpty() || smtpProps.getPort() == null) {
            return null;
        }
        JavaMailSenderImpl mailSender = new JavaMailSenderImpl();
        mailSender.setDefaultEncoding("UTF-8");
        mailSender.setHost(smtpProps.getHost());
        mailSender.setPort(smtpProps.getPort());
        mailSender.setUsername(smtpProps.getUsername());
        mailSender.setPassword(smtpProps.getPassword());

        Properties props = mailSender.getJavaMailProperties();
        if (smtpProps.getPropertiesMailTransportProtocol() != null) {
            props.put("mail.transport.protocol", smtpProps.getPropertiesMailTransportProtocol());
        }
        if (smtpProps.getPropertiesMailSmtpAuth() != null) {
            props.put("mail.smtp.auth", smtpProps.getPropertiesMailSmtpAuth());
        }
        if (smtpProps.getPropertiesMailSmtpSslEnable() != null) {
            props.put("mail.smtp.ssl.enable", smtpProps.getPropertiesMailSmtpSslEnable());
        }
        if (smtpProps.getPropertiesMailSmtpStarttlsEnable() != null) {
            props.put("mail.smtp.starttls.enable", smtpProps.getPropertiesMailSmtpStarttlsEnable());
        }

        return mailSender;
    }
    //<editor-fold>
}