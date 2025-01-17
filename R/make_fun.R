.make_title <- function(opdef) {
    descr_lines <- stringr::str_split(opdef$description, "\n")
    if (length(descr_lines) == 0 ||
        (length(descr_lines) == 1 && descr_lines[1] == "")) {
        descr_lines <- sprintf("API endpoint %s\n#'", opdef$operationId)
    }
    sapply(descr_lines, function(x) sprintf("#' %s", x))
}

.make_params <- function(opdef) {
    sapply(opdef$parameters, function(p) {
        if (!"required" %in% names(p)) {
            p$required <- FALSE
        }
        if (!"description" %in% names(p)) {
            p$description <- ""
        }
        if (is.null(p$description)) {
            p$description <- ""
        }
        sprintf(
            "#' @param %s %s %s %s",
            p$name,
            p$type,
            p$description,
            ifelse(p$required, "(required)", "")
        )
    })
}

.make_family <- function(opdef) {
    vapply(opdef$tags, function(f) sprintf("#' @family %s", f), character(1))
}

.make_func_call <- function(opdef, export = TRUE) {
    vals <- ""
    if (export) {
        vals <- "#' @export"
    }
    vals <- c(vals, sprintf("rb_%s <- function(", opdef$operationId))
    param_lines <- sapply(opdef$parameters, function(p) {
        if (!"required" %in% names(p)) {
            p$required <- FALSE
        }
        ifelse(p$required,
            sprintf("    %s", p$name),
            sprintf("    %s = NULL", p$name)
        )
    })
    vals <- c(vals, paste(param_lines, collapse = ",\n"))
    vals <- c(vals, ")\n")
    vals <- c(vals, sprintf('{
    args = as.list(environment())
    get_by_endpoint("%s", query=args)
}', opdef$path))
    vals
}

make_doc_from_operation <- function(api, operation) {
    defs <- get_operation_definitions(api)
    opdef <- defs[[operation]]
    vals <- .make_title(opdef)
    vals <- c(vals, .make_params(opdef))
    vals <- c(vals, .make_family(opdef))
    vals <- c(vals, .make_func_call(opdef))
    paste(vals, collapse = "\n")
}
