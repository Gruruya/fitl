## Implement metrics from the book Goodness-of-fit Techniques, 1986 edited by
## Ralph B. D'Agostino and Michael A. Stephens (referred to now as ds86).
import std/[math, random, algorithm], spfun/gauss, basicLA

type              # Open Topology              Circular Topology
  GoFTest* = enum gfD  = "kolmogorovSmirnovD", gfV  = "vKuiper" , # L_infinity
                  gfW2 = "cramerVonMisesW2"  , gfU2 = "watsonU2", # L2 norm
                  gfA2 = "andersonDarlingA2"

  GoFMod* = enum gfFin = "finiteN", gfEst = "estimates"

const gofName*: array[GoFTest, string] = [ "D", "V", "W^2", "U^2", "A^2" ]
const noMod: set[GoFMod] = {}

func kolmogorovSmirnovPM[F](ps: seq[F]): (F, F) =
  let nInv = F(1.0/float(ps.len))                               # ds86 Eq 4.2
  for i, p in ps:       #NOTE: formula converted to 0-origin indexes.
    result[0] = max(result[0], F(i+1)*nInv - p)
    result[1] = max(result[1], p - F(i)*nInv)

func kolmogorovSmirnov*[F](ps: seq[F], mods=noMod): F =
  ## Kolmogorov-Smirnov max(D+,D-) modified by ds86 for estimated mean, var,
  ## finite n. `u01ize` first!
  let (dP, dM) = ps.kolmogorovSmirnovPM                         # ds86 Eq 4.2
  result = max(dP, dM); let n = ps.len.F
  if gfFin in mods: result *= sqrt(n) + F(0.12) + F(0.11)/sqrt(n)
  if gfEst in mods: result *= sqrt(n) - F(0.01) + F(0.85)/sqrt(n)

func kuiperV*[F](ps: seq[F], mods=noMod): F =
  ## Kuiper V=Dp+Dm modified by ds86 for est.mean,var,finite n. `u01ize` first!
  let (dP, dM) = ps.kolmogorovSmirnovPM
  result = dP + dM; let n = ps.len.F                           # ds86 Eq 4.2
  if gfFin in mods: result *= sqrt(n) + F(0.155) + F(0.24)/sqrt(n)
  if gfEst in mods: result *= sqrt(n) + F(0.050) + F(0.82)/sqrt(n)

func cramerVonMises*[F](ps: seq[F], mods=noMod): F =
  ## W^2 modified by ds86 for estimated mean,var, finite n. `u01ize` first!
  let n = ps.len
  let nI2 = F(0.5)/F(n) #NOTE: formula converted to 0-origin indexes.
  result = nI2/F(6) + sum0(j, n, (ps[j] - F(2*j + 1)*nI2)^2)    # ds86 Eq 4.2
  if gfFin in mods: result *= (F(1) - F(0.4)/F(n) + F(0.6)/F(n*n))*(F(1) + F(1)/F(n))
  # Stephens1970, ds86 Table 4.2 & Eq6.19 all say '*',but '/' in ^^^ E.g. 4.4.1
  if gfEst in mods: result *= F(1) + nI2

func watsonU2*[F](ps: seq[F], mods=noMod): F =
  ## Watson U^2 modified by ds86 for estim.mean,var, finite n. `u01ize` first!
  let n = ps.len; let nF = n.F
  let nI2 = F(0.5)/nF   #NOTE: Formula converted to 0-origin indexes.
  let mn = sum0(j, n, F(ps[j]))/nF                              # ds86 Eq 6.18
  result = nI2/F(6) - nF*(mn - 0.5)^2 + sum0(j, n, (ps[j] - F(2*j + 1)*nI2)^2)
  if gfFin in mods: result *= (F(1) - F(0.1)/F(n) + F(0.1)/F(n*n))*(F(1) + F(0.8)/F(n))
  # Stephens1970, ds86 Table 4.2 & Eq6.19 all say '*',but '/' in ^^^ E.g. 4.4.1
  if gfEst in mods: result *= F(1) + nI2

func andersonDarling*[F](ps: seq[F], mods=noMod): F =
  ## A^2 modified by ds86 for estimated mean,var, finite n. `u01ize` first!
  let n = ps.len                                                # ds86 Eq 4.2
  let nInv = F(1)/F(n)  #NOTE: Formula converted to 0-origin indexes.
  result = F(-n) - nInv*sum0(j, n, F(2*j + 1)*ln(ps[j]*(F(1) - ps[n-1-j])))
  if gfEst in mods: result *= F(1) + F(0.75)*nInv + F(2.25)*nInv*nInv

func zscore*[F](xs: var seq[F]; mnVr: (F, F)) =
  ## Unitize a data sample `xs[i]` to its z-scores `(xs[i] - mn)/sqrt(vr))`.
  let scl = F(1)/sqrt(mnVr[1])
  for x in mitems(xs): x -= mnVr[0]; x *= scl

func pitz*[F](zs: var seq[F]) =
  ## z-scores `N(0,1)->U(0,1)` via Probability Integral Transform (PIT).
  for z in mitems(zs): z = gauss.cdf(z)

func u01ize*[F](xs: var seq[F], mnVr: (F, F)) =
  ## Convert into Z-scores, sort, and PIT-transform to be U(0,1)
  xs.zscore mnVr; xs.sort; xs.pitz

func gofStat*[F](sample: var seq[F], mnVr: (F,F), gof=gfA2, mods=noMod, u01d=false): F =
  ## Calculate goodness-of-fit stat for `sample` (clobbering `sample`).
  if not u01d: sample.u01ize(mnVr)
  case gof
  of gfD : sample.kolmogorovSmirnov(mods)
  of gfV : sample.kuiperV(mods)
  of gfW2: sample.cramerVonMises(mods)
  of gfU2: sample.watsonU2(mods)
  of gfA2: sample.andersonDarling(mods)

func gofStat*[F](sample: seq[F], mnVr: (F,F), gof=gfA2, mods=noMod, u01d=false): F =
  ## Calculate goodness-of-fit stat for `sample` (preserving `sample`).
  var sample = sample
  sample.gofStat mnVr, gof, mods, u01d

proc gofDist*[F](cdf: var seq[F], n: int, mV=(0.0,1.0), gof=gfA2, mods=noMod, m=5000) =
  ## Fill `cdf` with CDF of GoF stat `gof` for sample size `n`.  Slow for large `n*m`.
  let (mu, sig) = (mV[0], sqrt(mV[1]))
  var sample = newSeq[F](n)
  cdf.setLen 0
  for k in 1..m:
    for i in 0..<n: sample[i] = gauss.qtl(rand(1.0))*F(sig) + F(mu)
    cdf.add sample.gofStat(sample.mvars, gof, mods)
  cdf.sort

func prob*[F](cdf: seq[F], st: F): F =
  ## Return `P(x <= st)` {p-value}
  cdf.lowerBound(st)/cdf.len #XXX Interpolate via some local cubic polynom fit.

when isMainModule:
  import cligen, strformat
  proc `$`(xs: seq[float]): string =
    result.add $xs[0]
    for x in xs[1..^1]: result.add " "; result.add $x

  type Emit=enum eZ="z", ePITz="PITz", eStat="stat", eDist="dist", eProb="prob"

  proc gof(sample: seq[float], gofs: seq[GoFTest] = @[], adj: set[GoFMod]={},
        emit={eStat}, m=5000, knownM=0.0, knownV=0.0, pval=0.05, ran=true): int=
    ## Tests for a Gaussian shape with known|estimated parameters.  E.g.:
    ##  *gof -g,=,k,v,c,w,a -ep 15 16 17 18 19 19 20 20 21 22 22 23 23 23 24 27*
    ## If `prob` is in `emit` then exit status doubles as a boolean test for
    ## significant departure from a Gaussian at the *alpha* level `pval`.
    if ran: randomize()
    var sample = sample                 #NOTE: Sample variance to match ds86
    let mV   = if knownV == 0.0: sample.mvars else: (knownM, knownV)
    let adj  = if knownV == 0.0 and adj.len == 0: {gfEst} else: adj
    let gofs = if gofs.len == 0: @[ gfA2 ] else: gofs
    sample.zscore mV
    if eZ in emit: echo "zScores: ", sample
    sample.sort; sample.pitz
    if ePITz in emit: echo "PITz: ", sample
    var st: float; var cdf: seq[float]
    var nSignificantDepartures = 0
    for g in gofs:
      if (emit*{eStat,eProb}).len != 0: st = sample.gofStat(mV, g, adj, true)
      if (emit*{eDist,eProb}).len != 0: cdf.gofDist(sample.len, mV, g, adj, m)
      let gName = if adj.len == 0: gofName[g] else: "m" & gofName[g]
      if eStat in emit: echo &"{gName}: {st:.4g}"
      if eProb in emit:
        let p = 1.0 - cdf.prob(st)
        if p < pval: inc nSignificantDepartures
        echo &"P({gName}>val|Gauss): {p:.4g}"
      if eDist in emit: echo &"cdf({gName}): ", cdf
    nSignificantDepartures

  dispatch gof, positional="sample", short={"knownM":'M',"knownV":'V',}, help={
   "sample": "x_1 x_2 .. x_n data sample",
   "gofs":
     "kolmogorovSmirnovD cramerVonMisesW2 `andersonDarlingA2` vKuiper watsonU2",
   "adj"   : "adjust GoF stat for: **estimates** finiteN",
   "emit"  : "emits: z, PITz, stat, dist, prob",
   "m"     : "number of n-samples to estimate CDF",
   "knownM": "Gaussian of known *mean*",
   "knownV": "Gaussian of known *var*; 0 => **estimates**",
   "pval"  : "exit status = number of `prob` < `pval`",
   "ran"   : "randomize() for sampling"}
