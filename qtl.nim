proc quantile*[T: SomeFloat, U: SomeFloat](x: openArray[T], Q: U): U =
  ## Compute Parzen Qmid Quantile given sorted openArray[SomeFloat].  For more
  ## motivation of this definition, see Ma, Genton & Parzen 2011: "Asymptotic
  ## properties of sample quantiles of discrete distributions".  Personally, I
  ## see this as far better than any alternative definition and the right
  ## generalization of ancient "mid-ranking ties" ideas in rank correlation
  ## calculations.  It is sadly not as widely used|well known as it should be.
  let n = x.len; let N = float(n)
  if n < 1: return 0.0
  let qN = float(Q) * N
  if qN <= 0.5: return x[0]
  if qN >= N - 0.5: return x[n - 1]
  var iL, jL, iH, jH: int
  var xL, xH, cH, cL: float
  jL = int(qN); iL = jL                   #XXX Could replace scans with exponen.
  xL = x[iL]                              #  ..expanding search for *many* dups.
  while iL > 0 and x[iL-1] == xL: dec(iL)
  while jL < n and x[jL] == xL: inc(jL)
  cL = 0.5 * float(iL + jL)
  if cL <= qN:                            #Scan higher
    iH = jL; jH = iH
    xH = if jH < n: x[jH] else: xL
    while jH < n and x[jH] == xH: inc(jH)
    cH = 0.5 * float(iH + jH)
  else:                                   #Scan lower
    cH = cL; iH = iL; jH = jL; xH = xL    # *H <- *L
    jL = iH; iL = jL
    xL = if iL > 0: x[iL - 1] else: xH
    while iL > 0 and x[iL - 1] == xL: dec(iL)
    cL = 0.5 * float(iL + jL)
  let r = (qN - cL) / (cH - cL)
  return U((1.0 - r) * xL  +  r * xH)

when isMainModule:
  import strutils, algorithm, cligen
  proc qtl(ps: seq[float]) =
    ## Read one column of numbers on stdin; Emit Parzen-interpolated quantiles
    ## for probabilities `ps`. Eg.: *echo 1 1 2 4|tr ' ' '\\n'|qtl 0 .5 1*
    ## writes *1.0 1.66.. 4.0*
    var x: seq[float]
    for line in stdin.lines: x.add parseFloat(line.strip)
    x.sort
    for i, p in ps:
      if i > 0: stdout.write " "      
      stdout.write x.quantile(p)
    stdout.write '\n'
  dispatch qtl
