#' Draw an axial or sagittal slice of the MNI152 T1 image
#'
#' This function draws an axial or sagittal slice from the MNI152 T1 image, to
#' plot the vertices of a graph over it. It will optionally write to a file to
#' save the output.
#'
#' @param plane Character string, either 'axial' or 'sagittal'
#' @param slice Integer; the x or z-coordinate of the slice to use
#' @param hemi Character string, either 'L' or 'R'
#' @param save.graph Logical indicating whether or not a png file should be
#'   saved (default: \code{FALSE})
#' @param fname Character string; the name of the file to be saved (default:
#'   \code{NULL})
#' @export
#'
#' @family Plotting functions
#' @seealso \code{\link[oro.nifti]{image.nifti}}

plot_brainGraph_mni <- function(plane=c('axial', 'sagittal'), slice,
                                hemi=c('L', 'R'),
                                save.graph=FALSE, fname=NULL) {
    if (isTRUE(save.graph)) {
      png(filename=fname)
    } else {
      if (length(dev.list()) == 0) {
        dev.new()
      }
    }

    plane <- match.arg(plane)
    if (plane == 'axial') {
      slice <- 46
      X <- mni152
      slicemax <- max(X[, , slice])

    } else {
      hemi <- match.arg(hemi)
      if (hemi == 'R') {
        X <- mni152
      } else if (hemi == 'L') {
        tmp <- mni152@.Data
        X <- nifti(tmp[rev(seq_len(nrow(tmp))), rev(seq_len(ncol(tmp))), ])
      }

      slicemax <- max(X[slice, , ])
    }

    image(X, plot.type='single', plane=plane, z=slice, zlim=c(3500, slicemax))
    par(new=TRUE, mai=c(0, 0, 0, 0), mar=c(0, 0, 0, 0))
}
