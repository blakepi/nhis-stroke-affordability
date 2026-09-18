cat("pdftools available:", requireNamespace("pdftools", quietly=TRUE), "\n")
if (requireNamespace("pdftools", quietly=TRUE)) {
  for (p in list.files("data/documentation", pattern="[.]pdf$", recursive=TRUE, full.names=TRUE)) {
    dest <- sub("[.]pdf$", ".txt", p)
    if (!file.exists(dest)) {
      pages <- pdftools::pdf_text(p)
      writeLines(paste0("\n===== PDF PAGE ", seq_along(pages), " =====\n", pages), dest)
      cat("Extracted", p, "\n")
    }
  }
}
