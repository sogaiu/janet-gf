# XXX: possibly could be nicer with pegs?
# XXX: could generalize markers, but leave until later
# this works when the script is run from the project directory
(defn patch
  [src-file-path patch-file-path]
  # ensure src-file-path is as expected
  (def src-stat (os/stat src-file-path))
  (unless (and src-stat
               (= :file (src-stat :mode)))
    (eprintf "expected an existing file for: %s" src-file-path)
    (break false))
  # ensure patch-file-path is as expected
  (def patch-stat (os/stat patch-file-path))
  (unless (and patch-stat
               (= :file (patch-stat :mode)))
    (eprintf "expected an existing file for: %s" patch-file-path)
    (break false))
  # read in source lines
  (def src @[])
  (with [in-f (file/open src-file-path :r)]
    (var line (file/read in-f :line))
    (while line
      (array/push src line)
      (set line (file/read in-f :line))))
  # find start of patch marker
  (var patch-start nil)
  (for i 0 (length src)
    (def src-line (get src i))
    (when (string/has-prefix? "//////// start cfun_ts_init ////////"
                              src-line)
      (set patch-start i)
      (break)))
  (unless patch-start
    (eprint "failed to find start of patch marker")
    (break false))
  # find end of patch marker
  (var patch-end nil)
  (for j (inc patch-start) (length src)
    (def src-line (get src j))
    (when (string/has-prefix? "//////// end cfun_ts_init ////////"
                              src-line)
      (set patch-end j)
      (break)))
  (unless patch-end
    (eprint "failed to find end of patch marker")
    (break false))
  # read in patch lines
  (def patch @[])
  (with [in-f (file/open patch-file-path :r)]
    (var line (file/read in-f :line))
    (while line
      (array/push patch line)
      (set line (file/read in-f :line))))
  # assemble final file
  (with [out-f (file/open src-file-path :w)]
    (for i 0 patch-start
      (file/write out-f (get src i)))
    (each patch-line patch
      (file/write out-f patch-line))
    (for j (inc patch-end) (length src)
      (file/write out-f (get src j))))
  true)
