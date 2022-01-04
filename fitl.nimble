# Package
version     = "0.1.1"
author      = "Charles Blake"
description = "Self-contained fit of linear models with regression diagnostics"
license     = "MIT/ISC"

# Deps
requires    "nim >= 1.6.0"
requires    "spfun >= 0.3.0"
requires    "cligen >= 1.5.20"
installExt  = @[ ".nim" ]
bin         = @[ "fitl" ]
