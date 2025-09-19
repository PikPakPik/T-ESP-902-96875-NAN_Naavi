package fr.naavi.core.dto;


import com.fasterxml.jackson.annotation.JsonProperty;
import io.swagger.v3.oas.annotations.media.ArraySchema;
import io.swagger.v3.oas.annotations.media.Schema;

import java.util.List;

@SuppressWarnings("unused")
public class PaginatorDTO<T> {
    @ArraySchema(schema = @Schema(description = "List of items for the current page"))
    @JsonProperty("items")
    private List<T> items;

    @Schema(description = "Total number of items across all pages", example = "150")
    @JsonProperty("totalItems")
    private Integer totalItems;

    @Schema(description = "Total number of pages", example = "8")
    @JsonProperty("totalPages")
    private Integer totalPages;

    @Schema(description = "Current page number", example = "2")
    @JsonProperty("currentPage")
    private Integer currentPage;

    @Schema(description = "Next page number if available", example = "3")
    @JsonProperty("nextPage")
    private Integer nextPage;

    @Schema(description = "Previous page number if available", example = "1")
    @JsonProperty("previousPage")
    private Integer previousPage;

    /**
     * Constructs a PaginatorDto with the specified items, total items and pagination DTO.
     *
     * @param items The items to be paginated.
     * @param totalItems The total number of items.
     * @param paginationDTO The pagination DTO.
     */
    public PaginatorDTO(List<T> items, Integer totalItems, PaginationDTO paginationDTO) {
        this.items = items != null ? List.copyOf(items) : List.of();
        this.totalItems = totalItems;
        this.currentPage = paginationDTO.getPage();

        this.totalPages = (int) Math.ceil((double) totalItems / paginationDTO.getLimit());

        this.nextPage = (this.totalPages > 1 && this.currentPage < this.totalPages)
                ? this.currentPage + 1
                : null;

        this.previousPage = (this.currentPage > 1)
                ? this.currentPage - 1
                : null;
    }

    /**
     * Constructs a PaginatorDto with the specified items, total items and pagination DTO.
     *
     * @param items The items to be paginated.
     * @param totalItems The total number of items.
     * @param paginationDTO The pagination DTO.
     * @param <T> The type of the items.
     *
     * @return A PaginatorDto with the specified items, total items and pagination DTO.
     */
    public static <T> PaginatorDTO<T> of(List<T> items, Integer totalItems, PaginationDTO paginationDTO) {
        return new PaginatorDTO<>(items, totalItems, paginationDTO);
    }

    public List<T> getItems() {
        return items != null ? List.copyOf(items) : List.of();
    }

    public void setItems(List<T> items) {
        this.items = items != null ? List.copyOf(items) : List.of();
    }

    public Integer getTotalItems() {
        return totalItems;
    }

    public void setTotalItems(Integer totalItems) {
        this.totalItems = totalItems;
    }

    public Integer getTotalPages() {
        return totalPages;
    }

    public void setTotalPages(Integer totalPages) {
        this.totalPages = totalPages;
    }

    public Integer getCurrentPage() {
        return currentPage;
    }

    public void setCurrentPage(Integer currentPage) {
        this.currentPage = currentPage;
    }

    public Integer getNextPage() {
        return nextPage;
    }

    public void setNextPage(Integer nextPage) {
        this.nextPage = nextPage;
    }

    public Integer getPreviousPage() {
        return previousPage;
    }

    public void setPreviousPage(Integer previousPage) {
        this.previousPage = previousPage;
    }
}
