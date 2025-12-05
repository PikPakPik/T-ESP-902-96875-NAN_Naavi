package fr.naavi.core.service;

import fr.naavi.core.enums.S3Enum;
import fr.naavi.core.exception.S3Exception;
import fr.naavi.core.properties.S3Properties;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import software.amazon.awssdk.auth.credentials.AwsBasicCredentials;
import software.amazon.awssdk.auth.credentials.StaticCredentialsProvider;
import software.amazon.awssdk.core.sync.RequestBody;
import software.amazon.awssdk.regions.Region;
import software.amazon.awssdk.services.s3.S3Client;
import software.amazon.awssdk.services.s3.model.DeleteObjectRequest;
import software.amazon.awssdk.services.s3.model.PutObjectRequest;

import java.io.InputStream;
import java.net.URI;

@Service
public class S3Service {
    private final S3Client s3Client;
    private final String bucket;

    /**
     * Constructor for the S3Service.
     *
     * @param s3Properties The S3Properties object containing the S3 configuration.
     */
    @Autowired
    public S3Service(S3Properties s3Properties) {
        this.bucket = s3Properties.getBucket();
        this.s3Client = S3Client.builder()
                .region(Region.of(s3Properties.getRegion()))
                .endpointOverride(URI.create(s3Properties.getEndpoint()))
                .forcePathStyle(true)
                .credentialsProvider(StaticCredentialsProvider.create(
                        AwsBasicCredentials.create(
                                s3Properties.getAccessKey(),
                                s3Properties.getSecretKey()
                        )
                ))
                .build();
    }

    /**
     * Upload a file to S3.
     *
     * @param type The type of file to upload.
     * @param inputStream The InputStream containing the file data.
     * @param fileName The name of the file.
     * @param path A custom path to store the file in.
     */
    public void upload(S3Enum type, InputStream inputStream, String fileName, String path) {
        try {
            String key = path != null && !path.isEmpty()
                    ? type.toString() + "/" + path + "/" + fileName
                    : type.toString() + "/" + fileName;

            PutObjectRequest putObjectRequest = PutObjectRequest.builder()
                    .bucket(this.bucket)
                    .key(key)
                    .build();

            byte[] fileContent = inputStream.readAllBytes();
            s3Client.putObject(putObjectRequest, RequestBody.fromBytes(fileContent));
        } catch (Exception e) {
            throw new S3Exception("An error occurred while uploading the file to S3", e);
        }
    }

    /**
     * Delete a file from S3.
     *
     * @param type The type of file to delete.
     * @param fileName The name of the file.
     * @param path A custom path to store the file in.
     */
    public void delete(S3Enum type, String fileName, String path) {
        try {
            String key = path != null && !path.isEmpty()
                    ? type.toString() + "/" + path + "/" + fileName
                    : type.toString() + "/" + fileName;

            DeleteObjectRequest deleteObjectRequest = DeleteObjectRequest.builder()
                    .bucket(this.bucket)
                    .key(key)
                    .build();

            s3Client.deleteObject(deleteObjectRequest);
        } catch (Exception e) {
            throw new S3Exception("An error occurred while deleting the file from S3", e);
        }
    }
}
