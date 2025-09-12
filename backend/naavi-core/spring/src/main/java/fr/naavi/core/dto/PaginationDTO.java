package fr.naavi.core.dto;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.Pattern;

import java.util.Locale;

@SuppressWarnings("unused")
public class PaginationDTO {
    public static final String ORDER_ASC = "asc";
    public static final String ORDER_DESC = "desc";

    @Schema(description = "Search term", example = "john")
    private String query;

    @Schema(description = "Page number", example = "1", minimum = "1")
    @Min(value = 1, message = "The page must be greater than 0.")
    private Integer page = 1;

    @Schema(description = "Number of items per page", example = "20", minimum = "1", maximum = "1000")
    @Min(value = 1, message = "The limit must be greater than 0.")
    @Max(value = 1000, message = "The limit cannot exceed 1000.")
    private Integer limit = 20;

    @Schema(description = "Sort field", example = "email")
    private String orderField;

    @Schema(description = "Sort order", example = "asc", allowableValues = {"asc", "desc"})
    @Pattern(regexp = "^(asc|desc)$", message = "The order must be ascending or descending.")
    private String order;

    public String getQuery() {
        return query;
    }

    public Integer getPage() {
        return page;
    }

    public Integer getLimit() {
        return limit;
    }

    public String getOrderField() {
        return orderField != null ? orderField.toLowerCase(Locale.ROOT) : null;
    }

    public String getOrder() {
        return order != null ? order.toUpperCase(Locale.ROOT) : null;
    }

    public void setQuery(String query) {
        this.query = query;
    }

    public void setPage(Integer page) {
        this.page = page;
    }

    public void setLimit(Integer limit) {
        this.limit = limit;
    }

    public void setOrderField(String orderField) {
        this.orderField = orderField;
    }

    public void setOrder(String order) {
        this.order = order;
    }
}
