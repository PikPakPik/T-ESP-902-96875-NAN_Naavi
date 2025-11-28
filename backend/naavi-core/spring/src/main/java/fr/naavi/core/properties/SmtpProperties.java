package fr.naavi.core.properties;

import org.springframework.boot.context.properties.ConfigurationProperties;

@ConfigurationProperties(prefix = "spring.mail")
public class SmtpProperties {
    private String host;
    private Integer port;
    private String username;
    private String password;
    private String from;
    private Boolean propertiesMailSmtpAuth;
    private String propertiesMailTransportProtocol;
    private Boolean propertiesMailSmtpSslEnable;
    private Boolean propertiesMailSmtpStarttlsEnable;
    private Boolean propertiesMailSmtpStarttlsRequired;

    public String getHost() {
        return host;
    }

    public void setHost(String host) {
        this.host = host;
    }

    public Integer getPort() {
        return port;
    }

    public void setPort(Integer port) {
        this.port = port;
    }

    public String getUsername() {
        return username;
    }

    public void setUsername(String username) {
        this.username = username;
    }

    public String getPassword() {
        return password;
    }

    public void setPassword(String password) {
        this.password = password;
    }

    public String getFrom() {
        return from;
    }

    public void setFrom(String from) {
        this.from = from;
    }

    public Boolean getPropertiesMailSmtpAuth() {
        return propertiesMailSmtpAuth;
    }

    public void setPropertiesMailSmtpAuth(Boolean propertiesMailSmtpAuth) {
        this.propertiesMailSmtpAuth = propertiesMailSmtpAuth;
    }

    public String getPropertiesMailTransportProtocol() {
        return propertiesMailTransportProtocol;
    }

    public void setPropertiesMailTransportProtocol(String propertiesMailTransportProtocol) {
        this.propertiesMailTransportProtocol = propertiesMailTransportProtocol;
    }

    public Boolean getPropertiesMailSmtpSslEnable() {
        return propertiesMailSmtpSslEnable;
    }

    public void setPropertiesMailSmtpSslEnable(Boolean propertiesMailSmtpSslEnable) {
        this.propertiesMailSmtpSslEnable = propertiesMailSmtpSslEnable;
    }

    public Boolean getPropertiesMailSmtpStarttlsEnable() {
        return propertiesMailSmtpStarttlsEnable;
    }

    public void setPropertiesMailSmtpStarttlsEnable(Boolean propertiesMailSmtpStarttlsEnable) {
        this.propertiesMailSmtpStarttlsEnable = propertiesMailSmtpStarttlsEnable;
    }

    public Boolean getPropertiesMailSmtpStarttlsRequired() {
        return propertiesMailSmtpStarttlsRequired;
    }

    public void setPropertiesMailSmtpStarttlsRequired(Boolean propertiesMailSmtpStarttlsRequired) {
        this.propertiesMailSmtpStarttlsRequired = propertiesMailSmtpStarttlsRequired;
    }
}