#' Approaches to estimate individual network contribution
#'
#' \code{loo} calculates the individual contribution to group network data for
#' each subject in each group using a "leave-one-out" approach. The residuals of
#' a single subject are excluded, and a correlation matrix is created. This is
#' compared to the original correlation matrix using the Mantel test.
#'
#' @param resids Data table of model residuals
#' @param corrs List of lists of correlation matrices (as output by
#'   \code{\link{corr.matrix}}).
#' @param level Character string; the level at which you want to calculate
#'   contributions (either \code{global} or \code{regional})
#' @export
#' @importFrom ade4 mantel.rtest
#'
#' @return A \code{data.table} with columns for
#'   \item{Study.ID}{Subject identifier}
#'   \item{Group}{Group membership}
#'   \item{IC}{The value of the individual contribution}
#'
#' @name IndividualContributions
#' @aliases loo
#' @rdname individ_contrib
#' @examples
#' \dontrun{
#' IC <- loo(resids.all, corrs)
#' RC <- loo(resids.all, corrs, level='regional')
#' }
#' @family Group analysis functions
#' @author Christopher G. Watson, \email{cgwatson@@bu.edu}
#' @references Saggar M., Hosseini S.M.H., Buno J.L., Quintin E., Raman M.M.,
#'   Kesler S.R., Reiss A.L. (2015) \emph{Estimating individual contributions
#'   from group-based structural correlations networks}. NeuroImage, 120:274-284.
#'   doi:10.1016/j.neuroimage.2015.07.006

loo <- function(resids, corrs, level=c('global', 'regional')) {
  Group <- Study.ID <- i <- NULL
  level <- match.arg(level)
  if (level == 'global') {
    IC <- foreach (i=seq_len(nrow(resids)), .combine='c') %dopar% {
      cur.group <- resids[i, Group]
      resids.excl <- resids[-i]
      new.corrs <- corr.matrix(resids.excl[Group == cur.group,
                                           !c('Study.ID', 'Group'),
                                           with=F],
                               density=0.1)$R

      1 - mantel.rtest(as.dist(corrs[[as.numeric(cur.group)]][[1]]$R),
                       as.dist(new.corrs),
                       nrepet=1e3)$obs
    }

    return(data.table(resids[, list(Study.ID, Group)], IC=IC))
  } else if (level == 'regional') {
    RC <- foreach (i=seq_len(nrow(resids)), .combine='rbind') %dopar% {
      cur.group <- resids[i, Group]
      resids.excl <- resids[-i]
      new.corrs <- corr.matrix(resids.excl[Group == cur.group,
                                           !c('Study.ID', 'Group'),
                                           with=F],
                               density=0.1)$R
      colSums(abs(corrs[[as.numeric(cur.group)]][[1]]$R - new.corrs))
    }
    RC.dt <- cbind(resids[, list(Study.ID, Group)], RC)
    RC.m <- melt(RC.dt, id.vars=c('Study.ID', 'Group'),
                 variable.name='region', value.name='RC')
    return(RC.m)
  }
}

#' "Add-one-patient" approach to estimate individual network contribution
#'
#' \code{aop} calculates the individual contribution using an "add-one-patient"
#' approach. The residuals of a single patient are added to those of a control
#' group, and a correlation matrix is created.
#'
#' @param index Integer; the row number (in \code{resids}) of the subject to be
#'   added
#' @param corr.mat Numeric; correlation matrix of the \emph{control} group
#' @export
#' @importFrom ade4 mantel.rtest
#'
#' @aliases aop
#' @rdname individ_contrib
#' @examples
#' \dontrun{
#' IC <- adply(which(resids.all[, Group == groups[2]]), .margins=1, function(x)
#'             aop(resids.all, x, corrs[[1]][[1]]$R),
#'             .parallel=T, .id=NULL)
#' }

aop <- function(resids, index, corr.mat, level=c('global', 'regional')) {
  Group <- Study.ID <- NULL
  ctrl <- resids[, levels(Group)[1]]
  resids.aop <- rbind(resids[index], resids[ctrl])
  new.corr <- corr.matrix(resids.aop[, !c('Study.ID', 'Group'), with=F],
                           density=0.1)$R

  level <- match.arg(level)
  if (level == 'global') {
    r <- 1 - mantel.rtest(as.dist(corr.mat),
                          as.dist(new.corr),
                          nrepet=1e3)$obs
    return(data.table(resids[index, list(Study.ID, Group)], IC=r))
  } else if (level == 'regional') {
    RC <- colSums(abs(corr.mat - new.corr))
    RC.dt <- cbind(resids[index, list(Study.ID, Group)], t(RC))
    RC.m <- melt(RC.dt, id.vars=c('Study.ID', 'Group'),
                 variable.name='region', value.name='RC')
    return(RC.m)
  }
}
